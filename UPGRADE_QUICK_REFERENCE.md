# Upgrade System Quick Reference

## How Each Mechanic Works

### ⚔️ Critical Hits
- **When**: Calculated when bullet is created
- **Chance**: `Random().nextDouble() < player.critChance`
- **Damage**: `baseDamage * player.critDamage` (default 2x)
- **Visual**: Orange-red bullet, 1.5x size, glow effect
- **Upgrades**: Critical Strikes (+10% chance), Devastating Crits (+50% damage), Critical Cascade (+10% chance, +3 chain)

### 🔱 Pierce
- **When**: Bullet collides with enemy
- **Logic**: Bullet tracks `enemiesHit` counter
- **Removal**: Only when `enemiesHit > pierceCount`
- **Upgrades**: Piercing Shots (+1 pierce per upgrade)

### 💥 Explosion
- **When**: Bullet hits any enemy
- **Trigger**: If `player.explosionRadius > 0`
- **Damage**: 50% of bullet's actualDamage to nearby enemies
- **Range**: All enemies within `explosionRadius` pixels
- **Visual**: Expanding orange circle (0.3s duration)
- **Upgrades**: Explosive Rounds (+30 radius), Omega Cannon (+100 radius)

### ❄️ Freeze
- **When**: Bullet hits enemy
- **Chance**: `Random().nextDouble() < player.freezeChance`
- **Effect**: Enemy speed reduced to 30% for 2 seconds
- **Visual**: Blue overlay and border on frozen enemies
- **Upgrades**: Frost Rounds (+15% freeze chance)

### 🩸 Lifesteal
- **When**: Bullet damages enemy
- **Healing**: `actualDamage * player.lifesteal`
- **Cap**: Cannot exceed `player.maxHealth`
- **Upgrades**: Lifesteal (+10% per upgrade), Vampiric Aura (+20% + magnet)

### 🛡️ Shield Layers
- **Rendering**: Glowing cyan circles around player
- **Protection**: Each layer blocks ONE hit completely
- **Regeneration**: Timer-based (15s default with Resilient Shields)
- **Visual**: Semi-transparent cyan with glow
- **Upgrades**: Energy Shield (+1 layer), Resilient Shields (+1 layer + regen)

### 💚 Health Regeneration
- **When**: Every frame in update()
- **Rate**: `health += healthRegen * dt` per second
- **Cap**: Cannot exceed `maxHealth`
- **Upgrades**: Health Regen (+2 HP/sec per upgrade)

### 💨 Dodge
- **When**: Before damage calculation
- **Chance**: `Random().nextDouble() < player.dodgeChance`
- **Effect**: Completely avoid damage (no hit taken)
- **Upgrades**: Evasion (+10% dodge chance)

### 🔥 Phoenix Rebirth
- **When**: Health reaches 0
- **Chance**: 25% (from Phoenix Rebirth upgrade)
- **Effect**: Restore to 25% max health
- **Limitation**: Only works ONCE per game (`hasResurrected` flag)

## Upgrade Tier Guide

### Common (60% chance)
| Icon | Name | Effect |
|------|------|--------|
| ⚔️ | Increased Damage | +5 Damage |
| ⚡ | Faster Fire Rate | -0.1s shoot interval |
| 🎯 | Longer Range | +50 targeting range |
| 🔫 | Multi Shot | +1 projectile |
| 💨 | Bullet Speed | +100 bullet speed |
| 🏃 | Move Speed | +50 move speed |
| ❤️ | Max Health | +20 max HP |
| 🧲 | Magnet | +100 attraction radius |
| 💚 | Health Regen | +2 HP/sec |
| 🔱 | Piercing Shots | +1 pierce |
| 💥 | Critical Strikes | +10% crit chance |
| 💢 | Devastating Crits | +50% crit damage |
| 🩸 | Lifesteal | +10% lifesteal |
| 📈 | XP Boost | +25% XP gain |
| 🛡️ | Armor Plating | -10% damage taken |
| 💨 | Evasion | +10% dodge |
| 💣 | Explosive Rounds | +30 explosion radius |
| 🎯 | Homing Missiles | +50 homing strength |
| ❄️ | Frost Rounds | +15% freeze chance |
| ⭕ | Larger Projectiles | +2 bullet size |
| 🛸 | Orbital Drone | +1 orbital shooter |
| 🔵 | Energy Shield | +1 shield layer |
| 🍀 | Fortune | +20% better drops |
| 🛡️ | Resilient Shields | Shield regen every 15s |
| 🎯 | Focused Fire | +15% damage, -1 projectile |
| ⏱️ | Rapid Reload | 10% cooldown reduction |

### Rare (25% chance)
| Icon | Name | Effect |
|------|------|--------|
| 😡 | Berserker Rage | +50% damage when <30% HP |
| 🌵 | Thorns Armor | Reflect 20% damage |
| ⚡ | Chain Lightning | Bullets chain to 2 enemies |
| 🩸 | Bleeding Edge | 5 DPS bleed for 3s |
| 🍀 | Fortune's Favor | 15% double shot chance |

