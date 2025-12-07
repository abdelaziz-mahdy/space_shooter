import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/space_shooter_game.dart';

/// Base class for all game components.
///
/// This class automatically enforces:
/// 1. Pause state checking - all components stop updating when game is paused
/// 2. Rendering pattern - subclasses override renderShape() instead of render()
/// 3. Hitbox debug visualization - automatically shown when debug mode enabled
///
/// How pause handling works:
/// 1. BaseRenderedComponent.update() checks if game.isPaused
/// 2. If paused, returns immediately (stops all updates)
/// 3. If not paused, calls super.update(dt) which continues the update chain
/// 4. Subclasses override update() normally - pause check is automatic!
///
/// How rendering works:
/// - Override renderShape() instead of render() in subclasses
/// - Canvas is already transformed by Flame to position/rotation
/// - Draw from top-left (0, 0) - Flame handles anchor offset automatically
/// - Hitbox debug visualization is automatic when enabled
///
/// This ensures ALL components stop updating when the game is paused,
/// preventing bugs like orbital drones firing during pause.
abstract class BaseRenderedComponent extends PositionComponent with HasGameReference<SpaceShooterGame> {
  BaseRenderedComponent({
    required Vector2 position,
    required Vector2 size,
  }) : super(
    position: position,
    size: size,
  );

  @override
  void update(double dt) {
    // Check pause state FIRST - this is critical for consistency
    // If paused, return immediately without calling super.update()
    // This prevents ALL child component updates from running
    if (game.isPaused) return;

    // Only call super.update() if not paused
    // This allows subclasses' update() methods to run normally
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // Call the subclass's shape rendering
    // Canvas is already transformed by Flame to position and rotation
    renderShape(canvas);

    // Render hitbox debug visualization if enabled
    if (game.debugManager?.showHitboxes ?? false) {
      _renderHitboxDebug(canvas);
    }

    super.render(canvas);
  }

  /// Render hitbox outlines for debugging
  void _renderHitboxDebug(Canvas canvas) {
    final hitboxPaint = Paint()
      ..color = const Color(0xFF00FF00).withValues(alpha: 0.7)
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
