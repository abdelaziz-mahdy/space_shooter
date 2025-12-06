import 'dart:ui';
import 'package:flame/components.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import '../game/space_shooter_game.dart';

/// Visual chain lightning effect
class ChainLightningEffect extends BaseRenderedComponent
    with HasVisualCenter {
  final List<Vector2> path; // Chain path from start to all targets
  final Color lightningColor;
  double lifetime = 0;
  static const double maxLifetime = 0.2; // Lightning lasts 200ms

  ChainLightningEffect({
    required this.path,
    this.lightningColor = const Color(0xFF00FFFF), // Cyan default
  }) : super(
          position: path.isNotEmpty ? path.first : Vector2.zero(),
          size: Vector2.zero(), // We'll render manually
        ) {
    assert(path.length >= 2, 'Chain lightning needs at least 2 points');
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
  }

  @override
  Vector2 getVisualCenter() => path.isNotEmpty ? path.first : Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isPaused) return;

    lifetime += dt;
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    if (path.length < 2) return;

    // Calculate fade based on lifetime
    final fadeProgress = lifetime / maxLifetime;
    final opacity = (1.0 - fadeProgress).clamp(0.0, 1.0);

    // Draw main lightning bolt
    final mainPaint = Paint()
      ..color = lightningColor.withValues(alpha: opacity * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw glow
    final glowPaint = Paint()
      ..color = lightningColor.withValues(alpha: opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // Convert path to world-relative coordinates for rendering
    final localPath = Path();

    for (int i = 0; i < path.length; i++) {
      final worldPos = path[i];
      // Convert world position to local canvas coordinates
      final localPos = worldPos - position;

      if (i == 0) {
        localPath.moveTo(localPos.x, localPos.y);
      } else {
        localPath.lineTo(localPos.x, localPos.y);
      }
    }

    // Draw glow first, then main bolt
    canvas.drawPath(localPath, glowPaint);
    canvas.drawPath(localPath, mainPaint);

    // Draw arc points (energy nodes at each chain point)
    final nodePaint = Paint()
      ..color = lightningColor.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;

    for (final worldPos in path) {
      final localPos = worldPos - position;
      canvas.drawCircle(
        Offset(localPos.x, localPos.y),
        4.0,
        nodePaint,
      );
    }
  }
}
