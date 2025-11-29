import 'dart:math';
import 'package:flutter/material.dart';
import '../components/player_ship.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon_upgrade.dart';

/// Abstract base class for upgrade rarity levels
/// Following OOP principles - each rarity is a class, not an enum value
abstract class UpgradeRarity {
  String get name;
  Color get color;
  double get dropWeight;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpgradeRarity &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Common rarity - most frequent drops
class CommonRarity extends UpgradeRarity {
  @override
  String get name => 'Common';

  @override
  Color get color => const Color(0xFFFFFFFF);

  @override
  double get dropWeight => 0.60;
}

/// Rare rarity - less common, better upgrades
class RareRarity extends UpgradeRarity {
  @override
  String get name => 'Rare';

  @override
  Color get color => const Color(0xFF0099FF);

  @override
  double get dropWeight => 0.25;
}

/// Epic rarity - powerful upgrades
class EpicRarity extends UpgradeRarity {
  @override
  String get name => 'Epic';

  @override
  Color get color => const Color(0xFF9933FF);

  @override
  double get dropWeight => 0.12;
}

/// Legendary rarity - most powerful, rarest upgrades
class LegendaryRarity extends UpgradeRarity {
  @override
  String get name => 'Legendary';

  @override
  Color get color => const Color(0xFFFFAA00);

  @override
  double get dropWeight => 0.03;
}

/// Abstract base class for all upgrades
abstract class Upgrade {
  final String id;
  final String name;
  final String description;
  final String icon;

  Upgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });

  /// Apply this upgrade to the player
  void apply(PlayerShip player);

  /// Get the rarity of this upgrade
  UpgradeRarity get rarity => CommonRarity();

  /// Check if this upgrade is valid/useful for the current player state
  /// Override this to prevent showing upgrades that don't make sense
  bool isValidFor(PlayerShip player) => true;

  /// Get a list of status changes this upgrade provides
  /// Returns a list of strings describing each stat modification
  List<String> getStatusChanges() => [];
}

/// Increases player damage
class DamageUpgrade extends Upgrade {
  final double damageIncrease;

  DamageUpgrade({this.damageIncrease = 5})
      : super(
          id: 'damage',
          name: 'Increased Damage',
          description: '+$damageIncrease Damage',
          icon: '⚔️',
        );

  @override
  void apply(PlayerShip player) {
    player.damage += damageIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+$damageIncrease damage'];
}

/// Increases fire rate
class FireRateUpgrade extends Upgrade {
  final double fireRateDecrease;

  FireRateUpgrade({this.fireRateDecrease = 0.1})
      : super(
          id: 'fire_rate',
          name: 'Faster Fire Rate',
          description: 'Shoot faster',
          icon: '⚡',
        );

  @override
  void apply(PlayerShip player) {
    player.shootInterval = max(0.1, player.shootInterval - fireRateDecrease);
  }

  @override
  List<String> getStatusChanges() => ['Reduced fire interval by ${fireRateDecrease}s'];
}

/// Increases targeting range
class RangeUpgrade extends Upgrade {
  final double rangeIncrease;

  RangeUpgrade({this.rangeIncrease = 50})
      : super(
          id: 'range',
          name: 'Longer Range',
          description: '+$rangeIncrease Range',
          icon: '🎯',
        );

  @override
  void apply(PlayerShip player) {
    player.targetRange += rangeIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+${rangeIncrease.toInt()} target range'];
}

/// Adds additional projectiles
class MultiShotUpgrade extends Upgrade {
  final int additionalProjectiles;

  MultiShotUpgrade({this.additionalProjectiles = 2})
      : super(
          id: 'multi_shot',
          name: 'Multi Shot',
          description: '+$additionalProjectiles Projectiles',
          icon: '🔫',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += additionalProjectiles;
  }

  @override
  UpgradeRarity get rarity => RareRarity();

  @override
  List<String> getStatusChanges() => ['+$additionalProjectiles projectiles'];
}

/// Increases movement speed
class MoveSpeedUpgrade extends Upgrade {
  final double speedIncrease;

