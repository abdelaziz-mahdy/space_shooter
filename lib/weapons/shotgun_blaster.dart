import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/bullet.dart';
import '../components/player_ship.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Shotgun Blaster - fires many pellets in a tight cone with damage falloff
class ShotgunBlaster extends Weapon {
  static const String ID = 'shotgun_blaster';

  ShotgunBlaster()
      : super(
          id: ID,
          name: 'Shotgun Blaster',
          description: 'Close-range devastation with multiple pellets',
          damageMultiplier: 1.8, // High damage per pellet
          fireRateMultiplier: 1.8, // Slower fire rate for balance
          projectileSpeedMultiplier: 1.2, // Slightly faster pellets
        );

  @override
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  ) {
    final game = player.game;
    final bulletSpawnPosition = _getBulletSpawnPosition(player);
    final baseSpeed = getProjectileSpeed(player);
    final baseDamage = getDamage(player);

    // Roll crit once for all pellets in this shot (consistency)
    final shotIsCrit = Random().nextDouble() < player.critChance;

    // Fire 8 pellets in a cone
    const pelletCount = 8;
    const spreadAngle = 20.0; // degrees total spread (reduced from 25)
    final spreadRad = spreadAngle * (pi / 180);

    for (int i = 0; i < pelletCount; i++) {
      // First pellet always goes straight, rest spread around it
      final angleOffset = i == 0 ? 0.0 : ((i - pelletCount / 2) / pelletCount * spreadRad);

      // Rotate target direction by spread offset
      final cosAngle = cos(angleOffset);
      final sinAngle = sin(angleOffset);
      final spreadDirection = Vector2(
        targetDirection.x * cosAngle - targetDirection.y * sinAngle,
        targetDirection.x * sinAngle + targetDirection.y * cosAngle,
      ).normalized();

      // Slight speed variation for visual variety
      final speedVariation = 0.9 + (Random().nextDouble() * 0.2); // 90-110%
      final pelletSpeed = baseSpeed * speedVariation;

      // Create pellet bullet
      final bullet = Bullet(
        position: bulletSpawnPosition.clone(),
        direction: spreadDirection,
        speed: pelletSpeed,
        baseDamage: baseDamage,
        baseColor: const Color(0xFFFF8800), // Orange pellets
        customSize: Vector2.all(player.bulletSize * 0.7), // Smaller pellets
        forceCrit: shotIsCrit, // All pellets share same crit result
      );

      game.world.add(bullet);
    }
  }

  Vector2 _getBulletSpawnPosition(PlayerShip player) {
    final spawnDistance = player.size.y / 2;
    final angleRad = player.angle;
    final direction = Vector2(sin(angleRad), -cos(angleRad));
    return player.position + direction * spawnDistance;
  }

  /// Register this weapon with the factory and config
  static void init() {
    WeaponFactory.register(ID, () => ShotgunBlaster());

    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 25,
      displayName: 'Shotgun Blaster',
      description: 'Close-range multi-pellet devastation',
      icon: '💥',
    );
  }
}
