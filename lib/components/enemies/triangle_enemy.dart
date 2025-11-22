import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Triangle Enemy: Fast basic enemy
/// - Triangle shape, red color
/// - Simple chase behavior
class TriangleEnemy extends BaseEnemy {
  static const String ID = 'triangle';

  TriangleEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 20 + (wave * 2.0),
          speed: 75 + (wave * 2.5), // Increased from 60 + (wave * 2.0) (25% increase)
          lootValue: 1,
          color: const Color(0xFFFF0000), // Red
          size: Vector2(25, 25) * scale,
          contactDamage: 10.0,
        );

  @override
  Future<void> addHitbox() async {
    // Triangle hitbox
    final h = size.y;
    final w = size.x;
    final topY = h / 6;
    final bottomY = 5 * h / 6;

    add(
      PolygonHitbox([
        Vector2(w / 2, topY), // Top center
        Vector2(w, bottomY), // Bottom right
        Vector2(0, bottomY), // Bottom left
      ]),
    );
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

    // Draw triangle from top-left coordinate system
    final h = size.y;
    final w = size.x;
    final topY = h / 6;
    final bottomY = 5 * h / 6;

    final path = Path()
      ..moveTo(w / 2, topY) // Top center
      ..lineTo(w, bottomY) // Bottom right
      ..lineTo(0, bottomY) // Bottom left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw freeze effect if frozen
    renderFreezeEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return TriangleEnemy(
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