  MoveSpeedUpgrade({this.speedIncrease = 50})
      : super(
          id: 'move_speed',
          name: 'Move Speed',
          description: '+$speedIncrease Speed',
          icon: '🏃',
        );

  @override
  void apply(PlayerShip player) {
    player.moveSpeed += speedIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+${speedIncrease.toInt()} move speed'];
}

/// Increases maximum health
class MaxHealthUpgrade extends Upgrade {
  final double healthIncrease;

  MaxHealthUpgrade({this.healthIncrease = 20})
      : super(
          id: 'max_health',
          name: 'Max Health',
          description: '+$healthIncrease Max HP',
          icon: '❤️',
        );

  @override
  void apply(PlayerShip player) {
    player.maxHealth += healthIncrease;
    player.health += healthIncrease;
  }

  @override
  List<String> getStatusChanges() => [
    '+${healthIncrease.toInt()} max health',
    '+${healthIncrease.toInt()} current health'
  ];
}

/// Increases XP attraction radius
class MagnetUpgrade extends Upgrade {
  final double radiusIncrease;

  MagnetUpgrade({this.radiusIncrease = 100})
      : super(
          id: 'magnet',
          name: 'Magnet',
          description: '+${radiusIncrease.toInt()} Attraction Radius',
          icon: '🧲',
        );

  @override
  void apply(PlayerShip player) {
    player.magnetRadius += radiusIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+${radiusIncrease.toInt()} magnet radius'];
}

/// Regenerate health over time
class HealthRegenUpgrade extends Upgrade {
  final double regenRate;

  HealthRegenUpgrade({this.regenRate = 2.0})
      : super(
          id: 'health_regen',
          name: 'Health Regen',
          description: '+$regenRate HP/sec',
          icon: '💚',
        );

  @override
  void apply(PlayerShip player) {
    player.healthRegen += regenRate;
  }

  @override
  List<String> getStatusChanges() => ['+$regenRate HP/second regeneration'];
}

/// Increase bullet pierce (bullets can hit multiple enemies)
class PierceUpgrade extends Upgrade {
  final int pierceIncrease;

  PierceUpgrade({this.pierceIncrease = 1})
      : super(
          id: 'pierce',
          name: 'Piercing Shots',
          description: '+$pierceIncrease Pierce',
          icon: '🔱',
        );

  @override
  void apply(PlayerShip player) {
    player.bulletPierce += pierceIncrease;
  }

  @override
  List<String> getStatusChanges() => ['+$pierceIncrease bullet pierce'];
}

/// Increase critical hit chance
class CritChanceUpgrade extends Upgrade {
  final double critChanceIncrease;

  CritChanceUpgrade({this.critChanceIncrease = 0.1})
      : super(
          id: 'crit_chance',
          name: 'Critical Strikes',
          description: '+${(critChanceIncrease * 100).toInt()}% Crit Chance',
          icon: '💥',
        );

  @override
  void apply(PlayerShip player) {
    player.critChance += critChanceIncrease;
    player.critChance = player.critChance.clamp(0.0, 0.75);
  }

  @override
  List<String> getStatusChanges() => ['+${(critChanceIncrease * 100).toInt()}% crit chance'];
}

/// Increase critical hit damage multiplier
class CritDamageUpgrade extends Upgrade {
  final double critDamageIncrease;

  CritDamageUpgrade({this.critDamageIncrease = 0.5})
      : super(
          id: 'crit_damage',
          name: 'Devastating Crits',
          description: '+${(critDamageIncrease * 100).toInt()}% Crit Damage',
          icon: '💢',
        );

  @override
  void apply(PlayerShip player) {
    player.critDamage += critDamageIncrease;
    player.critDamage = player.critDamage.clamp(1.0, 5.0);
  }

  @override
  List<String> getStatusChanges() => ['+${(critDamageIncrease * 100).toInt()}% crit damage multiplier'];
}

/// Add lifesteal (heal on hit)
class LifestealUpgrade extends Upgrade {
  final double lifestealPercent;

  LifestealUpgrade({this.lifestealPercent = 0.1})
      : super(
          id: 'lifesteal',
          name: 'Lifesteal',
          description: '+${(lifestealPercent * 100).toInt()}% Lifesteal',
          icon: '🩸',
        );

