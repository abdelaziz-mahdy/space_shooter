import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/beam_effect.dart';
import '../components/player_ship.dart';
import '../components/enemies/base_enemy.dart';
import '../game/space_shooter_game.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import 'weapon.dart';

/// Laser Beam - continuous damage beam with shorter range than railgun
class LaserBeam extends Weapon {
  static const String ID = 'laser_beam';

  LaserBeam()
      : super(
          id: ID,
          name: 'Laser Beam',
          description: 'Continuous damage beam with moderate range',
          damageMultiplier: 0.4, // Lower damage per tick, but continuous
          fireRateMultiplier: 0.15, // Very fast fire rate for continuous beam effect
          projectileSpeedMultiplier: 1.0, // Not used for instant beam
        );

  @override
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  ) {
    final gameRef = (player.parent?.parent as SpaceShooterGame?);
    if (gameRef == null) return;

    final bulletSpawnPosition = _getBulletSpawnPosition(player);
    final damage = getDamage(player);

    // Shorter beam range than railgun
    const beamMaxRange = 350.0;

    // Find all enemies in beam path within range (including nested children like boss cores)
    final hitEnemies = <BaseEnemy>[];
    final allEnemies = gameRef.activeEnemies;

    for (final enemy in allEnemies) {
      // Skip non-targetable enemies (e.g., invulnerable bosses)
      if (!enemy.isTargetable) continue;

      final toEnemy = enemy.position - bulletSpawnPosition;
      final distance = toEnemy.length;

      // Skip enemies beyond range
      if (distance > beamMaxRange) continue;

      // Calculate if enemy is in beam path
      final dotProduct = toEnemy.normalized().dot(targetDirection.normalized());
      if (dotProduct > 0.98) {
        // Roughly 11 degrees cone
        hitEnemies.add(enemy);
      }
    }

    // Sort by distance and damage all
    hitEnemies.sort((a, b) {
      final distA = (a.position - bulletSpawnPosition).length;
      final distB = (b.position - bulletSpawnPosition).length;
      return distA.compareTo(distB);
    });

    // Deal damage to all enemies in beam
    for (final enemy in hitEnemies) {
      // Apply critical hit chance
      final isCrit = Random().nextDouble() < player.critChance;
      final actualDamage = isCrit ? damage * player.critDamage : damage;

      enemy.takeDamage(actualDamage, isCrit: isCrit);

      // Apply lifesteal
      if (player.lifesteal > 0 && actualDamage > 0) {
        final healAmount = actualDamage * player.lifesteal;
        player.health = (player.health + healAmount).clamp(0, player.maxHealth);
      }
    }

    // Create visual beam effect
    final beamEndPosition = hitEnemies.isNotEmpty
        ? hitEnemies.last.position
        : bulletSpawnPosition + (targetDirection.normalized() * beamMaxRange);

    final beam = BeamEffect(
      startPosition: bulletSpawnPosition,
      endPosition: beamEndPosition,
      beamColor: const Color(0xFFFF0000), // Red laser beam
      beamWidth: 3.0,
    );
    gameRef.world.add(beam);
  }

  Vector2 _getBulletSpawnPosition(PlayerShip player) {
    final spawnDistance = player.size.y / 2;
    final angleRad = player.angle;
    final direction = Vector2(sin(angleRad), -cos(angleRad));
    return player.position + direction * spawnDistance;
  }

  /// Register this weapon with the factory and config
  static void init() {
    WeaponFactory.register(ID, () => LaserBeam());

    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 20,
      displayName: 'Laser Beam',
      description: 'Continuous damage beam',
      icon: '🔴',
    );
  }
}
