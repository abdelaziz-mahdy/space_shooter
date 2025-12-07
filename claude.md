# Coding Principles for Space Shooter Game

## ⚠️ CRITICAL RULES

### **ALWAYS UPDATE VERSION & CHANGELOG FOR CLIENT CHANGES!**

**Why:** Players need to see what changed. The game automatically shows changelogs on updates.

**MANDATORY STEPS for ANY client-facing changes:**

1. **Update `pubspec.yaml` version:**

   ```yaml
   version: 0.3.0 # Increment: major.minor.patch
   ```

2. **Add entry to `assets/changelog.json` (at TOP of array):**

   ```json
   [
     {
       "version": "0.3.0",
       "title": "Brief Update Title (3-5 words)",
       "date": "YYYY-MM-DD", // Use DateTime.now() to get current date: DateTime.now().toIso8601String().split('T')[0]
       "sections": [
         {
           "title": "Section Name",
           "emoji": "🎯",
           "items": [
             "Brief summary (not full sentences)",
             "Focus on user impact, not technical details"
           ]
         }
       ]
     }
     // ... older versions
   ]
   ```

   **Getting today's date:**

   ```dart
   // In Dart, get current date:
   final today = DateTime.now().toIso8601String().split('T')[0]; // "2025-01-28"
   ```

**IMPORTANT - Keep Changelogs Client-Friendly:**

Changelogs are shown to PLAYERS, not developers. Avoid all technical jargon, code details, and implementation specifics.

**✅ GOOD (User-friendly):**
- "Added surrender option in settings menu"
- "See your predicted global rank before submitting score"
- "Faster and more accurate rank predictions"
- "Spread weapons now hit center targets"
- "Fixed game crashes at high waves"

**❌ BAD (Too technical):**
- "Added /rank/predict endpoint for accurate rank calculation"
- "Backend improvements with efficient SQL queries"
- "Modified PlasmaSpreader fire() method to ensure i==0 has zero offset"
- "Refactored Bullet class to accept forceCrit parameter"
- "Implemented enemy caching with O(1) lookup performance"
- "Reduced bandwidth usage for rank prediction"

**Why:** Players care about WHAT changed (features/fixes), not HOW (code details, APIs, algorithms)

**Guidelines:**
- Write for non-technical players (age 10+)
- Focus on gameplay impact, not code changes
- Avoid: endpoints, APIs, SQL, classes, methods, parameters, bandwidth, caching, queries
- Use: added, fixed, improved, faster, new option, better performance

**Rule:** Version in `pubspec.yaml` MUST match version in `changelog.json`. Both files must be updated together in the same commit.

**When to increment:**

- **Patch (0.2.1):** Bug fixes, small tweaks
- **Minor (0.3.0):** New features, balance changes, new content
- **Major (1.0.0):** Major releases, breaking changes

**CRITICAL - Always Test Build Before Completing:**

After finishing ALL changes for a version, you MUST run BOTH `flutter analyze` AND attempt to build/run:

**Step 1: Run `flutter analyze`**
```bash
flutter analyze --no-fatal-infos
```

Then check for errors (note the leading spaces in the pattern):
```bash
flutter analyze --no-fatal-infos 2>&1 | grep "error •"
```

- If output is empty: ✅ No errors found (but still need Step 2!)
- If output shows errors: ❌ Fix them immediately

**IMPORTANT:** Use `grep "error •"` NOT `grep "^error"` because analyze output has leading spaces!

**Step 2: Attempt to build/run (REQUIRED!)**

⚠️ **IMPORTANT:** `flutter analyze` does NOT catch all compilation errors! You MUST attempt to build:

```bash
flutter run
# OR
flutter build <platform>
```

**Why both are needed:**
- `flutter analyze` catches: static analysis issues, lints, type hints
- Build/run catches: actual compilation errors, missing imports, type conflicts

**Common errors ONLY caught by build:**
- Method name conflicts with inherited methods (e.g., `currentTime` vs `FlameGame.currentTime()`)
- Missing imports for UI classes (`TextPainter`, `TextSpan` from `flutter/material.dart`)
- Type conversion errors (`num` vs `double` from `pow()`)
- Static method calls missing class name (`getAllUpgrades()` vs `Upgrade.getAllUpgrades()`)

