import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Scout Enemy: Fast, fragile, zigzag movement
/// - Diamond shape, cyan color, size 15x15
/// - Health: 10 + (wave * 1), Speed: 120 + (wave * 3)
/// - Zigzag movement pattern using sine wave
/// - Flees when health < 30%
class ScoutEnemy extends BaseEnemy {
  static const String ID = 'scout';
  double movementTimer = 0;
  bool isFleeing = false;

  ScoutEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 10 + (wave * 1.0),
          speed: 150 + (wave * 3.75), // Increased from 120 + (wave * 3.0) (25% increase)
          lootValue: 1,
          color: const Color(0xFF00FFFF), // Cyan
          size: Vector2(15, 15) * scale,
          contactDamage: 8.0,
        );

  @override
  Future<void> addHitbox() async {
    // Diamond shape hitbox
    final w = size.x;
    final h = size.y;

    add(
      PolygonHitbox([
        Vector2(w / 2, 0), // Top
        Vector2(w, h / 2), // Right
        Vector2(w / 2, h), // Bottom
        Vector2(0, h / 2), // Left
      ]),
    );
  }

  @override
  void updateMovement(double dt) {
    movementTimer += dt;

    // Check if should flee (health < 30%)
    isFleeing = health < maxHealth * 0.3;

    if (isFleeing) {
      // Flee away from player
      final direction = PositionUtil.getDirectionTo(player, this);
      position += direction * getEffectiveSpeed() * dt;
    } else {
      // Zigzag movement towards player
      final baseDirection = PositionUtil.getDirectionTo(this, player);

      // Add sine wave for zigzag effect
      final perpendicular = Vector2(-baseDirection.y, baseDirection.x);
      final zigzagOffset = sin(movementTimer * 5) * 0.5; // Adjust frequency and amplitude

      final movement = baseDirection + (perpendicular * zigzagOffset);
      position += movement.normalized() * getEffectiveSpeed() * dt;
    }

    // Rotate to face movement direction
    final direction = isFleeing
        ? PositionUtil.getDirectionTo(player, this)
        : PositionUtil.getDirectionTo(this, player);
    angle = atan2(direction.y, direction.x) + pi / 4; // +45° for diamond orientation
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw diamond shape from top-left coordinate system
    final w = size.x;
    final h = size.y;

    final path = Path()
      ..moveTo(w / 2, 0) // Top
      ..lineTo(w, h / 2) // Right
      ..lineTo(w / 2, h) // Bottom
      ..lineTo(0, h / 2) // Left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw health bar
    // Draw freeze effect if frozen
    renderFreezeEffect(canvas);
    renderHealthBar(canvas);

    // Draw flee indicator if fleeing
    if (isFleeing) {
      final warningPaint = Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + 2,
        warningPaint,
      );
    }
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return ScoutEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Introduced from wave 2 onwards
    if (wave < 2) return 0.0;
    return 2.0 + (wave * 0.1);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
