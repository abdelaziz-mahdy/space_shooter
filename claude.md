# Coding Principles for Space Shooter Game

## ⚠️ CRITICAL RULES

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

### 8. **Coordinate Systems - Be Consistent**

**Rule:**
- World coordinates for positions (infinite scrolling)
- Local/relative coordinates for rendering (top-left origin)
- Use `PositionUtil` for all distance/direction calculations between components

---

### 9. **Pause Handling**

**✅ GOOD:**
```dart
@override
void update(double dt) {
  super.update(dt);

  // Check pause state at the start
  if (gameRef.isPaused) return;

  // Rest of update logic...
}
```

**Rule:** All components that should pause must check `gameRef.isPaused` at the start of `update()`.

---

### 10. **Damage Pipeline - Use Proper Death Sequence**

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
