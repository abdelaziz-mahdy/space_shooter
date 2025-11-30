/// Global balance configuration for easy tuning
class BalanceConfig {
  // Projectile System
  static const int maxProjectileCount = 5;

  // Damage Reduction
  static const double maxDamageReduction = 0.60; // 60% cap

  // Damage Numbers (Performance)
  static const double damageNumberCooldown = 0.05; // Show every 50ms (20/sec)

  // Crit System
  static const double maxCritChance = 0.75; // 75% cap
  static const double maxCritDamage = 5.0; // 5x cap

  // Orbital Drones
  static const int maxOrbitalDrones = 10;
}
