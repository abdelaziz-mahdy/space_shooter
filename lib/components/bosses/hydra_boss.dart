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

    // Spawn 3 cores
    _spawnAllCores();
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
    cores.removeWhere((core) => !core.isMounted);
    return cores.length;
  }

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

    // Check if all cores destroyed
    if (aliveCoresCount == 0 && !isVulnerable) {
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
        print('[HydraBoss] Vulnerability window ended, regenerating cores');
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
    print('[HydraBoss] All cores destroyed! Vulnerable for ${vulnerabilityDuration}s');
  }

  void _spawnAllCores() {
    for (int i = 0; i < totalCores; i++) {
      _spawnCore(i, 1.0);
    }
  }

  void _spawnCore(int index, double healthPercent) {
    final core = _HydraCore(
      parent: this,
      coreIndex: index,
      healthPercent: healthPercent,
    );

    cores.add(core);
    add(core);

    print('[HydraBoss] Spawned core $index (${cores.length}/$totalCores)');
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
        ..color = const Color(0xFFFF0000).withOpacity(0.6)
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
        ..color = const Color(0xFF8A2BE2).withOpacity(0.3)
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

    // Draw freeze effect and health bar
    renderFreezeEffect(canvas);
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
class _HydraCore extends PositionComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  final HydraBoss parent;
  final int coreIndex;
  final double healthPercent;

  double health = 0;
  double maxHealth = 0;
  double fireTimer = 0;

  _HydraCore({
    required this.parent,
    required this.coreIndex,
    required this.healthPercent,
  }) : super(
          size: Vector2(35, 35),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Calculate health based on wave
    maxHealth = 150 + (parent.wave * 25);
    health = maxHealth * healthPercent;

    // Add hitbox
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (gameRef.isPaused) return;

    // Update position to orbit around parent
    final baseAngle = (coreIndex * 2 * pi / HydraBoss.totalCores);
    final angle = baseAngle + parent.orbitAngle;

    // Vary orbit radius slightly for visual interest
    final radiusVariation = sin(parent.orbitAngle * 2) * 50;
    final orbitRadius = HydraBoss.coreMinOrbitRadius + radiusVariation;

    final offset = Vector2(
      cos(angle) * orbitRadius,
      sin(angle) * orbitRadius,
    );

    position = offset;

    // Fire bullets
    fireTimer += dt;
    if (fireTimer >= HydraBoss.coreFireInterval) {
      _fireBullet();
      fireTimer = 0;
    }
  }

  void _fireBullet() {
    // Fire toward player
    final coreWorldPos = parent.position + position;
    final directionToPlayer = (parent.player.position - coreWorldPos).normalized();

    final bullet = EnemyBullet(
      position: coreWorldPos,
      direction: directionToPlayer,
      damage: 18.0,
      speed: 160.0,
    );

    gameRef.world.add(bullet);
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      removeFromParent();
      print('[HydraCore] Core $coreIndex destroyed!');
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // Damage player on contact
    if (other is PlayerShip) {
      other.takeDamage(25.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 2;

    // Draw core body
    final corePaint = Paint()
      ..color = const Color(0xFF8A2BE2) // Violet
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      corePaint,
    );

    // Draw energy glow
    final glowPaint = Paint()
      ..color = const Color(0xFF9370DB).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 3,
      glowPaint,
    );

    // Draw health bar
    final healthBarWidth = size.x;
    final healthBarHeight = 2.0;
    final healthBarY = -2.0;

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(0, healthBarY, healthBarWidth, healthBarHeight),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()..color = const Color(0xFF00FF00);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }
}
