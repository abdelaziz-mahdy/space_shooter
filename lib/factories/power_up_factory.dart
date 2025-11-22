import 'dart:math';
import 'package:flame/components.dart';
import '../components/power_ups/base_power_up.dart';
import '../components/power_ups/health_power_up.dart';
import '../components/power_ups/bomb_power_up.dart';
import '../components/power_ups/magnet_power_up.dart';

/// Factory for creating power-ups
/// Follows the factory pattern to centralize power-up creation
class PowerUpFactory {
  static final Random _random = Random();

  /// All available power-up types
  static final List<BasePowerUp Function(Vector2)> _powerUpCreators = [
    (pos) => HealthPowerUp(position: pos),
    (pos) => BombPowerUp(position: pos),
    (pos) => MagnetPowerUp(position: pos),
  ];

  /// Create a random power-up at the given position
  static BasePowerUp createRandom(Vector2 position) {
    final creator = _powerUpCreators[_random.nextInt(_powerUpCreators.length)];
    return creator(position);
  }

  /// Get total number of power-up types
  static int get typeCount => _powerUpCreators.length;
}
