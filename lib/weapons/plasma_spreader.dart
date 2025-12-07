import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/bullet.dart';
import '../components/player_ship.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Plasma Spreader - fires multiple projectiles in a wide spread
class PlasmaSpreader extends Weapon {
  static const String ID = 'plasma_spreader';

  PlasmaSpreader()
      : super(
          id: ID,
          name: 'Plasma Spreader',
          description: 'Wide spread for crowd control',
          damageMultiplier: 0.6, // Each projectile does less damage
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
    final game = player.game;

    // Base number of projectiles (3) + player's multi-shot upgrades
    final baseProjectiles = 3;
    final totalProjectiles = baseProjectiles + player.projectileCount - 1;

    // Roll crit once for all bullets in this shot (consistency)
    final shotIsCrit = Random().nextDouble() < player.critChance;

    // Tighter spread angle - was too wide
    final angleSpread = 0.2; // Reduced from 0.4
    final baseAngle = atan2(targetDirection.y, targetDirection.x);

    for (int i = 0; i < totalProjectiles; i++) {
      // First bullet always goes straight, rest spread around it
      final offset = i == 0 ? 0.0 : ((i - totalProjectiles / 2) * angleSpread);
      final bulletAngle = baseAngle + offset;
      final bulletDirection = Vector2(cos(bulletAngle), sin(bulletAngle));

      // Only apply spawn offset if homing is active (to keep bullets visually separate)
      Vector2 spawnPos;
      if (player.homingStrength > 0) {
        const double spawnOffsetRadius = 15.0;
        final spawnOffsetAngle = (i / totalProjectiles) * 2 * pi;
        final spawnOffsetX = cos(spawnOffsetAngle) * spawnOffsetRadius;
        final spawnOffsetY = sin(spawnOffsetAngle) * spawnOffsetRadius;
        spawnPos = bulletSpawnPosition + Vector2(spawnOffsetX, spawnOffsetY);
      } else {
        // No homing - use regular spawn position
        spawnPos = bulletSpawnPosition.clone();
      }

      final bullet = Bullet(
        position: spawnPos,
        direction: bulletDirection.normalized(),
        baseDamage: getDamage(player),
        speed: getProjectileSpeed(player),
        baseColor: const Color(0xFF00FFFF), // Cyan
        bulletType: BulletType.plasma,
        pierceCount: player.bulletPierce,
        homingStrength: player.homingStrength,
        customSize: Vector2.all(player.bulletSize * 0.8), // Slightly smaller
        forceCrit: shotIsCrit, // All bullets share same crit result
      );
      game.world.add(bullet);
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
    WeaponFactory.register(ID, () => PlasmaSpreader());
  }

  static void init() {
    registerFactory();
    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 5,
      displayName: 'Plasma Spreader',
      description: 'Wide spread for crowd control',
      icon: '💠',
    );
  }
}
