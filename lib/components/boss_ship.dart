import 'dart:math';
import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import 'loot.dart';
import 'player_ship.dart';

class BossShip extends PositionComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  final PlayerShip player;
  final Color color;
  double health;
  final double maxHealth;
  final double speed;
  final int lootValue;

  BossShip({
    required Vector2 position,
    required this.player,
    this.color = const Color(0xFFFF0000),
    this.health = 500,
    this.speed = 30,
    this.lootValue = 20,
  }) : maxHealth = health,
       super(position: position, size: Vector2(80, 80));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Pentagon shape for boss
    final sides = 6;
    final points = <Vector2>[];
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      points.add(Vector2(cos(angle) * size.x / 2, sin(angle) * size.y / 2));
    }
    add(PolygonHitbox(points));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

    // Move towards player's current position
    final direction = (player.position - position).normalized();
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
    // Drop lots of loot
    for (int i = 0; i < lootValue; i++) {
      final loot = Loot(
        position: position.clone() + Vector2.random() * 50 - Vector2.all(25),
        xpValue: 5,
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
      other.takeDamage(30);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw hexagon boss
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final sides = 6;
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

    // Draw "BOSS" text
    final textPaint = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPaint.render(
      canvas,
      'BOSS',
      Vector2(0, -size.y / 2 - 20),
      anchor: Anchor.center,
    );

    // Draw health bar
    final healthBarWidth = size.x;
    final healthBarHeight = 5.0;
    final healthBarY = -size.y / 2 - 35;

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
    final healthPaint = Paint()..color = const Color(0xFFFFFF00);
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
