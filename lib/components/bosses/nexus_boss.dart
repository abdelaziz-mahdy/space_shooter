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
import '../enemy_homing_missile.dart';

/// The Nexus Boss - Wave 50+ (Ultimate Boss)
/// - Morphing shape (triangle → square → pentagon)
/// - Prismatic/rainbow shifting colors
/// - Health: 700 + (wave * 90) - ultimate boss
/// - Speed: Varies (30-70) by phase
/// - Contact damage: 38
/// - Loot: 55
///
/// Mechanics:
/// - 3 distinct phases at 100-66%, 66-33%, 33-0% health
/// - Phase 1: Triangle, blue, spiral patterns, slow movement
/// - Phase 2: Square, red, homing missiles + teleporting
/// - Phase 3: Pentagon, purple, rapid-fire + area mines, fast charges
/// - 2s invulnerability between phase transitions
/// - Each phase completion gives partial XP
/// - At 15% health in final phase: summons 2 mini-bosses from previous boss pool
class NexusBoss extends BaseEnemy {
  static const String ID = 'nexus_boss';

  // Phase tracking
  _NexusPhase currentPhase = _NexusPhase.phase1;
  bool isTransitioning = false;
  double transitionTimer = 0;
  static const double transitionDuration = 2.0;

  // Phase-specific properties
  double currentSpeed = 30.0;
  Color currentColor = const Color(0xFF0000FF);

  // Phase-specific timers
  double attackTimer = 0;
  double teleportTimer = 0;
  double mineTimer = 0;
  double colorShift = 0;

  // Phase 2 teleport
  static const double phase2TeleportInterval = 4.0;

  // Phase 3 mines
  final List<_AreaMine> mines = [];
  static const double mineSpawnInterval = 3.0;
  static const int maxMines = 6;

  // Mini-boss summoning
  bool hasSpawnedMiniBosses = false;

  NexusBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 700 + (wave * 90),
          speed: 30, // Phase 1 speed
          lootValue: 55,
          color: const Color(0xFF0000FF), // Phase 1 blue
          size: Vector2(60, 60) * scale,
          contactDamage: 38.0,
        );

  @override
  Future<void> addHitbox() async {
    // Initial triangle hitbox (Phase 1)
    _updateHitboxForPhase();
  }

  void _updateHitboxForPhase() {
    // Remove existing hitboxes
    children.whereType<ShapeHitbox>().toList().forEach((h) => h.removeFromParent());

    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 2;

    switch (currentPhase) {
      case _NexusPhase.phase1:
        // Triangle
        final points = <Vector2>[];
        for (int i = 0; i < 3; i++) {
          final angle = (i * 2 * pi / 3) - pi / 2;
          points.add(Vector2(
            centerX + cos(angle) * radius,
            centerY + sin(angle) * radius,
          ));
        }
        add(PolygonHitbox(points));
        break;

      case _NexusPhase.phase2:
        // Square
        final points = <Vector2>[
          Vector2(centerX - radius, centerY - radius),
          Vector2(centerX + radius, centerY - radius),
          Vector2(centerX + radius, centerY + radius),
          Vector2(centerX - radius, centerY + radius),
        ];
        add(PolygonHitbox(points));
        break;

      case _NexusPhase.phase3:
        // Pentagon
        final points = <Vector2>[];
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * pi / 5) - pi / 2;
          points.add(Vector2(
            centerX + cos(angle) * radius,
            centerY + sin(angle) * radius,
          ));
        }
        add(PolygonHitbox(points));
        break;
    }
  }

  @override
  double modifyIncomingDamage(double damage) {
    // Invulnerable during phase transitions
    return isTransitioning ? 0.0 : damage;
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    final healthBefore = health;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);

    final healthPercent = health / maxHealth;

    // Check for phase transitions
    if (currentPhase == _NexusPhase.phase1 && healthPercent <= 0.66 && healthBefore / maxHealth > 0.66) {
      _startPhaseTransition(_NexusPhase.phase2);
    } else if (currentPhase == _NexusPhase.phase2 && healthPercent <= 0.33 && healthBefore / maxHealth > 0.33) {
      _startPhaseTransition(_NexusPhase.phase3);
    }

    // Check for mini-boss summon
    if (currentPhase == _NexusPhase.phase3 && healthPercent <= 0.15 && !hasSpawnedMiniBosses) {
      _summonMiniBosses();
      hasSpawnedMiniBosses = true;
    }
  }

  void _startPhaseTransition(_NexusPhase newPhase) {
    isTransitioning = true;
    transitionTimer = 0;
    currentPhase = newPhase;

    // Update boss properties for new phase
    switch (newPhase) {
      case _NexusPhase.phase1:
        // Should never happen
        break;
      case _NexusPhase.phase2:
        currentSpeed = 50; // Medium speed
        currentColor = const Color(0xFFFF0000); // Red
        print('[NexusBoss] Transitioning to Phase 2 (Square, Red, Teleporting)');
        break;
      case _NexusPhase.phase3:
        currentSpeed = 70; // Fast speed
        currentColor = const Color(0xFF9900FF); // Purple
        print('[NexusBoss] Transitioning to Phase 3 (Pentagon, Purple, Rapid-Fire)');
        break;
    }

    // Update hitbox for new shape
    _updateHitboxForPhase();

    // Award partial XP for completing phase
    game.levelManager.addXP(20);
  }

  @override
  void updateMovement(double dt) {
    // Update color shift for prismatic effect
    colorShift += dt * 2;

    // Handle phase transition
    if (isTransitioning) {
      transitionTimer += dt;
      if (transitionTimer >= transitionDuration) {
        isTransitioning = false;
        transitionTimer = 0;
      }
      return; // Don't move or attack during transition
    }

    // Update mines
    mines.removeWhere((mine) => !mine.isMounted);

    // Phase-specific behavior
    switch (currentPhase) {
      case _NexusPhase.phase1:
        _updatePhase1(dt);
        break;
      case _NexusPhase.phase2:
        _updatePhase2(dt);
        break;
      case _NexusPhase.phase3:
        _updatePhase3(dt);
        break;
    }

    // Rotate
    angle += dt;
  }

  void _updatePhase1(double dt) {
    // Slow movement, spiral bullet patterns
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    position += directionToPlayer * currentSpeed * dt;

    attackTimer += dt;
    if (attackTimer >= 2.0) {
      _fireSpiralPattern();
      attackTimer = 0;
    }
  }

  void _updatePhase2(double dt) {
    // Teleporting, homing missiles
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    position += directionToPlayer * currentSpeed * dt;

    // Teleport
    teleportTimer += dt;
    if (teleportTimer >= phase2TeleportInterval) {
      _teleportPhase2();
      teleportTimer = 0;
    }

    // Fire homing missiles
    attackTimer += dt;
    if (attackTimer >= 1.5) {
      _fireHomingMissiles();
      attackTimer = 0;
    }
  }

  void _updatePhase3(double dt) {
    // Fast charges, rapid fire, area mines
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    position += directionToPlayer * currentSpeed * dt;

    // Rapid fire
    attackTimer += dt;
    if (attackTimer >= 0.4) {
      _fireRapidShot();
      attackTimer = 0;
    }

    // Spawn mines
    mineTimer += dt;
    if (mineTimer >= mineSpawnInterval && mines.length < maxMines) {
      _spawnMine();
      mineTimer = 0;
    }
  }

  void _fireSpiralPattern() {
    // Fire 8 bullets in spiral
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * pi / 8) + this.angle;
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: 20.0,
        speed: 140.0,
      );

      game.world.add(bullet);
    }

    print('[NexusBoss] Phase 1: Fired spiral pattern');
  }

  void _teleportPhase2() {
    // Teleport to random position around player
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = 300 + random.nextDouble() * 200;

    final offset = Vector2(cos(angle) * distance, sin(angle) * distance);
    position = player.position + offset;

    print('[NexusBoss] Phase 2: Teleported!');
  }

  void _fireHomingMissiles() {
    // Fire 2 homing missiles
    for (int i = 0; i < 2; i++) {
      final angle = (i * pi / 4) - pi / 8;
      final baseDir = PositionUtil.getDirectionTo(this, player);
      final direction = Vector2(
        baseDir.x * cos(angle) - baseDir.y * sin(angle),
        baseDir.x * sin(angle) + baseDir.y * cos(angle),
      ).normalized();

      final missile = EnemyHomingMissile(
        position: position.clone(),
        direction: direction,
        damage: 25.0,
        speed: 180.0,
      );

      game.world.add(missile);
    }

    print('[NexusBoss] Phase 2: Fired homing missiles');
  }

  void _fireRapidShot() {
    // Fire toward player
    final direction = PositionUtil.getDirectionTo(this, player);

    final bullet = EnemyBullet(
      position: position.clone(),
      direction: direction,
      damage: 18.0,
      speed: 220.0,
    );

    game.world.add(bullet);
  }

  void _spawnMine() {
    final mine = _AreaMine(parent: this);
    mines.add(mine);
    add(mine);

    print('[NexusBoss] Phase 3: Spawned mine (${mines.length}/$maxMines)');
  }

  void _summonMiniBosses() {
    print('[NexusBoss] Summoning 2 mini-bosses at 15% health!');

    // Summon 2 random previous bosses
    final previousBosses = [
      'shielder_boss',
      'gunship_boss',
      'berserker_boss',
      'vortex_boss',
      'splitter_boss',
      'summoner',
    ];

    final random = Random();
    for (int i = 0; i < 2; i++) {
      final bossId = previousBosses[random.nextInt(previousBosses.length)];

      if (!EnemyFactory.isRegistered(bossId)) continue;

      final angle = (i * pi) + random.nextDouble() * pi / 2;
      final offset = Vector2(cos(angle) * 200, sin(angle) * 200);
      final spawnPos = position + offset;

      try {
        final miniBoss = EnemyFactory.create(
          bossId,
          player,
          wave,
          spawnPos,
          scale: 0.7, // Smaller mini-boss
        );

        // Reduce health to 40%
        miniBoss.health = miniBoss.health * 0.4;

        game.world.add(miniBoss);
        print('[NexusBoss] Summoned mini-boss: $bossId');
      } catch (e) {
        print('[NexusBoss] Failed to summon $bossId: $e');
      }
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final radius = size.x / 2;

    // Calculate prismatic color by cycling through RGB
    final colorIndex = (colorShift * 2).floor() % 6;
    final prismColor = [
      const Color(0xFFFF0000), // Red
      const Color(0xFFFFFF00), // Yellow
      const Color(0xFF00FF00), // Green
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFF0000FF), // Blue
      const Color(0xFFFF00FF), // Magenta
    ][colorIndex];

    // Draw shape based on phase
    final path = Path();
    switch (currentPhase) {
      case _NexusPhase.phase1:
        // Triangle
        for (int i = 0; i < 3; i++) {
          final angle = (i * 2 * pi / 3) - pi / 2;
          final x = centerX + cos(angle) * radius;
          final y = centerY + sin(angle) * radius;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        break;

      case _NexusPhase.phase2:
        // Square
        path.addRect(Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: size.x,
          height: size.y,
        ));
        break;

      case _NexusPhase.phase3:
        // Pentagon
        for (int i = 0; i < 5; i++) {
          final angle = (i * 2 * pi / 5) - pi / 2;
          final x = centerX + cos(angle) * radius;
          final y = centerY + sin(angle) * radius;
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        break;
    }
    path.close();

    // Fill with prismatic/phase color
    final fillColor = isTransitioning ? prismColor : Color.lerp(currentColor, prismColor, 0.5)!;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Glow effect
    final glowPaint = Paint()
      ..color = fillColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glowPaint);

    // Draw transition effect
    if (isTransitioning) {
      final progress = transitionTimer / transitionDuration;
      for (int i = 0; i < 3; i++) {
        final ringProgress = (progress + i * 0.3) % 1.0;
        final ringRadius = radius * (1 + ringProgress * 2);
        final ringOpacity = (1.0 - ringProgress) * 0.8;

        final ringPaint = Paint()
          ..color = prismColor.withValues(alpha: ringOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawCircle(
          Offset(centerX, centerY),
          ringRadius,
          ringPaint,
        );
      }
    }

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 15,
      bossPaint,
    );

    // Draw phase indicator
    final phasePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final phaseText = 'P${currentPhase.index + 1}';
    // Note: In a real implementation, you'd use TextPainter here
    // For simplicity, we'll draw circles to indicate phase
    for (int i = 0; i <= currentPhase.index; i++) {
      canvas.drawCircle(
        Offset(centerX - 10 + (i * 10), centerY + radius + 20),
        3,
        phasePaint,
      );
    }

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return NexusBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 50 only (final unique boss)
    // Not included in boss pool for waves 55+
    if (wave == 50) {
      return 100.0;
    }
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Phase enum for Nexus Boss
enum _NexusPhase {
  phase1, // Triangle, blue, spiral
  phase2, // Square, red, missiles
  phase3, // Pentagon, purple, rapid-fire
}

/// Area mine component for Phase 3
class _AreaMine extends PositionComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  final NexusBoss parent;

  double lifeTimer = 0;
  static const double maxLifetime = 12.0;

  _AreaMine({required this.parent})
      : super(
          position: parent.position.clone(),
          size: Vector2(20, 20),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(radius: size.x / 2));
  }

  @override
  void update(double dt) {
    super.update(dt);

    lifeTimer += dt;
    if (lifeTimer >= maxLifetime) {
      explode();
    }
  }

  void explode() {
    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      other.takeDamage(30.0);
      explode();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw mine with pulsing warning
    final pulseIntensity = (sin(lifeTimer * 4) + 1) / 2;

    final minePaint = Paint()
      ..color = Color.lerp(
        const Color(0xFF660066),
        const Color(0xFFFF00FF),
        pulseIntensity,
      )!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2,
      minePaint,
    );

    // Draw danger indicator
    final dangerPaint = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: pulseIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      Offset(centerX, centerY),
      size.x / 2 + 3,
      dangerPaint,
    );
  }
}
