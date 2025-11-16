import 'dart:math';
import '../components/player_ship.dart';

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
}

/// Adds additional projectiles
class MultiShotUpgrade extends Upgrade {
  final int additionalProjectiles;

  MultiShotUpgrade({this.additionalProjectiles = 1})
      : super(
          id: 'multi_shot',
          name: 'Multi Shot',
          description: '+$additionalProjectiles Projectile',
          icon: '🔫',
        );

  @override
  void apply(PlayerShip player) {
    player.projectileCount += additionalProjectiles;
  }
}

/// Increases bullet speed
class BulletSpeedUpgrade extends Upgrade {
  final double speedIncrease;

  BulletSpeedUpgrade({this.speedIncrease = 100})
      : super(
          id: 'bullet_speed',
          name: 'Bullet Speed',
          description: 'Faster bullets',
          icon: '💨',
        );

  @override
  void apply(PlayerShip player) {
    player.bulletSpeed += speedIncrease;
  }
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
}

/// Factory class to create all available upgrades
class UpgradeFactory {
  static List<Upgrade> getAllUpgrades() {
    return [
      DamageUpgrade(),
      FireRateUpgrade(),
      RangeUpgrade(),
      MultiShotUpgrade(),
      BulletSpeedUpgrade(),
      MoveSpeedUpgrade(),
      MaxHealthUpgrade(),
      MagnetUpgrade(),
    ];
  }
}
