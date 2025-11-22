import 'dart:math';
import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import 'enemies/base_enemy.dart';
import 'player_ship.dart';

class BossShip extends BaseEnemy {
  final bool isBoss = true; // Flag to identify boss enemies

  BossShip({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    Color color = const Color(0xFFFF0000),
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 300 + (wave * 50), // Boss scales with wave
          speed: 37.5, // Increased from 30 (25% increase)
          lootValue: 25,
          color: color,
          size: Vector2(80, 80),
          contactDamage: 30.0,
        );

  @override
  Future<void> addHitbox() async {
    // Hexagon shape for boss
    final sides = 6;
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
  }

  @override
  void updateMovement(double dt) {
    // Move towards player's current position
    final direction = (player.position - position).normalized();
    position += direction * getEffectiveSpeed() * dt;

    // Rotate to face movement direction
    angle = atan2(direction.y, direction.x) + pi / 2;
  }

  @override
  void renderShape(Canvas canvas) {
    // Draw hexagon boss from top-left coordinate system
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final sides = 6;
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

    // Draw "BOSS" text above
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
      Vector2(size.x / 2, -20),
      anchor: Anchor.center,
    );

    // Draw health bar above text
    final healthBarWidth = size.x;
    final healthBarHeight = 5.0;
    final healthBarY = -35.0;

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
    final healthPaint = Paint()..color = const Color(0xFFFFFF00);
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
