import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';
import '../../rendering/holographic.dart';

/// Square Enemy: Medium speed, medium health basic enemy
/// - Square shape, orange color
/// - Simple chase behavior
class SquareEnemy extends BaseEnemy {
  static const String ID = 'square';

  SquareEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 40 + (wave * 3.0),
          speed: 50 + (wave * 1.875), // Increased from 40 + (wave * 1.5) (25% increase)
          lootValue: 2,
          color: const Color(0xFFFF8800), // Orange
          size: Vector2(25, 25) * scale,
          contactDamage: 10.0,
        );

  @override
  Future<void> addHitbox() async {
    // Square hitbox
    add(
      PolygonHitbox([
        Vector2(0, 0),
        Vector2(size.x, 0),
        Vector2(size.x, size.y),
        Vector2(0, size.y),
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
    // Draw square from top-left (0,0) to (size.x, size.y)
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.x, size.y));
    Holo.drawShape(canvas, path, color: Holo.blue);

    // Draw status effects
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return SquareEnemy(
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
