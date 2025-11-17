import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/position_util.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

class Loot extends BaseRenderedComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  static const double attractionRange = 100;
  static const double attractionSpeed = 200;
  final int xpValue;

  Loot({required Vector2 position, this.xpValue = 1})
    : super(position: position, size: Vector2(10, 10));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    add(CircleHitbox());
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    // Attract to player using PositionUtil
    final player = gameRef.player;
    final distanceToPlayer = PositionUtil.getDistance(this, player);

    // Use player's magnet radius for attraction
    if (distanceToPlayer < player.magnetRadius) {
      final direction = PositionUtil.getDirectionTo(this, player);
      position += direction * attractionSpeed * dt;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      gameRef.levelManager.addXP(xpValue);
      removeFromParent();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = const Color(0x4400FFFF)
      ..style = PaintingStyle.fill;

    // Draw circle in center of bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2 + 3, glow);
    canvas.drawCircle(center, size.x / 2, paint);
  }
}
