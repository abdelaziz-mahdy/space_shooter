import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../../game/space_shooter_game.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// The Architect Boss - Wave 40
/// - Gear/cog shape (10 teeth)
/// - Gold (#FFD700) metallic
/// - Health: 520 + (wave * 72)
/// - Speed: 38 + (wave * 0.7)
/// - Contact damage: 33
/// - Loot: 48
///
/// Movement:
/// - Moves in geometric patterns (squares, triangles) - teleports to vertices
///
/// Attack:
/// - Creates geometric bullet formations (rotating patterns)
/// - Builds 3 destructible barriers (50 HP each) forming partial shield
/// - Barriers block player bullets but not movement
/// - Rebuilds barriers every 15 seconds
/// - Below 50% health: adds turrets to barriers
class ArchitectBoss extends BaseEnemy {
  static const String ID = 'architect_boss';

  // Pattern movement constants
  static const double patternRadius = 300.0;
  static const double teleportInterval = 3.0;
  static const double teleportDuration = 0.3;

  // Attack constants
  static const double geometricFireInterval = 2.0;
  static const double bulletSpeed = 160.0;
  static const double bulletDamage = 20.0;
  static const int rotatingBulletCount = 12;

  // Barrier constants
  static const int maxBarriers = 3;
  static const double barrierRebuildInterval = 15.0;
  static const double barrierOrbitRadius = 80.0;

  // State tracking
  int currentPatternIndex = 0;
  List<Vector2> currentPattern = [];
  int currentVertexIndex = 0;
  double teleportTimer = 0;
  bool isTeleporting = false;
  double teleportAnimTimer = 0;

  double geometricFireTimer = 0;
  double rotationAngle = 0;

  final List<_ArchitectBarrier> barriers = [];
  double barrierRebuildTimer = 0;

  // Pattern types
  static final List<List<Vector2>> patterns = [
    // Square pattern (4 vertices)
    [
      Vector2(-1, -1),
      Vector2(1, -1),
      Vector2(1, 1),
      Vector2(-1, 1),
    ],
    // Triangle pattern (3 vertices)
    [
      Vector2(0, -1),
      Vector2(0.866, 0.5),
      Vector2(-0.866, 0.5),
    ],
  ];

  ArchitectBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 520 + (wave * 72),
          speed: 38 + (wave * 0.7),
          lootValue: 48,
          color: const Color(0xFFFFD700), // Gold
          size: Vector2(65, 65) * scale,
          contactDamage: 33.0,
        ) {
    _initializePattern();
  }

  void _initializePattern() {
    currentPattern = patterns[currentPatternIndex];
    currentVertexIndex = 0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Spawn initial barriers
    _spawnBarriers();
  }

  @override
  Future<void> addHitbox() async {
    // Gear/cog shape (10 teeth)
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;
    final innerRadius = size.x / 2 * 0.7;

    // Create 20 points (alternating outer/inner for teeth)
    for (int i = 0; i < 20; i++) {
      final angle = (i * pi / 10) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      points.add(Vector2(
        centerX + cos(angle) * radius,
        centerY + sin(angle) * radius,
      ));
    }

    add(PolygonHitbox(points));
  }

  bool get isBelowHalfHealth => health <= maxHealth * 0.5;

  @override
  void updateMovement(double dt) {
    // Update rotation
    rotationAngle += dt * 2;
    angle = rotationAngle;

    // Update barrier rebuild timer
    barrierRebuildTimer += dt;
    if (barrierRebuildTimer >= barrierRebuildInterval) {
      _rebuildBarriers();
      barrierRebuildTimer = 0;
    }

    // Remove destroyed barriers
    barriers.removeWhere((barrier) => !barrier.isMounted);

    // Handle teleportation
    if (isTeleporting) {
      teleportAnimTimer += dt;
      if (teleportAnimTimer >= teleportDuration) {
        _completeTeleport();
      }
      return; // Don't move during teleport
    }

    // Update teleport timer
    teleportTimer += dt;
    if (teleportTimer >= teleportInterval) {
      _startTeleport();
      return;
    }

    // Fire geometric patterns
    geometricFireTimer += dt;
    if (geometricFireTimer >= geometricFireInterval) {
      _fireGeometricPattern();
      geometricFireTimer = 0;
    }
  }

  void _startTeleport() {
    isTeleporting = true;
    teleportAnimTimer = 0;
    print('[ArchitectBoss] Starting teleport to next vertex');
  }

  void _completeTeleport() {
    // Move to next vertex in pattern
    currentVertexIndex = (currentVertexIndex + 1) % currentPattern.length;

    // If completed pattern, switch to next pattern
    if (currentVertexIndex == 0) {
      currentPatternIndex = (currentPatternIndex + 1) % patterns.length;
      currentPattern = patterns[currentPatternIndex];
      print('[ArchitectBoss] Switching to pattern $currentPatternIndex');
    }

    // Calculate new position around player
    final vertex = currentPattern[currentVertexIndex];
    final offset = vertex * patternRadius;
    position = player.position + offset;

    isTeleporting = false;
    teleportTimer = 0;
    teleportAnimTimer = 0;

    print('[ArchitectBoss] Teleported to vertex $currentVertexIndex');
  }

  void _fireGeometricPattern() {
    // Fire rotating pattern of bullets
    final baseAngle = rotationAngle;

    for (int i = 0; i < rotatingBulletCount; i++) {
      final angle = baseAngle + (i * 2 * pi / rotatingBulletCount);
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      game.world.add(bullet);
    }

    print('[ArchitectBoss] Fired $rotatingBulletCount-way rotating pattern');
  }

  void _spawnBarriers() {
    // Spawn 3 barriers in a partial shield formation
    for (int i = 0; i < maxBarriers; i++) {
      final angle = (i * 2 * pi / maxBarriers);
      final barrier = _ArchitectBarrier(
        parent: this,
        orbitIndex: i,
      );

      barriers.add(barrier);
      add(barrier);
    }

    print('[ArchitectBoss] Spawned $maxBarriers barriers');
  }

  void _rebuildBarriers() {
    // Remove existing barriers
    for (final barrier in barriers) {
      barrier.removeFromParent();
    }
    barriers.clear();

    // Spawn new barriers
    _spawnBarriers();

    print('[ArchitectBoss] Rebuilt barriers');
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw teleport effect
    if (isTeleporting) {
      _drawTeleportEffect(canvas, centerX, centerY);
    }

    // Draw gear/cog shape
    _drawGear(canvas, centerX, centerY);

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2 + 10,
      bossPaint,
    );

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  void _drawGear(Canvas canvas, double centerX, double centerY) {
    final outerRadius = size.x / 2;
    final innerRadius = size.x / 2 * 0.7;

    // Create gear path
    final path = Path();
    for (int i = 0; i < 20; i++) {
      final angle = (i * pi / 10) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + cos(angle) * radius;
      final y = centerY + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill with gold
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Metallic outline
    final strokePaint = Paint()
      ..color = const Color(0xFFDAA520) // Darker gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // Draw central hub
    final hubPaint = Paint()
      ..color = const Color(0xFFB8860B) // Dark golden rod
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      innerRadius * 0.4,
      hubPaint,
    );
  }

  void _drawTeleportEffect(Canvas canvas, double centerX, double centerY) {
    final progress = teleportAnimTimer / teleportDuration;
    final opacity = isTeleporting ? (1.0 - progress) : 0.0;

    // Draw expanding rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress + i * 0.2) % 1.0;
      final ringRadius = size.x / 2 * (1 + ringProgress * 2);
      final ringOpacity = (1.0 - ringProgress) * opacity;

      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: ringOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        Offset(centerX, centerY),
        ringRadius,
        ringPaint,
      );
    }
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return ArchitectBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 40 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 40) return 100.0;
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Barrier component for the Architect Boss
class _ArchitectBarrier extends PositionComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  final ArchitectBoss parent;
  final int orbitIndex;

  double health = 50.0;
  bool hasTurret = false;
  double turretFireTimer = 0;
  static const double turretFireInterval = 1.5;

  _ArchitectBarrier({
    required this.parent,
    required this.orbitIndex,
  }) : super(
          size: Vector2(40, 15),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add hitbox
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update position to orbit around parent
    final angle = (orbitIndex * 2 * pi / ArchitectBoss.maxBarriers);
    final offset = Vector2(
      cos(angle) * ArchitectBoss.barrierOrbitRadius,
      sin(angle) * ArchitectBoss.barrierOrbitRadius,
    );

    position = offset;

    // Add turret if parent is below 50% health
    if (parent.isBelowHalfHealth && !hasTurret) {
      hasTurret = true;
      print('[ArchitectBarrier] Added turret (boss below 50% health)');
    }

    // Fire from turret
    if (hasTurret) {
      turretFireTimer += dt;
      if (turretFireTimer >= turretFireInterval) {
        _fireTurret();
        turretFireTimer = 0;
      }
    }
  }

  void _fireTurret() {
    // Fire toward player
    final barrierWorldPos = parent.position + position;
    final directionToPlayer =
        (parent.player.position - barrierWorldPos).normalized();

    final bullet = EnemyBullet(
      position: barrierWorldPos,
      direction: directionToPlayer,
      damage: 18.0,
      speed: 140.0,
    );

    game.world.add(bullet);
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      removeFromParent();
      print('[ArchitectBarrier] Destroyed!');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw barrier
    final healthPercent = health / 50.0;
    final barrierColor = Color.lerp(
      const Color(0xFF888888),
      const Color(0xFFCCCCCC),
      healthPercent,
    )!;

    final barrierPaint = Paint()
      ..color = barrierColor
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: size.y,
      ),
      barrierPaint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = const Color(0xFF666666)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.x / 2, size.y / 2),
        width: size.x,
        height: size.y,
      ),
      borderPaint,
    );

    // Draw turret if active
    if (hasTurret) {
      final turretPaint = Paint()
        ..color = const Color(0xFFFF4444)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        4,
        turretPaint,
      );
    }

    // Draw health bar
    final healthBarWidth = size.x;
    final healthBarHeight = 2.0;
    final healthBarY = -2.0;

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(0, healthBarY, healthBarWidth, healthBarHeight),
      healthBgPaint,
    );

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
