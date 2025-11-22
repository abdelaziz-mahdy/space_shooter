import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/position_util.dart';
import 'base_rendered_component.dart';
import 'enemies/base_enemy.dart';
import 'damage_number.dart';
import '../game/space_shooter_game.dart';

enum BulletType {
  standard,
  plasma,
  missile,
}

class Bullet extends BaseRenderedComponent with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  Vector2 direction; // Changed from final to allow homing modification
  final double baseDamage;
  final double speed;
  final Color baseColor;
  final BulletType bulletType;
  final int pierceCount;
  final double homingStrength; // Homing tracking strength

  // Critical hit mechanics
  late final bool isCrit;
  late final double actualDamage;

  // Visual properties
  late final Color color;
  late final Vector2 renderSize;

  double lifetime = 0;
  static const double maxLifetime = 3.0; // 3 seconds before despawn
  int enemiesHit = 0; // Track how many enemies this bullet has hit

  Bullet({
    required Vector2 position,
    required this.direction,
    required this.baseDamage,
    required this.speed,
    this.baseColor = const Color(0xFFFFFF00), // Yellow default
    this.bulletType = BulletType.standard,
    this.pierceCount = 0,
    this.homingStrength = 0.0, // Default to no homing
    Vector2? customSize,
  }) : super(position: position, size: customSize ?? Vector2(8, 8)) {
    // Calculate critical hit in constructor
    final player = (findGame() as SpaceShooterGame?)?.player;
    if (player != null) {
      isCrit = Random().nextDouble() < player.critChance;
      actualDamage = isCrit ? baseDamage * player.critDamage : baseDamage;

      // Visual indicator for crits (larger and orange-red)
      if (isCrit) {
        color = const Color(0xFFFF4500); // Orange-red for crits
        renderSize = size * 1.5;
      } else {
        color = baseColor;
        renderSize = size.clone();
      }
    } else {
      isCrit = false;
      actualDamage = baseDamage;
      color = baseColor;
      renderSize = size.clone();
    }
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

    // Apply homing behavior if homingStrength > 0
    if (homingStrength > 0) {
      _applyHoming(dt);
    }

    position += direction * speed * dt;
    lifetime += dt;

    // Remove after lifetime expires (for infinite world)
    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  /// Apply homing/tracking behavior to the bullet
  void _applyHoming(double dt) {
    // Find nearest enemy within reasonable range
    const double homingRange = 400.0; // Bullets can track enemies up to 400px away

    final nearestEnemies = _findNearestEnemies(
      fromPosition: position,
      maxDistance: homingRange,
      maxCount: 1,
    );

    if (nearestEnemies.isEmpty) return; // No enemies in range to track

    final targetEnemy = nearestEnemies.first;

    // Calculate direction to target enemy
    final toTarget = targetEnemy.position - position;
    if (toTarget.length < 0.01) return; // Too close, avoid division by zero

    final targetDirection = toTarget.normalized();

    // Lerp current direction towards target direction
    // homingStrength controls how much the bullet can turn
    // Higher values = sharper turns, lower values = gentle curves
    final turnRate = homingStrength * dt * 3.0; // Scale by dt and a factor for smooth turning

    // Lerp the direction vector
    direction.x = direction.x + (targetDirection.x - direction.x) * turnRate;
    direction.y = direction.y + (targetDirection.y - direction.y) * turnRate;

    // Normalize to maintain consistent speed
    final length = direction.length;
    if (length > 0.01) {
      direction.normalize();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Handle enemy collisions
    if (other is BaseEnemy) {
      final player = gameRef.player;

      // Deal damage to the hit enemy
      other.takeDamage(actualDamage);

      // Spawn damage number at impact location
      final damageNumber = DamageNumber(
        position: other.position.clone(),
        damage: actualDamage,
        isCrit: isCrit,
      );
      gameRef.world.add(damageNumber);

      // Apply freeze effect (only BaseEnemy has freeze)
      if (player.freezeChance > 0 && Random().nextDouble() < player.freezeChance) {
        if (other is BaseEnemy) {
          other.applyFreeze(2.0); // 2 seconds freeze
        }
      }

      // Chain Lightning - jump to nearby enemies
      if (player.chainCount > 0) {
        _createChainLightning(other, player.chainCount);
      }

      // Lifesteal - heal player
      if (player.lifesteal > 0) {
        final healAmount = actualDamage * player.lifesteal;
        player.health = min(player.health + healAmount, player.maxHealth);

        // Show healing number on player
        final healNumber = DamageNumber(
          position: player.position.clone(),
          damage: healAmount,
          isHealing: true,
        );
        gameRef.world.add(healNumber);
      }

      // Explosion on hit - damage nearby enemies
      if (player.explosionRadius > 0) {
        _createExplosion(other);
      }

      enemiesHit++;

      // Only remove if pierce count is exceeded
      // Pierce allows hitting additional enemies beyond the first
      if (enemiesHit > pierceCount) {
        removeFromParent();
      }
    }
  }

  void _createExplosion(BaseEnemy hitEnemy) {
    final player = gameRef.player;
    final explosionDamage = actualDamage * 0.5; // 50% of bullet damage

    // Find all enemies within explosion radius (excluding the directly hit enemy)
    final enemiesInRange = _findNearestEnemies(
      fromPosition: position,
      excludeEnemy: hitEnemy,
      maxDistance: player.explosionRadius,
    );

    // Deal damage to all enemies in range
    for (final enemy in enemiesInRange) {
      _damageEnemy(enemy, explosionDamage, isCrit: false);
    }

    // Visual explosion effect (simple expanding circle)
    final explosion = ExplosionEffect(
      position: position.clone(),
      radius: player.explosionRadius,
    );
    gameRef.world.add(explosion);
  }

  /// Generic helper to find enemies sorted by distance from a position
  List<BaseEnemy> _findNearestEnemies({
    required Vector2 fromPosition,
    BaseEnemy? excludeEnemy,
    double? maxDistance,
    int? maxCount,
  }) {
    final allEnemies = gameRef.world.children.whereType<BaseEnemy>().toList();

    // Remove excluded enemy if specified
    if (excludeEnemy != null) {
      allEnemies.remove(excludeEnemy);
    }

    // Filter by distance if specified
    if (maxDistance != null) {
      allEnemies.removeWhere((enemy) {
        final distance = fromPosition.distanceTo(enemy.position);
        return distance > maxDistance;
      });
    }

    // Sort by distance
    allEnemies.sort((a, b) {
      final distA = fromPosition.distanceTo(a.position);
      final distB = fromPosition.distanceTo(b.position);
      return distA.compareTo(distB);
    });

    // Limit count if specified
    if (maxCount != null && allEnemies.length > maxCount) {
      return allEnemies.sublist(0, maxCount);
    }

    return allEnemies;
  }

  /// Generic helper to deal damage to an enemy with visual effects
  void _damageEnemy(BaseEnemy enemy, double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    enemy.takeDamage(damage);

    if (showDamageNumber) {
      final damageNumber = DamageNumber(
        position: enemy.position.clone(),
        damage: damage,
        isCrit: isCrit,
      );
      gameRef.world.add(damageNumber);
    }
  }

  void _createChainLightning(BaseEnemy hitEnemy, int maxChains) {
    const double chainRange = 200.0; // Lightning can jump up to 200px
    final chainDamage = actualDamage * 0.7; // 70% of original damage per chain

    BaseEnemy currentEnemy = hitEnemy;
    int chainedCount = 0;

    for (int i = 0; i < maxChains; i++) {
      // Find nearest enemies to the current enemy
      final nearestEnemies = _findNearestEnemies(
        fromPosition: currentEnemy.position,
        excludeEnemy: currentEnemy,
        maxDistance: chainRange,
        maxCount: 1,
      );

      if (nearestEnemies.isEmpty) break;

      final nextEnemy = nearestEnemies.first;

      // Deal damage to the chained enemy
      _damageEnemy(nextEnemy, chainDamage, isCrit: false);

      // Create visual lightning bolt effect
      final lightning = LightningEffect(
        startPos: currentEnemy.position.clone(),
        endPos: nextEnemy.position.clone(),
      );
      gameRef.world.add(lightning);

      currentEnemy = nextEnemy; // Next chain starts from this enemy
      chainedCount++;
    }

    if (chainedCount > 0) {
      print('[Bullet] Chain lightning hit $chainedCount enemies');
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw circle in the center of the bounding box (from top-left)
    final center = Offset(size.x / 2, size.y / 2);
    final radius = renderSize.x / 2;
    canvas.drawCircle(center, radius, paint);

    // Add glow effect for critical hits
    if (isCrit) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 1.5, glowPaint);
    }
  }
}

