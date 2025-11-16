import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../ui/upgrade_overlay.dart';
import '../upgrades/upgrade.dart';

class LevelManager extends Component with HasGameRef<SpaceShooterGame> {
  int currentLevel = 1;
  int currentXP = 0;
  int xpToNextLevel = 10;

  LevelManager({required SpaceShooterGame game});

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

    gameRef.pauseForUpgrade();
    print('[LevelManager] Game paused');

    // This will be handled by the overlay system
    final upgrades = getRandomUpgrades(3);
    print('[LevelManager] Generated ${upgrades.length} upgrades: ${upgrades.map((u) => u.name).join(", ")}');

    final overlay = UpgradeOverlay(
      onUpgradeSelected: (Upgrade upgrade) {
        print('[LevelManager] Upgrade selected: ${upgrade.name}');
        upgrade.apply(gameRef.player);
        gameRef.resumeFromUpgrade();
        print('[LevelManager] Game resumed');
      },
      availableUpgrades: upgrades,
    );

    print('[LevelManager] Adding overlay to viewport');
    await gameRef.camera.viewport.add(overlay);
    print('[LevelManager] Overlay added to viewport');
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
