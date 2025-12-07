import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

/// Base class for all game components that should respect game pause state.
///
/// This class automatically handles pause state checking to ensure consistent
/// behavior across all components. Subclasses should override updateGame() instead
/// of update() to implement their game logic.
///
/// The pause check happens at the start of update():
/// - If game is paused, update() returns immediately
/// - If game is not paused, updateGame(dt) is called with the delta time
///
/// This ensures ALL components stop updating when the game is paused,
/// preventing bugs like orbital drones firing during pause.
abstract class BaseGameComponent extends PositionComponent with HasGameReference<SpaceShooterGame> {
  BaseGameComponent({
    super.position,
    super.size,
    super.scale,
    super.anchor,
    super.children,
  });

  @override
  void update(double dt) {
    // Check pause state FIRST - this is critical for consistency
    if (game.isPaused) return;

    // Call the game-specific update logic
    updateGame(dt);

    super.update(dt);
  }

  /// Override this method instead of update() to implement game logic.
  /// This method will NOT be called when the game is paused.
  ///
  /// dt is the delta time in seconds since the last frame.
  void updateGame(double dt) {
    // Default implementation - subclasses override as needed
  }
}
