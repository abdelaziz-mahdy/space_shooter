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

  // XP Collection
  static const double waveEndCollectionSpeed = 800; // Units per second for wave-end XP pull
  static const double normalAttractionSpeed = 200; // Units per second for normal magnet attraction

  // XP Orb Sizes (base sizes - scaled by screen in implementation)
  static const double xpOrbSize1 = 10.0;   // Tiny (1 XP cyan)
  static const double xpOrbSize5 = 12.0;   // Small (5 XP green)
  static const double xpOrbSize10 = 14.0;  // Medium (10 XP yellow)
  static const double xpOrbSize25 = 16.0;  // Large (25 XP orange)
  static const double xpOrbSize50 = 20.0;  // Very large (50 XP pink)
  static const double xpOrbSize100 = 22.0; // Huge (100 XP red)
  static const double xpOrbSize250 = 24.0; // Mega (250 XP purple)
}
