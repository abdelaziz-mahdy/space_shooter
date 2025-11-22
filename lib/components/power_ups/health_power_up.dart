import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Health Power-Up - Restores player health
class HealthPowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<double>(
    value: 15.0,
    descriptionBuilder: PowerUpDescriptions.health,
  );

  HealthPowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => '+';

  @override
  Color get color => const Color(0xFF00FF00);

  @override
  void applyEffect(PlayerShip player) {
    player.health = (player.health + _config.value).clamp(0, player.maxHealth);
    print('[PowerUp] Health restored: +${_config.value} HP');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final iconSize = radius * 0.5;

    // Vertical line of plus/cross
    canvas.drawLine(
      Offset(center.dx, center.dy - iconSize),
      Offset(center.dx, center.dy + iconSize),
      iconPaint,
    );

    // Horizontal line of plus/cross
    canvas.drawLine(
      Offset(center.dx - iconSize, center.dy),
      Offset(center.dx + iconSize, center.dy),
      iconPaint,
    );
  }
}
