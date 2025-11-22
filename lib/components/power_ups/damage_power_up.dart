import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Damage Power-Up - Permanently increases damage
class DamagePowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<double>(
    value: 5.0,
    descriptionBuilder: PowerUpDescriptions.damage,
  );

  DamagePowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => 'D';

  @override
  Color get color => const Color(0xFFFF0000);

  @override
  void applyEffect(PlayerShip player) {
    player.damage += _config.value;
    print('[PowerUp] Damage boost: +${_config.value} damage');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final swordSize = radius * 0.6;

    // Create sword/blade shape
    final bladePath = Path();

    // Blade tip (top)
    bladePath.moveTo(center.dx, center.dy - swordSize);

    // Right edge of blade
    bladePath.lineTo(center.dx + swordSize * 0.15, center.dy + swordSize * 0.3);

    // Guard (right)
    bladePath.lineTo(center.dx + swordSize * 0.35, center.dy + swordSize * 0.35);
    bladePath.lineTo(center.dx + swordSize * 0.1, center.dy + swordSize * 0.35);

    // Handle (right side)
    bladePath.lineTo(center.dx + swordSize * 0.1, center.dy + swordSize * 0.8);

    // Pommel bottom
    bladePath.lineTo(center.dx - swordSize * 0.1, center.dy + swordSize * 0.8);

    // Handle (left side)
    bladePath.lineTo(center.dx - swordSize * 0.1, center.dy + swordSize * 0.35);

    // Guard (left)
    bladePath.lineTo(center.dx - swordSize * 0.35, center.dy + swordSize * 0.35);
    bladePath.lineTo(center.dx - swordSize * 0.15, center.dy + swordSize * 0.3);

    // Left edge of blade
    bladePath.lineTo(center.dx, center.dy - swordSize);

    canvas.drawPath(bladePath, iconPaint);
  }
}
