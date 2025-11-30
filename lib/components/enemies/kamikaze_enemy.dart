import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Kamikaze Enemy: Suicide bomber with explosion
/// - Pulsing circle, red with warning pulses, size 18x18
/// - Health: 25 + (wave * 1.5), Speed: 100 + (wave * 3.75)
/// - Speeds up as it gets closer to player
/// - Explodes on death (60 radius, 20 damage)
/// - Always explodes even if shot down
/// - IMPORTANT: No contact damage - only explosion damage on death!
class KamikazeEnemy extends BaseEnemy {
  static const String ID = 'kamikaze';
  static const double explosionRadius = 60; // Reduced from 80
  static const double explosionDamage = 20; // Reduced from 30
  static const double accelerationDistance = 200; // Distance to start accelerating

  double pulseTimer = 0;

  KamikazeEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 25 + (wave * 1.5),
          speed: 100 + (wave * 3.75),
          lootValue: 1,
          color: const Color(0xFFFF0000), // Red
          size: Vector2(18, 18) * scale,
          contactDamage: 0.0, // No contact damage - only explosion damage!
        );

  @override
  Future<void> addHitbox() async {
    // Circle hitbox
    add(CircleHitbox());
  }

  @override
  void updateMovement(double dt) {
    pulseTimer += dt;

    final distanceToPlayer = PositionUtil.getDistance(this, player);
    final direction = PositionUtil.getDirectionTo(this, player);

    // Speed up as it gets closer to player
    double currentSpeed = speed;
    if (distanceToPlayer < accelerationDistance) {
      // Speed multiplier based on proximity (1x to 2.5x)
      final proximityFactor = 1.0 - (distanceToPlayer / accelerationDistance);
      currentSpeed = getEffectiveSpeed() * (1.0 + proximityFactor * 1.5);
    }

    position += direction * currentSpeed * dt;

    // Rotate to face movement direction
    angle = atan2(direction.y, direction.x) + pi / 2;
  }

  @override
  void onDeath() {
    // Always explode on death
    explode();
  }

  void explode() {
    print('[KamikazeEnemy] Exploding at ${position}');

    // Check if player is in explosion radius
    final distanceToPlayer = PositionUtil.getDistance(this, player);
    if (distanceToPlayer <= explosionRadius) {
      // Calculate pushback direction for consistency with collision damage
      final pushbackDirection = PositionUtil.getDirectionTo(this, player);
      player.takeDamage(explosionDamage, pushbackDirection: pushbackDirection);
      print('[KamikazeEnemy] Player caught in explosion! Damage: $explosionDamage');
    }

    // TODO: Add visual explosion effect (particle system or temporary sprite)
    // For now, just damage the player if in range
  }

  @override
  void renderShape(Canvas canvas) {
    // Pulsing effect
    final pulsePhase = sin(pulseTimer * 6); // Fast pulse
    final pulseScale = 1.0 + (pulsePhase * 0.2);

    // Draw pulsing warning circle
    final warningPaint = Paint()
      ..color = const Color(0xFFFFFF00).withOpacity(0.3 + pulsePhase * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      (size.x / 2) * pulseScale + 4,
      warningPaint,
    );

    // Draw main circle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = (size.x / 2) * pulseScale;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, strokePaint);

    // Draw danger symbol (exclamation mark pattern)
    final distanceToPlayer = PositionUtil.getDistance(this, player);
    if (distanceToPlayer < accelerationDistance) {
      final dangerPaint = Paint()
        ..color = const Color(0xFFFFFF00)
        ..style = PaintingStyle.fill;

      // Draw simple warning indicator
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2 - 2),
        2,
        dangerPaint,
      );
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2 + 2),
        1.5,
        dangerPaint,
      );
    }

    // Draw status effects
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return KamikazeEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Introduced from wave 7 onwards
    if (wave < 7) return 0.0;
    return 1.2 + (wave * 0.1);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
