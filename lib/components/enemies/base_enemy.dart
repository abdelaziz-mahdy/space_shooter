import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game/space_shooter_game.dart';
import '../../utils/visual_center_mixin.dart';
import '../../utils/position_util.dart';
import '../../config/balance_config.dart';
import '../base_rendered_component.dart';
import '../damage_number.dart';
import '../loot.dart';
import '../../factories/power_up_factory.dart';
import '../player_ship.dart';

/// Abstract base class for all enemy types
/// Provides common functionality like health, damage, loot drops, and collision handling
abstract class BaseEnemy extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  final PlayerShip player;
  final int wave;

  double health;
  final double maxHealth;
  final double speed;
  final int lootValue;
  final Color color;
  double contactDamage;

  // Death guard to prevent double-death
  bool isDying = false;

  // Freeze effect
  bool isFrozen = false;
  double freezeTimer = 0;
  double freezeSlowMultiplier = 1.0;

  // Bleed effect
  bool isBleeding = false;
  double bleedTimer = 0;
  double bleedDamagePerSecond = 0;
  static const double bleedDuration = 3.0; // 3 seconds

  // Damage number rate limiting (for performance at high levels)
  double _lastDamageNumberTime = 0;
  double _accumulatedDamage = 0;
  bool _wasLastCrit = false;

  // Collision behavior
  static const double bossHealthThreshold = 100.0; // Enemies with health >= this survive collision

  BaseEnemy({
    required Vector2 position,
    required this.player,
    required this.wave,
    required this.health,
    required this.speed,
    required this.lootValue,
    required this.color,
    required Vector2 size,
    this.contactDamage = 10.0,
  })  : maxHealth = health,
        super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Subclasses should add their own hitboxes
    await addHitbox();
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  /// Override this to add custom hitbox for each enemy type
  Future<void> addHitbox();

  /// Override this for custom movement behavior
  void updateMovement(double dt);

  /// Override this to make enemy non-targetable (e.g., invulnerable bosses)
  /// When false, weapons and auto-targeting will skip this enemy
  bool get isTargetable => true;

  /// Apply freeze effect to this enemy
  void applyFreeze(double duration) {
    isFrozen = true;
    freezeTimer = duration;
    freezeSlowMultiplier = 0.3; // Move at 30% speed when frozen
  }

  /// Apply bleed effect to this enemy
  void applyBleed(double damagePerSecond) {
    if (damagePerSecond <= 0) return;
    isBleeding = true;
    bleedTimer = bleedDuration;
    bleedDamagePerSecond = damagePerSecond;
  }

  /// Get current effective speed (accounting for freeze and global time scale)
  double getEffectiveSpeed() {
    final globalTimeScale = game.player.globalTimeScale ?? 1.0;
    return speed * freezeSlowMultiplier * globalTimeScale;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update freeze timer
    if (isFrozen) {
      freezeTimer -= dt;
      if (freezeTimer <= 0) {
        isFrozen = false;
        freezeTimer = 0;
        freezeSlowMultiplier = 1.0;
      }
    }

    // Update bleed effect
    if (isBleeding) {
      bleedTimer -= dt;
      // Apply bleed damage over time (no damage number to avoid spam)
      final bleedDamage = bleedDamagePerSecond * dt;
      health -= bleedDamage;

      if (health <= 0) {
        die();
        return;
      }

      if (bleedTimer <= 0) {
        isBleeding = false;
        bleedTimer = 0;
        bleedDamagePerSecond = 0;
      }
    }

    // Call custom movement logic
    updateMovement(dt);
  }

  /// Take damage with optional damage modification
  /// Shows damage number automatically - weapons don't need to handle this
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    final actualDamage = modifyIncomingDamage(damage);
    health -= actualDamage;

    // Accumulate damage and show merged numbers every 50ms
    if (showDamageNumber && actualDamage > 0) {
      final now = game.gameTime;
      _accumulatedDamage += actualDamage;
      _wasLastCrit = _wasLastCrit || isCrit; // Track if any hit was a crit

      if (now - _lastDamageNumberTime >= BalanceConfig.damageNumberCooldown) {
        final damageNumber = DamageNumber(
          position: position.clone(),
          damage: _accumulatedDamage,
          isCrit: _wasLastCrit,
        );
        game.world.add(damageNumber);
        _lastDamageNumberTime = now;
        _accumulatedDamage = 0;
        _wasLastCrit = false;
      }
    }

    // Apply bleed effect if player has bleed damage
    // Scale bleed damage with current wave (1 + 0.3 per wave after wave 1)
    if (player.bleedDamage > 0) {
      final waveMultiplier = 1.0 + ((game.enemyManager.getCurrentWave() - 1) * 0.3);
      final scaledBleedDamage = player.bleedDamage * waveMultiplier;
      applyBleed(scaledBleedDamage);
    }

    if (health <= 0) {
      die();
    }
  }

  /// Override this to modify incoming damage (e.g., Tank's damage reduction)
  double modifyIncomingDamage(double damage) {
    return damage;
  }

  /// Override this for custom death behavior (e.g., Kamikaze's explosion)
  void onDeath() {
    // Subclasses can override for custom death effects
  }

  /// Find the closest loot within merge radius from position, or null if none exist
  Loot? _findClosestLootNearby(Vector2 dropPosition) {
    Loot? closestLoot;
    double closestDistance = BalanceConfig.lootMergeRadius;

    // Find all nearby loot entities
    final allLoot = game.world.children.whereType<Loot>();
    for (final loot in allLoot) {
      final distance = PositionUtil.getDistance(
        PositionComponent(position: dropPosition),
        loot,
      );
      if (distance < closestDistance && distance <= BalanceConfig.lootMergeRadius) {
        closestDistance = distance;
        closestLoot = loot;
      }
    }

    return closestLoot;
  }

  /// Drop or merge a single loot value, preferring to merge with nearby loot
  void _dropOrMergeLoot(Vector2 dropPosition, int xpValue) {
    // Try to find existing loot to merge with
    final closestLoot = _findClosestLootNearby(dropPosition);

    if (closestLoot != null) {
      // Merge with existing loot by increasing its XP value
      // This is more efficient than creating a new entity
      closestLoot.xpValue += xpValue;
    } else {
      // No nearby loot, create a new one
      final loot = Loot(
        position: dropPosition,
        xpValue: xpValue,
      );
      game.world.add(loot);
    }
  }

  /// Drop XP in merged cores to reduce entity count
  /// XP tiers: 1 XP (cyan), 5 XP (green), 10 XP (yellow), 25 XP (orange), 50 XP (pink), 100 XP (red), 250 XP (purple)
  void _dropMergedXP(int totalXP) {
    if (totalXP <= 0) return;

    // Merge into larger cores for better performance
    // Priority: 250 > 100 > 50 > 25 > 10 > 5 > 1
    int remaining = totalXP;

    // Drop 250 XP cores (purple) - mega orbs
    while (remaining >= 250) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 250);
      remaining -= 250;
    }

    // Drop 100 XP cores (red) - huge orbs
    while (remaining >= 100) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 100);
      remaining -= 100;
    }

    // Drop 50 XP cores (pink) - very large orbs
    while (remaining >= 50) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 50);
      remaining -= 50;
    }

    // Drop 25 XP cores (orange) - large orbs
    while (remaining >= 25) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 25);
      remaining -= 25;
    }

    // Drop 10 XP cores (yellow) - medium orbs
    while (remaining >= 10) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 10);
      remaining -= 10;
    }

    // Drop 5 XP cores (green) - small orbs
    while (remaining >= 5) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 5);
      remaining -= 5;
    }

    // Drop remaining 1 XP cores (cyan) - tiny orbs
    for (int i = 0; i < remaining; i++) {
      final dropPosition = position.clone() + Vector2.random() * 20 - Vector2.all(10);
      _dropOrMergeLoot(dropPosition, 1);
    }
  }

  /// Called when enemy dies - handles loot drops and cleanup
  void die() {
    // Prevent double-death (race condition when multiple damage sources kill enemy simultaneously)
    if (isDying) {
      print('[BaseEnemy] die() called but already dying - IGNORED for ${runtimeType}');
      return;
    }
    isDying = true;

    print('[BaseEnemy] die() called for ${runtimeType} - wave=${game.enemyManager.getCurrentWave()}, isMounted=$isMounted');

    // Play explosion sound
    game.audioManager.playExplosion();

    // Call custom death behavior first
    onDeath();

    // Drop XP loot - merge into higher-tier cores to reduce entity count
    _dropMergedXP(lootValue);

    // Random chance to drop power-up (affected by player luck)
    final random = Random();
    final dropChance = 0.08 + (player.luck * 0.1); // Base 8% + luck bonus

    if (random.nextDouble() < dropChance) {
      // Create random power-up using factory
      final powerUp = PowerUpFactory.createRandom(position.clone());
      game.world.add(powerUp);
      print('[${runtimeType}] Dropped power-up: ${powerUp.runtimeType}');
    }

    // Increment kill count
    final beforeKills = game.statsManager.enemiesKilledInWave;
    game.statsManager.incrementKills();
    final afterKills = game.statsManager.enemiesKilledInWave;
    print('[BaseEnemy] Kill count incremented: ${beforeKills} -> ${afterKills} (total in wave)');

    // Add kill to combo meter
    game.comboManager.addKill();

    print('[BaseEnemy] Calling removeFromParent() for ${runtimeType}');
    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      // Calculate pushback direction (away from enemy)
      final pushbackDirection = PositionUtil.getDirectionTo(this, other);

      // Deal damage with pushback
      other.takeDamage(contactDamage, pushbackDirection: pushbackDirection);

      // Apply thorns damage reflection
      if (player.thornsPercent > 0) {
        final thornsDamage = contactDamage * player.thornsPercent; // thornsPercent already a fraction (0.0-0.5)

        // Show thorns damage with special visual indicator
        final thornsDamageNumber = DamageNumber(
          position: position.clone(),
          damage: thornsDamage,
          isThorns: true,
        );
        game.world.add(thornsDamageNumber);

        // Apply the damage (without showing duplicate damage number)
        takeDamage(thornsDamage, showDamageNumber: false);
      }

      // Only kill weak enemies on collision, bosses survive
      // Bosses have high max HP and should not die from ramming
      // Use maxHealth instead of health to prevent damaged bosses from dying
      if (maxHealth < bossHealthThreshold) {
        die(); // Small enemies die on collision with player
      }
    }
  }

  /// Helper method to draw health bar
  void renderHealthBar(Canvas canvas) {
    final healthBarWidth = size.x;
    final healthBarHeight = 3.0;
    final healthBarY = -5.0; // Above the component

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()..color = const Color(0xFF00FF00);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }

  /// Helper method to render freeze effect
  void renderFreezeEffect(Canvas canvas) {
    if (!isFrozen) return;

    // Blue overlay to indicate frozen state
    final freezePaint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw freeze overlay over the enemy
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      freezePaint,
    );

    // Draw ice crystal border
    final borderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }

  /// Helper method to render bleed effect
  void renderBleedEffect(Canvas canvas) {
    if (!isBleeding) return;

    // Red pulsing border to indicate bleeding
    final borderPaint = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }
}
