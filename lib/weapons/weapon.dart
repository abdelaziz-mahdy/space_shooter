import 'package:flame/components.dart';
import '../components/player_ship.dart';

/// Abstract base class for all weapons
abstract class Weapon {
  final String id;
  final String name;
  final String description;

  // Multipliers that affect base weapon stats
  double damageMultiplier;
  double fireRateMultiplier;
  double projectileSpeedMultiplier;

  // Cooldown tracking
  double cooldownTimer = 0;

  Weapon({
    required this.id,
    required this.name,
    required this.description,
    this.damageMultiplier = 1.0,
    this.fireRateMultiplier = 1.0,
    this.projectileSpeedMultiplier = 1.0,
  });

  /// Fire the weapon
  /// [player] - The player ship firing the weapon
  /// [targetDirection] - Direction to fire (normalized vector)
  /// [targetEnemy] - Optional target for homing/tracking weapons
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  );

  /// Update weapon state (cooldowns, etc.)
  void update(double dt) {
    if (cooldownTimer > 0) {
      cooldownTimer -= dt;
    }
  }

  /// Check if weapon is ready to fire
  bool canFire() {
    return cooldownTimer <= 0;
  }

  /// Get the actual fire rate based on player stats and weapon multiplier
  double getFireRate(PlayerShip player) {
    return player.shootInterval * fireRateMultiplier;
  }

  /// Get the actual damage based on player stats and weapon multiplier
  double getDamage(PlayerShip player) {
    var damage = player.damage * damageMultiplier;

    // Check for berserk bonus (low health damage boost)
    final healthPercent = player.health / player.maxHealth;
    if (healthPercent < 0.3 && player.berserkMultiplier > 1.0) {
      damage *= player.berserkMultiplier;
    }

    return damage;
  }

  /// Get the actual projectile speed based on player stats and weapon multiplier
  double getProjectileSpeed(PlayerShip player) {
    return player.bulletSpeed * projectileSpeedMultiplier;
  }

  /// Reset cooldown after firing
  void resetCooldown(PlayerShip player) {
    cooldownTimer = getFireRate(player);
  }

  /// Get detailed description including multipliers
  String getDetailedDescription() {
    final parts = <String>[description];

    // Add damage multiplier info
    if (damageMultiplier != 1.0) {
      parts.add('${damageMultiplier}x damage');
    }

    // Add fire rate info
    if (fireRateMultiplier != 1.0) {
      final fireRatePct = (1.0 / fireRateMultiplier * 100).toStringAsFixed(0);
      parts.add('$fireRatePct% fire rate');
    }

    // Add speed info if different
    if (projectileSpeedMultiplier != 1.0) {
      parts.add('${projectileSpeedMultiplier}x speed');
    }

    return parts.join('\n');
  }
}
