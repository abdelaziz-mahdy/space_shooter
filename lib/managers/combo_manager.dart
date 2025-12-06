import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';

/// Manages the combo/kill streak system
/// Tracks consecutive kills and provides XP multipliers
class ComboManager extends Component with HasGameReference<SpaceShooterGame> {
  int combo = 0;
  double timeSinceLastKill = 0;
  static const double resetTime = 3.0; // Combo resets after 3 seconds

  int highestCombo = 0;

  // Combo milestones
  static const List<int> milestones = [10, 25, 50, 100, 200, 500];

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (game.isPaused) return;

    if (combo > 0) {
      timeSinceLastKill += dt;
      if (timeSinceLastKill >= resetTime) {
        // Combo broken
        print('[ComboManager] COMBO BROKEN! Final: $combo');
        combo = 0;
        timeSinceLastKill = 0;
      }
    }
  }

  /// Add a kill to the combo
  void addKill() {
    combo++;
    timeSinceLastKill = 0;

    // Track highest combo
    if (combo > highestCombo) {
      highestCombo = combo;
    }

    // Check for milestones
    if (milestones.contains(combo)) {
      _onMilestoneReached(combo);
    }

    // Apply XP multiplier based on combo
    final multiplier = getXPMultiplier();
    print('[ComboManager] Combo: $combo | XP Multiplier: ${multiplier.toStringAsFixed(2)}x');
  }

  /// Get XP multiplier based on current combo
  /// Formula: 1.0 + (combo / 100), no cap
  double getXPMultiplier() {
    return 1.0 + (combo / 100.0);
  }

  /// Get time remaining until combo resets (0-3 seconds)
  double getTimeUntilReset() {
    if (combo == 0) return 0;
    return max(0, resetTime - timeSinceLastKill);
  }

  /// Get combo reset progress (0.0 - 1.0)
  double getResetProgress() {
    if (combo == 0) return 0;
    return getTimeUntilReset() / resetTime;
  }

  /// Called when a combo milestone is reached
  void _onMilestoneReached(int milestone) {
    print('[ComboManager] 🎯 COMBO MILESTONE REACHED: $milestone');

    // Could trigger visual/audio feedback here
    // For now, just log it
  }

  /// Reset combo (used when player dies or game restarts)
  void reset() {
    combo = 0;
    timeSinceLastKill = 0;
    highestCombo = 0;
  }
}
