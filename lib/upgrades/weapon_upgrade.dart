import 'package:space_shooter/components/player_ship.dart';
import 'package:space_shooter/upgrades/upgrade.dart';

/// Base class for weapon-specific upgrades
/// These upgrades only appear when the player has the specific weapon equipped
abstract class WeaponUpgrade extends Upgrade {
  final String weaponId;

  WeaponUpgrade({
    required this.weaponId,
    required super.id,
    required super.name,
    required super.description,
    required super.icon,
  });

  @override
  bool isValidFor(PlayerShip player) {
    // Only offer this upgrade if the weapon is currently equipped
    return player.weaponManager.currentWeapon?.id == weaponId;
  }
}

// ============================================================================
// PULSE CANNON UPGRADES
// ============================================================================

/// Pulse Cannon: Increased damage
class PulseCannonDamageUpgrade extends WeaponUpgrade {
  final double damageIncrease;

  PulseCannonDamageUpgrade({this.damageIncrease = 8.0})
      : super(
          weaponId: 'pulse_cannon',
          id: 'pulse_cannon_damage',
          name: 'Pulse Amplification',
          description: '+${damageIncrease.toInt()} damage',
          icon: '⚡',
        );

  @override
  void apply(PlayerShip player) {
    player.damage += damageIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+${damageIncrease.toInt()} damage (Pulse Cannon)'];
}

/// Pulse Cannon: Extra projectiles
class PulseCannonMultiShotUpgrade extends WeaponUpgrade {
  final int projectileIncrease;

  PulseCannonMultiShotUpgrade({this.projectileIncrease = 1})
      : super(
          weaponId: 'pulse_cannon',
          id: 'pulse_cannon_multi_shot',
          name: 'Pulse Barrage',
          description: '+$projectileIncrease projectile',
          icon: '⚡',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += projectileIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+$projectileIncrease projectile (Pulse Cannon)'];
}

// ============================================================================
// PLASMA SPREADER UPGRADES
// ============================================================================

/// Plasma Spreader: Increased damage
class PlasmaSpreaderDamageUpgrade extends WeaponUpgrade {
  final double damageIncrease;

  PlasmaSpreaderDamageUpgrade({this.damageIncrease = 6.0})
      : super(
          weaponId: 'plasma_spreader',
          id: 'plasma_spreader_damage',
          name: 'Plasma Intensification',
          description: '+${damageIncrease.toInt()} damage per shot',
          icon: '🌀',
        );

  @override
  void apply(PlayerShip player) {
    player.damage += damageIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+${damageIncrease.toInt()} damage (Plasma Spreader)'];
}

/// Plasma Spreader: Wider spread
class PlasmaSpreaderWideSpreadUpgrade extends WeaponUpgrade {
  final int projectileIncrease;

  PlasmaSpreaderWideSpreadUpgrade({this.projectileIncrease = 2})
      : super(
          weaponId: 'plasma_spreader',
          id: 'plasma_spreader_wide_spread',
          name: 'Plasma Storm',
          description: '+$projectileIncrease projectiles',
          icon: '🌀',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += projectileIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+$projectileIncrease projectiles (Plasma Spreader)'];
}

/// Plasma Spreader: Pierce through enemies
class PlasmaSpreaderPierceUpgrade extends WeaponUpgrade {
  final int pierceIncrease;

  PlasmaSpreaderPierceUpgrade({this.pierceIncrease = 2})
      : super(
          weaponId: 'plasma_spreader',
          id: 'plasma_spreader_pierce',
          name: 'Plasma Penetration',
          description: '+$pierceIncrease pierce',
          icon: '🌀',
        );

  @override
  void apply(PlayerShip player) {
    player.bulletPierce += pierceIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+$pierceIncrease pierce (Plasma Spreader)'];
}

// ============================================================================
// RAILGUN UPGRADES
// ============================================================================

/// Railgun: Increased damage
class RailgunDamageUpgrade extends WeaponUpgrade {
  final double damageIncrease;

