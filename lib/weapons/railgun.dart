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

/// Railgun - instant piercing beam that hits all enemies in line
class Railgun extends Weapon {
  static const String ID = 'railgun';

  Railgun()
      : super(
          id: ID,
          name: 'Railgun',
          description: 'Piercing beam weapon that hits all enemies in line',
          damageMultiplier: 4.0, // High damage to compensate for slow fire rate
          fireRateMultiplier: 2.5, // Slower fire rate but not as extreme
          projectileSpeedMultiplier: 1.0, // Not used for instant beam
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

    // Calculate beam end position (max range or screen edge)
    final maxRange = 1000.0;
    final beamEnd = bulletSpawnPosition + (targetDirection.normalized() * maxRange);

    // Scale beam width based on damage (visual feedback for power)
    final baseDamage = getDamage(player);
    final beamWidth = (4.0 + (baseDamage / 20.0)).clamp(4.0, 12.0);

    // Create visual beam effect
    final beam = BeamEffect(
      startPosition: bulletSpawnPosition,
      endPosition: beamEnd,
      beamColor: const Color(0xFF00FFFF), // Cyan/white beam
      beamWidth: beamWidth,
    );
    game.world.add(beam);

    // Instant hit - find all enemies in the beam's path
    _hitEnemiesInLine(game, bulletSpawnPosition, targetDirection, maxRange, player);
  }

  void _hitEnemiesInLine(
    SpaceShooterGame game,
    Vector2 start,
    Vector2 direction,
    double maxRange,
    PlayerShip player,
  ) {
    final directionNormalized = direction.normalized();
    final damage = getDamage(player);
    // Beam radius scales with damage
    final beamHitRadius = (2.0 + (damage / 20.0)).clamp(2.0, 8.0);

    // Calculate crit
    final isCrit = Random().nextDouble() < player.critChance;
    final actualDamage = isCrit ? damage * player.critDamage : damage;

    // Get all enemies
    final allEnemies = game.world.children.whereType<BaseEnemy>();

    // Check each enemy if it's in the beam's path
    for (final enemy in allEnemies) {
      if (_isEnemyInBeamPath(start, directionNormalized, maxRange, enemy, beamHitRadius)) {
        // Apply damage to enemy (damage number shown automatically by base_enemy)
        enemy.takeDamage(actualDamage, isCrit: isCrit);

        // Play hit sound
        game.audioManager.playHit();

        // Apply lifesteal
        if (player.lifesteal > 0) {
          final healAmount = actualDamage * player.lifesteal;
          player.health = min(player.health + healAmount, player.maxHealth);
        }
      }
    }
  }

  bool _isEnemyInBeamPath(
    Vector2 start,
    Vector2 direction,
    double maxRange,
    PositionComponent enemy,
    double beamRadius,
  ) {
    // Get enemy position
    final enemyPos = enemy.position;

    // Vector from beam start to enemy
    final toEnemy = enemyPos - start;

    // Project enemy position onto beam direction
    final projectionLength = toEnemy.dot(direction);

    // Check if enemy is within beam range
    if (projectionLength < 0 || projectionLength > maxRange) {
      return false;
    }

    // Calculate closest point on beam to enemy
    final closestPoint = start + (direction * projectionLength);

    // Calculate distance from enemy to beam line
    final distanceToBeam = enemyPos.distanceTo(closestPoint);

    // Enemy hitbox radius (approximate)
    final enemyRadius = enemy.size.length / 2;

    // Check if enemy is close enough to beam (beamRadius passed in)
    return distanceToBeam <= (enemyRadius + beamRadius);
  }

  Vector2 _getBulletSpawnPosition(PlayerShip player) {
    // Spawn beam from the triangle's tip (accounting for rotation)
    final tipLocalOffset = Vector2(0, -player.size.y / 2);
    final cosA = cos(player.angle);
    final sinA = sin(player.angle);
    final rotatedTipX = tipLocalOffset.x * cosA - tipLocalOffset.y * sinA;
    final rotatedTipY = tipLocalOffset.x * sinA + tipLocalOffset.y * cosA;
    return player.position + Vector2(rotatedTipX, rotatedTipY);
  }

  // Factory registration methods
  static void registerFactory() {
    WeaponFactory.register(ID, () => Railgun());
  }

  static void init() {
    registerFactory();
    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 10,
      displayName: 'Railgun',
      description: 'Piercing beam weapon',
      icon: '⚡',
    );
  }
}
