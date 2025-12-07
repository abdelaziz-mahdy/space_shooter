import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/position_util.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

/// Homing missile fired by enemies that tracks the player
class EnemyHomingMissile extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  Vector2 direction;
  final double damage;
  final double speed;

  double lifetime = 0;
  static const double maxLifetime = 5.0; // 5 seconds before despawn
  static const double homingStrength = 150.0; // Turn rate

  EnemyHomingMissile({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.speed,
  }) : super(position: position, size: Vector2(12, 6));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Rectangular hitbox for missile shape
    add(RectangleHitbox());
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

    // Apply homing toward player
    _applyHoming(dt);

    // Move missile
    position += direction * speed * dt;

    // Rotate missile to face direction of travel
    angle = atan2(direction.y, direction.x);

    lifetime += dt;

    // Remove after lifetime expires
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  void _applyHoming(double dt) {
    // Calculate direction to player
    final toPlayer = PositionUtil.getDirectionTo(this, game.player);

    // Smoothly turn towards player
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
    // Draw missile body (cyan to match boss)
    final bodyPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;

    // Missile body (elongated rectangle)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(bodyRect, bodyPaint);

    // Missile tip (white)
    final tipPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final tipPath = Path()
      ..moveTo(size.x, size.y / 2) // Right middle
      ..lineTo(size.x + 4, size.y / 2 - 3) // Tip top
      ..lineTo(size.x + 4, size.y / 2 + 3) // Tip bottom
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Exhaust trail (dark blue glow)
    final exhaustPaint = Paint()
      ..color = const Color(0xFF0000AA).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final exhaustRect = Rect.fromCenter(
      center: Offset(-2, size.y / 2),
      width: 6,
      height: 4,
    );
    canvas.drawOval(exhaustRect, exhaustPaint);
  }
}
