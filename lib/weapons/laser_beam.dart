import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/beam_effect.dart';
import '../components/player_ship.dart';
import '../game/space_shooter_game.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import '../utils/targeting_system.dart';
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
    final game = (player.parent?.parent as SpaceShooterGame?);
    if (game == null) return;

    final bulletSpawnPosition = _getBulletSpawnPosition(player);
    final damage = getDamage(player);

    // Shorter beam range than railgun
    const beamMaxRange = 350.0;
    const coneAngle = 0.02; // ~11 degree cone (dotProduct 0.98 ≈ cos(11°) ≈ 0.98)

    // Use centralized targeting system to find all enemies in cone
    final hitEnemies = TargetingSystem.findEnemiesInCone(
      game: game,
      origin: bulletSpawnPosition,
      direction: targetDirection,
      maxRange: beamMaxRange,
      coneAngle: coneAngle,
      onlyTargetable: true,
    );

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
    game.world.add(beam);
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
