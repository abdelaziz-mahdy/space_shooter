import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// The Shielder Boss - Wave 5 Boss
/// - Large dodecagon (12 sides), deep blue with cyan shield layers
/// - Health: 500 + (wave * 75)
/// - Special: 3 rotating shield layers that regenerate
/// - Movement: Orbits player at medium distance with occasional dashes
/// - Attack: 8-way spread bullets (cardinal + diagonal)
class ShielderBoss extends BaseEnemy {
  static const String ID = 'shielder_boss';

  // Movement constants
  static const double orbitDistance = 350;
  static const double orbitSpeed = 50;
  static const double dashSpeed = 200;
  static const double dashInterval = 5.0;
  static const double dashDuration = 0.8;

  // Combat constants
  static const double shootIntervalShielded = 1.5;
  static const double shootIntervalUnshielded = 0.8; // Faster when vulnerable
  static const double bulletSpeed = 150;
  static const double bulletDamage = 20;
  static const double bulletSize = 12; // Large bullets

  // Shield constants
  static const int maxShieldLayers = 3;
  static const double shieldHealthPerLayer = 100;
  static const double shieldRegenInterval = 8.0; // Time to regen after not being hit
  static const double shieldRotationSpeed = 2.0; // radians per second
  static const double noHitRequiredForRegen = 5.0; // Must not be hit for 5s before regen starts

  // State
  double shootTimer = 0;
  double dashTimer = 0;
  double dashCooldown = 0;
  bool isDashing = false;
  Vector2? dashDirection;

  // Shield state
  int shieldLayers = maxShieldLayers;
  double currentShieldHealth = shieldHealthPerLayer;
  double shieldRegenTimer = 0;
  double shieldRotation = 0;
  double timeSinceLastHit = 0; // Track time since last damage taken

  ShielderBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 500 + (wave * 75),
          speed: 30 + (wave * 0.5),
          lootValue: 40,
          color: const Color(0xFF0000FF), // Deep blue
          size: Vector2(60, 60) * scale,
          contactDamage: 35.0,
        );

  @override
  Future<void> addHitbox() async {
    // Dodecagon (12 sides) hitbox
    final sides = 12;
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      points.add(Vector2(
        centerX + cos(angle) * size.x / 2,
        centerY + sin(angle) * size.y / 2,
      ));
    }

    add(PolygonHitbox(points));
  }

  bool get hasShields => shieldLayers > 0 || currentShieldHealth > 0;

  double get currentSpeed => hasShields ? speed : speed * 1.5;

  double get currentShootInterval => hasShields ? shootIntervalShielded : shootIntervalUnshielded;

  @override
  void updateMovement(double dt) {
    final distanceToPlayer = PositionUtil.getDistance(this, player);
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);

    // Update shield rotation
    shieldRotation += shieldRotationSpeed * dt;
    if (shieldRotation > 2 * pi) {
      shieldRotation -= 2 * pi;
    }

    // Update time since last hit
    timeSinceLastHit += dt;

    // Update shield regeneration - only if not hit for a while
    if (shieldLayers < maxShieldLayers && timeSinceLastHit >= noHitRequiredForRegen) {
      shieldRegenTimer += dt;
      if (shieldRegenTimer >= shieldRegenInterval) {
        regenerateShield();
        shieldRegenTimer = 0;
      }
    }

    // Dash logic
    if (isDashing) {
      dashCooldown += dt;
      if (dashCooldown >= dashDuration) {
        isDashing = false;
        dashCooldown = 0;
        dashDirection = null;
      } else if (dashDirection != null) {
        position += dashDirection! * dashSpeed * dt;
      }
    } else {
      // Normal orbital movement
      dashTimer += dt;
      if (dashTimer >= dashInterval && distanceToPlayer > 100) {
        // Initiate dash toward player
        isDashing = true;
        dashDirection = directionToPlayer.clone();
        dashTimer = 0;
        print('[ShielderBoss] Dashing toward player!');
      } else {
        // Orbit around player
        final targetDistance = orbitDistance;

        if (distanceToPlayer < targetDistance - 50) {
          // Too close - move away
          position += directionToPlayer * -currentSpeed * dt;
        } else if (distanceToPlayer > targetDistance + 50) {
          // Too far - move closer
          position += directionToPlayer * getEffectiveSpeed() * dt;
        } else {
          // Perfect distance - strafe in a circle
          final perpendicular = Vector2(-directionToPlayer.y, directionToPlayer.x);
          position += perpendicular * orbitSpeed * dt;
        }
      }
    }

    // Always face player
    angle = atan2(directionToPlayer.y, directionToPlayer.x) + pi / 2;

    // Handle shooting
    shootTimer += dt;
    if (shootTimer >= currentShootInterval) {
      shoot8Way();
      shootTimer = 0;
    }
  }

  void shoot8Way() {
    // Get direction to player
    final toPlayer = PositionUtil.getDirectionTo(this, player);
    final baseAngle = atan2(toPlayer.y, toPlayer.x);

    // Shoot 8 bullets in a spread, centered on player direction
    // This ensures some bullets always go toward the player
    for (int i = 0; i < 8; i++) {
      final spreadAngle = baseAngle + (i * pi / 4); // 45 degrees apart
      final bulletDirection = Vector2(cos(spreadAngle), sin(spreadAngle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: bulletDirection,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      // Make bullets larger
      bullet.size = Vector2(bulletSize, bulletSize);

      gameRef.world.add(bullet);
    }

    print('[ShielderBoss] Fired 8-way spread (shields: $shieldLayers, health: ${currentShieldHealth.toStringAsFixed(0)})');
  }

  void regenerateShield() {
    shieldLayers++;
    currentShieldHealth = shieldHealthPerLayer;
    print('[ShielderBoss] Shield regenerated! Layers: $shieldLayers');
  }

  @override
  double modifyIncomingDamage(double damage) {
    // Reset hit timer - player is actively attacking
    timeSinceLastHit = 0;
    shieldRegenTimer = 0; // Reset regen progress when hit

    if (hasShields) {
      // Shield absorbs damage
      currentShieldHealth -= damage;

      if (currentShieldHealth <= 0) {
        // Shield layer broken
        shieldLayers--;

        if (shieldLayers > 0) {
          // Still have layers, reset shield health
          currentShieldHealth = shieldHealthPerLayer;
        } else {
          // All shields gone
          currentShieldHealth = 0;
        }

        print('[ShielderBoss] Shield layer broken! Remaining: $shieldLayers');
      }

      // Shield absorbed all damage
      return 0;
    }

    // No shields - take full damage
    return damage;
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw dodecagon (12 sides)
    final sides = 12;
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = centerX + cos(angle) * size.x / 2;
      final y = centerY + sin(angle) * size.y / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw shield layers
    if (hasShields) {
      renderShields(canvas, centerX, centerY);
    }

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2 + 8,
      bossPaint,
    );

    // Draw freeze effect if frozen
    renderFreezeEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);

    // Draw shield bar below health bar
    if (shieldLayers > 0 || currentShieldHealth > 0) {
      renderShieldBar(canvas);
    }
  }

  void renderShields(Canvas canvas, double centerX, double centerY) {
    final shieldPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4) // Cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw rotating hexagons for each shield layer
    for (int layer = 0; layer < shieldLayers; layer++) {
      final radius = (size.x / 2) + 10 + (layer * 8);
      final hexPath = Path();
      final hexSides = 6;

      for (int i = 0; i < hexSides; i++) {
        // Add rotation based on layer and time
        final angle = (i * 2 * pi / hexSides) + shieldRotation + (layer * pi / 3);
        final x = centerX + cos(angle) * radius;
        final y = centerY + sin(angle) * radius;

        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();

      canvas.drawPath(hexPath, shieldPaint);
    }

    // If current layer is damaged, show it with reduced opacity
    if (currentShieldHealth < shieldHealthPerLayer && shieldLayers > 0) {
      final damagedPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final layer = shieldLayers - 1;
      final radius = (size.x / 2) + 10 + (layer * 8);
      final hexPath = Path();
      final hexSides = 6;

      for (int i = 0; i < hexSides; i++) {
        final angle = (i * 2 * pi / hexSides) + shieldRotation + (layer * pi / 3);
        final x = centerX + cos(angle) * radius;
        final y = centerY + sin(angle) * radius;

        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();

      canvas.drawPath(hexPath, damagedPaint);
    }
  }

  void renderShieldBar(Canvas canvas) {
    final shieldBarWidth = size.x;
    final shieldBarHeight = 2.0;
    final shieldBarY = -9.0; // Below health bar

    // Background
    final shieldBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(0, shieldBarY, shieldBarWidth, shieldBarHeight),
      shieldBgPaint,
    );

    // Calculate shield percentage
    final totalShieldHealth = shieldLayers * shieldHealthPerLayer + currentShieldHealth;
    final maxShieldHealth = maxShieldLayers * shieldHealthPerLayer;
    final shieldPercent = totalShieldHealth / maxShieldHealth;

    // Draw shield bar
    final shieldPaint = Paint()..color = const Color(0xFF00FFFF); // Cyan
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        shieldBarY,
        shieldBarWidth * shieldPercent,
        shieldBarHeight,
      ),
      shieldPaint,
    );
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return ShielderBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 5 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 5) {
      return 1.0; // Boss wave
    }
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
