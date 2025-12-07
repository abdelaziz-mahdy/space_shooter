import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/position_util.dart';
import 'base_rendered_component.dart';
import 'enemies/base_enemy.dart';
import 'power_ups/bomb_power_up.dart';
import '../config/balance_config.dart';

/// Homing missile component
class Missile extends BaseRenderedComponent
    with CollisionCallbacks, HasVisualCenter {
  Vector2 direction;
  final double damage;
  final double speed;
  final double explosionRadius;
  final double explosionDamage;
  final double homingStrength;

  double lifetime = 0;
  static const double maxLifetime = 5.0; // 5 seconds before despawn
  static const double baseHomingStrength = 150.0; // Base turn rate

  PositionComponent? targetEnemy;

  Missile({
    required Vector2 position,
    required this.direction,
    required this.damage,
    required this.speed,
    this.explosionRadius = 40.0,
    this.explosionDamage = 0.8,
    this.homingStrength = baseHomingStrength, // Use base by default
  }) : super(position: position, size: Vector2(12, 6));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Rectangular hitbox for missile shape
    add(RectangleHitbox());
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

    // Find nearest enemy to home in on
    _findNearestEnemy();

    // Apply homing behavior
    if (targetEnemy != null) {
      _applyHoming(dt);
    }

    // Move missile
    position += direction * speed * dt;

    // Rotate missile to face direction of travel
    angle = atan2(direction.y, direction.x);

    lifetime += dt;

    // Remove after lifetime expires
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  void _findNearestEnemy() {
    PositionComponent? nearest;
    double nearestDistance = double.infinity;

    // Use cached active enemies list instead of querying world children
    for (final enemy in game.activeEnemies) {
      final distance = PositionUtil.getDistance(this, enemy);
      if (distance < nearestDistance && distance <= 400) {
        // 400px homing range
        nearestDistance = distance;
        nearest = enemy;
      }
    }

    targetEnemy = nearest;
  }

  void _applyHoming(double dt) {
    if (targetEnemy == null) return;

    // Calculate direction to target
    final toTarget = PositionUtil.getDirectionTo(this, targetEnemy!);

    // Smoothly turn towards target
    // Scale by dt and factor for consistent turn rate with bullets
    final turnRate = (homingStrength * dt * 0.01).clamp(0.0, 1.0); // Clamp to prevent overshooting
    direction = (direction + (toTarget * turnRate)).normalized();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Handle enemy collisions
    if (other is BaseEnemy) {
      // Direct hit damage
      other.takeDamage(damage);

      // Explosion damage to nearby enemies
      _explode();

      removeFromParent();
    }
  }

  void _explode() {
    // Find all enemies within explosion radius using cached active enemies
    // Consolidate damage: only damage if no nearby missile explosion was just handled
    final nearbyMissileExplosion = _findNearbyMissileExplosion(position);

    if (nearbyMissileExplosion == null) {
      // Only apply damage if this is the first/primary explosion
      // Subsequent merged explosions won't re-apply damage
      for (final enemy in game.activeEnemies) {
        final distance = PositionUtil.getDistance(this, enemy);
        if (distance <= explosionRadius) {
          // Apply explosion damage
          final damageAmount = damage * explosionDamage;
          enemy.takeDamage(damageAmount);
        }
      }
    }

    // Create visual bomb explosion effect
    // Check for nearby bomb effects to merge with instead of creating new ones
    final nearbyBombEffect = _findNearbyBombEffect(position);

    if (nearbyBombEffect != null) {
      // Merge: expand existing effect instead of creating a new one
      nearbyBombEffect.mergeWith(explosionRadius);
    } else {
      // No nearby effect, create new visual wave effect
      final waveEffect = BombWaveEffect(
        position: position.clone(),
        maxRadius: explosionRadius,
      );
      game.world.add(waveEffect);
    }
  }

  /// Find a nearby missile that just exploded to avoid duplicate damage
  BombWaveEffect? _findNearbyMissileExplosion(Vector2 position) {
    final allEffects = game.world.children.whereType<BombWaveEffect>();

    for (final effect in allEffects) {
      final distance = position.distanceTo(effect.position);
      // If effect is very close and just started (young), it's from a recent missile hit
      if (distance <= explosionRadius * 1.5) {
        return effect;
      }
    }
    return null;
  }

  /// Find a nearby bomb effect to merge with
  BombWaveEffect? _findNearbyBombEffect(Vector2 position) {
    final allEffects = game.world.children.whereType<BombWaveEffect>();

    for (final effect in allEffects) {
      final distance = position.distanceTo(effect.position);
      if (distance <= BalanceConfig.effectMergeRadius) {
        return effect;
      }
    }
    return null;
  }

  @override
  void renderShape(Canvas canvas) {
    // Draw missile body (red/orange rocket)
    final bodyPaint = Paint()
      ..color = const Color(0xFFFF4500)
      ..style = PaintingStyle.fill;

    // Missile body (elongated rectangle)
    final bodyRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(bodyRect, bodyPaint);

    // Missile tip (white)
    final tipPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final tipPath = Path()
      ..moveTo(size.x, size.y / 2) // Right middle
      ..lineTo(size.x + 4, size.y / 2 - 3) // Tip top
      ..lineTo(size.x + 4, size.y / 2 + 3) // Tip bottom
      ..close();
    canvas.drawPath(tipPath, tipPaint);

    // Exhaust trail (yellow/orange glow)
    final exhaustPaint = Paint()
      ..color = const Color(0xFFFFAA00).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final exhaustRect = Rect.fromCenter(
      center: Offset(-2, size.y / 2),
      width: 6,
      height: 4,
    );
    canvas.drawOval(exhaustRect, exhaustPaint);
  }
}
