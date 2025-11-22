# Weapon System Quick Reference

## Weapon Stats Comparison

| Weapon | Damage | Fire Rate | Speed | Special Features |
|--------|--------|-----------|-------|------------------|
| Pulse Cannon | 1.0x | 1.0x | 1.0x | Balanced, multi-shot compatible |
| Plasma Spreader | 0.6x | 1.0x | 1.0x | 3+ projectiles, wide spread (0.4 rad) |
| Railgun | 2.5x | 3.0x (slow) | Instant | Infinite pierce, instant hit |
| Missile Launcher | 1.5x | 1.43x (slow) | 0.6x | Homing, 40px AOE, 80% explosion damage |

## Unlock Levels

```
Level 1: Pulse Cannon (Default)
Level 3: Plasma Spreader OR Railgun (Choice)
Level 5: The other weapon from Level 3
Level 8: Missile Launcher
```

## How to Add a New Weapon

1. **Create weapon file** in `/lib/weapons/your_weapon.dart`
```dart
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../components/bullet.dart';
import '../components/player_ship.dart';
import 'weapon.dart';
import 'weapon_type.dart';

class YourWeapon extends Weapon {
  YourWeapon()
      : super(
          type: WeaponType.yourWeapon,
          name: 'Your Weapon',
          description: 'Description here',
          damageMultiplier: 1.0,
          fireRateMultiplier: 1.0,
          projectileSpeedMultiplier: 1.0,
        );

  @override
  void fire(
    PlayerShip player,
    Vector2 targetDirection,
    PositionComponent? targetEnemy,
  ) {
    // Implement firing logic
  }
}
```

2. **Add to WeaponType enum** in `/lib/weapons/weapon_type.dart`
```dart
enum WeaponType {
  // ... existing weapons
  yourWeapon,
}

// Add to extension methods
case WeaponType.yourWeapon:
  return 'Your Weapon Name';
```

3. **Register in WeaponManager** in `/lib/weapons/weapon_manager.dart`
```dart
import 'your_weapon.dart';

// In constructor:
weaponInstances[WeaponType.yourWeapon] = YourWeapon();
```

4. **Add unlock logic** in `/lib/managers/level_manager.dart`
```dart
if (currentLevel == X) {
  if (!unlockedWeapons.contains(WeaponType.yourWeapon)) {
    return [WeaponUnlockUpgrade(weaponType: WeaponType.yourWeapon)];
  }
}
```

## Useful Helper Methods

### Get Bullet Spawn Position
```dart
Vector2 _getBulletSpawnPosition(PlayerShip player) {
  final tipLocalOffset = Vector2(0, -player.size.y / 2);
  final cosA = cos(player.angle);
  final sinA = sin(player.angle);
  final rotatedTipX = tipLocalOffset.x * cosA - tipLocalOffset.y * sinA;
  final rotatedTipY = tipLocalOffset.x * sinA + tipLocalOffset.y * cosA;
  return player.position + Vector2(rotatedTipX, rotatedTipY);
}
```

### Spawn Multiple Projectiles with Spread
```dart
final angleSpread = 0.2; // Adjust for tighter/wider spread
final baseAngle = atan2(targetDirection.y, targetDirection.x);

for (int i = 0; i < count; i++) {
  final offset = (i - (count - 1) / 2) * angleSpread;
  final bulletAngle = baseAngle + offset;
  final bulletDirection = Vector2(cos(bulletAngle), sin(bulletAngle));

  // Create bullet with bulletDirection
}
```

### Get Player Stats with Multipliers
```dart
final damage = getDamage(player);           // player.damage * damageMultiplier
final speed = getProjectileSpeed(player);   // player.bulletSpeed * speedMultiplier
final fireRate = getFireRate(player);       // player.shootInterval * fireRateMultiplier
```

## Weapon-Specific Components

### Creating a Bullet
```dart
final bullet = Bullet(
  position: bulletSpawnPosition.clone(),
  direction: direction.normalized(),
  damage: getDamage(player),
  speed: getProjectileSpeed(player),
  color: const Color(0xFFFFFF00), // Yellow
  bulletType: BulletType.standard,
  pierceCount: player.bulletPierce,
  customSize: Vector2.all(player.bulletSize),
);
player.gameRef.world.add(bullet);
```

### Creating a Beam Effect
```dart
final beam = BeamEffect(
  startPosition: startPos,
  endPosition: endPos,
  beamColor: const Color(0xFF00FFFF),
  beamWidth: 6.0,
);
player.gameRef.world.add(beam);
```

### Creating a Missile
```dart
final missile = Missile(
  position: spawnPos.clone(),
  direction: direction.normalized(),
  damage: getDamage(player),
  speed: getProjectileSpeed(player),
  explosionRadius: 40.0,
  explosionDamage: 0.8, // 80% of direct damage
);
player.gameRef.world.add(missile);
```

## Testing Your Weapon

1. **Quick test:** Modify `WeaponManager` constructor to unlock your weapon:
```dart
unlockedWeapons.add(WeaponType.yourWeapon);
currentWeapon = weaponInstances[WeaponType.yourWeapon]!;
```

2. **Run the game** and verify:
   - Weapon fires correctly
   - Visual effects appear
   - Damage is applied
   - Fire rate feels right
   - Integrates with player upgrades

3. **Revert changes** and add proper unlock level

## Common Issues

### Weapon Not Firing
- Check `canFire()` returns true
- Verify cooldown is being reset
- Ensure weapon is added to WeaponManager instances

### Projectiles Not Spawning
- Verify game reference: `player.gameRef.world.add(projectile)`
- Check spawn position calculation
- Ensure direction is normalized

### Stats Not Scaling
- Use `getDamage(player)`, `getProjectileSpeed(player)`, etc.
- Don't use `player.damage` directly
- Verify multipliers are set in constructor

### Weapon Not Unlocking
- Check level unlock logic in LevelManager
- Verify WeaponUnlockUpgrade is in upgrade pool
- Ensure weapon type is registered

## Color Reference

Common projectile colors:
- Yellow: `0xFFFFFF00` (Pulse Cannon)
- Cyan: `0xFF00FFFF` (Plasma Spreader, Railgun)
- Red: `0xFFFF0000` (Missiles, danger)
- Orange: `0xFFFF4500` (Missile body)
- Green: `0xFF00FF00` (Healing, positive)
- Purple: `0xFF9400D3` (Special effects)
- White: `0xFFFFFFFF` (Core beams, highlights)

## Performance Tips

1. **Reuse components** when possible (weapon instances)
2. **Limit projectile lifetime** (3-5 seconds max)
3. **Use instant-hit** for beam weapons (no projectile spam)
4. **Batch spawning** if creating many projectiles
5. **Clean up effects** quickly (beam effects: 150ms)

## Architecture Notes

- Weapons are **stateless** (state goes in WeaponManager)
- Weapons **don't extend Component** (they're data + logic)
- **WeaponManager** is the Component that updates
- Projectiles **are Components** that get added to world
- Effects **are Components** with short lifetimes