  @override
  void apply(PlayerShip player) {
    player.lifesteal += lifestealPercent;
  }

  @override
  List<String> getStatusChanges() => ['+${(lifestealPercent * 100).toInt()}% lifesteal'];
}

/// Increase XP gain
class XPBoostUpgrade extends Upgrade {
  final double xpMultiplier;

  XPBoostUpgrade({this.xpMultiplier = 0.25})
      : super(
          id: 'xp_boost',
          name: 'XP Boost',
          description: '+${(xpMultiplier * 100).toInt()}% XP Gain',
          icon: '📈',
        );

  @override
  void apply(PlayerShip player) {
    player.xpMultiplier += xpMultiplier;
  }

  @override
  List<String> getStatusChanges() => ['+${(xpMultiplier * 100).toInt()}% XP gain'];
}

/// Reduce damage taken
class ArmorUpgrade extends Upgrade {
  final double damageReduction;

  ArmorUpgrade({this.damageReduction = 0.1})
      : super(
          id: 'armor',
          name: 'Armor Plating',
          description: '-${(damageReduction * 100).toInt()}% Damage Taken',
          icon: '🛡️',
        );

  @override
  void apply(PlayerShip player) {
    player.damageReduction += damageReduction;
    player.damageReduction = player.damageReduction.clamp(0.0, 0.80);
  }

  @override
  List<String> getStatusChanges() => ['+${(damageReduction * 100).toInt()}% damage reduction'];
}

/// Increase maximum shield layers
class MaxShieldUpgrade extends Upgrade {
  final int maxShieldIncrease;

  MaxShieldUpgrade({this.maxShieldIncrease = 1})
      : super(
          id: 'max_shield',
          name: 'Shield Capacity',
          description: 'Increases maximum shield layers by +$maxShieldIncrease',
          icon: '🛡️',
        );

  @override
  void apply(PlayerShip player) {
    player.maxShieldLayers += maxShieldIncrease;
    // Clamp current shields to new max
    player.shieldLayers = min(player.shieldLayers, player.maxShieldLayers);
  }

  @override
  List<String> getStatusChanges() => ['+$maxShieldIncrease max shield capacity'];
}

/// Bullets explode on hit
class ExplosiveShotsUpgrade extends Upgrade {
  final double explosionRadius;

  ExplosiveShotsUpgrade({this.explosionRadius = 30.0})
      : super(
          id: 'explosive_shots',
          name: 'Explosive Rounds',
          description: 'Bullets explode on impact',
          icon: '💣',
        );

  @override
  void apply(PlayerShip player) {
    player.explosionRadius += explosionRadius;
  }

  @override
  List<String> getStatusChanges() => ['+${explosionRadius.toInt()} explosion radius'];
}

/// Bullets home towards enemies
class HomingUpgrade extends Upgrade {
  final double homingStrength;

  HomingUpgrade({this.homingStrength = 50.0})
      : super(
          id: 'homing',
          name: 'Smart Bullets',
          description: 'All bullets track enemies',
          icon: '🎯',
        );

  @override
  void apply(PlayerShip player) {
    player.homingStrength += homingStrength;
  }

  @override
  List<String> getStatusChanges() => ['+${homingStrength.toInt()} tracking power'];
}

/// Chance to freeze enemies on hit
class FreezeUpgrade extends Upgrade {
  final double freezeChance;

  FreezeUpgrade({this.freezeChance = 0.15})
      : super(
          id: 'freeze',
          name: 'Frost Rounds',
          description: '+${(freezeChance * 100).toInt()}% Freeze Chance',
          icon: '❄️',
        );

  @override
  void apply(PlayerShip player) {
    player.freezeChance += freezeChance;
  }

  @override
  List<String> getStatusChanges() => ['+${(freezeChance * 100).toInt()}% freeze chance'];
}

/// Orbital satellites that shoot
class OrbitalUpgrade extends Upgrade {
  final int orbitals;

  OrbitalUpgrade({this.orbitals = 1})
      : super(
          id: 'orbital',
          name: 'Orbital Drone',
          description: '+$orbitals Orbital Shooter',
          icon: '🛸',
        );

