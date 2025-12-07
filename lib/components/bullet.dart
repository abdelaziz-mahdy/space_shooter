import 'dart:ui';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../utils/visual_center_mixin.dart';
import '../utils/targeting_system.dart';
import '../config/balance_config.dart';
import 'base_rendered_component.dart';
import 'enemies/base_enemy.dart';
import 'damage_number.dart'; // Still needed for healing numbers
import '../game/space_shooter_game.dart';

enum BulletType {
  standard,
  plasma,
  missile,
}

class Bullet extends BaseRenderedComponent with CollisionCallbacks, HasVisualCenter {
  Vector2 direction; // Changed from final to allow homing modification
  final double baseDamage;
  final double speed;
  final Color baseColor;
  final BulletType bulletType;
  final int pierceCount;
  final double homingStrength; // Homing tracking strength

  // Critical hit mechanics
  late bool isCrit;
  late double actualDamage;

  // Visual properties
  late Color color;
  late Vector2 renderSize;

  double lifetime = 0;
  static const double maxLifetime = 3.0; // 3 seconds before despawn
  int enemiesHit = 0; // Track how many enemies this bullet has hit

  final bool? forceCrit; // Optional: force crit on/off for multi-shot consistency

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
    this.forceCrit, // If provided, use this instead of rolling
  }) : super(position: position, size: customSize ?? Vector2(8, 8));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Calculate critical hit AFTER component is added to tree (game available)
    final player = game.player;
    // Use forceCrit if provided (for multi-shot consistency), otherwise roll
    isCrit = forceCrit ?? (Random().nextDouble() < player.critChance);
    actualDamage = isCrit ? baseDamage * player.critDamage : baseDamage;

    // Visual indicator for crits (larger and orange-red)
    if (isCrit) {
      color = const Color(0xFFFF4500); // Orange-red for crits
      renderSize = size * 1.5;
    } else {
      color = baseColor;
      renderSize = size.clone();
    }

    add(CircleHitbox(anchor: Anchor.center));
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  @override
  void update(double dt) {
    super.update(dt);

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
      final player = game.player;

      // Play hit sound effect
      game.audioManager.playHit();

      // Deal damage to the hit enemy (damage number is shown by base_enemy.takeDamage)
      // Note: Berserk multiplier already applied in weapon.getDamage()
      other.takeDamage(actualDamage, isCrit: isCrit);

      // Apply freeze effect (only BaseEnemy has freeze)
      if (player.freezeChance > 0 && Random().nextDouble() < player.freezeChance) {
        if (other is BaseEnemy) {
          other.applyFreeze(2.0); // 2 seconds freeze
        }
      }

      // Chain Lightning - jump to nearby enemies
      // Only trigger chain if enemy actually took damage (not invulnerable)
      if (player.chainCount > 0 && other.modifyIncomingDamage(actualDamage) > 0) {
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
        game.world.add(healNumber);
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
    final player = game.player;
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

    // Check for nearby explosion effects to merge with instead of creating new ones
    final nearbyExplosion = _findNearbyExplosionEffect(position);

    if (nearbyExplosion != null) {
      // Merge: expand existing effect instead of creating a new one
      nearbyExplosion.mergeWith(player.explosionRadius);
    } else {
      // No nearby effect, create new visual effect
      final explosion = ExplosionEffect(
        position: position.clone(),
        radius: player.explosionRadius,
      );
      game.world.add(explosion);
    }
  }

  /// Find a nearby explosion effect to merge with
  ExplosionEffect? _findNearbyExplosionEffect(Vector2 position) {
    final allEffects = game.world.children.whereType<ExplosionEffect>();

    for (final effect in allEffects) {
      final distance = position.distanceTo(effect.position);
      if (distance <= BalanceConfig.effectMergeRadius) {
        return effect;
      }
    }
    return null;
  }

  /// Find nearest enemies using centralized targeting system
  List<BaseEnemy> _findNearestEnemies({
    required Vector2 fromPosition,
    BaseEnemy? excludeEnemy,
    double? maxDistance,
    int? maxCount,
  }) {
    return TargetingSystem.findNearestEnemies(
      game: game,
      fromPosition: fromPosition,
      maxDistance: maxDistance,
      maxCount: maxCount,
      excludeEnemy: excludeEnemy,
      onlyTargetable: true,
    );
  }

  /// Generic helper to deal damage to an enemy with visual effects
  void _damageEnemy(BaseEnemy enemy, double damage, {bool isCrit = false}) {
    // Damage number is shown automatically by base_enemy.takeDamage
    enemy.takeDamage(damage, isCrit: isCrit);
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
      game.world.add(lightning);

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
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 1.5, glowPaint);
    }
  }
}