  RailgunDamageUpgrade({this.damageIncrease = 15.0})
      : super(
          weaponId: 'railgun',
          id: 'railgun_damage',
          name: 'Railgun Overcharge',
          description: '+${damageIncrease.toInt()} damage',
          icon: '🔫',
        );

  @override
  void apply(PlayerShip player) {
    player.damage += damageIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+${damageIncrease.toInt()} damage (Railgun)'];
}

/// Railgun: Explosive impact
class RailgunExplosiveUpgrade extends WeaponUpgrade {
  final double explosionIncrease;

  RailgunExplosiveUpgrade({this.explosionIncrease = 80.0})
      : super(
          weaponId: 'railgun',
          id: 'railgun_explosive',
          name: 'Explosive Rounds',
          description: '+${explosionIncrease.toInt()} explosion radius',
          icon: '🔫',
        );

  @override
  void apply(PlayerShip player) {
    player.explosionRadius += explosionIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.epic;

  @override
  List<String> getStatusChanges() => ['+${explosionIncrease.toInt()} explosion radius (Railgun)'];
}

// ============================================================================
// MISSILE LAUNCHER UPGRADES
// ============================================================================

/// Missile Launcher: Increased damage
class MissileLauncherDamageUpgrade extends WeaponUpgrade {
  final double damageIncrease;

  MissileLauncherDamageUpgrade({this.damageIncrease = 10.0})
      : super(
          weaponId: 'missile_launcher',
          id: 'missile_launcher_damage',
          name: 'Missile Warheads',
          description: '+${damageIncrease.toInt()} damage',
          icon: '🚀',
        );

  @override
  void apply(PlayerShip player) {
    player.damage += damageIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+${damageIncrease.toInt()} damage (Missile Launcher)'];
}

/// Missile Launcher: More missiles
class MissileLauncherMultiShotUpgrade extends WeaponUpgrade {
  final int projectileIncrease;

  MissileLauncherMultiShotUpgrade({this.projectileIncrease = 2})
      : super(
          weaponId: 'missile_launcher',
          id: 'missile_launcher_multi_shot',
          name: 'Missile Barrage',
          description: '+$projectileIncrease missiles',
          icon: '🚀',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += projectileIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.epic;

  @override
  List<String> getStatusChanges() => ['+$projectileIncrease missiles (Missile Launcher)'];
}

/// Missile Launcher: Stronger homing
class MissileLauncherHomingUpgrade extends WeaponUpgrade {
  final double homingIncrease;

  MissileLauncherHomingUpgrade({this.homingIncrease = 80.0})
      : super(
          weaponId: 'missile_launcher',
          id: 'missile_launcher_homing',
          name: 'Advanced Guidance',
          description: '+${homingIncrease.toInt()} tracking power',
          icon: '🚀',
        );

  @override
  void apply(PlayerShip player) {
    player.homingStrength += homingIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.rare;

  @override
  List<String> getStatusChanges() => ['+${homingIncrease.toInt()} tracking power (Missile Launcher)'];
}

/// Missile Launcher: Bigger explosions
class MissileLauncherExplosionUpgrade extends WeaponUpgrade {
  final double explosionIncrease;

  MissileLauncherExplosionUpgrade({this.explosionIncrease = 50.0})
      : super(
          weaponId: 'missile_launcher',
          id: 'missile_launcher_explosion',
          name: 'Cluster Warheads',
          description: '+${explosionIncrease.toInt()} explosion radius',
          icon: '🚀',
        );

  @override
  void apply(PlayerShip player) {
    player.explosionRadius += explosionIncrease;
  }

  @override
  UpgradeRarity get rarity => UpgradeRarity.epic;

  @override
  List<String> getStatusChanges() => ['+${explosionIncrease.toInt()} explosion radius (Missile Launcher)'];
}
