import 'package:flame/components.dart';

/// Mixin for components that need to define their visual center
/// (which may differ from their anchor position)
mixin HasVisualCenter on PositionComponent {
  /// Get the actual visual center (centroid) in world coordinates
  Vector2 getVisualCenter();
}
