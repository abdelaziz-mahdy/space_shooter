import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import 'base_enemy.dart';
import '../player_ship.dart';

/// Scout Enemy: Fast, fragile, zigzag movement
/// - Diamond shape, cyan color, size 15x15
/// - Health: 10 + (wave * 1), Speed: 120 + (wave * 3)
/// - Zigzag movement pattern using sine wave
/// - Flees when health < 30%, commits to kamikaze attack when too far
class ScoutEnemy extends BaseEnemy {
  static const String ID = 'scout';
  double movementTimer = 0;
  bool isFleeing = false;
  bool isCommittedToAttack = false; // Once fled too far, commit to kamikaze attack

  ScoutEnemy({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 10 + (wave * 1.0),
          speed: 150 + (wave * 3.75), // Increased from 120 + (wave * 3.0) (25% increase)
          lootValue: 1,
          color: const Color(0xFF00FFFF), // Cyan
          size: Vector2(15, 15) * scale,
          contactDamage: 8.0,
        );

  @override
  Future<void> addHitbox() async {
    // Diamond shape hitbox
    final w = size.x;
    final h = size.y;

    add(
      PolygonHitbox([
        Vector2(w / 2, 0), // Top
        Vector2(w, h / 2), // Right
        Vector2(w / 2, h), // Bottom
        Vector2(0, h / 2), // Left
      ]),
    );
  }

  @override
  void updateMovement(double dt) {
    movementTimer += dt;

    // Check distance from player
    final distanceFromPlayer = PositionUtil.getDistance(this, player);

    // Max distance to flee before committing to kamikaze attack
    const maxFleeDistance = 600.0;

    // Once committed to attack, never flee again - kamikaze mode
    if (isCommittedToAttack) {
      // Aggressive straight-line attack towards player with speed boost
      final direction = PositionUtil.getDirectionTo(this, player);
      position += direction * getEffectiveSpeed() * 1.3 * dt;
      angle = atan2(direction.y, direction.x) + pi / 4;
      return;
    }

    // Check if fleeing scout has gone too far - commit to kamikaze attack
    if (isFleeing && distanceFromPlayer > maxFleeDistance) {
      isFleeing = false;
      isCommittedToAttack = true;
      return;
    }

    // Check if should flee (health < 30%)
    final shouldFlee = health < maxHealth * 0.3;

    if (shouldFlee && !isFleeing) {
      // Start fleeing
      isFleeing = true;
    } else if (!shouldFlee && isFleeing) {
      // Health recovered, stop fleeing
      isFleeing = false;
    }

    if (isFleeing) {
      // Flee away from player
      final direction = PositionUtil.getDirectionTo(player, this);
      position += direction * getEffectiveSpeed() * dt;
      angle = atan2(direction.y, direction.x) + pi / 4;
    } else {
      // Normal zigzag movement towards player
      final baseDirection = PositionUtil.getDirectionTo(this, player);
      final perpendicular = Vector2(-baseDirection.y, baseDirection.x);
      final zigzagOffset = sin(movementTimer * 5) * 0.5;

      final movement = baseDirection + (perpendicular * zigzagOffset);
      position += movement.normalized() * getEffectiveSpeed() * dt;
      angle = atan2(baseDirection.y, baseDirection.x) + pi / 4;
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw diamond shape from top-left coordinate system
    final w = size.x;
    final h = size.y;

    final path = Path()
      ..moveTo(w / 2, 0) // Top
      ..lineTo(w, h / 2) // Right
      ..lineTo(w / 2, h) // Bottom
      ..lineTo(0, h / 2) // Left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw health bar
    // Draw freeze effect if frozen
    renderFreezeEffect(canvas);
    renderHealthBar(canvas);

    // Draw state indicator
    if (isCommittedToAttack) {
      // Red pulsing circle when committed to attack (kamikaze mode)
      final attackPaint = Paint()
        ..color = const Color(0xFFFF0000).withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + 3,
        attackPaint,
      );
    } else if (isFleeing) {
      // Yellow circle when fleeing
      final warningPaint = Paint()
        ..color = const Color(0xFFFFFF00).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + 2,
        warningPaint,
      );
    }
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return ScoutEnemy(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Introduced from wave 2 onwards
    if (wave < 2) return 0.0;
    return 2.0 + (wave * 0.1);
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