  @override
  void apply(PlayerShip player) {
    player.orbitalCount += orbitals;
    player.orbitalCount = player.orbitalCount.clamp(0, 10); // Cap at 10 for performance
  }

  @override
  List<String> getStatusChanges() => ['+$orbitals orbital shooter'];
}

/// Shield that blocks damage
class ShieldUpgrade extends Upgrade {
  final int shieldLayers;

  ShieldUpgrade({this.shieldLayers = 1})
      : super(
          id: 'shield',
          name: 'Energy Shield',
          description: '+$shieldLayers Shield Layer',
          icon: '🔵',
        );

  @override
  void apply(PlayerShip player) {
    player.maxShieldLayers += shieldLayers; // Increase max capacity
    player.shieldLayers = min(player.shieldLayers + shieldLayers, player.maxShieldLayers);
  }

  @override
  List<String> getStatusChanges() => ['+$shieldLayers shield layer'];
}

/// Unlock a new weapon
class WeaponUnlockUpgrade extends Upgrade {
  final String weaponId;

  WeaponUnlockUpgrade({required this.weaponId})
      : super(
          id: 'weapon_unlock_$weaponId',
          name: 'Unlock ${WeaponUnlockConfig.getDisplayName(weaponId)}',
          description: WeaponUnlockConfig.getDetailedDescription(weaponId),
          icon: WeaponUnlockConfig.getIcon(weaponId),
        );

  @override
  void apply(PlayerShip player) {
    player.weaponManager.unlockWeapon(weaponId);
    // Automatically switch to the newly unlocked weapon
    player.weaponManager.switchWeapon(weaponId);
  }

  @override
  List<String> getStatusChanges() => ['Unlock and equip new weapon'];
}

/// Resilient Shields - Shields regenerate over time
class ResilientShieldsUpgrade extends Upgrade {
  ResilientShieldsUpgrade()
      : super(
          id: 'resilient_shields',
          name: 'Resilient Shields',
          description: 'Shields regenerate every 15s',
          icon: '🛡️',
        );

  @override
  void apply(PlayerShip player) {
    player.shieldRegenInterval = 15.0;
    player.shieldLayers = min(player.shieldLayers + 1, player.maxShieldLayers); // Also add one shield layer
  }

  @override
  UpgradeRarity get rarity => CommonRarity();

  @override
  List<String> getStatusChanges() => [
    '+1 shield layer',
    'Shields regenerate every 15s'
  ];
}

/// Focused Fire - More damage, fewer projectiles
class FocusedFireUpgrade extends Upgrade {
  FocusedFireUpgrade()
      : super(
          id: 'focused_fire',
          name: 'Focused Fire',
          description: '+15% damage, -1 projectile',
          icon: '🎯',
        );

  @override
  void apply(PlayerShip player) {
    player.damageMultiplier += 0.15;
    player.projectileCount = max(1, player.projectileCount - 1);
  }

  @override
  bool isValidFor(PlayerShip player) {
    // Only show this upgrade if player has more than 1 projectile
    return player.projectileCount > 1;
  }

  @override
  UpgradeRarity get rarity => CommonRarity();

  @override
  List<String> getStatusChanges() => [
    '+15% damage multiplier',
    '-1 projectile count'
  ];
}

/// Berserker Rage - Massive damage when low HP
class BerserkerRageUpgrade extends Upgrade {
  BerserkerRageUpgrade()
      : super(
          id: 'berserker_rage',
          name: 'Berserker Rage',
          description: '+50% damage when below 30% HP',
          icon: '😡',
        );

  @override
  void apply(PlayerShip player) {
    player.berserkMultiplier += 0.5;
  }

  @override
  bool isValidForPlayer(PlayerShip player) {
    // Don't show if player already has berserk
    return player.berserkMultiplier == 0;
  }

  @override
  UpgradeRarity get rarity => RareRarity();

  @override
  List<String> getStatusChanges() => ['+50% damage when below 30% HP'];
}

/// Thorns Armor - Reflect damage
class ThornsArmorUpgrade extends Upgrade {
  ThornsArmorUpgrade()
      : super(
          id: 'thorns_armor',
          name: 'Thorns Armor',
          description: 'Reflect 20% damage taken',
          icon: '🌵',
        );