**If build errors are found:**
1. Fix all errors immediately
2. Run `flutter analyze` again
3. Attempt build again
4. Only proceed when BOTH pass with 0 errors

See [Release Process](#release-process--version-management) section for detailed guidelines.

---

### **RESPONSIVE DESIGN - GAME ENGINE VS FLUTTER UI**

**Why:** Different rendering systems require different approaches for responsive layouts.

---

#### **For Game Engine (Flame Components):**

**Use percentage-based sizing** - Flame components don't have layout widgets, so calculate manually.

**❌ NEVER DO THIS:**

```dart
// BAD: Conditional adjustments and clamping in game components
final scaleFactor = (size.x / 800.0).clamp(0.7, 1.5);
var enemySize = (50.0 * scaleFactor).clamp(30.0, 80.0);
```

**✅ ALWAYS USE PERCENTAGE-BASED SIZING:**

```dart
// GOOD: Simple percentage-based responsive sizing for game components
final enemySize = gameRef.size.x * 0.05; // 5% of screen width
final bulletSpeed = gameRef.size.y * 0.4; // 40% of screen height per second
final spacing = gameRef.size.x * 0.02; // 2% of screen width

// Text sizes based on game canvas size
final fontSize = gameRef.size.x * 0.03; // 3% of width
```

---

#### **For Flutter UI (Overlays, Dialogs, HUD):**

**Use Flutter's layout widgets** - Expanded, Flexible, AspectRatio, LayoutBuilder, etc.

**❌ NEVER DO THIS:**

```dart
// BAD: Manual width calculations in Flutter UI
final screenWidth = constraints.maxWidth;
final cardWidth = (screenWidth * 0.9 - spacing) / 3;
final cardHeight = cardWidth * 1.25;

return Row(
  children: [
    Container(width: cardWidth, height: cardHeight, ...),
    SizedBox(width: spacing),
    Container(width: cardWidth, height: cardHeight, ...),
  ],
);
```

**✅ ALWAYS USE FLUTTER LAYOUT WIDGETS:**

```dart
// GOOD: Use Expanded, AspectRatio, and LayoutBuilder for responsive Flutter UI
return Row(
  children: List.generate(3, (index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing),
        child: AspectRatio(
          aspectRatio: 0.8, // width:height ratio
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Now calculate font sizes based on actual size
              final fontSize = constraints.maxWidth * 0.1;
              return Container(...);
            },
          ),
        ),
      ),
    );
  }),
);
```

**Benefits:**

1. **Game Engine (Flame)**: Manual percentages work because no layout system exists
2. **Flutter UI**: Built-in widgets handle complex layouts automatically
3. **Safer**: Flutter widgets prevent overflow and handle edge cases
4. **More responsive**: Expanded/Flexible adapt to available space dynamically

**Rule:**

- **Flame components**: Use percentages of `gameRef.size.x/y` for positions and dimensions
- **Flutter UI**: Use `Expanded`, `Flexible`, `AspectRatio`, and `LayoutBuilder` instead of manual calculations

**Key Flutter Layout Patterns:**

1. **For consistent element positioning across cards/items:**

```dart
// Use Expanded with flex ratios to ensure elements align across all items
Column(
  children: [
    Expanded(flex: 3, child: IconWidget()),  // Icon takes 3 parts
    SizedBox(height: spacing),
    Expanded(flex: 2, child: TitleWidget()), // Title takes 2 parts
    SizedBox(height: spacing),
    Expanded(flex: 3, child: DescWidget()),  // Desc takes 3 parts
  ],
)
```

This ensures icons, titles, and descriptions are in the same vertical positions across all cards, regardless of text length.

2. **For preventing icon/emoji cutoff:**

```dart
// Wrap in FittedBox with BoxFit.contain
Expanded(
  child: FittedBox(
    fit: BoxFit.contain,
    child: Text(emoji, style: TextStyle(fontSize: iconSize)),
  ),
)
```

This scales the emoji to fit within its container without clipping.

---

### **AVOID ENUMS AT ALL COSTS!**

**Why:** Enums are rigid, non-extensible, and lead to switch statements scattered throughout the codebase. They violate OOP principles.

**❌ NEVER DO THIS:**

```dart
enum PowerUpType { health, shield, damage }

// Switch statements everywhere!
void apply(PowerUpType type) {
  switch (type) {
    case PowerUpType.health: /* logic */; break;
    case PowerUpType.shield: /* logic */; break;
  }
}

Color getColor(PowerUpType type) {
  switch (type) {
    case PowerUpType.health: return Colors.green;
    // More scattered logic!
  }
}
```

**✅ ALWAYS USE CLASSES WITH INTERFACES:**

```dart
// Abstract base class defines the interface
abstract class PowerUp {
  String get description;
  Color get color;
  String get symbol;
  void apply(PlayerShip player);
}

// Each type is its own class
class HealthPowerUp extends PowerUp {
  @override
  String get description => 'Restores +30 HP';

  @override
  Color get color => const Color(0xFF00FF00);

  @override
  String get symbol => '+';

  @override
  void apply(PlayerShip player) {
    player.health = (player.health + 30).clamp(0, player.maxHealth);
  }
}

class ShieldPowerUp extends PowerUp {
  @override
  String get description => 'Grants +1 shield layer';

  @override
  Color get color => const Color(0xFF00FFFF);

  @override
  String get symbol => 'S';

  @override
  void apply(PlayerShip player) {
    player.shieldLayers += 1;
  }
}

// Usage is clean and polymorphic
void usePowerUp(PowerUp powerUp, PlayerShip player) {
  powerUp.apply(player);  // No switch needed!
  final color = powerUp.color;  // Each class knows its own data
}
```

**Benefits of Classes over Enums:**

1. **Extensible** - Add new power-ups without modifying existing code
2. **Encapsulated** - Each power-up owns its logic and data
3. **Polymorphic** - No switch statements, just call methods
4. **Maintainable** - Logic is centralized in one place per type

---

## Architecture & Design Patterns

### 1. **Avoid Code Duplication - Use Inheritance & Composition**

**❌ BAD:**

```dart
// Creating separate base classes that duplicate functionality
class Enemy { /* health, damage logic */ }
class BossShip { /* health, damage logic - duplicated! */ }
```

**✅ GOOD:**

```dart
// BossShip extends BaseEnemy, inheriting all common functionality
class BossShip extends BaseEnemy {
  // Only override what's different (hitbox, movement, rendering)
}
```

**Rule:** If two classes share behavior, use inheritance or composition. Don't duplicate code.

---

### 2. **Keep Data in Sync with Code - No Hardcoded Values**

**❌ BAD:**

```dart
// Hardcoded multiplier values that can drift from actual weapon code
static String getDescription(String weaponId) {
  switch (weaponId) {
    case 'plasma_spreader':
      return '0.6x damage per shot';  // What if weapon code changes?
  }
}
```

**✅ GOOD:**

```dart
// Dynamically fetch from the actual weapon instance
static String getDetailedDescription(String weaponId) {
  final weapon = WeaponFactory.create(weaponId);
  return weapon.getDetailedDescription();  // Always in sync!
}
```

**Rule:** Data should come from code, not be duplicated in strings. Use extension methods, getters, or factory patterns to ensure single source of truth.

---

### 3. **Use Extension Methods for Type-Specific Behavior**

**❌ BAD:**

```dart
// Scattered switch statements throughout codebase
void renderPowerUp(PowerUpType type) {
  Color color;
  switch (type) {
    case PowerUpType.health: color = Colors.green; break;
    // ...
  }
}

void getPowerUpText(PowerUpType type) {
  String text;
  switch (type) {
    case PowerUpType.health: text = 'Health'; break;
    // ...
  }
}
```

**✅ GOOD:**

```dart
// Extension methods keep type-specific behavior centralized
extension PowerUpTypeExtension on PowerUpType {
  Color getColor() {
    switch (this) {
      case PowerUpType.health: return const Color(0xFF00FF00);
      // ...
    }
  }

  String getDescription() {
    switch (this) {
      case PowerUpType.health: return 'Restores +30 HP';
      // ...
    }
  }
}

// Usage:
final color = type.getColor();
final desc = type.getDescription();
```

**Rule:** Group type-specific behavior using extension methods. This creates a single source of truth and makes the code easier to maintain.

---

### 4. **Follow Interface Patterns - Let Classes Expose Their Own Data**

**❌ BAD:**

```dart
// External class guessing about weapon properties
class WeaponUI {
  String getWeaponStats(String weaponId) {
    // This violates encapsulation!
    if (weaponId == 'railgun') {
      return '2.5x damage, slower fire rate';  // Guessing values
    }
  }
}
```

**✅ GOOD:**

```dart
// Weapon classes expose their own properties
abstract class Weapon {
  final double damageMultiplier;
  final double fireRateMultiplier;

  String getDetailedDescription() {
    return '$description\n${damageMultiplier}x damage, ${fireRateMultiplier}x fire rate';
  }
}

// PlasmaSpreader exposes its actual values
class PlasmaSpreader extends Weapon {
  PlasmaSpreader() : super(
    damageMultiplier: 0.6,  // Actual value from code
    fireRateMultiplier: 1.0,
  );
}

// UI just reads from the source
String getWeaponStats(Weapon weapon) {
  return weapon.getDetailedDescription();  // Always accurate!
}
```

**Rule:** Classes should expose their own data through interfaces/methods. Don't make external code guess or hardcode class-specific values.

---

### 5. **Generic Type Handling - Use Base Classes Properly**

**❌ BAD:**

```dart
// Separate checks for each enemy type
if (other is BaseEnemy) {
  // handle
} else if (other is BossShip) {
  // handle boss separately
}
```

**✅ GOOD:**

```dart
// BossShip extends BaseEnemy, so one check handles all
if (other is BaseEnemy) {
  other.takeDamage(damage);  // Works for all enemy types including bosses
}
```

**Rule:** Use `whereType<BaseClass>()` for generic filtering. If BossShip extends BaseEnemy, don't treat them separately.

---

### 6. **Component Lifecycle - Proper Initialization Order**

**✅ GOOD:**

```dart
class PlayerShip extends Component {
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Set anchor before adding hitboxes
    anchor = Anchor.center;

    // Add components
    add(PolygonHitbox([...]));
    add(weaponManager);
  }
}
```

**Rule:** Always call `super.onLoad()` first, set properties like `anchor` before adding child components.

---

### 7. **Factory Pattern - Centralize Object Creation**

**✅ GOOD:**

```dart
// All weapons registered through factory
class WeaponFactory {
  static final Map<String, Weapon Function()> _factories = {};

  static void register(String id, Weapon Function() factory) {
    _factories[id] = factory;
  }

  static Weapon create(String id) {
    final factory = _factories[id];
    if (factory == null) throw Exception('Unknown weapon: $id');
    return factory();
  }
}

// Weapons self-register
class PulseCannon extends Weapon {
  static void init() {
    WeaponFactory.register('pulse_cannon', () => PulseCannon());
  }
}
```

**Rule:** Use factories for creating different variants of the same type. Makes adding new types easy without modifying existing code.

---

### 8. **Pause Handling - Enforce at Base Class Level**

**Why:** Game components must respect pause state. Forgetting to check `game.isPaused` in any component leads to subtle bugs (e.g., orbital drones firing during pause).

**Pattern: Use `BaseGameComponent` for all game logic components**

All game components should extend from the pause-aware hierarchy:
- `BaseGameComponent` - Base for all game components (enforces pause)
- `BaseRenderedComponent` (extends `BaseGameComponent`) - For rendered components
- `BaseEnemy` (extends `BaseRenderedComponent`) - For all enemies

**✅ GOOD - New Components:**

```dart
// Extend BaseGameComponent for simple game components
class OrbitalDrone extends BaseGameComponent {
  @override
  void updateGame(double dt) {
    // This is NEVER called when game is paused
    // Pause check is automatic in base class
    angle += rotationSpeed * dt;
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      _shootAtNearestEnemy();
    }
  }
}

// Extend BaseRenderedComponent for rendered components
class Bullet extends BaseRenderedComponent {
  @override
  void updateGame(double dt) {
    // Pause check automatic - no manual check needed!
    position += direction * speed * dt;
    lifetime += dt;
  }
}

// All enemy types automatically inherit pause handling
class SquareEnemy extends BaseEnemy {
  @override
  void updateGame(double dt) {
    // Pause is handled automatically by BaseEnemy
    // which extends BaseRenderedComponent
    // which extends BaseGameComponent
    updateMovement(dt); // Safe - won't be called during pause
  }
}
```

**❌ BAD - Old Pattern (Don't Use):**

```dart
// Manually checking pause in every component (error-prone!)
class OrbitalDrone extends PositionComponent {
  @override
  void update(double dt) {
    if (game.isPaused) return; // Easy to forget!
    // ... update logic
  }
}
```

**How It Works:**

The pause check is enforced in `BaseGameComponent.update()`:

```dart
abstract class BaseGameComponent extends PositionComponent {
  @override
  void update(double dt) {
    // Check pause FIRST - all game logic is prevented during pause
    if (game.isPaused) return;

    // Only call updateGame() if not paused
    updateGame(dt);

    super.update(dt);
  }

  // Subclasses override this instead of update()
  void updateGame(double dt) { }
}
```

**Migration Steps for Existing Components:**

1. Change `extends PositionComponent` to `extends BaseGameComponent`
   - Or better: `extends BaseRenderedComponent` if it needs rendering
   - Or: `extends BaseEnemy` if it's an enemy type

2. Change `void update(double dt)` to `void updateGame(double dt)`
   - Remove any manual `if (game.isPaused) return;` checks
   - Pause check is now automatic

3. Remove manual pause checks since they're handled by base class:
   ```dart
   // BEFORE
   @override
   void update(double dt) {
     if (game.isPaused) return;
     // ... logic
   }

   // AFTER
   @override
   void updateGame(double dt) {
     // No pause check needed - handled by base class!
     // ... logic
   }
   ```

**Benefits:**

1. ✅ **Can't forget pause check** - Enforced by base class, not optional
2. ✅ **Single source of truth** - One place where pause logic lives
3. ✅ **Cleaner code** - No repeated pause checks in every component
4. ✅ **Safer refactoring** - New components automatically safe
5. ✅ **Consistent behavior** - All components pause together

**Rule:** ALL components that have game logic MUST extend from the pause-aware hierarchy and override `updateGame(dt)` instead of `update(dt)`. This is non-negotiable for consistency.

---

### 9. **Centralized Balance Configuration - Use Static Config Classes**

**Why:** Balance values used across multiple files should be centralized in one place for easy tuning.

**❌ BAD:**

```dart
// Scattered magic numbers across codebase
class MultiShotUpgrade {
  bool isValidFor(PlayerShip player) {
    return player.projectileCount < 5; // Hardcoded cap
  }
}

class PlayerShip {
  void takeDamage(double damage) {
    final cappedReduction = damageReduction.clamp(0.0, 0.60); // Hardcoded cap
  }
}

class BaseEnemy {
  static const double damageNumberCooldown = 0.05; // Hardcoded rate
}
```

**✅ GOOD:**

```dart
// lib/config/balance_config.dart
/// Global balance configuration for easy tuning
class BalanceConfig {
  // Projectile System
  static const int maxProjectileCount = 5;

  // Damage Reduction
  static const double maxDamageReduction = 0.60; // 60% cap

  // Damage Numbers (Performance)
  static const double damageNumberCooldown = 0.05; // Show every 50ms

  // Crit System
  static const double maxCritChance = 0.75; // 75% cap
  static const double maxCritDamage = 5.0; // 5x cap

  // Orbital Drones
  static const int maxOrbitalDrones = 10;
}

// Usage across codebase:
class MultiShotUpgrade {
  bool isValidFor(PlayerShip player) {
    return player.projectileCount < BalanceConfig.maxProjectileCount;
  }
}

class PlayerShip {
  void takeDamage(double damage) {
    final cappedReduction = damageReduction.clamp(0.0, BalanceConfig.maxDamageReduction);
  }
}

class BaseEnemy {
  static const double damageNumberCooldown = BalanceConfig.damageNumberCooldown;
}
```

**Benefits:**

1. **Single source of truth** - All balance values in one file
2. **Easy tweaking** - Change value once, affects entire game
3. **Clear visibility** - See all caps/limits at a glance
4. **Better testing** - Modify all related values together
5. **Prevents drift** - Can't have different caps in different files

**What should go in BalanceConfig:**

- Global caps/limits (max projectiles, max crit chance, max damage reduction)
- Shared cooldowns (damage numbers, abilities)
- Performance tuning values (spawn rates, entity limits)
- Core balance numbers used in multiple places

**What should NOT go in BalanceConfig:**

- Component-specific values (enemy health, weapon damage) - keep in the component
- One-time values used in a single place
- Values that need to scale with wave/level

**Rule:** If a balance value is referenced in 2+ files, or is a global cap/limit, put it in `BalanceConfig`. Always import and use the config instead of hardcoding values.

---

### 10. **Coordinate Systems - Be Consistent**

**Rule:**

- World coordinates for positions (infinite scrolling)
- Local/relative coordinates for rendering (top-left origin)
- Use `PositionUtil` for all distance/direction calculations between components

---

### 11. **Damage Pipeline - Use Proper Death Sequence**

**❌ BAD:**

```dart
// Removing enemy directly - no loot!
enemy.removeFromParent();
```

**✅ GOOD:**

```dart
// Using damage pipeline triggers proper death with loot
enemy.takeDamage(999999);  // Calls die() → drops XP → removes
```

**Rule:** Never call `removeFromParent()` on enemies directly. Always use `takeDamage()` to trigger the proper death sequence with loot drops.

---

## Summary

1. **DRY (Don't Repeat Yourself)** - Use inheritance, composition, and extension methods
2. **Single Source of Truth** - Data comes from code, not hardcoded strings
3. **Encapsulation** - Classes expose their own data through interfaces
4. **Generic Programming** - Use base classes and `whereType<T>()` properly
5. **Factory Pattern** - Centralize object creation for extensibility
6. **Consistency** - Coordinate systems, pause handling, damage pipeline

**Golden Rule:** If you find yourself copying code or hardcoding values that exist elsewhere in the codebase, there's a better pattern available. Use abstraction and polymorphism.

---

## Release Process & Version Management

### **When Releasing a New Version**

**CRITICAL:** Always update these files together:

1. **`pubspec.yaml`** - Bump the version number

   ```yaml
   version: 0.3.0 # Increment appropriately
   ```

2. **`assets/changelog.json`** - Add new changelog entry at the TOP of the array
   ```json
   [
     {
       "version": "0.3.0",
       "title": "Brief Update Title",
       "date": "YYYY-MM-DD", // Use DateTime.now().toIso8601String().split('T')[0] to get today's date
       "sections": [
         {
           "title": "Section Name",
           "emoji": "🎯",
           "items": [
             "Concise description of change",
             "Another important change"
           ]
         }
       ]
     }
     // ... older versions below
   ]
   ```

### **Changelog Best Practices**

**Keep it Mobile-Friendly:**

- Use **concise descriptions** (max 1-2 lines per item)
- Focus on **user-visible changes** (not internal refactors)
- Group related changes into sections
- Use emojis for visual scanning

**Section Examples:**

- `🐛 Bug Fixes` - Fixed issues
- `⚖️ Balance` - Gameplay balance changes
- `✨ New Features` - New functionality
- `🎨 UI Improvements` - Visual/UX changes
- `🔒 New Caps` - New limits/restrictions
- `⚡ Performance` - Optimization changes

**Example Entry:**

```json
{
  "version": "0.3.0",
  "title": "Enemy Variety Update",
  "date": "2025-02-15", // Get current date: DateTime.now().toIso8601String().split('T')[0]
  "sections": [
    {
      "title": "New Content",
      "emoji": "✨",
      "items": [
        "3 new enemy types with unique abilities",
        "Boss rush mode unlocked at wave 50"
      ]
    },
    {
      "title": "Balance",
      "emoji": "⚖️",
      "items": [
        "Enemy health scaling increased 30% → 50% per wave",
        "Shield power-up now gives 2 layers instead of 1"
      ]
    }
  ]
}
```

**Note:** Always use code to get the current date to avoid hardcoding wrong dates.

### **Automatic Changelog Display**

The changelog system automatically:

1. **Detects version changes** via `VersionService`
2. **Shows on first launch** after update (500ms delay)
3. **Tracks last seen version** in SharedPreferences
4. **Only shows new changes** since user's last version

**Files Involved:**

- `lib/services/version_service.dart` - Version detection
- `lib/models/changelog.dart` - Data models
- `lib/ui/changelog_dialog.dart` - Display UI
- `lib/ui/main_menu.dart` - Integration point

**DON'T FORGET:** Both `pubspec.yaml` version and `changelog.json` must match!
