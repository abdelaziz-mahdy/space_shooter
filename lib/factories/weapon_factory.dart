import '../weapons/weapon.dart';

/// Factory for creating weapons with self-registration pattern
/// No enums needed - weapons register themselves by String ID
class WeaponFactory {
  static final Map<String, Weapon Function()> _creators = {};

  /// Register a weapon creator function
  static void register(String id, Weapon Function() creator) {
    _creators[id] = creator;
    print('[WeaponFactory] Registered weapon: $id');
  }

  /// Create a weapon by ID
  static Weapon create(String id) {
    final creator = _creators[id];
    if (creator == null) {
      throw Exception('Unknown weapon type: $id. Available types: ${_creators.keys.join(", ")}');
    }
    return creator();
  }

  /// Get all registered weapon IDs
  static List<String> getAllIds() => _creators.keys.toList();

  /// Check if a weapon type is registered
  static bool isRegistered(String id) => _creators.containsKey(id);

  /// Clear all registrations (useful for testing)
  static void clearRegistrations() {
    _creators.clear();
  }
}
