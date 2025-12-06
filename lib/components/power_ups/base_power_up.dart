import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../base_rendered_component.dart';
import '../player_ship.dart';
import '../../game/space_shooter_game.dart';
import '../../utils/visual_center_mixin.dart';

/// Abstract base class for all power-ups
/// Each power-up type extends this and provides its own implementation
abstract class BasePowerUp extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {

  final double lifespan; // Time before it disappears
  double lifetime = 0;

  BasePowerUp({
    required Vector2 position,
    this.lifespan = 10.0,
  }) : super(position: position, size: Vector2(20, 20));

  /// Description of what this power-up does
  String get description;

  /// Symbol to render on the power-up
  String get symbol;

  /// Color of the power-up
  Color get color;

  /// Icon type for visual representation
  /// Subclasses should override this to render custom icons
  void renderIcon(Canvas canvas, Offset center, double radius);

  /// Apply the power-up effect to the player
  void applyEffect(PlayerShip player);

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

    if (game.isPaused) return;

    lifetime += dt;
    if (lifetime >= lifespan) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      // Play power-up sound
      game.audioManager.playPowerUp();

      applyEffect(other);
      removeFromParent();
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final shouldBlink = lifetime > lifespan * 0.7 &&
                       ((lifetime * 10).floor() % 2 == 0);

    if (shouldBlink) return; // Blink effect

    // Draw background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      bgPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      borderPaint,
    );

    // Draw custom icon for this power-up
    final center = Offset(size.x / 2, size.y / 2);
    renderIcon(canvas, center, size.x / 2);
  }
}
