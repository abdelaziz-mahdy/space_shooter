import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../../game/space_shooter_game.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';
import '../damage_number.dart';

/// The Hydra Boss - Wave 45
/// - Central hexagon (70x70) + 3 orbiting cores (35x35 each)
/// - Dark purple (#4B0082) center, violet (#8A2BE2) cores
/// - Central: 300 + (wave * 50) HP
/// - Each core: 150 + (wave * 25) HP
/// - Speed: 42 + (wave * 0.8)
/// - Contact damage: 35 (central), 25 (cores)
/// - Loot: 50
///
/// Mechanics:
/// - Central core moves toward player
/// - 3 cores orbit around center (120° apart, 150-250px radius)
/// - Each core fires independently
/// - Central core invulnerable while ANY core is alive
/// - Must destroy all 3 cores for 20s damage window on central
/// - After 20s, cores regenerate (one every 5s) at 75% health
/// - Cores can be destroyed in any order
class HydraBoss extends BaseEnemy {
  static const String ID = 'hydra_boss';

  // Core constants
  static const int totalCores = 3;
  static const double coreMinOrbitRadius = 150.0;
  static const double coreMaxOrbitRadius = 250.0;
  static const double coreOrbitSpeed = 1.0; // radians per second
  static const double coreFireInterval = 1.2;

  // Vulnerability window constants
  static const double vulnerabilityDuration = 20.0;
  static const double coreRegenInterval = 5.0;

  // State tracking
  final List<_HydraCore> cores = [];
  bool isVulnerable = false;
  double vulnerabilityTimer = 0;
  double coreRegenTimer = 0;
  int coresDestroyed = 0;
  double orbitAngle = 0;
  bool _coresInitialized = false; // Prevent vulnerability check until cores are ready

  HydraBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 300 + (wave * 50),
          speed: 42 + (wave * 0.8),
          lootValue: 50,
          color: const Color(0xFF4B0082), // Dark purple
          size: Vector2(70, 70) * scale,
          contactDamage: 35.0,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onMount() {
    super.onMount();

    // Spawn cores after the boss is fully mounted and positioned
    _spawnAllCores();

    // Mark cores as initialized after spawning
    // (they'll mount asynchronously but we can start checking them now)
    Future.delayed(Duration.zero, () {
      _coresInitialized = true;
    });
  }

  @override
  Future<void> addHitbox() async {
    // Hexagon hitbox
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - pi / 2;
      points.add(Vector2(
        centerX + cos(angle) * radius,
        centerY + sin(angle) * radius,
      ));
    }

    add(PolygonHitbox(points));
  }

  int get aliveCoresCount {
    // Only remove cores that were mounted and then removed (died)
    // Don't remove cores that haven't mounted yet (just spawned)
    cores.removeWhere((core) => core.isRemoved);
    return cores.length;
  }

  @override
  bool get isTargetable => aliveCoresCount == 0; // Only targetable when all cores destroyed

  @override
  double modifyIncomingDamage(double damage) {
    // Invulnerable while any core is alive
    if (aliveCoresCount > 0) {
      return 0.0;
    }

    // Vulnerable after all cores destroyed
    return damage;
  }

  @override
  void updateMovement(double dt) {
    // Update orbit angle
    orbitAngle += coreOrbitSpeed * dt;
    if (orbitAngle > 2 * pi) {
      orbitAngle -= 2 * pi;
    }

    // Check if all cores destroyed (only after cores are initialized)
    if (_coresInitialized && aliveCoresCount == 0 && !isVulnerable) {
      _startVulnerabilityWindow();
    }

    // Handle vulnerability window
    if (isVulnerable) {
      vulnerabilityTimer += dt;

      if (vulnerabilityTimer >= vulnerabilityDuration) {
        // End vulnerability, start regenerating cores
        isVulnerable = false;
        vulnerabilityTimer = 0;
        coresDestroyed = 0;
      }
    }

    // Handle core regeneration
    if (!isVulnerable && aliveCoresCount < totalCores) {
      coreRegenTimer += dt;

      if (coreRegenTimer >= coreRegenInterval) {
        _regenerateCore();
        coreRegenTimer = 0;
      }
    }

    // Move toward player
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    position += directionToPlayer * getEffectiveSpeed() * dt;

    // Face player
    angle = atan2(directionToPlayer.y, directionToPlayer.x);
  }

  void _startVulnerabilityWindow() {
    isVulnerable = true;
    vulnerabilityTimer = 0;
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Ignore collisions with own cores (they orbit around us)
    if (other is _HydraCore) {
      return;
    }

    // Ignore collisions with enemy bullets (we're an enemy)
    if (other is EnemyBullet) {
      return;
    }

    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void onDeath() {
    // Clean up any remaining cores when boss dies
    for (final core in cores) {
      if (core.isMounted) {
        core.removeFromParent();
      }
    }
    cores.clear();
  }

  void _spawnAllCores() {
    for (int i = 0; i < totalCores; i++) {
      _spawnCore(i, 1.0);
    }
  }

  void _spawnCore(int index, double healthPercent) {
    // Calculate initial orbital position (relative to parent)
    final baseAngle = (index * 2 * pi / HydraBoss.totalCores);
    final angle = baseAngle + orbitAngle;
    final orbitRadius = HydraBoss.coreMinOrbitRadius;

    // CRITICAL: Position RELATIVE to parent (boss center at 0,0)
    final initialPos = Vector2(
      cos(angle) * orbitRadius,
      sin(angle) * orbitRadius,
    );

    final core = _HydraCore(
      parent: this,
      coreIndex: index,
      healthPercent: healthPercent,
      initialPosition: initialPos,
    );

    cores.add(core);
    // CRITICAL: Add as CHILD of boss, not to world!
    // This makes the core position relative to boss, and hitbox follows automatically
    add(core);
  }

  void _regenerateCore() {
    final coresAlive = aliveCoresCount;
    if (coresAlive >= totalCores) return;

    // Find which core index is missing
    final existingIndices = cores.map((c) => c.coreIndex).toSet();
    for (int i = 0; i < totalCores; i++) {
      if (!existingIndices.contains(i)) {
        _spawnCore(i, 0.75); // Regenerate at 75% health
        break;
      }
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw hexagon
    final path = Path();
    final radius = size.x / 2;

    for (int i = 0; i < 6; i++) {
      final angle = (i * pi / 3) - pi / 2;
      final x = centerX + cos(angle) * radius;
      final y = centerY + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill with dark purple
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw outline
    final strokePaint = Paint()
      ..color = const Color(0xFF2F004F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, strokePaint);

    // Draw vulnerability indicator
    if (isVulnerable) {
      final vulnPaint = Paint()
        ..color = const Color(0xFFFF0000).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawPath(path, vulnPaint);

      // Draw timer arc
      final timerProgress = vulnerabilityTimer / vulnerabilityDuration;
      final timerPaint = Paint()
        ..color = const Color(0xFFFFFF00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius + 8),
        -pi / 2,
        2 * pi * timerProgress,
        false,
        timerPaint,
      );
    }

    // Draw invulnerability shield if cores are alive
    if (aliveCoresCount > 0) {
      final shieldPaint = Paint()
        ..color = const Color(0xFF8A2BE2).withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(centerX, centerY),
        radius + 5,
        shieldPaint,
      );
    }

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 12,
      bossPaint,
    );

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return HydraBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 45 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 45) return 100.0;
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Orbiting core component for the Hydra Boss
class _HydraCore extends BaseEnemy {
  final HydraBoss parent;
  final int coreIndex;

