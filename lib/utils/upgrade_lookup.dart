import '../upgrades/upgrade.dart';
import '../config/weapon_unlock_config.dart';

/// Utility class to look up upgrade information by ID
class UpgradeLookup {
  static final Map<String, UpgradeInfo> _upgradeMap = _buildUpgradeMap();

  static Map<String, UpgradeInfo> _buildUpgradeMap() {
    final map = <String, UpgradeInfo>{};

    // Add all generic upgrades
    for (final upgrade in UpgradeFactory.getAllUpgrades()) {
      map[upgrade.id] = UpgradeInfo(
        id: upgrade.id,
        name: upgrade.name,
        description: upgrade.description,
        icon: upgrade.icon,
        rarity: upgrade.rarity,
      );
    }

    // Add all weapon upgrades
    for (final upgrade in UpgradeFactory.getAllWeaponUpgrades()) {
      map[upgrade.id] = UpgradeInfo(
        id: upgrade.id,
        name: upgrade.name,
        description: upgrade.description,
        icon: upgrade.icon,
        rarity: upgrade.rarity,
      );
    }

    // Add weapon unlock upgrades
    for (final weaponId in WeaponUnlockConfig.getAllWeaponIds()) {
      final id = 'weapon_unlock_$weaponId';
      map[id] = UpgradeInfo(
        id: id,
        name: 'Unlock ${WeaponUnlockConfig.getDisplayName(weaponId)}',
        description: WeaponUnlockConfig.getDescription(weaponId),
        icon: WeaponUnlockConfig.getIcon(weaponId),
        rarity: UpgradeRarity.rare,
      );
    }

    return map;
  }

  /// Get upgrade info by ID, returns null if not found
  static UpgradeInfo? getUpgradeInfo(String id) {
    return _upgradeMap[id];
  }

  /// Get all upgrade infos for a list of IDs
  static List<UpgradeInfo> getUpgradesForIds(List<String> ids) {
    return ids
        .map((id) => _upgradeMap[id])
        .where((info) => info != null)
        .cast<UpgradeInfo>()
        .toList();
  }
}

/// Simple data class for upgrade information
class UpgradeInfo {
  final String id;
  final String name;
  final String description;
  final String icon;
  final UpgradeRarity rarity;

  const UpgradeInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
  });
}
