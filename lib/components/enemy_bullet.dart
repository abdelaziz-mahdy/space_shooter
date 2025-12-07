import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

/// Bullet fired by enemy ships (like Ranger)
class EnemyBullet extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  final Vector2 direction;
  final double damage;
  final double speed;
  double lifetime = 0;
  static const double maxLifetime = 3.0; // 3 seconds before despawn

  EnemyBullet({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.speed,
  }) : super(position: position, size: Vector2(8, 8));

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

    position += direction * speed * dt;
    lifetime += dt;

    // Remove after lifetime expires (for infinite world)
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFF4400) // Red-orange color for enemy bullets
      ..style = PaintingStyle.fill;

    // Draw circle in the center of the bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, paint);

    // Add a small white center for visibility
    final centerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x / 4, centerPaint);
  }
}
