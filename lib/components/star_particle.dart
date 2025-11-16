import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';

class StarParticle extends PositionComponent {
  final Random random = Random();
  late double opacity;
  late double twinkleSpeed;
  late double twinklePhase;

  StarParticle({required Vector2 position})
    : super(position: position, size: Vector2.all(2)) {
    anchor = Anchor.center;
    opacity = 0.3 + random.nextDouble() * 0.7;
    twinkleSpeed = 0.5 + random.nextDouble() * 2;
    twinklePhase = random.nextDouble() * 2 * pi;
  }

  @override
  void update(double dt) {
    super.update(dt);
    twinklePhase += twinkleSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final twinkle = (sin(twinklePhase) + 1) / 2;
    final currentOpacity = opacity * (0.5 + twinkle * 0.5);

    final paint = Paint()
      ..color = Color.fromRGBO(255, 255, 255, currentOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size.x / 2, paint);
  }
}
