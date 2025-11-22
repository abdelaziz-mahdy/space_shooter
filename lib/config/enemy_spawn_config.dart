import 'dart:math';

/// Configuration for enemy spawn weights
/// Each enemy registers its spawn weight function here
class EnemySpawnConfig {
  static final Map<String, double Function(int wave)> _spawnWeights = {};

  /// Register a spawn weight function for an enemy type
  static void registerSpawnWeight(
    String enemyId,
    double Function(int wave) weightFunction,
  ) {
    _spawnWeights[enemyId] = weightFunction;
    print('[EnemySpawnConfig] Registered spawn weight for: $enemyId');
  }

  /// Get spawn weights for all enemies at a specific wave
  static Map<String, double> getWeightsForWave(int wave) {
    final weights = <String, double>{};
    for (final entry in _spawnWeights.entries) {
      weights[entry.key] = entry.value(wave);
    }
    return weights;
  }

  /// Get spawn weight for a specific enemy at a specific wave
  static double getWeightForEnemy(String enemyId, int wave) {
    final weightFunc = _spawnWeights[enemyId];
    if (weightFunc == null) {
      return 0.0; // Enemy not registered
    }
    return weightFunc(wave);
  }

  /// Check if an enemy has registered spawn weights
  static bool hasSpawnWeight(String enemyId) {
    return _spawnWeights.containsKey(enemyId);
  }

  /// Get all registered enemy IDs
  static List<String> getAllEnemyIds() => _spawnWeights.keys.toList();

  /// Clear all registrations (useful for testing)
  static void clearRegistrations() {
    _spawnWeights.clear();
  }
}
