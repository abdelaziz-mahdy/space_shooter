import 'dart:ui';
import 'package:flame/components.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import '../game/space_shooter_game.dart';

/// Visual beam effect for railgun
class BeamEffect extends BaseRenderedComponent
    with HasVisualCenter {
  final Vector2 startPosition;
  final Vector2 endPosition;
  final Color beamColor;
  final double beamWidth;
  double lifetime = 0;
  static const double maxLifetime = 0.15; // Beam lasts 150ms

  BeamEffect({
    required this.startPosition,
    required this.endPosition,
    this.beamColor = const Color(0xFF00FFFF),
    this.beamWidth = 4.0,
  }) : super(
          position: startPosition,
          size: Vector2.zero(), // We'll render manually
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
  }

  @override
  Vector2 getVisualCenter() => startPosition.clone();

  @override
  void update(double dt) {
    super.update(dt);

    lifetime += dt;

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    // Calculate fade out effect
    final alpha = (1.0 - (lifetime / maxLifetime)).clamp(0.0, 1.0);

    // Draw outer glow
    final glowPaint = Paint()
      ..color = beamColor.withValues(alpha: alpha * 0.3)
      ..strokeWidth = beamWidth * 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw main beam
    final beamPaint = Paint()
      ..color = beamColor.withValues(alpha: alpha)
      ..strokeWidth = beamWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw inner core (bright)
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha)
      ..strokeWidth = beamWidth * 0.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Convert world positions to local canvas positions
    final localStart = Offset.zero; // Start is at our position
    final localEnd = Offset(
      endPosition.x - startPosition.x,
      endPosition.y - startPosition.y,
    );

    canvas.drawLine(localStart, localEnd, glowPaint);
    canvas.drawLine(localStart, localEnd, beamPaint);
    canvas.drawLine(localStart, localEnd, corePaint);
  }
}
