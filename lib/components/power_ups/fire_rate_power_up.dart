import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Fire Rate Power-Up - Permanently increases fire rate
class FireRatePowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<double>(
    value: 0.85,
    descriptionBuilder: PowerUpDescriptions.fireRate,
  );

  FireRatePowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => 'F';

  @override
  Color get color => const Color(0xFFFF8800);

  @override
  void applyEffect(PlayerShip player) {
    player.shootInterval *= _config.value;
    player.shootInterval = max(0.1, player.shootInterval); // Min 0.1s
    final increasePercent = ((1.0 - _config.value) * 100).toInt();
    print('[PowerUp] Fire rate boost: $increasePercent% faster');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final arrowSize = radius * 0.5;
    final spacing = arrowSize * 0.4;

    // Draw two arrows pointing right to represent rapid fire

    // First arrow (front)
    final arrow1Path = Path();
    arrow1Path.moveTo(center.dx - arrowSize + spacing, center.dy - arrowSize * 0.5);
    arrow1Path.lineTo(center.dx + spacing, center.dy);
    arrow1Path.lineTo(center.dx - arrowSize + spacing, center.dy + arrowSize * 0.5);

    // Arrow shaft
    canvas.drawLine(
      Offset(center.dx - arrowSize * 1.2 + spacing, center.dy),
      Offset(center.dx + spacing, center.dy),
      iconPaint,
    );

    canvas.drawPath(arrow1Path, iconPaint);

    // Second arrow (back, slightly offset)
    final arrow2Path = Path();
    arrow2Path.moveTo(center.dx - arrowSize - spacing, center.dy - arrowSize * 0.5);
    arrow2Path.lineTo(center.dx - spacing, center.dy);
    arrow2Path.lineTo(center.dx - arrowSize - spacing, center.dy + arrowSize * 0.5);

    // Arrow shaft
    canvas.drawLine(
      Offset(center.dx - arrowSize * 1.2 - spacing, center.dy),
      Offset(center.dx - spacing, center.dy),
      iconPaint,
    );

    canvas.drawPath(arrow2Path, iconPaint);
  }
}
