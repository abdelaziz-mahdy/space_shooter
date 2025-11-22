import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Shield Power-Up - Grants shield layer
class ShieldPowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<int>(
    value: 1,
    descriptionBuilder: PowerUpDescriptions.shield,
  );

  ShieldPowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => 'S';

  @override
  Color get color => const Color(0xFF00FFFF);

  @override
  void applyEffect(PlayerShip player) {
    player.shieldLayers += _config.value;
    print('[PowerUp] Shield granted: +${_config.value} layer');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final shieldSize = radius * 0.6;

    // Create shield shape using path
    final path = Path();

    // Top point of shield
    path.moveTo(center.dx, center.dy - shieldSize);

    // Right curve
    path.quadraticBezierTo(
      center.dx + shieldSize * 0.8, center.dy - shieldSize * 0.5,
      center.dx + shieldSize * 0.6, center.dy + shieldSize * 0.2,
    );

    // Bottom point
    path.lineTo(center.dx, center.dy + shieldSize);

    // Left curve
    path.lineTo(center.dx - shieldSize * 0.6, center.dy + shieldSize * 0.2);
    path.quadraticBezierTo(
      center.dx - shieldSize * 0.8, center.dy - shieldSize * 0.5,
      center.dx, center.dy - shieldSize,
    );

    canvas.drawPath(path, iconPaint);

    // Add vertical line in center for detail
    final detailPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(center.dx, center.dy - shieldSize * 0.8),
      Offset(center.dx, center.dy + shieldSize * 0.8),
      detailPaint,
    );
  }
}
