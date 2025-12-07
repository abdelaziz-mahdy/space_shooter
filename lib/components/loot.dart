import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/position_util.dart';
import '../utils/visual_center_mixin.dart';
import '../config/balance_config.dart';
import 'base_rendered_component.dart';
import 'player_ship.dart';
import '../game/space_shooter_game.dart';

class Loot extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  static const double attractionRange = 100;
  int xpValue;

  // Wave-end collection state
  bool isWaveEndCollecting = false;

  Loot({required Vector2 position, this.xpValue = 1})
    : super(
        position: position,
        // Size based on XP value: bigger cores for more XP
        size: Vector2.all(_getSizeForXP(xpValue)),
      );

  /// Get size based on XP value
  static double _getSizeForXP(int xp) {
    if (xp >= 250) return 24.0; // Epic purple cores (mega)
    if (xp >= 100) return 22.0; // Epic red cores (huge)
    if (xp >= 50) return 20.0;  // Epic pink cores (very large)
    if (xp >= 25) return 16.0;  // Orange cores (large)
    if (xp >= 10) return 14.0;  // Yellow cores (medium)
    if (xp >= 5) return 12.0;   // Green cores (small)
    return 10.0;                // Cyan cores (tiny)
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    add(CircleHitbox());
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  /// Start wave-end collection animation
  void startWaveEndCollection() {
    isWaveEndCollecting = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update size if xpValue changed due to merging
    final newSize = Vector2.all(_getSizeForXP(xpValue));
    if (size != newSize) {
      size = newSize;
    }

    // Attract to player using PositionUtil
    final player = game.player;
    final distanceToPlayer = PositionUtil.getDistance(this, player);

    // Wave-end collection: pull all XP aggressively
    if (isWaveEndCollecting) {
      final direction = PositionUtil.getDirectionTo(this, player);
      position += direction * BalanceConfig.waveEndCollectionSpeed * dt;
      return;
    }

    // Normal attraction: use player's magnet radius
    if (distanceToPlayer < player.magnetRadius) {
      final direction = PositionUtil.getDirectionTo(this, player);
      position += direction * BalanceConfig.normalAttractionSpeed * dt;
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      game.levelManager.addXP(xpValue);
      removeFromParent();
    }
  }

  /// Get color based on XP value
  Color _getColorForXP() {
    if (xpValue >= 250) return const Color(0xFFAA00FF); // Purple (mega)
    if (xpValue >= 100) return const Color(0xFFFF0000); // Red (huge)
    if (xpValue >= 50) return const Color(0xFFFF00FF);  // Pink (very large)
    if (xpValue >= 25) return const Color(0xFFFF8800);  // Orange (large)
    if (xpValue >= 10) return const Color(0xFFFFFF00);  // Yellow (medium)
    if (xpValue >= 5) return const Color(0xFF00FF00);   // Green (small)
    return const Color(0xFF00FFFF);                      // Cyan (tiny)
  }

  @override
  void renderShape(Canvas canvas) {
    final coreColor = _getColorForXP();

    final paint = Paint()
      ..color = coreColor
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = coreColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // Draw circle in center of bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2 + 3, glow);
    canvas.drawCircle(center, size.x / 2, paint);
  }
}
