import '../factories/weapon_factory.dart';

/// Configuration for weapon unlock progression
/// Each weapon registers its unlock level and metadata here
class WeaponUnlockConfig {
  static final Map<String, WeaponMetadata> _weaponMetadata = {};

  /// Register weapon metadata including unlock level
  static void registerWeapon(
    String weaponId, {
    required int unlockLevel,
    required String displayName,
    required String description,
    required String icon,
  }) {
    _weaponMetadata[weaponId] = WeaponMetadata(
      id: weaponId,
      unlockLevel: unlockLevel,
      displayName: displayName,
      description: description,
      icon: icon,
    );
    print('[WeaponUnlockConfig] Registered weapon: $weaponId (unlock level: $unlockLevel)');
  }

  /// Get unlock level for a specific weapon
  static int getUnlockLevel(String weaponId) {
    final metadata = _weaponMetadata[weaponId];
    if (metadata == null) {
      throw Exception('Weapon not registered: $weaponId');
    }
    return metadata.unlockLevel;
  }

  /// Get all weapons unlocked at or below a specific level
  static List<String> getWeaponsForLevel(int level) {
    return _weaponMetadata.entries
        .where((entry) => entry.value.unlockLevel <= level)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get metadata for a specific weapon
  static WeaponMetadata? getMetadata(String weaponId) {
    return _weaponMetadata[weaponId];
  }

  /// Get all registered weapon IDs
  static List<String> getAllWeaponIds() => _weaponMetadata.keys.toList();

  /// Check if a weapon is registered
  static bool isRegistered(String weaponId) {
    return _weaponMetadata.containsKey(weaponId);
  }

  /// Get display name for a weapon
  static String getDisplayName(String weaponId) {
    final metadata = _weaponMetadata[weaponId];
    return metadata?.displayName ?? weaponId;
  }

  /// Get description for a weapon
  static String getDescription(String weaponId) {
    final metadata = _weaponMetadata[weaponId];
    return metadata?.description ?? '';
  }

  /// Get icon for a weapon
  static String getIcon(String weaponId) {
    final metadata = _weaponMetadata[weaponId];
    return metadata?.icon ?? '🔫';
  }

  /// Get detailed description including multipliers (dynamically from weapon instance)
  /// This ensures the description always matches the actual weapon code
  static String getDetailedDescription(String weaponId) {
    try {
      // Get weapon instance from factory to read its actual multipliers
      final weapon = WeaponFactory.create(weaponId);
      return weapon.getDetailedDescription();
    } catch (e) {
      // Fallback to basic description if weapon not found
      print('[WeaponUnlockConfig] Could not get detailed description for $weaponId: $e');
      return getDescription(weaponId);
    }
  }

  /// Clear all registrations (useful for testing)
  static void clearRegistrations() {
    _weaponMetadata.clear();
  }
}

/// Metadata for a weapon
class WeaponMetadata {
  final String id;
  final int unlockLevel;
  final String displayName;
  final String description;
  final String icon;

  const WeaponMetadata({
    required this.id,
    required this.unlockLevel,
    required this.displayName,
    required this.description,
    required this.icon,
  });
}
