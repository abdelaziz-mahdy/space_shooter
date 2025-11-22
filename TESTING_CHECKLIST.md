# Weapon System Testing Checklist

## Pre-Flight Checks ✅

- [x] Code compiles without errors
- [x] All weapon files created
- [x] All component files created
- [x] Upgrade system integrated
- [x] HUD updated
- [x] Documentation complete

## Basic Functionality Tests

### 1. Game Start
- [ ] Game launches successfully
- [ ] No console errors on startup
- [ ] Player ship spawns correctly
- [ ] HUD displays "🔫 Pulse Cannon" at bottom center
- [ ] Game is playable with keyboard/touch controls

### 2. Pulse Cannon (Default Weapon)
- [ ] Fires yellow projectiles
- [ ] Auto-targets nearest enemy
- [ ] Projectiles damage enemies
- [ ] Fire rate feels responsive (~0.5s)
- [ ] Projectiles despawn after 3 seconds

### 3. Level Progression
- [ ] XP bar fills as enemies are killed
- [ ] Level up occurs at correct XP threshold
- [ ] Level up shows upgrade selection
- [ ] Game pauses during upgrade selection

## Weapon Unlock Tests

### 4. Level 3 - First Weapon Choice
- [ ] Reaching Level 3 shows weapon unlock options
- [ ] Two weapons available: Plasma Spreader AND Railgun
- [ ] Each weapon shows correct icon (💠 and ⚡)
- [ ] Each weapon shows description
- [ ] Clicking weapon applies unlock
- [ ] Selected weapon becomes active immediately
- [ ] HUD updates to show new weapon
- [ ] Normal upgrades NOT shown at Level 3

### 5. Plasma Spreader Testing
**If selected at Level 3:**
- [ ] HUD shows "💠 Plasma Spreader"
- [ ] Fires 3 cyan projectiles
- [ ] Projectiles spread in wide pattern (~0.4 radians)
- [ ] Each projectile does reduced damage (~60%)
- [ ] Works with multi-shot upgrades (adds more projectiles)
- [ ] Projectiles use pierce upgrade correctly
- [ ] Effective against groups of enemies

