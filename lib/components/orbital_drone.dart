import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../game/space_shooter_game.dart';
import 'bullet.dart';
import 'player_ship.dart';

/// Orbital drone that circles the player and shoots at enemies
class OrbitalDrone extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final PlayerShip player;
  final int index; // Which orbital this is (0, 1, 2, etc.)
  final int totalOrbitals; // Total number of orbitals

  double angle = 0;
  double orbitRadius = 60.0;
  double rotationSpeed = 2.0; // Radians per second
  double shootTimer = 0;
  double shootInterval = 1.5; // Seconds between shots

  OrbitalDrone({
    required this.player,
    required this.index,
    required this.totalOrbitals,
  }) : super(
          size: Vector2.all(16),
          anchor: Anchor.center,
        ) {
    // Evenly space orbitals around the player
    angle = (index / totalOrbitals) * 2 * pi;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add collision detection
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Rotate around the player
    angle += rotationSpeed * dt;
    if (angle > 2 * pi) {
      angle -= 2 * pi;
    }

    // Calculate position relative to player
    position = player.position +
        Vector2(
          cos(angle) * orbitRadius,
          sin(angle) * orbitRadius,
        );

    // Shoot at nearby enemies
    shootTimer += dt;
    if (shootTimer >= shootInterval) {
      shootTimer = 0;
      _shootAtNearestEnemy();
    }
  }

  void _shootAtNearestEnemy() {
    // Find nearest enemy within range
    const double shootRange = 300.0;
    PositionComponent? nearestEnemy;
    double nearestDistance = shootRange;

    for (final component in gameRef.world.children) {
      // Only check PositionComponents that are enemies (not managers or other components)
      if (component is PositionComponent &&
          component.runtimeType.toString().contains('Enemy')) {
        final distance = position.distanceTo(component.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = component;
        }
      }
    }

    // Shoot at nearest enemy if found
    if (nearestEnemy != null) {
      final direction = (nearestEnemy.position - position).normalized();
      final bullet = Bullet(
        position: position.clone(),
        direction: direction,
        baseDamage: player.damage * 0.5, // Orbitals do 50% player damage
        speed: 400,
        homingStrength: player.homingStrength,
      );
      gameRef.world.add(bullet);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw orbital drone as a glowing circle
    final paint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Glow effect
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 4,
      glowPaint,
    );

    // Main body
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      paint,
    );

    // Core
    final corePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 4,
      corePaint,
    );
  }
}
