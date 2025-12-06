import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/chain_lightning_effect.dart';
import '../components/player_ship.dart';
import '../components/enemies/base_enemy.dart';
import '../game/space_shooter_game.dart';
import '../factories/weapon_factory.dart';
import '../config/weapon_unlock_config.dart';
import '../utils/position_util.dart';
import 'weapon.dart';

/// Tesla Coil - automatic chain lightning weapon
class TeslaCoil extends Weapon {
  static const String ID = 'tesla_coil';

  TeslaCoil()
      : super(
          id: ID,
          name: 'Tesla Coil',
          description: 'Chain lightning that arcs between enemies',
          damageMultiplier: 1.2, // Moderate base damage
          fireRateMultiplier: 1.2, // Slightly slower fire rate
          projectileSpeedMultiplier: 1.0, // Not used for instant lightning
        );

  @override
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  ) {
    final gameRef = (player.parent?.parent as SpaceShooterGame?);
    if (gameRef == null) return;

    // Start from the nearest enemy within range
    if (targetEnemy == null || targetEnemy is! BaseEnemy) return;

    final damage = getDamage(player);
    const chainRange = 200.0; // Range for chain jumps
    const maxChains = 5; // Maximum number of chain jumps

    // Track hit enemies to avoid hitting the same enemy twice
    final hitEnemies = <BaseEnemy>{targetEnemy as BaseEnemy};
    final chainPath = <Vector2>[player.position, targetEnemy.position];

    // Apply damage to first target
    final isCrit = Random().nextDouble() < player.critChance;
    final actualDamage = isCrit ? damage * player.critDamage : damage;
    targetEnemy.takeDamage(actualDamage, isCrit: isCrit);

    // Apply lifesteal
    if (player.lifesteal > 0 && actualDamage > 0) {
      final healAmount = actualDamage * player.lifesteal;
      player.health = (player.health + healAmount).clamp(0, player.maxHealth);
    }

    // Chain to nearby enemies
    BaseEnemy? currentTarget = targetEnemy;
    for (int i = 0; i < maxChains; i++) {
      if (currentTarget == null) break;

      // Find nearest enemy to current target that hasn't been hit yet
      BaseEnemy? nextTarget;
      double nearestDistance = double.infinity;

      // Use cached active enemies list instead of querying world children
      for (final enemy in gameRef.activeEnemies) {
        if (hitEnemies.contains(enemy)) continue;

        final distance = PositionUtil.getDistance(currentTarget, enemy);
        if (distance <= chainRange && distance < nearestDistance) {
          nearestDistance = distance;
          nextTarget = enemy;
        }
      }

      if (nextTarget != null) {
        // Add to hit set and chain path
        hitEnemies.add(nextTarget);
        chainPath.add(nextTarget.position.clone());

        // Damage decreases with each chain (90% of previous)
        final chainDamage = actualDamage * pow(0.9, i + 1);
        nextTarget.takeDamage(chainDamage, isCrit: false);

        // Apply lifesteal
        if (player.lifesteal > 0 && chainDamage > 0) {
          final healAmount = chainDamage * player.lifesteal;
          player.health = (player.health + healAmount).clamp(0, player.maxHealth);
        }

        currentTarget = nextTarget;
      } else {
        break; // No more enemies in range
      }
    }

    // Create visual chain lightning effect
    if (chainPath.length >= 2) {
      final lightning = ChainLightningEffect(
        path: chainPath,
        lightningColor: const Color(0xFF00FFFF), // Cyan lightning
      );
      gameRef.world.add(lightning);
    }
  }

  /// Register this weapon with the factory and config
  static void init() {
    WeaponFactory.register(ID, () => TeslaCoil());

    WeaponUnlockConfig.registerWeapon(
      ID,
      unlockLevel: 30,
      displayName: 'Tesla Coil',
      description: 'Auto-chaining lightning weapon',
      icon: '⚡',
    );
  }
}
