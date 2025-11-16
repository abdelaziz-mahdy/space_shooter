import 'package:flame/components.dart';

/// Centralized utility for handling position calculations between components
/// to ensure consistency across the game
class PositionUtil {
  /// Get the center position of a component in world coordinates
  /// This works for components with anchor = Anchor.center
  static Vector2 getCenter(PositionComponent component) {
    return component.position.clone();
  }

  /// Calculate the direction vector from one component to another
  /// Returns a normalized direction vector
  static Vector2 getDirectionTo(
    PositionComponent from,
    PositionComponent to,
  ) {
    final fromCenter = getCenter(from);
    final toCenter = getCenter(to);
    return (toCenter - fromCenter).normalized();
  }

  /// Calculate the distance between two components
  static double getDistance(
    PositionComponent from,
    PositionComponent to,
  ) {
    final fromCenter = getCenter(from);
    final toCenter = getCenter(to);
    return fromCenter.distanceTo(toCenter);
  }

  /// Get the position offset for rendering (for drawing debug lines, etc.)
  /// This gives the relative position from 'from' to 'to' for canvas drawing
  static Vector2 getRelativePosition(
    PositionComponent from,
    PositionComponent to,
  ) {
    final fromCenter = getCenter(from);
    final toCenter = getCenter(to);
    return toCenter - fromCenter;
  }
}