  @override
  void apply(PlayerShip player) {
    player.thornsPercent += 0.20; // Store as fraction (0.20 = 20%)
    player.thornsPercent = player.thornsPercent.clamp(0.0, 0.50); // Cap at 50%
  }

  @override
  UpgradeRarity get rarity => RareRarity();

  @override
  List<String> getStatusChanges() => ['Reflect 20% of damage taken'];
}

/// Chain Lightning - Bullets chain to nearby enemies
class ChainLightningUpgrade extends Upgrade {
  ChainLightningUpgrade()
      : super(
          id: 'chain_lightning',
          name: 'Chain Lightning',
          description: 'Bullets chain to 2 nearby enemies',
          icon: '⚡',
        );

  @override
  void apply(PlayerShip player) {
    player.chainCount += 2;
  }

  @override
  UpgradeRarity get rarity => RareRarity();

  @override
  List<String> getStatusChanges() => ['+2 chain targets'];
}

/// Bleeding Edge - Enemies bleed over time
class BleedingEdgeUpgrade extends Upgrade {
  BleedingEdgeUpgrade()
      : super(
          id: 'bleeding_edge',
          name: 'Bleeding Edge',
          description: 'Enemies bleed for 5 DPS for 3s',
          icon: '🩸',
        );

  @override
  void apply(PlayerShip player) {
    player.bleedDamage += 5.0;
  }

  @override
  UpgradeRarity get rarity => RareRarity();

  @override
  List<String> getStatusChanges() => ['Enemies bleed 5 DPS for 3s'];
}

/// Vampiric Aura - Heal from nearby kills
class VampiricAuraUpgrade extends Upgrade {
  VampiricAuraUpgrade()
      : super(
          id: 'vampiric_aura',
          name: 'Vampiric Aura',
          description: 'Heal from kills within 200 radius',
          icon: '🦇',
        );

  @override
  void apply(PlayerShip player) {
    player.lifesteal += 0.2;
    player.magnetRadius += 100; // Also increase magnet radius
  }

  @override
  UpgradeRarity get rarity => EpicRarity();

  @override
  List<String> getStatusChanges() => [
    '+20% lifesteal',
    '+100 magnet radius'
  ];
}

/// Time Dilation - Slow time periodically
class TimeDilationUpgrade extends Upgrade {
  TimeDilationUpgrade()
      : super(
          id: 'time_dilation',
          name: 'Time Dilation',
          description: 'Slow enemy speed by 30%',
          icon: '⏰',
        );

  @override
  void apply(PlayerShip player) {
    // Apply a permanent slow effect to enemies
    // This is tracked via a global time scale multiplier
    player.globalTimeScale = (player.globalTimeScale ?? 1.0) * 0.7;
  }

  @override
  UpgradeRarity get rarity => EpicRarity();

  @override
  List<String> getStatusChanges() => ['Slow enemy speed by 30%'];
}

/// Bullet Storm - More projectiles with slight damage penalty
class BulletStormUpgrade extends Upgrade {
  BulletStormUpgrade()
      : super(
          id: 'bullet_storm',
          name: 'Bullet Storm',
          description: '+2 projectiles, -15% damage per shot',
          icon: '🌪️',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += 2;
    player.damageMultiplier *= 0.85; // 15% damage reduction per bullet
  }

  @override
  UpgradeRarity get rarity => EpicRarity();

  @override
  List<String> getStatusChanges() => [
    '+2 projectiles',
    '-15% damage per shot'
  ];
}

/// Phoenix Rebirth - Resurrect on death
class PhoenixRebirthUpgrade extends Upgrade {
  PhoenixRebirthUpgrade()
      : super(
          id: 'phoenix_rebirth',
          name: 'Phoenix Rebirth',
          description: '25% chance to resurrect on death (once)',
          icon: '🔥',
        );

  @override
  void apply(PlayerShip player) {
    player.resurrectionChance = 0.25;
  }

  @override
  UpgradeRarity get rarity => EpicRarity();

