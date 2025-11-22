/// Generic class to keep values and their descriptions in sync
/// This ensures that descriptions always match the actual values used in code
class ValueWithDescription<T> {
  final T value;
  final String Function(T) descriptionBuilder;

  ValueWithDescription({
    required this.value,
    required this.descriptionBuilder,
  });

  String get description => descriptionBuilder(value);
}

/// Common description builders for power-ups
class PowerUpDescriptions {
  static String health(double value) => 'Restores +${value.toInt()} HP';

  static String bomb(double range) => 'Destroys all enemies within ${range.toInt()}px range';

  static String magnet() => 'Collects all XP on the map';
}
