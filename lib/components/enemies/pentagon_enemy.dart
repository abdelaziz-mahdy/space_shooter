import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Pentagon Enemy: Slow, high health basic enemy
/// - Pentagon shape, magenta color
/// - Simple chase behavior
class PentagonEnemy extends BaseEnemy {
  static const String ID = 'pentagon';

  PentagonEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 60 + (wave * 4.0),
          speed: 37.5 + (wave * 1.25), // Increased from 30 + wave (25% increase)
          lootValue: 3,
          color: const Color(0xFFFF00FF), // Magenta
          size: Vector2(25, 25) * scale,
          contactDamage: 10.0,
        );

  @override
  Future<void> addHitbox() async {
    // Pentagon hitbox
    final sides = 5;
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
  void updateMovement(double dt) {
    // Simple chase behavior
    final direction = PositionUtil.getDirectionTo(this, player);
    position += direction * getEffectiveSpeed() * dt;

    // Rotate to face movement direction
    angle = atan2(direction.y, direction.x) + pi / 2;
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

    // Draw pentagon centered in the bounding box
    final sides = 5;
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

    // Draw status effects
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return PentagonEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Always available, but weight decreases as waves progress
    return max(1.0, 3.0 - (wave * 0.1));
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
