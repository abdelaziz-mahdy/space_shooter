import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

/// Floating damage number that appears when damage is dealt
/// Animates upward and fades out over its lifetime
class DamageNumber extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final double damage;
  final bool isCrit;
  final bool isHealing;
  final bool isPlayerDamage;

  double lifetime = 0;
  static const double maxLifetime = 0.8;

  late TextPaint textPainter;

  DamageNumber({
    required Vector2 position,
    required this.damage,
    this.isCrit = false,
    this.isHealing = false,
    this.isPlayerDamage = false,
  }) : super(position: position, size: Vector2(50, 30)) {
    anchor = Anchor.center;

    // Setup text painter with appropriate styling
    final color = _getColor();
    final fontSize = isCrit ? 20.0 : 14.0;

    textPainter = TextPaint(
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    if (isHealing) return const Color(0xFF00FF00); // Green
    if (isPlayerDamage) return const Color(0xFFFF0000); // Red
    if (isCrit) return const Color(0xFFFF8800); // Orange
    return const Color(0xFFFFFFFF); // White
  }

  @override
  void update(double dt) {
    super.update(dt);

    lifetime += dt;

    // Float upward at 50 pixels per second
    position.y -= 50 * dt;

    // Slight randomized horizontal drift for visual variety
    if (isCrit) {
      position.x += (dt * 10); // Crits drift to the right
    }

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate opacity based on lifetime (fade out)
    final opacity = 1.0 - (lifetime / maxLifetime);

    // Update text color with current opacity
    final color = _getColor().withOpacity(opacity);
    final fontSize = isCrit ? 20.0 : 14.0;

    textPainter = TextPaint(
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.8 * opacity),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      ),
    );

    // Format damage text
    String damageText;
    if (damage == 0 && !isPlayerDamage) {
      // Special case for block
      damageText = 'BLOCKED!';
    } else if (isHealing) {
      damageText = '+${damage.toStringAsFixed(0)}';
    } else {
      damageText = damage.toStringAsFixed(0);
    }

    // Render the text centered
    textPainter.render(
      canvas,
      damageText,
      Vector2(size.x / 2, size.y / 2),
      anchor: Anchor.center,
    );

    // Add "CRIT!" text above critical hits
    if (isCrit) {
      final critText = TextPaint(
        style: TextStyle(
          color: const Color(0xFFFFFF00).withOpacity(opacity),
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.8 * opacity),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      );

      critText.render(
        canvas,
        'CRIT!',
        Vector2(size.x / 2, size.y / 2 - 15),
        anchor: Anchor.center,
      );
    }
  }
}
