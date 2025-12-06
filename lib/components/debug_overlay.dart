import 'package:flame/components.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'player_ship.dart';
import 'enemies/base_enemy.dart';
import 'enemies/triangle_enemy.dart';
import '../utils/visual_center_mixin.dart';
import '../game/space_shooter_game.dart';

class DebugOverlay extends Component with HasGameReference<SpaceShooterGame> {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final player = game.player;
    _drawComponentDebug(canvas, player, 'Player');

    final enemies = game.world.children.whereType<BaseEnemy>();
    for (final enemy in enemies) {
      _drawComponentDebug(canvas, enemy, 'Enemy');

      // Draw line from enemy visual center to player visual center
      final enemyVisualCenter = enemy.getVisualCenter();
      final linePaint = Paint()
        ..color = const Color(0xFF00FFFF)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(enemyVisualCenter.x, enemyVisualCenter.y),
        Offset(player.position.x, player.position.y),
        linePaint,
      );
    }
  }

  void _drawComponentDebug(
    Canvas canvas,
    PositionComponent component,
    String label,
  ) {
    // Draw manual bounding box based on size and anchor
    final halfW = component.size.x / 2;
    final halfH = component.size.y / 2;

    // With Anchor.center, the bounding box should be centered at position
    final manualRect = Rect.fromCenter(
      center: Offset(component.position.x, component.position.y),
      width: component.size.x,
      height: component.size.y,
    );

    // Draw rotated bounding box to show correct orientation
    if (component is PlayerShip || component is BaseEnemy) {
      final h = component.size.y;
      final w = component.size.x;
      final top = -h / 2;
      final bottom = h / 4;

      canvas.save();
      canvas.translate(component.position.x, component.position.y);
      canvas.rotate(component.angle);

      // Draw the rotated bounding box (cyan)
      final rotatedBoxPaint = Paint()
        ..color = const Color(0xFF00FFFF)  // Cyan
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        rotatedBoxPaint,
      );

      // Draw the correct triangle outline (magenta) for triangular shapes
      if ((component is PlayerShip) || (component is TriangleEnemy)) {
        final trianglePath = Path()
          ..moveTo(0, top)
          ..lineTo(w / 2, bottom)
          ..lineTo(-w / 2, bottom)
          ..close();

        final triangleDebugPaint = Paint()
          ..color = const Color(0xFFFF00FF)  // Magenta
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawPath(trianglePath, triangleDebugPaint);
      }

      canvas.restore();
    }

    // Draw manual bounding box (yellow)
    final bboxPaint = Paint()
      ..color = const Color(0xFFFFFF00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(manualRect, bboxPaint);

    // Draw anchor position (red X)
    _drawAnchorMarker(
      canvas,
      component.position,
      const Color(0xFFFF0000),
      'Anchor',
    );

    // Draw bounding box center (blue circle) - should overlap with anchor
    final boundingBoxCenter = Vector2(
      component.position.x,
      component.position.y,
    );
    _drawCircleMarker(
      canvas,
      boundingBoxCenter,
      const Color(0xFF0000FF),
      'BBox Center',
    );

    // Draw visual center (green crosshair)
    if (component is HasVisualCenter) {
      final visualCenter = component.getVisualCenter();
      _drawWorldMarker(
        canvas,
        visualCenter,
        const Color(0xFF00FF00),
        'Visual Center',
      );
    }
  }

  void _drawWorldMarker(
    Canvas canvas,
    Vector2 worldPos,
    Color color,
    String label,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    // Draw crosshair (plus sign)
    canvas.drawLine(
      Offset(worldPos.x - 20, worldPos.y),
      Offset(worldPos.x + 20, worldPos.y),
      paint,
    );
    canvas.drawLine(
      Offset(worldPos.x, worldPos.y - 20),
      Offset(worldPos.x, worldPos.y + 20),
      paint,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label: ${worldPos.x.toInt()},${worldPos.y.toInt()}',
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(worldPos.x + 25, worldPos.y - 10));
  }

  void _drawAnchorMarker(
    Canvas canvas,
    Vector2 worldPos,
    Color color,
    String label,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    // Draw X shape for anchor
    canvas.drawLine(
      Offset(worldPos.x - 15, worldPos.y - 15),
      Offset(worldPos.x + 15, worldPos.y + 15),
      paint,
    );
    canvas.drawLine(
      Offset(worldPos.x + 15, worldPos.y - 15),
      Offset(worldPos.x - 15, worldPos.y + 15),
      paint,
    );

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label: ${worldPos.x.toInt()},${worldPos.y.toInt()}',
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(worldPos.x + 20, worldPos.y + 15));
  }

  void _drawCircleMarker(
    Canvas canvas,
    Vector2 worldPos,
    Color color,
    String label,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw circle
    canvas.drawCircle(Offset(worldPos.x, worldPos.y), 5, paint);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label: ${worldPos.x.toInt()},${worldPos.y.toInt()}',
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(worldPos.x + 10, worldPos.y - 25));
  }
}
