import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/space_shooter_game.dart';

/// Base class for all components that need custom rendering.
/// This ensures consistent rendering behavior across all game components.
///
/// Instead of overriding `render()`, subclasses should override `renderShape()`.
/// The canvas is already transformed by Flame to the component's position and rotation,
/// so hitboxes and rendering will align correctly.
abstract class BaseRenderedComponent extends PositionComponent with HasGameRef<SpaceShooterGame> {
  BaseRenderedComponent({
    required super.position,
    required super.size,
  });

  @override
  void render(Canvas canvas) {
    // Call the subclass's shape rendering
    // Canvas is already transformed by Flame to position and rotation
    renderShape(canvas);

    // Render hitbox debug visualization if enabled
    if (gameRef.debugManager.showHitboxes) {
      _renderHitboxDebug(canvas);
    }

    super.render(canvas);
  }

  /// Render hitbox outlines for debugging
  void _renderHitboxDebug(Canvas canvas) {
    final hitboxPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final child in children) {
      if (child is ShapeHitbox) {
        if (child is CircleHitbox) {
          // Draw circle hitbox
          canvas.drawCircle(
            Offset(child.position.x + child.radius, child.position.y + child.radius),
            child.radius,
            hitboxPaint,
          );
        } else if (child is PolygonHitbox) {
          // Draw polygon hitbox
          final path = Path();
          for (int i = 0; i < child.vertices.length; i++) {
            final vertex = child.vertices[i];
            if (i == 0) {
              path.moveTo(vertex.x, vertex.y);
            } else {
              path.lineTo(vertex.x, vertex.y);
            }
          }
          path.close();
          canvas.drawPath(path, hitboxPaint);
        } else if (child is RectangleHitbox) {
          // Draw rectangle hitbox
          canvas.drawRect(
            Rect.fromLTWH(
              child.position.x,
              child.position.y,
              child.size.x,
              child.size.y,
            ),
            hitboxPaint,
          );
        }
      }
    }
  }

  /// Override this method in subclasses to define how the shape should be rendered.
  /// The canvas is already transformed by Flame based on position, rotation, and anchor.
  /// Draw from top-left (0, 0) - Flame will handle anchor offset automatically.
  void renderShape(Canvas canvas);
}
