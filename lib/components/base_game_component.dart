import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

/// Base class for all game components that should respect game pause state.
///
/// This class automatically enforces pause state checking without requiring
/// any changes to subclasses. The pause check happens transparently in the
/// update() method - subclasses just inherit this behavior automatically.
///
/// How it works:
/// 1. BaseGameComponent.update() checks if game.isPaused
/// 2. If paused, returns immediately (stops all updates)
/// 3. If not paused, calls super.update(dt) which continues the update chain
/// 4. Subclasses override update() normally - pause check is automatic!
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
    // If paused, return immediately without calling super.update()
    // This prevents ALL child component updates from running
    if (game.isPaused) return;

    // Only call super.update() if not paused
    // This allows subclasses' update() methods to run normally
    super.update(dt);
  }
}
