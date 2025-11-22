import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Speed Power-Up - Permanently increases speed
class SpeedPowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<double>(
    value: 25.0,
    descriptionBuilder: PowerUpDescriptions.speed,
  );

  SpeedPowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => '>';

  @override
  Color get color => const Color(0xFFFFFF00);

  @override
  void applyEffect(PlayerShip player) {
    player.moveSpeed += _config.value;
    print('[PowerUp] Speed boost: +${_config.value} speed');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.miter;

    final boltSize = radius * 0.6;

    // Create lightning bolt shape
    final boltPath = Path();

    // Start at top
    boltPath.moveTo(center.dx - boltSize * 0.2, center.dy - boltSize);

    // Right edge going down
    boltPath.lineTo(center.dx + boltSize * 0.3, center.dy - boltSize);

    // Zigzag to center-right
    boltPath.lineTo(center.dx - boltSize * 0.1, center.dy - boltSize * 0.1);

    // Right tip
    boltPath.lineTo(center.dx + boltSize * 0.5, center.dy);

    // Back to center
    boltPath.lineTo(center.dx + boltSize * 0.1, center.dy + boltSize * 0.1);

    // To bottom-right
    boltPath.lineTo(center.dx + boltSize * 0.2, center.dy + boltSize);

    // Bottom tip
    boltPath.lineTo(center.dx - boltSize * 0.1, center.dy + boltSize);

    // Back up the left side
    boltPath.lineTo(center.dx + boltSize * 0.05, center.dy + boltSize * 0.3);

    // Left tip
    boltPath.lineTo(center.dx - boltSize * 0.5, center.dy + boltSize * 0.2);

    // Back to top
    boltPath.lineTo(center.dx - boltSize * 0.05, center.dy - boltSize * 0.2);
    boltPath.lineTo(center.dx - boltSize * 0.2, center.dy - boltSize);

    canvas.drawPath(boltPath, iconPaint);
  }
}
