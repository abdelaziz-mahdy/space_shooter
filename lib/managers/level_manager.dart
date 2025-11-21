import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';

class LevelManager extends Component with HasGameRef<SpaceShooterGame> {
  int currentLevel = 1;
  int currentXP = 0;
  int xpToNextLevel = 10;
  bool _hasShownInitialUpgrade = false;

  LevelManager({required SpaceShooterGame game});

  @override
  void update(double dt) {
    super.update(dt);

    // Show upgrade overlay on first frame for testing
    if (!_hasShownInitialUpgrade && isMounted) {
      _hasShownInitialUpgrade = true;
      // Delay slightly to ensure game is fully loaded
      Future.delayed(Duration(milliseconds: 500), () {
        showUpgradeSelection();
      });
    }
  }

  void addXP(int amount) {
    currentXP += amount;

    if (currentXP >= xpToNextLevel) {
      levelUp();
    }
  }

  void levelUp() {
    currentLevel++;
    currentXP -= xpToNextLevel;
    xpToNextLevel = (xpToNextLevel * 1.5).round();

    // Show upgrade selection
    showUpgradeSelection();
  }

  Future<void> showUpgradeSelection() async {
    print('[LevelManager] showUpgradeSelection called');

    // Just pause the game - Flutter UI will handle the rest via callbacks
    gameRef.pauseForUpgrade();
    print('[LevelManager] Game paused - waiting for Flutter UI');
  }

  List<Upgrade> getRandomUpgrades(int count) {
    final allUpgrades = UpgradeFactory.getAllUpgrades();

    final random = Random();
    final selected = <Upgrade>[];
    final available = List<Upgrade>.from(allUpgrades);

    for (int i = 0; i < count && available.isNotEmpty; i++) {
      final index = random.nextInt(available.length);
      selected.add(available.removeAt(index));
    }

    return selected;
  }

  int getLevel() => currentLevel;
  int getXP() => currentXP;
  int getXPToNextLevel() => xpToNextLevel;
  double getXPProgress() => currentXP / xpToNextLevel;
}