  @override
  List<String> getStatusChanges() => ['25% chance to resurrect on death (once)'];
}

/// Infinity Orbitals - Many orbital shooters
class InfinityOrbitalsUpgrade extends Upgrade {
  InfinityOrbitalsUpgrade()
      : super(
          id: 'infinity_orbitals',
          name: 'Infinity Orbitals',
          description: '+5 orbital shooters',
          icon: '🌌',
        );

  @override
  void apply(PlayerShip player) {
    player.orbitalCount += 5;
  }

  @override
  UpgradeRarity get rarity => LegendaryRarity();

  @override
  List<String> getStatusChanges() => ['+5 orbital shooters'];
}

/// Perfect Harmony - Boost all stats
class PerfectHarmonyUpgrade extends Upgrade {
  PerfectHarmonyUpgrade()
      : super(
          id: 'perfect_harmony',
          name: 'Perfect Harmony',
          description: '+10% to ALL stats',
          icon: '✨',
        );

  @override
  void apply(PlayerShip player) {
    player.damage *= 1.1;
    player.maxHealth *= 1.1;
    player.health = min(player.health * 1.1, player.maxHealth);
    player.moveSpeed *= 1.1;
    player.bulletSpeed *= 1.1;
    player.critChance = min(1.0, player.critChance * 1.1);
    player.critDamage *= 1.1;
    player.healthRegen *= 1.1;
  }

  @override
  UpgradeRarity get rarity => LegendaryRarity();

  @override
  List<String> getStatusChanges() => [
    '+10% damage',
    '+10% max health',
    '+10% move speed',
    '+10% bullet speed',
    '+10% crit chance',
    '+10% crit damage',
    '+10% health regen'
  ];
}

/// Glass Cannon - High risk, high reward
class GlassCannonUpgrade extends Upgrade {
  GlassCannonUpgrade()
      : super(
          id: 'glass_cannon',
          name: 'Glass Cannon',
          description: '+100% damage, -50% max HP',
          icon: '💔',
        );

  @override
  void apply(PlayerShip player) {
    player.damageMultiplier += 1.0;
    player.damage *= 2.0;
    player.maxHealth *= 0.5;
    player.health = min(player.health, player.maxHealth);
  }

  @override
  UpgradeRarity get rarity => LegendaryRarity();

  @override
  List<String> getStatusChanges() => [
    '+100% damage multiplier',
    '+100% base damage',
    '-50% max health'
  ];
}

/// Immovable Object - Tank build
class ImmovableObjectUpgrade extends Upgrade {
  ImmovableObjectUpgrade()
      : super(
          id: 'immovable_object',
          name: 'Immovable Object',
          description: '+200% HP, +50% armor, -30% speed',
          icon: '🗿',
        );

  @override
  void apply(PlayerShip player) {
    player.maxHealth *= 3.0;
    player.health *= 3.0;
    player.damageReduction += 0.5;
    player.moveSpeed *= 0.7;
  }

  @override
  UpgradeRarity get rarity => LegendaryRarity();

  @override
  List<String> getStatusChanges() => [
    '+200% max health',
    '+200% current health',
    '+50% damage reduction',
    '-30% move speed'
  ];
}

/// Critical Cascade - Crits chain to other enemies
class CriticalCascadeUpgrade extends Upgrade {
  CriticalCascadeUpgrade()
      : super(
          id: 'critical_cascade',
          name: 'Critical Cascade',
          description: 'Crits chain to 3 enemies at 50% damage',
          icon: '💫',
        );

  @override
  void apply(PlayerShip player) {
    player.critChance += 0.1;
    player.chainCount += 3;
  }

  @override
  UpgradeRarity get rarity => LegendaryRarity();

