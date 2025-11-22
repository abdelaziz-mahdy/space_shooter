# Weapon Progression Diagram

## Level-Based Unlock Flow

```
START GAME
    |
    v
┌─────────────────────────────────────┐
│  LEVEL 1 - Starting Weapon          │
│  🔫 PULSE CANNON (Auto-unlocked)    │
│                                     │
│  Stats: 1.0x dmg, 1.0x rate, 1.0x   │
│  Features: Balanced, reliable       │
│  Color: Yellow                      │
└─────────────────────────────────────┘
    |
    | Level up → Kill enemies, collect XP
    v
┌─────────────────────────────────────┐
│  LEVEL 3 - First Choice             │
│  ⚠️  IMPORTANT DECISION              │
│                                     │
│  Choose ONE:                        │
│  ┌────────────────────────────────┐│
│  │ Option A: 💠 PLASMA SPREADER  ││
│  │ - Wide spread (3+ projectiles)││
│  │ - 0.6x damage per shot        ││
│  │ - Cyan color                  ││
│  │ - Best for: Crowd control     ││
│  └────────────────────────────────┘│
│         OR                          │
│  ┌────────────────────────────────┐│
│  │ Option B: ⚡ RAILGUN           ││
│  │ - Instant piercing beam       ││
│  │ - 2.5x damage                 ││
│  │ - Infinite pierce             ││
│  │ - Best for: Single target     ││
│  └────────────────────────────────┘│
└─────────────────────────────────────┘
    |
    | Level up → Continue progression
    v
┌─────────────────────────────────────┐
│  LEVEL 5 - Guaranteed Unlock        │
│  ✅ Get the weapon you DIDN'T pick  │
│                                     │
│  If Level 3 = Plasma Spreader       │
│    → Unlock: ⚡ Railgun             │
│                                     │
│  If Level 3 = Railgun               │
│    → Unlock: 💠 Plasma Spreader     │
└─────────────────────────────────────┘
    |
    | Level up → Final weapon unlock
    v
┌─────────────────────────────────────┐
│  LEVEL 8 - Ultimate Weapon          │
│  🚀 MISSILE LAUNCHER                │
│                                     │
│  Stats: 1.5x dmg + 0.8x explosion   │
│  Features: Homing, AOE damage       │
│  Color: Red/Orange                  │
│  Explosion Radius: 40px             │
└─────────────────────────────────────┘
    |
    v
ALL 4 WEAPONS UNLOCKED! 🎉
```

## Weapon Comparison Chart

```
┌────────────────┬──────────┬───────────┬─────────┬──────────────────────────┐
│ Weapon         │ Damage   │ Fire Rate │ Speed   │ Special                  │
├────────────────┼──────────┼───────────┼─────────┼──────────────────────────┤
│ Pulse Cannon   │ ⭐⭐⭐    │ ⭐⭐⭐     │ ⭐⭐⭐   │ Balanced, Multi-shot     │
│ 🔫             │ 1.0x     │ 1.0x      │ 1.0x    │ compatible               │
├────────────────┼──────────┼───────────┼─────────┼──────────────────────────┤
│ Plasma         │ ⭐⭐      │ ⭐⭐⭐     │ ⭐⭐⭐   │ 3+ wide spread           │
│ Spreader 💠    │ 0.6x     │ 1.0x      │ 1.0x    │ Crowd control            │
├────────────────┼──────────┼───────────┼─────────┼──────────────────────────┤
│ Railgun        │ ⭐⭐⭐⭐⭐ │ ⭐         │ Instant │ Infinite pierce          │
│ ⚡             │ 2.5x     │ 3.0x slow │ N/A     │ Line damage              │
├────────────────┼──────────┼───────────┼─────────┼──────────────────────────┤
│ Missile        │ ⭐⭐⭐⭐   │ ⭐⭐       │ ⭐⭐     │ Homing + Explosion       │
│ Launcher 🚀    │ 1.5x     │ 1.43x     │ 0.6x    │ 40px AOE, 0.8x AoE dmg   │
└────────────────┴──────────┴───────────┴─────────┴──────────────────────────┘
```

## Visual Guide

### Pulse Cannon (Default)
```
Player → ●═══════→ Enemy
         (Yellow shot)
```

### Plasma Spreader
```
             ╱ ●═══════→ Enemy
Player → ●═══●═══════→ Enemy
             ╲ ●═══════→ Enemy
         (3 Cyan shots, wide spread)
```

### Railgun
```
Player → ━━━━━━━━━━━━━━━━━━━━━━━━━→ Enemies
         (Instant beam, hits ALL)

         Enemy 1 ●━━━━┐
         Enemy 2 ●━━━━┤ All hit!
         Enemy 3 ●━━━━┘
```

### Missile Launcher
```
Player → 🚀~~~~~~~> Enemy 1
         🚀~~~~╱
              ╱  (Homing)
         🚀~~╱
            ╲
             ╲~~~~~> Enemy 2

On Impact:   💥 ← Explosion damages nearby enemies
           ╱ │ ╲
        ●    ●    ● (All take damage)
```

## Strategic Considerations

### Level 3 Choice Strategy

**Choose Plasma Spreader if:**
- You're facing many weak enemies
- You prefer consistent crowd control
- You want to clear waves quickly
- You enjoy spray-and-pray gameplay

**Choose Railgun if:**
- You want maximum single-target damage
- You prefer precision over volume
- You face tanky enemies
- You like high-risk, high-reward gameplay

### Weapon Synergies with Upgrades

```
PULSE CANNON + Multi-Shot = Excellent spray pattern
PULSE CANNON + Pierce = Penetrating shots
PULSE CANNON + Fire Rate = Machine gun mode

PLASMA SPREADER + Multi-Shot = Screen-filling projectiles
PLASMA SPREADER + Damage = Compensates for low per-shot damage
PLASMA SPREADER + Bullet Speed = Faster spreading death

RAILGUN + Damage = One-shot kill potential
RAILGUN + Fire Rate = More frequent beam attacks
RAILGUN + (Pierce = No effect, already infinite)

MISSILE LAUNCHER + Multi-Shot = Multiple homing missiles
MISSILE LAUNCHER + Damage = Devastating explosions
MISSILE LAUNCHER + Bullet Speed = Faster missile tracking
```

## Upgrade Priority Recommendations

### Early Game (Levels 1-3)
1. Damage - Increases all weapon effectiveness
2. Fire Rate - More shots = more damage
3. Multi-Shot - Works great with Pulse Cannon

### Mid Game (Levels 4-7)
1. Damage - Keep scaling
2. Pierce - Works with Pulse Cannon & Plasma Spreader
3. Critical Chance - Multiplies your damage

### Late Game (Level 8+)
1. Damage - Never stop scaling
2. Fire Rate - Maximize DPS
3. Crit Damage - Huge damage spikes

## HUD Reference

The weapon display appears at **bottom center** of the screen:

```
┌────────────────────────────────────────────────┐
│                 Wave 5                         │
│  [==================] HP                       │
│                                                │
│         [Your ship is here]                    │
│                                                │
│                                                │
│            🔫 Pulse Cannon                     │  ← Current Weapon
└────────────────────────────────────────────────┘
```

## Tips

1. **Experiment:** Each weapon plays differently
2. **Adapt:** Switch strategies based on enemy types
3. **Synergize:** Build your upgrades around your weapon choice
4. **Have Fun:** There's no "wrong" choice at Level 3

Remember: You'll eventually unlock ALL weapons, so your Level 3 choice just determines what you get first!
