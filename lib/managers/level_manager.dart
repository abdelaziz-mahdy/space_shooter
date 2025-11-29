import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';
import '../config/weapon_unlock_config.dart';

class LevelManager extends Component with HasGameRef<SpaceShooterGame> {
  /// Maximum number of weapon unlocks that can appear in a single upgrade selection
  /// This ensures players always have stat upgrade options available
  static const int maxWeaponUpgradesPerSelection = 2;

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
    final allWeaponUpgrades = _getWeaponUpgradesForLevel();

    // IMPORTANT: Limit weapon unlocks to max 2 per upgrade selection
    // This prevents being forced to choose only weapons with no stat upgrades
    final weaponUpgrades = allWeaponUpgrades.isEmpty
        ? <Upgrade>[]
        : (allWeaponUpgrades..shuffle(random)).take(maxWeaponUpgradesPerSelection).toList();

    // Calculate how many regular upgrades we need
    // If we have 2 weapon upgrades, we need (count - 2) regular upgrades
    final regularUpgradesNeeded = count - weaponUpgrades.length;

    // Get regular random upgrades (already filtered by player validity)
    final regularUpgrades = UpgradeFactory.getRandomUpgradesByRarity(
      regularUpgradesNeeded * 2, // Get extra to ensure variety
      player: player,
    ).take(regularUpgradesNeeded).toList();

    // Combine weapon upgrades + regular upgrades, then shuffle
    final allUpgrades = [...weaponUpgrades, ...regularUpgrades];

    // Validate we have enough upgrades (edge case protection)
    if (allUpgrades.length < count) {
      print('[LevelManager] Warning: Only ${allUpgrades.length} upgrades available, expected $count');
    }

    allUpgrades.shuffle(random);
    return allUpgrades.take(count).toList();
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
