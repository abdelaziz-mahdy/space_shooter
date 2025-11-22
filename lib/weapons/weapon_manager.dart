import 'package:flame/components.dart';
import '../components/player_ship.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Manages weapon switching and firing for the player
class WeaponManager extends Component {
  late Weapon currentWeapon;
  final List<String> unlockedWeapons = [];
  final Map<String, Weapon> weaponInstances = {};

  WeaponManager() {
    // Get all registered weapons and create instances
    final allWeaponIds = WeaponFactory.getAllIds();
    for (final weaponId in allWeaponIds) {
      weaponInstances[weaponId] = WeaponFactory.create(weaponId);
    }

    // Unlock weapons at level 1 by default (typically just pulse_cannon)
    final defaultWeapons = WeaponUnlockConfig.getWeaponsForLevel(1);
    unlockedWeapons.addAll(defaultWeapons);

    // Set pulse cannon as default weapon
    if (weaponInstances.containsKey('pulse_cannon')) {
      currentWeapon = weaponInstances['pulse_cannon']!;
    } else if (weaponInstances.isNotEmpty) {
      // Fallback to first weapon if pulse cannon not found
      currentWeapon = weaponInstances.values.first;
    } else {
      throw Exception('No weapons registered! Call weapon init() methods before creating WeaponManager');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update current weapon cooldown
    currentWeapon.update(dt);
  }

  /// Switch to a different weapon by ID
  void switchWeapon(String weaponId) {
    if (!isUnlocked(weaponId)) {
      print('[WeaponManager] Cannot switch to locked weapon: $weaponId');
      return;
    }

    final weapon = weaponInstances[weaponId];
    if (weapon != null) {
      currentWeapon = weapon;
      final displayName = WeaponUnlockConfig.getDisplayName(weaponId);
      print('[WeaponManager] Switched to weapon: $displayName');
    }
  }

  /// Unlock a new weapon by ID
  void unlockWeapon(String weaponId) {
    if (!unlockedWeapons.contains(weaponId)) {
      unlockedWeapons.add(weaponId);
      final displayName = WeaponUnlockConfig.getDisplayName(weaponId);
      print('[WeaponManager] Unlocked weapon: $displayName');
    }
  }

  /// Unlock all weapons up to a certain level
  void unlockWeaponsForLevel(int level) {
    final weaponsToUnlock = WeaponUnlockConfig.getWeaponsForLevel(level);
    for (final weaponId in weaponsToUnlock) {
      unlockWeapon(weaponId);
    }
  }

  /// Check if a weapon is unlocked
  bool isUnlocked(String weaponId) {
    return unlockedWeapons.contains(weaponId);
  }

  /// Fire the current weapon
  void fireCurrentWeapon(
    PlayerShip player,
    Vector2? direction,
    PositionComponent? target,
  ) {
    if (direction == null) return;

    if (currentWeapon.canFire()) {
      currentWeapon.fire(player, direction, target);
      currentWeapon.resetCooldown(player);
    }
  }

  /// Get list of all unlocked weapon IDs
  List<String> getUnlockedWeapons() {
    return List.from(unlockedWeapons);
  }

  /// Get the current weapon ID
  String getCurrentWeaponId() {
    return currentWeapon.id;
  }

  /// Get the current weapon name
  String getCurrentWeaponName() {
    return currentWeapon.name;
  }

  /// Cycle to next unlocked weapon
  void cycleWeapon() {
    if (unlockedWeapons.length <= 1) return;

    final currentIndex = unlockedWeapons.indexOf(currentWeapon.id);
    final nextIndex = (currentIndex + 1) % unlockedWeapons.length;
    switchWeapon(unlockedWeapons[nextIndex]);
  }
}
