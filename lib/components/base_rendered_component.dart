import 'dart:ui';
import 'package:flame/components.dart';

/// Base class for all components that need custom rendering.
/// This ensures consistent rendering behavior across all game components.
///
/// Instead of overriding `render()`, subclasses should override `renderShape()`.
/// The canvas is already transformed by Flame to the component's position and rotation,
/// so hitboxes and rendering will align correctly.
abstract class BaseRenderedComponent extends PositionComponent {
  BaseRenderedComponent({
    required super.position,
    required super.size,
  });

  @override
  void render(Canvas canvas) {
    // Call the subclass's shape rendering
    // Canvas is already transformed by Flame to position and rotation
    renderShape(canvas);
    super.render(canvas);
  }

  /// Override this method in subclasses to define how the shape should be rendered.
  /// The canvas is already transformed by Flame based on position, rotation, and anchor.
  /// Draw from top-left (0, 0) - Flame will handle anchor offset automatically.
  void renderShape(Canvas canvas);
}
