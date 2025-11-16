import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/rendering.dart';
import '../game/space_shooter_game.dart';
import '../utils/position_util.dart';
import 'loot.dart';
import 'player_ship.dart';

enum EnemyShape { triangle, square, pentagon }

class EnemyShip extends PositionComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
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

    // Add collision hitbox based on shape
    switch (shape) {
      case EnemyShape.triangle:
        add(
          PolygonHitbox([
            Vector2(0, -size.y / 2),
            Vector2(size.x / 2, size.y / 2),
            Vector2(-size.x / 2, size.y / 2),
          ]),
        );
        break;
      case EnemyShape.square:
        add(
          PolygonHitbox([
            Vector2(-size.x / 2, -size.y / 2),
            Vector2(size.x / 2, -size.y / 2),
            Vector2(size.x / 2, size.y / 2),
            Vector2(-size.x / 2, size.y / 2),
          ]),
        );
        break;
      case EnemyShape.pentagon:
        final sides = 5;
        final points = <Vector2>[];
        for (int i = 0; i < sides; i++) {
          final angle = (i * 2 * pi / sides) - pi / 2;
          points.add(Vector2(cos(angle) * size.x / 2, sin(angle) * size.y / 2));
        }
        add(PolygonHitbox(points));
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

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
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    switch (shape) {
      case EnemyShape.triangle:
        final path = Path()
          ..moveTo(0, -size.y / 2)
          ..lineTo(size.x / 2, size.y / 2)
          ..lineTo(-size.x / 2, size.y / 2)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
        break;

      case EnemyShape.square:
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: size.x,
          height: size.y,
        );
        canvas.drawRect(rect, paint);
        canvas.drawRect(rect, strokePaint);
        break;

      case EnemyShape.pentagon:
        final sides = 5;
        final path = Path();
        for (int i = 0; i < sides; i++) {
          final angle = (i * 2 * pi / sides) - pi / 2;
          final x = cos(angle) * size.x / 2;
          final y = sin(angle) * size.y / 2;
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

    // Draw health bar
    final healthBarWidth = size.x;
    final healthBarHeight = 3.0;
    final healthBarY = -size.y / 2 - 8;

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        -healthBarWidth / 2,
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
        -healthBarWidth / 2,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }
}
