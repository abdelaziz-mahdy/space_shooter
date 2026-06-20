/// Global balance configuration for easy tuning
class BalanceConfig {
  // Projectile System
  static const int maxProjectileCount = 7; // Raised from 5 so multi-shot builds have late-game headroom

  // Damage Reduction
  static const double maxDamageReduction = 0.60; // 60% cap

  // Lifesteal (heal-on-hit) - capped to keep sustain in check
  static const double maxLifesteal = 0.15; // 15% of damage dealt, max

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
  // (e.g., a multi-shot burst or rocket salvo landing together), merge them into
  // one effect instead of stacking duplicates at a stale location.
  static const double effectMergeRadius = 120.0; // Merge only nearby effects (was 350 - merged distant hits)
  static const double effectMergeTimeWindow = 0.02; // Only merge effects created < 20ms apart (same burst)

  // Wave Scaling
  static const double bleedDamageWaveMultiplier = 0.3; // Bleed damage increases 0.3x per wave after wave 1
}