  @override
  List<String> getStatusChanges() => [
    '+10% crit chance',
    '+3 chain targets',
    'Crits chain at 50% damage'
  ];
}

/// Factory class to create all available upgrades
class UpgradeFactory {
  static List<Upgrade> getAllUpgrades() {
    return [
      // Basic upgrades (Common) - Generic stat boosts
      DamageUpgrade(),
      FireRateUpgrade(),
      RangeUpgrade(),
      MoveSpeedUpgrade(),
      MaxHealthUpgrade(),
      MagnetUpgrade(),
      MultiShotUpgrade(),

      // Advanced upgrades (Common/Rare)
      HealthRegenUpgrade(),
      CritChanceUpgrade(),
      CritDamageUpgrade(),
      LifestealUpgrade(),
      XPBoostUpgrade(),
      ArmorUpgrade(),
      MaxShieldUpgrade(),
      PierceUpgrade(),

      // Special upgrades (Common/Rare) - Generic effects
      OrbitalUpgrade(),
      ShieldUpgrade(),

      // New Common Tier
      ResilientShieldsUpgrade(),
      FocusedFireUpgrade(),

      // New Rare Tier
      BerserkerRageUpgrade(),
      ThornsArmorUpgrade(),
      ChainLightningUpgrade(),
      BleedingEdgeUpgrade(),
      HomingUpgrade(),
      FreezeUpgrade(),
      ExplosiveShotsUpgrade(),

      // New Epic Tier
      VampiricAuraUpgrade(),
      TimeDilationUpgrade(),
      BulletStormUpgrade(),
      PhoenixRebirthUpgrade(),

      // New Legendary Tier
      InfinityOrbitalsUpgrade(),
      PerfectHarmonyUpgrade(),
      GlassCannonUpgrade(),
      ImmovableObjectUpgrade(),
      CriticalCascadeUpgrade(),
    ];
  }

  /// Get all weapon-specific upgrades
  static List<WeaponUpgrade> getAllWeaponUpgrades() {
    return [
      // Pulse Cannon upgrades
      PulseCannonDamageUpgrade(),
      PulseCannonFireRateUpgrade(),
      PulseCannonMultiShotUpgrade(),

      // Plasma Spreader upgrades
      PlasmaSpreaderDamageUpgrade(),
      PlasmaSpreaderWideSpreadUpgrade(),
      PlasmaSpreaderPierceUpgrade(),

      // Railgun upgrades
      RailgunDamageUpgrade(),
      RailgunFireRateUpgrade(),
      RailgunExplosiveUpgrade(),

      // Missile Launcher upgrades
      MissileLauncherDamageUpgrade(),
      MissileLauncherMultiShotUpgrade(),
      MissileLauncherHomingUpgrade(),
      MissileLauncherExplosionUpgrade(),
    ];
  }

  /// Get upgrades filtered by rarity with weighted random selection
  /// Includes both generic and weapon-specific upgrades
  static List<Upgrade> getRandomUpgradesByRarity(int count, {PlayerShip? player}) {
    final random = Random();
    final selected = <Upgrade>[];

    // Combine generic and weapon-specific upgrades
    final genericUpgrades = getAllUpgrades();
    final weaponUpgrades = getAllWeaponUpgrades();
    final allUpgrades = [...genericUpgrades, ...weaponUpgrades];

    for (int i = 0; i < count; i++) {
      // Weighted rarity selection
      // 60% common, 25% rare, 12% epic, 3% legendary
      final rarityRoll = random.nextDouble();
      UpgradeRarity targetRarity;

      if (rarityRoll < 0.60) {
        targetRarity = CommonRarity();
      } else if (rarityRoll < 0.85) {
        targetRarity = RareRarity();
      } else if (rarityRoll < 0.97) {
        targetRarity = EpicRarity();
      } else {
        targetRarity = LegendaryRarity();
      }

      // Get upgrades of target rarity that are valid for the player
      final availableUpgrades = allUpgrades
          .where((u) =>
            u.rarity == targetRarity &&
            !selected.contains(u) &&
            (player == null || u.isValidFor(player)))
          .toList();

      if (availableUpgrades.isNotEmpty) {
        final upgrade = availableUpgrades[random.nextInt(availableUpgrades.length)];
        selected.add(upgrade);
      } else {
        // Fallback to any available upgrade if target rarity is exhausted
        final anyAvailable = allUpgrades
            .where((u) =>
              !selected.contains(u) &&
              (player == null || u.isValidFor(player)))
            .toList();
        if (anyAvailable.isNotEmpty) {
          selected.add(anyAvailable[random.nextInt(anyAvailable.length)]);
        }
      }
    }

    return selected;
  }
}
