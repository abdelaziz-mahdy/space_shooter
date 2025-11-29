import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';
import '../config/weapon_unlock_config.dart';

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
    xpToNextLevel = (xpToNextLevel * 1.2).round(); // Reduced from 1.5x to 1.2x for faster leveling

    // Play level up sound
    gameRef.audioManager.playLevelUp();

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
    final random = Random();
    final player = gameRef.player;

    // Check if this level should offer weapon unlocks
    final weaponUpgrades = _getWeaponUpgradesForLevel();

    // Get regular random upgrades (already filtered by player validity)
    final regularUpgrades = UpgradeFactory.getRandomUpgradesByRarity(count * 2, player: player);

    if (weaponUpgrades.isNotEmpty) {
      // Mix weapon upgrades with regular upgrades
      final allUpgrades = [...weaponUpgrades, ...regularUpgrades];

      // Shuffle and take the requested count
      allUpgrades.shuffle(random);
      return allUpgrades.take(count).toList();
    }

    // No weapon upgrades this level, just return regular upgrades (filtered and limited to count)
    return regularUpgrades.take(count).toList();
  }

  List<Upgrade> _getWeaponUpgradesForLevel() {
    final player = gameRef.player;
    final unlockedWeapons = player.weaponManager.getUnlockedWeapons();
    final options = <Upgrade>[];

    // Get all registered weapons from the config
    final allWeaponIds = WeaponUnlockConfig.getAllWeaponIds();

    // Check each weapon to see if it should be unlocked at this level
    for (final weaponId in allWeaponIds) {
      final unlockLevel = WeaponUnlockConfig.getUnlockLevel(weaponId);

      // Offer weapon if:
      // 1. Player has reached the unlock level
      // 2. Player doesn't already have it unlocked
      if (currentLevel >= unlockLevel && !unlockedWeapons.contains(weaponId)) {
        options.add(WeaponUnlockUpgrade(weaponId: weaponId));
      }
    }

    return options;
  }

  int getLevel() => currentLevel;
  int getXP() => currentXP;
  int getXPToNextLevel() => xpToNextLevel;
  double getXPProgress() => currentXP / xpToNextLevel;
}
