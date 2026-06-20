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
  // When multiple impacts happen in the same place AND within a tiny time window
  // (e.g., a multi-shot burst landing together), merge effects into one instead
  // of stacking duplicates at the wrong spot.
  static const double effectMergeRadius = 100.0; // Merge only nearby effects (was 350 - too wide, merged distant hits)
  static const double effectMergeTimeWindow = 0.02; // Only merge effects created < 20ms apart (same burst)

  // Wave Scaling
  static const double bleedDamageWaveMultiplier = 0.3; // Bleed damage increases 0.3x per wave after wave 1
}
