import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'enemy_ship.dart';
import '../game/space_shooter_game.dart';

class Bullet extends PositionComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  final Vector2 direction;
  final double damage;
  final double speed;
  double lifetime = 0;
  static const double maxLifetime = 3.0; // 3 seconds before despawn

  Bullet({
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
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

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

    if (other is EnemyShip) {
      other.takeDamage(damage);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}
