import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import '../loot.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Magnet Power-Up - Collects all XP on the map
class MagnetPowerUp extends BasePowerUp {
  MagnetPowerUp({required super.position});

  @override
  String get description => PowerUpDescriptions.magnet();

  @override
  String get symbol => 'M';

  @override
  Color get color => const Color(0xFFFF00FF);

  @override
  void applyEffect(PlayerShip player) {
    final playerPosition = player.position;

    // Get all loot components in the game world
    final allLoot = gameRef.world.children.whereType<Loot>().toList();

    // Teleport all loot to the player position to trigger collection
    for (final loot in allLoot) {
      // Create a visual effect for each loot being attracted
      final lootEffect = LootAttractionEffect(
        startPosition: loot.position.clone(),
        endPosition: playerPosition.clone(),
        lootSize: loot.size.clone(),
      );
      gameRef.world.add(lootEffect);

      // Teleport the loot to the player to trigger collection
      loot.position.setFrom(playerPosition);
    }
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final magnetSize = radius * 0.6;

    // Draw U-shaped magnet
    final magnetPath = Path();

    // Left vertical bar
    final leftTop = Offset(center.dx - magnetSize * 0.5, center.dy - magnetSize * 0.6);
    final leftBottom = Offset(center.dx - magnetSize * 0.5, center.dy + magnetSize * 0.4);

    // Right vertical bar
    final rightTop = Offset(center.dx + magnetSize * 0.5, center.dy - magnetSize * 0.6);
    final rightBottom = Offset(center.dx + magnetSize * 0.5, center.dy + magnetSize * 0.4);

    // Draw left bar
    magnetPath.moveTo(leftTop.dx, leftTop.dy);
    magnetPath.lineTo(leftBottom.dx, leftBottom.dy);

    // Draw bottom arc connecting left to right
    magnetPath.arcToPoint(
      rightBottom,
      radius: Radius.circular(magnetSize * 0.5),
      clockwise: false,
    );

    // Draw right bar
    magnetPath.lineTo(rightTop.dx, rightTop.dy);

    canvas.drawPath(magnetPath, iconPaint);

    // Add filled ends to make it look like a horseshoe magnet
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Left end (North pole - red in real magnets, but we use the power-up color)
    canvas.drawCircle(leftTop, 2.5, fillPaint);

    // Right end (South pole)
    canvas.drawCircle(rightTop, 2.5, fillPaint);

    // Draw attraction lines (field lines)
    final fieldLinePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw curved field lines between the poles
    final numFieldLines = 3;
    for (int i = 0; i < numFieldLines; i++) {
      final offsetY = (i + 1) * magnetSize * 0.15;

      final fieldPath = Path();
      fieldPath.moveTo(leftTop.dx, leftTop.dy - offsetY);

      // Arc from left pole to right pole
      fieldPath.quadraticBezierTo(
        center.dx,
        center.dy - magnetSize * 0.8 - offsetY * 0.5,
        rightTop.dx,
        rightTop.dy - offsetY,
      );

      canvas.drawPath(fieldPath, fieldLinePaint);
    }
  }
}

/// Visual effect for loot being attracted to the player
class LootAttractionEffect extends PositionComponent {
  final Vector2 startPosition;
  final Vector2 endPosition;
  final Vector2 lootSize;
  final double duration;

  double _elapsedTime = 0.0;
  Vector2 _currentPosition;
  double _opacity = 1.0;

  LootAttractionEffect({
    required this.startPosition,
    required this.endPosition,
    required this.lootSize,
    this.duration = 0.3, // 0.3 seconds
  })  : _currentPosition = startPosition.clone(),
        super(position: startPosition.clone(), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // Calculate progress (0 to 1)
    final progress = (_elapsedTime / duration).clamp(0.0, 1.0);

    // Interpolate position with ease-in effect (accelerates towards player)
    final easedProgress = _easeInCubic(progress);
    _currentPosition = startPosition + (endPosition - startPosition) * easedProgress;
    position.setFrom(_currentPosition);

    // Fade out as it approaches the player
    _opacity = 1.0 - progress * 0.5; // Fade to 50% opacity

    // Remove when animation completes
    if (_elapsedTime >= duration) {
      removeFromParent();
    }
  }

  /// Ease in cubic function for smooth acceleration
  double _easeInCubic(double t) {
    return t * t * t;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw loot trail effect
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withValues(alpha: _opacity)
      ..style = PaintingStyle.fill;

    final glow = Paint()
      ..color = const Color(0x4400FFFF).withValues(alpha: _opacity * 0.7)
      ..style = PaintingStyle.fill;

    final center = Offset.zero;
    final radius = lootSize.x / 2;

    canvas.drawCircle(center, radius + 3, glow);
    canvas.drawCircle(center, radius, paint);

    // Draw motion trail (line from current position towards player)
    final trailPaint = Paint()
      ..color = const Color(0xFFFF00FF).withValues(alpha: _opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final direction = (endPosition - _currentPosition).normalized();
    final trailLength = 15.0;
    final trailStart = Offset.zero;
    final trailEnd = Offset(-direction.x * trailLength, -direction.y * trailLength);

    canvas.drawLine(trailStart, trailEnd, trailPaint);
  }
}
