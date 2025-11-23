import 'dart:ui';
import 'enemy_bullet.dart';
import 'package:flame/components.dart';

/// Green variant of EnemyBullet used by Summoner Boss
/// Extends EnemyBullet and only overrides rendering for green color
class GreenEnemyBullet extends EnemyBullet {
  GreenEnemyBullet({
    required Vector2 position,
    required Vector2 direction,
    required double damage,
    required double speed,
  }) : super(
          position: position,
          direction: direction,
          damage: damage,
          speed: speed,
        );

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFF00FF00) // Bright green color for Summoner bullets
      ..style = PaintingStyle.fill;

    // Draw circle in the center of the bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, paint);

    // Add a small white center for visibility
    final centerPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.x / 4, centerPaint);
  }
}
