import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/rendering.dart';
import '../game/space_shooter_game.dart';
import '../utils/position_util.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import 'loot.dart';
import 'player_ship.dart';

enum EnemyShape { triangle, square, pentagon }

class EnemyShip extends BaseRenderedComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  final PlayerShip player;
  final EnemyShape shape;
  final Color color;
  double health;
  final double maxHealth;
  final double speed;
  final int lootValue;

  EnemyShip({
    required Vector2 position,
    required this.player,
    this.shape = EnemyShape.triangle,
    this.color = const Color(0xFFFF0000),
    this.health = 30,
    this.speed = 50,
    this.lootValue = 1,
  }) : maxHealth = health,
       super(position: position, size: Vector2(25, 25));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Add collision hitbox matching rendered shapes (from top-left coordinate system)
    switch (shape) {
      case EnemyShape.triangle:
        final h = size.y;
        final w = size.x;
        final topY = h / 6;
        final bottomY = 5 * h / 6;

        add(
          PolygonHitbox([
            Vector2(w / 2, topY),  // Top center
            Vector2(w, bottomY),   // Bottom right
            Vector2(0, bottomY),   // Bottom left
          ]),
        );
        break;

      case EnemyShape.square:
        add(
          PolygonHitbox([
            Vector2(0, 0),
            Vector2(size.x, 0),
            Vector2(size.x, size.y),
            Vector2(0, size.y),
          ]),
        );
        break;

      case EnemyShape.pentagon:
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
        break;
    }
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    // Use PositionUtil for consistent position calculations
    final direction = PositionUtil.getDirectionTo(this, player);
    position += direction * speed * dt;

    // Rotate to face movement direction
    angle = atan2(direction.y, direction.x) + pi / 2;
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      die();
    }
  }

  void die() {
    // Drop loot
    for (int i = 0; i < lootValue; i++) {
      final loot = Loot(
        position: position.clone() + Vector2.random() * 20 - Vector2.all(10),
      );
      gameRef.world.add(loot);
    }

    // Increment kill count
    gameRef.statsManager.incrementKills();

    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      other.takeDamage(10);
      die(); // Enemy dies on collision with player
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
      ..strokeWidth = 2;

    switch (shape) {
      case EnemyShape.triangle:
        // Draw from top-left - anchor will handle centering
        final h = size.y;
        final w = size.x;
        final topY = h / 6;
        final bottomY = 5 * h / 6;

        final path = Path()
          ..moveTo(w / 2, topY)  // Top center
          ..lineTo(w, bottomY)   // Bottom right
          ..lineTo(0, bottomY)   // Bottom left
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case EnemyShape.square:
        // Draw from top-left (0,0) to (size.x, size.y)
        final rect = Rect.fromLTWH(0, 0, size.x, size.y);
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case EnemyShape.pentagon:
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
        break;
    }

    // Draw health bar above the shape
    final healthBarWidth = size.x;
    final healthBarHeight = 3.0;
    final healthBarY = -5.0; // Above the component

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()..color = const Color(0xFF00FF00);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }
}
