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
  static const double waveEndCollectionSpeed = 800; // Speed for wave-end XP pull
  static const double normalAttractionSpeed = 200; // Normal magnet speed

  // Loot Merging (Performance)
  static const double lootMergeRadius = 60.0; // Drops merge if another loot is within this range

  // Effect Pooling (Performance) - Merge overlapping visual effects
  // When multiple impacts happen in same location (e.g., 10 rockets at once),
  // merge effects instead of creating duplicates
  static const double effectMergeRadius = 350.0; // Merge visual effects within this radius
}
