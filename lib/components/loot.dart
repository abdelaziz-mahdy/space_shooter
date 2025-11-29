import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/position_util.dart';
import '../utils/visual_center_mixin.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

class Loot extends BaseRenderedComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  static const double attractionRange = 100;
  static const double attractionSpeed = 200;
  final int xpValue;

  Loot({required Vector2 position, this.xpValue = 1})
    : super(
        position: position,
        // Size based on XP value: bigger cores for more XP
        size: Vector2.all(_getSizeForXP(xpValue)),
      );

  /// Get size based on XP value
  static double _getSizeForXP(int xp) {
    if (xp >= 25) return 16.0; // Orange cores (largest)
    if (xp >= 10) return 14.0; // Yellow cores
    if (xp >= 5) return 12.0;  // Green cores
    return 10.0;               // Cyan cores (smallest)
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    add(CircleHitbox());
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    // Attract to player using PositionUtil
    final player = gameRef.player;
    final distanceToPlayer = PositionUtil.getDistance(this, player);

    // Use player's magnet radius for attraction
    if (distanceToPlayer < player.magnetRadius) {
      final direction = PositionUtil.getDirectionTo(this, player);
      position += direction * attractionSpeed * dt;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      gameRef.levelManager.addXP(xpValue);
      removeFromParent();
    }
  }

  /// Get color based on XP value
  Color _getColorForXP() {
    if (xpValue >= 25) return const Color(0xFFFF8800); // Orange (epic)
    if (xpValue >= 10) return const Color(0xFFFFFF00); // Yellow (rare)
    if (xpValue >= 5) return const Color(0xFF00FF00);  // Green (uncommon)
    return const Color(0xFF00FFFF);                     // Cyan (common)
  }

  @override
  void renderShape(Canvas canvas) {
    final coreColor = _getColorForXP();

    final paint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = coreColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw circle in center of bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2 + 3, glow);
    canvas.drawCircle(center, size.x / 2, paint);
  }
}
