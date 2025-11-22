import 'dart:math';
import 'package:flame/components.dart';
import '../components/enemies/base_enemy.dart';
import '../components/player_ship.dart';

/// Factory for creating enemies with self-registration pattern
/// No enums needed - enemies register themselves by String ID
class EnemyFactory {
  static final Map<String, BaseEnemy Function(PlayerShip, int, Vector2, double)> _creators = {};
  static final Random _random = Random();

  /// Register an enemy creator function
  static void register(
    String id,
    BaseEnemy Function(PlayerShip player, int wave, Vector2 spawnPos, double scale) creator,
  ) {
    _creators[id] = creator;
    print('[EnemyFactory] Registered enemy: $id');
  }

  /// Create an enemy by ID
  static BaseEnemy create(String id, PlayerShip player, int wave, Vector2 spawnPos, {double scale = 1.0}) {
    final creator = _creators[id];
    if (creator == null) {
      throw Exception('Unknown enemy type: $id. Available types: ${_creators.keys.join(", ")}');
    }
    return creator(player, wave, spawnPos, scale);
  }

  /// Get all registered enemy IDs
  static List<String> getAllIds() => _creators.keys.toList();

  /// Check if an enemy type is registered
  static bool isRegistered(String id) => _creators.containsKey(id);

  /// Create a weighted random enemy based on spawn weights
  /// Returns the enemy that was selected
  static BaseEnemy createWeightedRandom(
    PlayerShip player,
    int wave,
    Vector2 spawnPos,
    Map<String, double> weights,
    {double scale = 1.0}
  ) {
    // Filter weights to only include registered enemies with weight > 0
    final validWeights = <String, double>{};
    for (final entry in weights.entries) {
      if (_creators.containsKey(entry.key) && entry.value > 0) {
        validWeights[entry.key] = entry.value;
      }
    }

    if (validWeights.isEmpty) {
      throw Exception('No valid enemies available for spawning at wave $wave');
    }

    // Calculate total weight
    final totalWeight = validWeights.values.reduce((a, b) => a + b);

    // Pick random enemy based on weights
    final randomValue = _random.nextDouble() * totalWeight;
    double cumulativeWeight = 0;

    for (final entry in validWeights.entries) {
      cumulativeWeight += entry.value;
      if (randomValue <= cumulativeWeight) {
        return create(entry.key, player, wave, spawnPos, scale: scale);
      }
    }

    // Fallback (should never reach here)
    final firstId = validWeights.keys.first;
    return create(firstId, player, wave, spawnPos, scale: scale);
  }

  /// Clear all registrations (useful for testing)
  static void clearRegistrations() {
    _creators.clear();
  }
}
