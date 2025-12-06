import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/position_util.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

/// Bullet with homing capability fired by enemies
class HomingEnemyBullet extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  Vector2 direction;
  final double damage;
  final double speed;
  final double homingStrength;

  double lifetime = 0;
  static const double maxLifetime = 5.0; // 5 seconds before despawn

  HomingEnemyBullet({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.speed,
    this.homingStrength = 50.0, // Lower than missiles for slight homing
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

    // Don't update if game is paused
    if (game.isPaused) return;

    // Apply slight homing toward player
    _applyHoming(dt);

    position += direction * speed * dt;
    lifetime += dt;

    // Remove after lifetime expires
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  void _applyHoming(double dt) {
    // Calculate direction to player
    final toPlayer = PositionUtil.getDirectionTo(this, game.player);

    // Smoothly turn towards player (weaker than missiles)
    direction = (direction + (toPlayer * homingStrength * dt)).normalized();
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
    // Draw bullet with purple/pink color (matches Splitter theme)
    final paint = Paint()
      ..color = const Color(0xFFFF00FF) // Magenta for homing bullets
      ..style = PaintingStyle.fill;

    // Draw circle in the center of the bounding box
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, paint);

    // Add a white center for visibility
    final centerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x / 4, centerPaint);
  }
}