/// Visual explosion effect
class ExplosionEffect extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final double radius;
  double lifetime = 0;
  static const double maxLifetime = 0.3; // Short duration

  ExplosionEffect({
    required Vector2 position,
    required this.radius,
  }) : super(position: position, size: Vector2.all(radius * 2));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime += dt;

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = lifetime / maxLifetime;
    final currentRadius = radius * (1 + progress);
    final alpha = (1 - progress) * 0.6;

    final paint = Paint()
      ..color = const Color(0xFFFF6600).withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      currentRadius,
      paint,
    );
  }
}

/// Visual lightning effect for chain lightning
class LightningEffect extends PositionComponent with HasGameRef<SpaceShooterGame> {
  final Vector2 startPos;
  final Vector2 endPos;
  double lifetime = 0;
  static const double maxLifetime = 0.2; // Very brief flash
  final List<Vector2> _segments = [];
  final Random _random = Random();

  LightningEffect({
    required this.startPos,
    required this.endPos,
  }) : super(position: startPos.clone()) {
    anchor = Anchor.center;
    _generateLightningSegments();
  }

  void _generateLightningSegments() {
    // Generate jagged lightning bolt path
    _segments.clear();
    _segments.add(Vector2.zero()); // Start at origin (this component's position)

    final direction = endPos - startPos;
    final distance = direction.length;
    final steps = (distance / 30).ceil().clamp(2, 8); // Segments every ~30 pixels

    for (int i = 1; i < steps; i++) {
      final progress = i / steps;
      final basePoint = direction * progress;

      // Add random perpendicular offset for jagged effect
      final perpendicular = Vector2(-direction.y, direction.x).normalized();
      final offset = perpendicular * (_random.nextDouble() - 0.5) * 30;

      _segments.add(basePoint + offset);
    }

    _segments.add(direction); // End at target position (relative to start)
  }

  @override
  void update(double dt) {
    super.update(dt);
    lifetime += dt;

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = lifetime / maxLifetime;
    final alpha = (1 - progress).clamp(0.0, 1.0);

    // Main lightning bolt (bright cyan)
    final mainPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Glow effect (wider, more transparent)
    final glowPaint = Paint()
      ..color = const Color(0xFF88FFFF).withOpacity(alpha * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    // Draw lightning path
    final path = Path();
    if (_segments.isNotEmpty) {
      path.moveTo(_segments[0].x, _segments[0].y);
      for (int i = 1; i < _segments.length; i++) {
        path.lineTo(_segments[i].x, _segments[i].y);
      }
    }

    // Draw glow first (background)
    canvas.drawPath(path, glowPaint);
    // Draw main bolt on top
    canvas.drawPath(path, mainPaint);
  }
}