  double fireTimer = 0;

  _HydraCore({
    required this.parent,
    required this.coreIndex,
    required double healthPercent,
    Vector2? initialPosition, // Allow setting initial position
  }) : super(
          position: initialPosition ?? Vector2.zero(), // Use provided position or zero
          player: parent.player,
          wave: parent.wave,
          health: (150 + (parent.wave * 25)) * healthPercent,
          speed: 0, // Cores don't move independently
          lootValue: 0, // No loot from individual cores
          color: const Color(0xFF8A2BE2), // Violet
          size: Vector2(35, 35),
          contactDamage: 25.0,
        );

  @override
  Future<void> addHitbox() async {
    // Use simple CircleHitbox with RELATIVE positioning
    add(CircleHitbox.relative(
      0.9, // 90% of component size
      parentSize: size,
    ));
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    // Ignore collisions with enemy bullets (cores are enemies, shouldn't take friendly fire)
    if (other is EnemyBullet) {
      return;
    }

    // Ignore collisions with parent boss (part of the same entity)
    if (other is HydraBoss) {
      return;
    }

    super.onCollisionStart(intersectionPoints, other);
  }

  @override
  void updateMovement(double dt) {
    // Update position to orbit around parent (cores are children of boss now)
    final baseAngle = (coreIndex * 2 * pi / HydraBoss.totalCores);
    final angle = baseAngle + parent.orbitAngle;

    // Vary orbit radius slightly for visual interest
    final radiusVariation = sin(parent.orbitAngle * 2) * 50;
    final orbitRadius = HydraBoss.coreMinOrbitRadius + radiusVariation;

    // CRITICAL: Position is now RELATIVE to parent (since cores are children)
    // No need to add parent.position - that's handled automatically by Flame!
    position = Vector2(
      cos(angle) * orbitRadius,
      sin(angle) * orbitRadius,
    );

    // Fire bullets
    fireTimer += dt;
    if (fireTimer >= HydraBoss.coreFireInterval) {
      _fireBullet();
      fireTimer = 0;
    }
  }

  void _fireBullet() {
    // Fire toward player (use absolutePosition since cores are children of boss)
    final coreWorldPos = absolutePosition;
    final directionToPlayer = (player.position - coreWorldPos).normalized();

    final bullet = EnemyBullet(
      position: coreWorldPos.clone(),
      direction: directionToPlayer,
      damage: 18.0,
      speed: 160.0,
    );

    game.world.add(bullet);
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    // ALWAYS show damage numbers for cores (disable rate limiting)
    // This helps players see hits more clearly
    final actualDamage = modifyIncomingDamage(damage);
    health -= actualDamage;

    if (showDamageNumber && actualDamage > 0) {
      final damageNumber = DamageNumber(
        position: absolutePosition.clone(), // Use absolute position for world-space damage number
        damage: actualDamage,
        isCrit: isCrit,
      );
      game.world.add(damageNumber);
    }

    // Apply bleed effect if player has bleed damage
    if (player.bleedDamage > 0) {
      applyBleed(player.bleedDamage);
    }

    if (health <= 0) {
      die();
    }
  }

  @override
  void die() {
    // Prevent double-death
    if (isDying) return;
    isDying = true;


    // Don't drop loot (parent boss handles loot)
    // Don't increment kill count (parent boss is the real enemy)
    // Just remove the core
    removeFromParent();
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 2;

    // Draw core body
    final corePaint = Paint()
      ..color = color // Use color from BaseEnemy
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      corePaint,
    );

    // Draw energy glow
    final glowPaint = Paint()
      ..color = const Color(0xFF9370DB).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 3,
      glowPaint,
    );


    // Draw status effects and health bar (provided by BaseEnemy)
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }
}
