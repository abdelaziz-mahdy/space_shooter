import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image; // Hide to avoid conflict with dart:ui Image
import '../utils/position_util.dart';
import '../game/space_shooter_game.dart';
import 'enemies/base_enemy.dart';
import 'boss_ship.dart';

/// Shows arrows at screen edges pointing to off-screen enemies
class EnemyIndicator extends PositionComponent with HasGameRef<SpaceShooterGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Don't render if game is paused
    if (gameRef.isPaused) return;

    final player = gameRef.player;
    final screenSize = gameRef.size;

    // Percentage-based sizing for responsive design (CLAUDE.md line 86)
    final edgeOffset = screenSize.x * 0.025; // 2.5% of screen width
    final arrowSize = screenSize.x * 0.025; // 2.5% of screen width
    final fontSize = screenSize.x * 0.015; // 1.5% of screen width

    // Get all enemies from cached list (refreshed once per frame for performance)
    // CLAUDE.md line 222: Use cached enemy list to avoid expensive queries every frame
    final allEnemies = gameRef.activeEnemies;

    // Filter to only off-screen enemies
    final offScreenEnemies = allEnemies.where((enemy) {
      if (!enemy.isMounted) return false;

      // Calculate relative position to player (center of screen)
      final relativePos = PositionUtil.getRelativePosition(player, enemy);

      // Check if off-screen
      final isOffScreenX = relativePos.x.abs() > screenSize.x / 2;
      final isOffScreenY = relativePos.y.abs() > screenSize.y / 2;

      return isOffScreenX || isOffScreenY;
    }).toList();

    // Draw indicators for each off-screen enemy
    for (final enemy in offScreenEnemies) {
      _renderIndicator(canvas, player, enemy, screenSize, edgeOffset, arrowSize, fontSize);
    }
  }

  void _renderIndicator(
    Canvas canvas,
    PositionComponent player,
    BaseEnemy enemy,
    Vector2 screenSize,
    double edgeOffset,
    double arrowSize,
    double fontSize,
  ) {
    // Calculate relative position
    final relativePos = PositionUtil.getRelativePosition(player, enemy);

    // Calculate clamped position on screen edges
    final clampedX = relativePos.x.clamp(-screenSize.x / 2 + edgeOffset, screenSize.x / 2 - edgeOffset);
    final clampedY = relativePos.y.clamp(-screenSize.y / 2 + edgeOffset, screenSize.y / 2 - edgeOffset);

    // Convert to screen coordinates (relative to player at center)
    final indicatorPos = Vector2(
      screenSize.x / 2 + clampedX,
      screenSize.y / 2 + clampedY,
    );

    // Arrow should always point toward enemy (use relative position directly)
    // This ensures arrows point outward from screen edges toward off-screen enemies
    final directionVector = relativePos.clone();
    directionVector.normalize();
    // Use atan2 to get angle - atan2(y, x) gives angle from positive X axis
    // We want angle from UP (negative Y), so we use atan2(x, -y)
    final angle = atan2(directionVector.x, -directionVector.y);

    // Determine color based on enemy type
    final color = enemy is BossShip
        ? const Color(0xFFFF0000) // Red for bosses
        : const Color(0xFFFFAA00); // Orange for normal enemies

    // Draw arrow with tip at the edge
    canvas.save();
    canvas.translate(indicatorPos.x, indicatorPos.y);
    canvas.rotate(angle);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Arrow shape (pointing up, will be rotated)
    // Tip at (0, 0) so after translation, tip is at indicatorPos (screen edge)
    final arrowPath = Path()
      ..moveTo(0, 0) // Tip at origin (will be at screen edge)
      ..lineTo(-arrowSize / 3, arrowSize) // Bottom left
      ..lineTo(0, arrowSize * 0.75) // Middle notch
      ..lineTo(arrowSize / 3, arrowSize) // Bottom right
      ..close();

    canvas.drawPath(arrowPath, paint);
    canvas.drawPath(arrowPath, outlinePaint);

    canvas.restore();

    // Draw distance text if boss
    if (enemy is BossShip) {
      final distance = PositionUtil.getDistance(player, enemy);
      final distanceText = '${(distance / 100).toStringAsFixed(0)}';

      final textPainter = TextPainter(
        text: TextSpan(
          text: distanceText,
          style: TextStyle(
            color: const Color(0xFFFFFFFF),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                color: Color(0xFF000000),
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // Position text below the arrow base (arrow now extends from tip at edge)
      textPainter.paint(
        canvas,
        Offset(indicatorPos.x - textPainter.width / 2, indicatorPos.y + arrowSize + 5),
      );
    }
  }
}
