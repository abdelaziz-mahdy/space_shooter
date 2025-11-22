import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// Ranger Enemy: Ranged shooter, keeps distance
/// - Star shape (5 points), orange, size 22x22
/// - Health: 35 + (wave * 2.5), Speed: 45 + (wave * 1.5)
/// - Maintains 250-400 unit distance from player
/// - Shoots enemy bullets every 2 seconds
/// - Flees if player within 150 units
class RangerEnemy extends BaseEnemy {
  static const String ID = 'ranger';
  static const double minDistance = 250;
  static const double maxDistance = 400;
  static const double fleeDistance = 150;
  static const double shootInterval = 2.0;
  static const double bulletSpeed = 200;
  static const double bulletDamage = 15;

  double shootTimer = 0;

  RangerEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 35 + (wave * 2.5),
          speed: 56.25 + (wave * 1.875), // Increased from 45 + (wave * 1.5) (25% increase)
          lootValue: 2,
          color: const Color(0xFFFF8800), // Orange
          size: Vector2(22, 22) * scale,
          contactDamage: 12.0,
        );

  @override
  Future<void> addHitbox() async {
    // Star shape (5 points) hitbox
    final sides = 5;
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      points.add(Vector2(
        centerX + cos(angle) * size.x / 2,
        centerY + sin(angle) * size.y / 2,
      ));
    }

    add(PolygonHitbox(points));
  }

  @override
  void updateMovement(double dt) {
    final distanceToPlayer = PositionUtil.getDistance(this, player);
    final direction = PositionUtil.getDirectionTo(this, player);

    // Movement behavior based on distance
    if (distanceToPlayer < fleeDistance) {
      // Too close - flee away from player
      position += direction * -speed * dt;
    } else if (distanceToPlayer < minDistance) {
      // Too close to ideal range - back away slowly
      position += direction * -speed * 0.5 * dt;
    } else if (distanceToPlayer > maxDistance) {
      // Too far - move closer
      position += direction * getEffectiveSpeed() * dt;
    } else {
      // In ideal range - strafe around player
      final perpendicular = Vector2(-direction.y, direction.x);
      position += perpendicular * getEffectiveSpeed() * 0.7 * dt;
    }

    // Rotate to face player
    angle = atan2(direction.y, direction.x) + pi / 2;

    // Handle shooting
    shootTimer += dt;
    if (shootTimer >= shootInterval && distanceToPlayer <= maxDistance) {
      shoot();
      shootTimer = 0;
    }
  }

  void shoot() {
    // Shoot bullet towards player
    final direction = PositionUtil.getDirectionTo(this, player);

    final bullet = EnemyBullet(
      position: position.clone(),
      direction: direction,
      damage: bulletDamage,
      speed: bulletSpeed,
    );

    gameRef.world.add(bullet);
    print('[RangerEnemy] Fired bullet at player');
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw 5-pointed star from top-left coordinate system
    final sides = 5;
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = centerX + cos(angle) * size.x / 2;
      final y = centerY + sin(angle) * size.y / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw shoot indicator (charging effect)
    if (shootTimer > shootInterval * 0.8) {
      final chargePaint = Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + 3,
        chargePaint,
      );
    }

    // Draw health bar
    // Draw freeze effect if frozen
    renderFreezeEffect(canvas);
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return RangerEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Introduced from wave 4 onwards
    if (wave < 4) return 0.0;
    return 1.5 + (wave * 0.1);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