### Epic (12% chance)
| Icon | Name | Effect |
|------|------|--------|
| 🦇 | Vampiric Aura | Heal from nearby kills |
| ⏰ | Time Dilation | Slow time every 5 kills |
| 🌪️ | Bullet Storm | +3 projectiles, +30% fire rate |
| 🔥 | Phoenix Rebirth | 25% resurrect chance |

### Legendary (3% chance)
| Icon | Name | Effect | Build Type |
|------|------|--------|------------|
| 💀 | Omega Cannon | Massive projectiles + AOE | Explosion Build |
| 🌌 | Infinity Orbitals | +5 orbital shooters | Orbital Build |
| ✨ | Perfect Harmony | +10% to ALL stats | Balanced Build |
| 💔 | Glass Cannon | +100% damage, -50% HP | High Risk Build |
| 🗿 | Immovable Object | +200% HP, +50% armor, -30% speed | Tank Build |
| 💫 | Critical Cascade | Crits chain to 3 enemies | Crit Build |

## Build Archetypes

### 🔴 Glass Cannon Build
- **Core**: Glass Cannon, Berserker Rage, Focused Fire
- **Support**: Critical Strikes, Devastating Crits, Increased Damage
- **Playstyle**: High damage, low survivability, risky but powerful

### 🟢 Tank Build
- **Core**: Immovable Object, Resilient Shields, Armor Plating
- **Support**: Max Health, Health Regen, Thorns Armor
- **Playstyle**: Survive everything, slower movement, steady damage

### 🔵 Crit Build
- **Core**: Critical Cascade, Devastating Crits, Critical Strikes
- **Support**: Fortune's Favor (double shot), Focused Fire
- **Playstyle**: Burst damage, chain reactions, RNG dependent

### 🟡 Explosion Build
- **Core**: Omega Cannon, Explosive Rounds, Bullet Size
- **Support**: Increased Damage, Multi Shot
- **Playstyle**: AOE damage, crowd control, visual chaos

### 🟣 Lifesteal/Vampire Build
- **Core**: Vampiric Aura, Lifesteal, Phoenix Rebirth
- **Support**: Increased Damage, Multi Shot, Armor
- **Playstyle**: Self-sustaining, aggressive, hard to kill

### ⚪ Bullet Storm Build
- **Core**: Bullet Storm, Multi Shot, Faster Fire Rate
- **Support**: Piercing Shots, Chain Lightning
- **Playstyle**: Screen-filling bullets, sustained DPS

### 🟠 Orbital Build
- **Core**: Infinity Orbitals, Orbital Drone
- **Support**: Perfect Harmony, XP Boost
- **Playstyle**: Passive damage, focus on positioning

## Synergies

### 💪 Powerful Combinations
- **Crit + Explosion**: Critical hits trigger bigger explosions
- **Pierce + Multi-Shot**: Bullets pass through entire waves
- **Lifesteal + Glass Cannon**: Offset low HP with healing
- **Freeze + Bullet Storm**: Slow enemies, overwhelm with bullets
- **Berserker + Phoenix Rebirth**: Stay low HP safely

### ⚠️ Anti-Synergies
- **Glass Cannon + Immovable Object**: Contradictory HP modifiers
- **Focused Fire + Multi-Shot**: Working against each other
- **Move Speed + Tank Build**: Tank wants to be slow anyway

## Parameter Reference

### Bullet Constructor Changes
```dart
// OLD
Bullet(
  damage: player.damage,
  color: const Color(0xFFFFFF00),
)

// NEW
Bullet(
  baseDamage: player.damage,  // ← Changed
  baseColor: const Color(0xFFFFFF00),  // ← Changed
)
```

### Enemy Speed Usage
```dart
// OLD
position += direction * speed * dt;

// NEW
position += direction * getEffectiveSpeed() * dt;  // ← Accounts for freeze
```

## Testing Checklist

- [ ] Crit bullets are orange and larger
- [ ] Pierce bullets pass through multiple enemies
- [ ] Explosions damage nearby enemies
- [ ] Frozen enemies have blue overlay and move slowly
- [ ] Shields render as cyan circles
- [ ] Health bar increases with regen
- [ ] Lifesteal heals on hit
- [ ] Dodge occasionally avoids damage
- [ ] Phoenix Rebirth resurrects once
- [ ] Legendary upgrades are rare
- [ ] Weapon unlocks still work at levels 5, 10, 15

## Debug Tips

### View Player Stats
Add to debug overlay:
```dart
'Crit Chance: ${player.critChance.toStringAsFixed(2)}'
'Pierce: ${player.bulletPierce}'
'Shields: ${player.shieldLayers}'
'Freeze: ${player.freezeChance.toStringAsFixed(2)}'
```

### Test Specific Upgrade
```dart
// In level_manager.dart
return [
  CriticalCascadeUpgrade(),
  OmegaCannonUpgrade(),
  PhoenixRebirthUpgrade(),
];
```

### Force Legendary Drops
```dart
// In upgrade_factory.dart, getRandomUpgradesByRarity()
targetRarity = UpgradeRarity.legendary; // Always legendary
```

---

**Quick Tip**: Press the upgrade button 3 times per level to maximize build potential!