/// Visual explosion effect
class ExplosionEffect extends BaseGameComponent {
  double radius;
  double lifetime = 0;
  static const double maxLifetime = 0.3; // Short duration
  int mergeCount = 1; // Track how many explosions merged into this one

  ExplosionEffect({
    required Vector2 position,
    required this.radius,
  }) : super(position: position, size: Vector2.all(radius * 2), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    lifetime += dt;

    if (lifetime >= maxLifetime) {
      removeFromParent();
    }
  }

  /// Merge with another explosion - expand radius instead of creating new effect
  void mergeWith(double newRadius) {
    mergeCount++; // Track merge count for visual feedback

    // Expand the radius if the incoming explosion is larger
    if (newRadius > radius) {
      radius = newRadius;
    }

    // Reset lifetime to show effect longer when merging
    lifetime = 0;
  }

  /// Get color based on merge count for visual feedback
  Color _getColorForMergeCount() {
    // Colors progress from orange → red → white as more explosions merge
    // White indicates massive bullet explosion cluster
    if (mergeCount <= 1) {
      return const Color(0xFFFF6600); // Orange - single explosion
    } else if (mergeCount <= 3) {
      return const Color(0xFFFF4400); // Dark orange - 2-3 merges
    } else if (mergeCount <= 5) {
      return const Color(0xFFFF2200); // Red - 4-5 merges
    } else if (mergeCount <= 8) {
      return const Color(0xFFFF0000); // Bright red - 6-8 merges
    } else {
      return const Color(0xFFFFFFFF); // White - 9+ merges (extreme!)
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = lifetime / maxLifetime;
    final currentRadius = radius; // Match visual to damage radius
    final alpha = (1 - progress) * 0.6;

    final baseColor = _getColorForMergeCount();
    final paint = Paint()
      ..color = baseColor.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      currentRadius,
      paint,
    );

    // Draw merge count indicator rings if merged
    if (mergeCount > 1) {
      final indicatorPaint = Paint()
        ..color = baseColor.withValues(alpha: alpha * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Draw count indicator rings (1 ring per merge)
      for (int i = 1; i <= mergeCount && i <= 5; i++) {
        final ringRadius = currentRadius * (0.6 + (i * 0.08));
        canvas.drawCircle(
          Offset(size.x / 2, size.y / 2),
          ringRadius,
          indicatorPaint,
        );
      }
    }
  }
}

/// Visual lightning effect for chain lightning
class LightningEffect extends BaseGameComponent {
  final Vector2 startPos;
  final Vector2 endPos;
  double lifetime = 0;
  static const double maxLifetime = 0.2; // Very brief flash
  final List<Vector2> _segments = [];
  final Random _random = Random();

  LightningEffect({
    required this.startPos,
    required this.endPos,
  }) : super(position: startPos.clone(), anchor: Anchor.center) {
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
      ..color = const Color(0xFF00FFFF).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Glow effect (wider, more transparent)
    final glowPaint = Paint()
      ..color = const Color(0xFF88FFFF).withValues(alpha: alpha * 0.5)
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
