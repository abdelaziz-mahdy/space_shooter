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

  static String shield(int value) => 'Grants +$value shield layer${value > 1 ? 's' : ''}';

  static String damage(double value) => 'Permanently increases damage by +${value.toInt()}';

  static String speed(double value) => 'Permanently increases speed by +${value.toInt()}';

  static String fireRate(double reductionFactor) {
    final increasePercent = ((1.0 - reductionFactor) * 100).toInt();
    return 'Permanently increases fire rate by $increasePercent%';
  }

  static String bomb(double range) => 'Destroys all enemies within ${range.toInt()}px range';
}
