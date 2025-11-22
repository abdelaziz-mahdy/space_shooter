import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/bullet.dart';
import '../components/player_ship.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Default weapon - single shot pulse cannon
class PulseCannon extends Weapon {
  static const String ID = 'pulse_cannon';

  PulseCannon()
      : super(
          id: ID,
          name: 'Pulse Cannon',
          description: 'Standard energy weapon with balanced stats',
          damageMultiplier: 1.0,
          fireRateMultiplier: 1.0,
          projectileSpeedMultiplier: 1.0,
        );

  @override
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  ) {
    // Get bullet spawn position from player's tip
    final bulletSpawnPosition = _getBulletSpawnPosition(player);

    // Get the game reference
    final game = player.gameRef;

    if (player.projectileCount == 1) {
      // Single shot
      final bullet = Bullet(
        position: bulletSpawnPosition,
        direction: targetDirection.normalized(),
        baseDamage: getDamage(player),
        speed: getProjectileSpeed(player),
        baseColor: const Color(0xFFFFFF00), // Yellow
        bulletType: BulletType.standard,
        pierceCount: player.bulletPierce,
        homingStrength: player.homingStrength,
        customSize: Vector2.all(player.bulletSize),
      );
      game.world.add(bullet);
    } else {
      // Multiple projectiles in a spread pattern
      final angleSpread = 0.2;
      final baseAngle = atan2(targetDirection.y, targetDirection.x);

      for (int i = 0; i < player.projectileCount; i++) {
        final offset = (i - (player.projectileCount - 1) / 2) * angleSpread;
        final bulletAngle = baseAngle + offset;
        final bulletDirection = Vector2(cos(bulletAngle), sin(bulletAngle));

        final bullet = Bullet(
          position: bulletSpawnPosition.clone(),
          direction: bulletDirection.normalized(),
          baseDamage: getDamage(player),
          speed: getProjectileSpeed(player),
          baseColor: const Color(0xFFFFFF00), // Yellow
          bulletType: BulletType.standard,
          pierceCount: player.bulletPierce,
          homingStrength: player.homingStrength,
          customSize: Vector2.all(player.bulletSize),
        );
        game.world.add(bullet);
      }
    }
  }

  Vector2 _getBulletSpawnPosition(PlayerShip player) {
    // Spawn bullet from the triangle's tip (accounting for rotation)
    final tipLocalOffset = Vector2(0, -player.size.y / 2);
    final cosA = cos(player.angle);
    final sinA = sin(player.angle);
    final rotatedTipX = tipLocalOffset.x * cosA - tipLocalOffset.y * sinA;
    final rotatedTipY = tipLocalOffset.x * sinA + tipLocalOffset.y * cosA;
    return player.position + Vector2(rotatedTipX, rotatedTipY);
  }

  // Factory registration methods
  static void registerFactory() {
    WeaponFactory.register(ID, () => PulseCannon());
  }

  static void init() {
    registerFactory();
    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 1,
      displayName: 'Pulse Cannon',
      description: 'Standard energy weapon',
      icon: '🔫',
    );
  }
}
