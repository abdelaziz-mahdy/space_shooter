import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Tank Enemy: Slow, high health, damage reduction
/// - Octagon shape, dark red, size 40x40
/// - Health: 150 + (wave * 10), Speed: 20 + (wave * 0.5)
/// - 30% damage reduction in takeDamage
/// - 2% health regen per second after 3s without damage
class TankEnemy extends BaseEnemy {
  static const String ID = 'tank';
  static const double damageReduction = 0.30; // 30% damage reduction
  static const double regenRate = 0.02; // 2% per second
  static const double regenDelay = 3.0; // 3 seconds without damage

  double timeSinceLastDamage = 0;

  TankEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 150 + (wave * 10.0),
          speed: 25 + (wave * 0.625), // Increased from 20 + (wave * 0.5) (25% increase)
          lootValue: 3,
          color: const Color(0xFF8B0000), // Dark red
          size: Vector2(40, 40) * scale,
          contactDamage: 20.0,
        );

  @override
  Future<void> addHitbox() async {
    // Octagon shape hitbox
    final sides = 8;
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

  @override
  double modifyIncomingDamage(double damage) {
    // Apply damage reduction
    return damage * (1 - damageReduction);
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);
    // Reset regeneration timer when damaged
    timeSinceLastDamage = 0;
  }

  @override
  void updateMovement(double dt) {
    // Simple straight movement towards player
    final direction = PositionUtil.getDirectionTo(this, player);
    position += direction * getEffectiveSpeed() * dt;

    // Rotate to face movement direction
    angle = atan2(direction.y, direction.x) + pi / 2;

    // Handle health regeneration
    timeSinceLastDamage += dt;

    if (timeSinceLastDamage >= regenDelay) {
      final regenAmount = maxHealth * regenRate * dt;
      health = (health + regenAmount).clamp(0, maxHealth);
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Draw octagon from top-left coordinate system
    final sides = 8;
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

    // Draw armor indicator (small shield symbol)
    if (timeSinceLastDamage < regenDelay) {
      // Draw damage reduction indicator
      final armorPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 4,
        armorPaint,
      );
    } else {
      // Draw regeneration indicator
      final regenPaint = Paint()
        ..color = const Color(0xFF00FF00).withValues(alpha: 0.4)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 4,
        regenPaint,
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
      return TankEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Introduced from wave 5 onwards
    if (wave < 5) return 0.0;
    return 1.0 + (wave * 0.08);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
