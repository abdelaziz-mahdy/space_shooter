import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../utils/position_util.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/game_logger.dart';
import 'base_rendered_component.dart';
import 'enemies/base_enemy.dart';
import 'damage_number.dart';
import '../game/space_shooter_game.dart';
import '../weapons/weapon_manager.dart';
import 'orbital_drone.dart';

class PlayerShip extends BaseRenderedComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  static const double baseShootInterval = 0.5;
  double shootTimer = 0;
  double shootInterval = baseShootInterval;

  // Weapon system
  late WeaponManager weaponManager;

  PositionComponent? targetEnemy;
  double targetRange = 300;

  // Movement
  double moveSpeed = 162.5; // Reduced from 250 (35% reduction)
  Vector2 velocity = Vector2.zero();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Touch controls
  Vector2? touchStartPosition;
  Vector2? currentTouchPosition;

  // Upgradeable stats - Basic
  double damage = 10;
  double bulletSpeed = 400;
  int projectileCount = 1;
  double maxHealth = 100;
  double health = 100;
  double magnetRadius = 100; // Default attraction radius

  // Upgradeable stats - Advanced
  double healthRegen = 0; // HP per second
  int bulletPierce = 0; // Number of enemies a bullet can hit
  double critChance = 0; // Chance for critical hit (0.0 - 1.0)
  double critDamage = 2.0; // Critical hit multiplier (default 2x)
  double lifesteal = 0; // Percentage of damage healed (0.0 - 1.0)
  double xpMultiplier = 1.0; // XP gain multiplier
  double damageReduction = 0; // Damage reduction percentage (0.0 - 1.0)

  // Upgradeable stats - Special
  double explosionRadius = 0; // Explosion radius on bullet hit
  double homingStrength = 0; // Homing bullet strength
  double freezeChance = 0; // Chance to freeze enemy (0.0 - 1.0)
  double bulletSize = 5.0; // Bullet size multiplier
  int orbitalCount = 0; // Number of orbital shooters
  int shieldLayers = 1; // Energy shield layers (starts with 1)
  int maxShieldLayers = 1; // Maximum shield layers (starts at 1, upgrade to increase)
  double luck = 0; // Better loot drops (0.0 - 1.0+)

  // Scaling stats
  double damageMultiplier = 1.0;
  double attackSizeMultiplier = 1.0;
  double cooldownReduction = 0;

  // Invulnerability frames (prevent multiple collision damage)
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0;
  static const double invulnerabilityDuration = 1.0; // 1 second of immunity after hit

  // Damage number rate limiting (for performance at high levels)
  double _lastDamageNumberTime = 0;
  double _accumulatedDamage = 0;
  static const double damageNumberCooldown = 0.05; // Show damage every 50ms

  // Pushback animation state
  bool isPushingBack = false;
  double pushbackProgress = 0.0;
  Vector2 pushbackStartPos = Vector2.zero();
  Vector2 pushbackEndPos = Vector2.zero();
  static const double pushbackDuration = 0.5; // 0.5 seconds smooth animation (doubled from 0.25s)

  // Time/Wave mechanics
  double berserkThreshold = 0.3;
  double berserkMultiplier = 0;
  double killStreakBonus = 0;
  int killStreakCount = 0;
  double? globalTimeScale; // Time scale multiplier (affects enemy speed)

  // Helper getters
  bool get isBerserk => (health / maxHealth) < berserkThreshold && berserkMultiplier > 1.0;

  // Defensive mechanics
  double thornsPercent = 0;
  double lastStandShield = 0;
  bool hasResurrected = false;

  // Offensive mechanics
  double chainLightningChance = 0;
  int chainCount = 0;
  double bleedDamage = 0;
  bool hasDoubleShot = false;
  double doubleShotChance = 0;

  // Utility
  double resurrectionChance = 0;
  double shieldRegenTimer = 0;
  double shieldRegenInterval = 15.0; // Regenerate shield every 15 seconds

  // Orbital drones list
  final List<OrbitalDrone> _orbitals = [];
  int _lastOrbitalCount = 0;

  // Track applied upgrades for leaderboard
  final List<String> appliedUpgrades = [];

  PlayerShip({required Vector2 position, double scale = 1.0})
    : super(position: position, size: Vector2(30, 30) * scale);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Initialize weapon manager
    weaponManager = WeaponManager();
    add(weaponManager);

    // Triangle hitbox matching the rendered triangle (from top-left coordinate system)
    final h = size.y;
    final w = size.x;
    final topY = h / 6;       // 1/6 down from top
    final bottomY = 5 * h / 6; // 5/6 down from top

    add(
      PolygonHitbox([
        Vector2(w / 2, topY),  // Top center
        Vector2(w, bottomY),   // Bottom right
        Vector2(0, bottomY),   // Bottom left
      ]),
    );
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  void handleKeyDown(LogicalKeyboardKey key) {
    _pressedKeys.add(key);
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    _pressedKeys.remove(key);
  }

  void handleTouchStart(Vector2 touchPosition) {
    touchStartPosition = touchPosition;
    currentTouchPosition = touchPosition;
  }

  void handleTouchMove(Vector2 touchPosition) {
    currentTouchPosition = touchPosition;
  }

  void handleTouchEnd() {
    touchStartPosition = null;
    currentTouchPosition = null;
    velocity = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    // Update invulnerability timer
    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
        invulnerabilityTimer = 0;
      }
    }

    // Update pushback animation
    if (isPushingBack) {
      pushbackProgress += dt / pushbackDuration;

      if (pushbackProgress >= 1.0) {
        // Animation complete
        isPushingBack = false;
        pushbackProgress = 0.0;
        position = pushbackEndPos.clone();
      } else {
        // Cubic ease-out interpolation for smooth deceleration
        final t = pushbackProgress;
        final easeOut = (1 - pow(1 - t, 3)).toDouble();

        position = pushbackStartPos + (pushbackEndPos - pushbackStartPos) * easeOut;
      }
    }

    // Update orbital drones when count changes
    _updateOrbitals();

    // Handle keyboard movement
    velocity = Vector2.zero();

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      velocity.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      velocity.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      velocity.x += 1;
    }

    // Handle touch movement (virtual joystick)
    if (touchStartPosition != null && currentTouchPosition != null) {
      final offset = currentTouchPosition! - touchStartPosition!;
      final maxOffset = 50.0;

      velocity = Vector2(
        (offset.x / maxOffset).clamp(-1.0, 1.0),
        (offset.y / maxOffset).clamp(-1.0, 1.0),
      );
    }

    // Normalize and apply velocity (don't move during pushback)
    if (velocity.length > 0 && !isPushingBack) {
      velocity.normalize();
      position += velocity * moveSpeed * dt;
      // No bounds clamping - infinite world with camera following player
    }

    // Health regeneration
    if (healthRegen > 0) {
      health = min(health + healthRegen * dt, maxHealth);
    }

    // Shield regeneration timer
    shieldRegenTimer += dt;
    if (shieldRegenTimer >= shieldRegenInterval && shieldRegenInterval > 0) {
      shieldLayers = min(shieldLayers + 1, maxShieldLayers);
      shieldRegenTimer = 0;
    }

    // Find nearest enemy
    findNearestEnemy();

    // Auto-shoot at target
    shootTimer += dt;
    if (shootTimer >= shootInterval && targetEnemy != null) {
      shoot();
      shootTimer = 0;
    }

    // Rotate to face target with smooth animation
    if (targetEnemy != null) {
      // Use PositionUtil for consistent direction calculation
      final direction = PositionUtil.getRelativePosition(this, targetEnemy!);
      final targetAngle = atan2(direction.y, direction.x) + pi / 2;

      // Smooth rotation
      final angleDiff = targetAngle - angle;
      final normalizedDiff = (angleDiff + pi) % (2 * pi) - pi;
      angle += normalizedDiff * 10 * dt; // Adjust rotation speed
    }
  }

  void findNearestEnemy() {
    PositionComponent? nearest;
    double nearestDistance = double.infinity;

    // Use cached enemy list from game (refreshed once per frame)
    final allEnemies = gameRef.activeEnemies;

    for (final enemy in allEnemies) {
      // Use PositionUtil for consistent distance calculation
      final distance = PositionUtil.getDistance(this, enemy);
      if (distance < nearestDistance && distance <= targetRange) {
        nearestDistance = distance;
        nearest = enemy;
      }
    }

    targetEnemy = nearest;
  }

  void shoot() {
    if (targetEnemy == null) return;

    // Use PositionUtil for consistent direction calculation
    final direction = PositionUtil.getDirectionTo(this, targetEnemy!);

    // Use weapon manager to fire current weapon
    weaponManager.fireCurrentWeapon(this, direction, targetEnemy);

    // Play shoot sound effect
    gameRef.audioManager.playShoot();
  }

  /// Apply knockback force to push player away from enemy with smooth animation
  void _applyPushback(Vector2 direction) {
    // Don't start new pushback if already pushing back
    if (isPushingBack) return;

    // Use percentage-based pushback (15% of screen width) for responsive design
    final pushbackDistance = gameRef.size.x * 0.15;

    // Set up animation
    isPushingBack = true;
    pushbackProgress = 0.0;
    pushbackStartPos = position.clone();
    pushbackEndPos = position + (direction * pushbackDistance);
  }

  void takeDamage(double damage, {Vector2? pushbackDirection}) {
    // Invulnerability frames prevent multiple hits
    if (isInvulnerable) return;

    // Shield blocks damage
    if (shieldLayers > 0) {
      shieldLayers--;
      // Show "BLOCKED!" text
      final blockedText = DamageNumber(
        position: position.clone(),
        damage: 0,
        isPlayerDamage: false,
      );
      gameRef.world.add(blockedText);

      // Apply pushback even when shield absorbs damage
      if (pushbackDirection != null) {
        _applyPushback(pushbackDirection);
      }

      // Start invulnerability frames
      isInvulnerable = true;
      invulnerabilityTimer = invulnerabilityDuration;

      return; // Shield absorbed hit
    }

    // Apply damage reduction with global 60% cap
    final cappedReduction = damageReduction.clamp(0.0, 0.60);
    final actualDamage = damage * (1.0 - cappedReduction);

    // Accumulate damage and show merged numbers every 50ms
    final now = gameRef.gameTime;
    _accumulatedDamage += actualDamage;

    if (now - _lastDamageNumberTime >= damageNumberCooldown) {
      final damageNumber = DamageNumber(
        position: position.clone(),
        damage: _accumulatedDamage,
        isPlayerDamage: true,
      );
      gameRef.world.add(damageNumber);
      _lastDamageNumberTime = now;
      _accumulatedDamage = 0;
    }

    // Apply pushback
    if (pushbackDirection != null) {
      _applyPushback(pushbackDirection);
    }

    // Start invulnerability frames
    isInvulnerable = true;
    invulnerabilityTimer = invulnerabilityDuration;

    health -= actualDamage;

    if (health <= 0) {
      // Check for resurrection
      if (!hasResurrected && resurrectionChance > 0 && Random().nextDouble() < resurrectionChance) {
        health = maxHealth * 0.25; // Resurrect with 25% health
        hasResurrected = true;
        return;
      }

      health = 0;
      gameRef.gameOver();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    // Draw shield layers first (behind ship)
    if (shieldLayers > 0) {
      final center = Offset(size.x / 2, size.y / 2);

      for (int i = 0; i < shieldLayers; i++) {
        final shieldRadius = (size.x / 2) + 8 + (i * 6);
        final shieldPaint = Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        canvas.drawCircle(center, shieldRadius, shieldPaint);

        // Add glow effect
        final glowPaint = Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0;

        canvas.drawCircle(center, shieldRadius, glowPaint);
      }
    }

    // Draw from top-left (0,0) - anchor will handle centering
    // Triangle pointing up with centroid offset
    final h = size.y;
    final w = size.x;

    // For anchor.center to work correctly, draw triangle within bounds (0,0) to (size.x, size.y)
    // Top point at (w/2, h/6), bottom edge at y = 5h/6
    final topY = h / 6;  // 1/6 down from top
    final bottomY = 5 * h / 6;  // 5/6 down from top

    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(w / 2, topY)  // Top center
      ..lineTo(w, bottomY)   // Bottom right
      ..lineTo(0, bottomY)   // Bottom left
      ..close();

    canvas.drawPath(path, paint);

    // Draw health bar below the triangle
    final healthBarWidth = size.x + 20;
    final healthBarHeight = 4.0;
    final healthBarY = size.y + 5;  // Just below component

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        (size.x - healthBarWidth) / 2,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()
      ..color = healthPercent > 0.5
          ? const Color(0xFF00FF00)
          : healthPercent > 0.25
          ? const Color(0xFFFFFF00)
          : const Color(0xFFFF0000);
    canvas.drawRect(
      Rect.fromLTWH(
        (size.x - healthBarWidth) / 2,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );

    // Draw XP bar below health bar
    final xpBarY = healthBarY + healthBarHeight + 2;
    final xpBarWidth = healthBarWidth;
    final xpBarHeight = 3.0;

    final xpBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        (size.x - xpBarWidth) / 2,
        xpBarY,
        xpBarWidth,
        xpBarHeight,
      ),
      xpBgPaint,
    );

    final xpPercent = gameRef.levelManager.getXPProgress();
    final xpPaint = Paint()..color = const Color(0xFF00FFFF); // Cyan
    canvas.drawRect(
      Rect.fromLTWH(
        (size.x - xpBarWidth) / 2,
        xpBarY,
        xpBarWidth * xpPercent,
        xpBarHeight,
      ),
      xpPaint,
    );

    // Draw level text above health bar
    final levelText = 'Lv${gameRef.levelManager.getLevel()}';
    final levelTextPainter = TextPainter(
      text: TextSpan(
        text: levelText,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Color(0xFF000000),
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    levelTextPainter.layout();
    levelTextPainter.paint(
      canvas,
      Offset((size.x - levelTextPainter.width) / 2, healthBarY - 12),
    );

    // Draw shield indicator only if player has shield capacity
    if (maxShieldLayers > 0) {
      final shieldY = xpBarY + xpBarHeight + 2;
      final shieldText = '🛡️ $shieldLayers/$maxShieldLayers';
      final shieldTextPainter = TextPainter(
        text: TextSpan(
          text: shieldText,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0xFF000000),
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      shieldTextPainter.layout();
      shieldTextPainter.paint(
        canvas,
        Offset((size.x - shieldTextPainter.width) / 2, shieldY),
      );
    }
  }

  /// Update orbital drones when count changes
  void _updateOrbitals() {
    if (orbitalCount == _lastOrbitalCount) return;

    // Remove all existing orbitals
    for (final orbital in _orbitals) {
      orbital.removeFromParent();
    }
    _orbitals.clear();

    // Add new orbitals
    for (int i = 0; i < orbitalCount; i++) {
      final orbital = OrbitalDrone(
        player: this,
        index: i,
        totalOrbitals: orbitalCount,
      );
      gameRef.world.add(orbital);
      _orbitals.add(orbital);
    }

    _lastOrbitalCount = orbitalCount;
    GameLogger.debug('Updated orbitals: $orbitalCount drones', tag: 'PlayerShip');
  }

}
