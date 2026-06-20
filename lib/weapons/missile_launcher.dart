import 'dart:math';
import 'package:flame/components.dart';
import '../components/missile.dart';
import '../components/player_ship.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Missile Launcher - fires homing missiles with explosion damage
class MissileLauncher extends Weapon {
  static const String ID = 'missile_launcher';

  MissileLauncher()
      : super(
          id: ID,
          name: 'Missile Launcher',
          description: 'Homing missiles with area damage',
          damageMultiplier: 1.5, // Direct hit damage
          fireRateMultiplier: 1.43, // Slower fire rate (0.5s * 1.43 = ~0.7s)
          projectileSpeedMultiplier: 0.6, // Slower missiles
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

    // Fire missiles (respect multi-shot upgrade)
    for (int i = 0; i < player.projectileCount; i++) {
      Vector2 missileDirection;
      Vector2 missileSpawnPos;

      if (player.projectileCount == 1) {
        // Single missile - fire straight
        missileDirection = targetDirection.normalized();
        missileSpawnPos = bulletSpawnPosition.clone();
      } else {
        // Multiple missiles - tighter spread since missiles are homing
        final angleSpread = 0.1; // ~5.7° between missiles
        final baseAngle = atan2(targetDirection.y, targetDirection.x);
        final offset = (i - (player.projectileCount - 1) / 2) * angleSpread;
        final missileAngle = baseAngle + offset;
        missileDirection = Vector2(cos(missileAngle), sin(missileAngle));

        // Missiles always have built-in homing, so always apply spawn offset for visual spread
        const double spawnOffsetRadius = 15.0;
        final spawnOffsetAngle = (i / player.projectileCount) * 2 * pi;
        final spawnOffsetX = cos(spawnOffsetAngle) * spawnOffsetRadius;
        final spawnOffsetY = sin(spawnOffsetAngle) * spawnOffsetRadius;
        missileSpawnPos = bulletSpawnPosition + Vector2(spawnOffsetX, spawnOffsetY);
      }

      final missile = Missile(
        position: missileSpawnPos,
        direction: missileDirection.normalized(),
        damage: getDamage(player),
        speed: getProjectileSpeed(player),
        explosionRadius: 40.0 + player.explosionRadius, // Base + player bonus
        explosionDamage: 0.8, // 80% of direct hit damage in area
        homingStrength: 150.0 + player.homingStrength, // Base + player bonus
      );
      game.world.add(missile);
    }
  }

  Vector2 _getBulletSpawnPosition(PlayerShip player) {
    // Spawn missile from the triangle's tip (accounting for rotation)
    final tipLocalOffset = Vector2(0, -player.size.y / 2);
    final cosA = cos(player.angle);
    final sinA = sin(player.angle);
    final rotatedTipX = tipLocalOffset.x * cosA - tipLocalOffset.y * sinA;
    final rotatedTipY = tipLocalOffset.x * sinA + tipLocalOffset.y * cosA;
    return player.position + Vector2(rotatedTipX, rotatedTipY);
  }

  // Factory registration methods
  static void registerFactory() {
    WeaponFactory.register(ID, () => MissileLauncher());
  }

  static void init() {
    registerFactory();
    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 15,
      displayName: 'Missile Launcher',
      description: 'Homing explosive missiles',
      icon: '🚀',
    );
  }
}