### 6. Railgun Testing
**If selected at Level 3:**
- [ ] HUD shows "⚡ Railgun"
- [ ] Fires cyan/white beam instantly
- [ ] Beam appears for ~150ms
- [ ] Beam has glow effect (three layers)
- [ ] Hits ALL enemies in line of fire
- [ ] Damage is noticeably higher (~2.5x)
- [ ] Fire rate is slower (~1.5s between shots)
- [ ] Pierce works infinitely (doesn't stop at first enemy)

### 7. Level 5 - Second Weapon Unlock
- [ ] Reaching Level 5 shows weapon unlock
- [ ] Shows ONLY the weapon NOT picked at Level 3
- [ ] If Level 3 = Plasma → Level 5 = Railgun
- [ ] If Level 3 = Railgun → Level 5 = Plasma
- [ ] Unlocking automatically switches weapon
- [ ] HUD updates correctly
- [ ] Both weapons now available

### 8. Level 8 - Missile Launcher
- [ ] Reaching Level 8 shows Missile Launcher unlock
- [ ] HUD shows "🚀 Missile Launcher"
- [ ] Fires red/orange missiles
- [ ] Missiles have visible exhaust trail
- [ ] Missiles rotate to face direction of travel
- [ ] Missiles home towards nearest enemy
- [ ] Missiles explode on impact
- [ ] Explosion damages nearby enemies (~40px radius)
- [ ] Fire rate is slower (~0.7s)
- [ ] Missiles move slower than bullets

## Integration Tests

### 9. Upgrade Compatibility
- [ ] **Damage Upgrade**: Increases all weapon damage
- [ ] **Fire Rate Upgrade**: Decreases cooldown for all weapons
- [ ] **Multi-Shot Upgrade**:
  - Pulse Cannon: Fires more shots
  - Plasma Spreader: Fires even more projectiles
  - Railgun: (No effect - still one beam)
  - Missile Launcher: Fires multiple missiles
- [ ] **Pierce Upgrade**:
  - Pulse Cannon: Bullets pierce enemies
  - Plasma Spreader: Projectiles pierce
  - Railgun: (No effect - already infinite)
  - Missiles: (No effect - explode on first hit)
- [ ] **Bullet Speed**: Affects all projectiles except Railgun
- [ ] **Bullet Size**: Affects all projectiles except Railgun beam

### 10. Auto-Targeting
- [ ] All weapons target nearest enemy
- [ ] Player rotates to face target
- [ ] Weapons fire in correct direction
- [ ] Works with both EnemyShip and BaseEnemy types
- [ ] Stops firing when no enemies in range

### 11. Game State Management
- [ ] Weapons pause when game is paused
- [ ] Weapons resume correctly after unpause
- [ ] Weapon state persists through upgrade selection
- [ ] Game over doesn't cause weapon errors

### 12. UI/HUD
- [ ] Weapon name displays at bottom center
- [ ] Weapon icon shows correctly
- [ ] Display updates immediately on weapon switch
- [ ] Text is readable and visible
- [ ] No overlap with other HUD elements

## Edge Cases

### 13. Boundary Conditions
- [ ] Works correctly with 0 enemies (doesn't crash)
- [ ] Handles rapid weapon unlocking
- [ ] Missiles don't crash when target dies
- [ ] Railgun works with empty screen
- [ ] Weapons work at screen edges

### 14. Performance
- [ ] No lag when firing Plasma Spreader with multi-shot
- [ ] Railgun beam doesn't cause frame drops
- [ ] Multiple missiles don't slow game
- [ ] Beam effects clean up properly (no memory leak)
- [ ] Game runs smoothly with all weapons

### 15. Multiple Playthroughs
- [ ] Weapon unlocks reset on game restart
- [ ] Starting new game gives Pulse Cannon
- [ ] Level progression works correctly each time
- [ ] No state carryover between games

## Visual Quality

### 16. Aesthetics
- [ ] Pulse Cannon: Clean yellow circles
- [ ] Plasma Spreader: Distinct cyan color
- [ ] Railgun: Impressive beam effect with glow
- [ ] Missiles: Clear rocket shape with trail
- [ ] All projectiles clearly visible
- [ ] Colors don't clash with background/enemies

### 17. Feedback
- [ ] Clear visual indication of weapon firing
- [ ] Projectiles move at appropriate speeds
- [ ] Explosions are satisfying
- [ ] Beam feels powerful and instant

## Bug Checks

### 18. Common Issues
- [ ] No null pointer exceptions
- [ ] No weapon getting "stuck"
- [ ] Cooldowns reset properly
- [ ] No duplicate weapon unlocks
- [ ] Weapon switching is smooth
- [ ] No projectiles spawning at (0,0)

### 19. Console Output
- [ ] No error messages in console
- [ ] Weapon unlock messages print correctly
- [ ] No warning spam
- [ ] Performance is acceptable

## Advanced Testing (Optional)

### 20. Stress Tests
- [ ] Spam upgrade to Level 8 quickly
- [ ] Test with max multi-shot (many projectiles)
- [ ] Test with many enemies on screen
- [ ] Rapidly switch between weapons (if cycling implemented)

## Final Verification

### 21. Complete Playthrough
- [ ] Start new game
- [ ] Play to Level 3
- [ ] Choose a weapon
- [ ] Play to Level 5
- [ ] Unlock second weapon
- [ ] Play to Level 8
- [ ] Unlock Missile Launcher
- [ ] Test all 4 weapons
- [ ] Verify all work correctly
- [ ] Game is fun and balanced

## Acceptance Criteria

**System is considered complete when:**
- ✅ All 4 weapons work correctly
- ✅ Unlock progression works as designed
- ✅ No crashes or critical bugs
- ✅ Integrates with existing systems
- ✅ HUD displays correctly
- ✅ Game is playable and enjoyable

## Known Limitations (Expected)

These are NOT bugs, they're design decisions:
- Railgun doesn't benefit from pierce upgrade (already infinite)
- Missiles don't benefit from pierce (explode on hit)
- Railgun beam doesn't scale with bullet speed (instant)
- Weapon cycling keybind not yet implemented
- Only 4 of 8 weapon types implemented

## Reporting Issues

If you find bugs, note:
1. **What** happened
2. **When** it happened (which level, which weapon)
3. **How** to reproduce it
4. **Console** error messages
5. **Expected** vs **Actual** behavior

## Success Metrics

- [ ] 0 crashes during 10-minute playthrough
- [ ] All weapons feel unique and fun
- [ ] Unlock progression feels rewarding
- [ ] System integrates seamlessly
- [ ] Code is maintainable and documented

---

**Status:** Ready for Testing
**Build:** ✅ Compiles Successfully
**Last Updated:** 2025-11-21
