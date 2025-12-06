import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';
import '../player_ship.dart';
import '../enemies/base_enemy.dart';
import 'base_power_up.dart';
import '../../utils/value_with_description.dart';

/// Bomb Power-Up - Destroys all enemies in range
class BombPowerUp extends BasePowerUp {
  static final _config = ValueWithDescription<double>(
    value: 350.0,
    descriptionBuilder: PowerUpDescriptions.bomb,
  );

  BombPowerUp({required Vector2 position}) : super(position: position);

  @override
  String get description => _config.description;

  @override
  String get symbol => 'B';

  @override
  Color get color => const Color(0xFFFF00FF);

  @override
  void applyEffect(PlayerShip player) {
    final playerPosition = player.position;
    final bombRange = _config.value;

    // Use cached active enemies list instead of querying world children
    final allEnemies = gameRef.activeEnemies;

    int enemiesDamaged = 0;

    // Deal damage to all enemies in range
    for (final enemy in allEnemies) {
      final distance = playerPosition.distanceTo(enemy.position);
      if (distance <= bombRange) {
        // Check if enemy is a boss (health > 500 is a simple heuristic for boss detection)
        final isBoss = enemy.maxHealth > 500;
        final bombDamage = isBoss
            ? enemy.maxHealth * 0.15  // Bosses: 15% of max health
            : enemy.maxHealth;         // Normal enemies: one-shot kill

        enemy.takeDamage(bombDamage);
        enemiesDamaged++;
      }
    }

    // Create visual wave effect with same radius as damage range
    final waveEffect = BombWaveEffect(
      position: playerPosition.clone(),
      maxRadius: bombRange,
    );
    gameRef.world.add(waveEffect);

    print('[PowerUp] Bomb activated: $enemiesDamaged/${allEnemies.length} enemies damaged (within ${bombRange.toInt()}px)');
  }

  @override
  void renderIcon(Canvas canvas, Offset center, double radius) {
    final iconPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final burstSize = radius * 0.6;
    final numRays = 8;

    // Draw explosion/starburst rays
    for (int i = 0; i < numRays; i++) {
      final angle = (i * 2 * math.pi) / numRays;

      // Inner point (short)
      final innerRadius = burstSize * 0.3;
      final innerX = center.dx + innerRadius * math.cos(angle);
      final innerY = center.dy + innerRadius * math.sin(angle);

      // Outer point (long)
      final outerRadius = burstSize;
      final outerX = center.dx + outerRadius * math.cos(angle);
      final outerY = center.dy + outerRadius * math.sin(angle);

      // Draw ray
      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        iconPaint,
      );
    }

    // Draw center circle
    final centerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      center,
      burstSize * 0.25,
      centerPaint,
    );

    // Draw center circle border
    final centerBorderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      center,
      burstSize * 0.25,
      centerBorderPaint,
    );
  }
}

/// Visual effect for bomb power-up - expanding circular wave
class BombWaveEffect extends PositionComponent {
  final double maxRadius;
  final double duration;

  double _elapsedTime = 0.0;
  double _currentRadius = 0.0;
  double _opacity = 1.0;

  BombWaveEffect({
    required Vector2 position,
    this.maxRadius = 400.0,
    this.duration = 0.75, // 0.75 seconds
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;

    // Calculate progress (0 to 1)
    final progress = (_elapsedTime / duration).clamp(0.0, 1.0);

    // Expand radius - use easeOut for smooth expansion
    _currentRadius = maxRadius * _easeOutCubic(progress);

    // Fade out - faster fade at the end
    _opacity = (1.0 - progress);

    // Remove when animation completes
    if (_elapsedTime >= duration) {
      removeFromParent();
    }
  }

  /// Ease out cubic function for smooth deceleration
  double _easeOutCubic(double t) {
    final t1 = t - 1.0;
    return t1 * t1 * t1 + 1.0;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw expanding ring/wave effect with cyan/blue color
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(_opacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    // Draw outer wave
    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      paint,
    );

    // Draw inner wave (slightly smaller, for depth effect)
    final innerPaint = Paint()
      ..color = const Color(0xFF00AAFF).withOpacity(_opacity * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(
      Offset.zero,
      _currentRadius - 10,
      innerPaint,
    );

    // Draw fill with gradient effect (very transparent)
    final fillPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(_opacity * 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      fillPaint,
    );
  }
}
