import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../green_enemy_bullet.dart';

/// The Summoner Boss - Wave 20
/// - Pentagon with glowing center, dark green with bright green core
/// - Health: 350 + (wave * 55), Speed: 25 + (wave * 0.4) - very slow
/// - Summons 2-4 minions every 5 seconds (max 8 alive)
/// - Below 50% health: summons elite enemies more frequently
/// - On death: summons 6 kamikaze enemies as final attack
/// - Teleports to random position when health < 30%
class SummonerBoss extends BaseEnemy {
  static const String ID = 'summoner';

  // Combat constants
  static const double shootInterval = 2.0;
  static const double bulletSpeed = 120; // Slow-moving
  static const double bulletDamage = 20;
  static const double bulletSize = 15; // Large bullets
  static const int bulletSpreadCount = 3; // 3-shot spread

  // Summoning constants
  static const double summonInterval = 5.0;
  static const int minMinionsPerSummon = 2;
  static const int maxMinionsPerSummon = 4;
  static const int maxActiveMinions = 8;
  static const double minionScale = 0.75; // 75% size and health
  static const double summonRange = 100; // Distance from boss to spawn minions

  // Teleport constants
  static const double teleportHealthThreshold = 0.30; // Below 30% health
  static const double teleportRange = 400; // Max distance from player to teleport

  // State tracking
  double shootTimer = 0;
  double summonTimer = 0;
  bool isSummoning = false;
  double summoningTimer = 0;
  static const double summoningDuration = 1.0; // Boss stops to summon for 1 second
  bool hasTeleported = false;

  // Track summoned minions
  final List<BaseEnemy> summonedMinions = [];

  // Visual effects
  double glowPulse = 0;

  // Elite enemy types (Tank and Ranger)
  static const List<String> eliteEnemyTypes = ['tank', 'ranger'];

  // Normal enemy types
  static const List<String> normalEnemyTypes = [
    'triangle',
    'square',
    'pentagon',
    'scout',
  ];

  SummonerBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 350 + (wave * 55),
          speed: 25 + (wave * 0.4),
          lootValue: 42,
          color: const Color(0xFF006400), // Dark green
          size: Vector2(50, 50) * scale,
          contactDamage: 25.0,
        );

  @override
  Future<void> addHitbox() async {
    // Pentagon (5 sides) hitbox
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

  bool get isBelowHalfHealth => health <= maxHealth * 0.5;

  int get aliveMinionsCount {
    // Remove dead minions from tracking list
    summonedMinions.removeWhere((minion) => minion.isMounted == false);
    return summonedMinions.length;
  }

  @override
  void updateMovement(double dt) {
    glowPulse += dt * 3;
    shootTimer += dt;
    summonTimer += dt;

    // Handle summoning state
    if (isSummoning) {
      summoningTimer += dt;
      if (summoningTimer >= summoningDuration) {
        isSummoning = false;
        summoningTimer = 0;
      }
      // Don't move while summoning
      return;
    }

    // Check for teleport (only once when health drops below 30%)
    if (!hasTeleported && health <= maxHealth * teleportHealthThreshold) {
      teleportToRandomPosition();
      hasTeleported = true;
    }

    // Slow movement toward player
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    position += directionToPlayer * getEffectiveSpeed() * dt;

    // Face player
    angle = atan2(directionToPlayer.y, directionToPlayer.x) + pi / 2;

    // Handle shooting
    if (shootTimer >= shootInterval) {
      shootSpread();
      shootTimer = 0;
    }

    // Handle summoning
    if (summonTimer >= summonInterval && aliveMinionsCount < maxActiveMinions) {
      summonMinions();
      summonTimer = 0;
    }
  }

  /// Shoot 3-bullet spread
  void shootSpread() {
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    final baseAngle = atan2(directionToPlayer.y, directionToPlayer.x);

    // Calculate spread angles (15 degrees on each side)
    final spreadAngle = pi / 12; // 15 degrees
    final angles = [
      baseAngle - spreadAngle, // Left
      baseAngle, // Center
      baseAngle + spreadAngle, // Right
    ];

    for (final angle in angles) {
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = GreenEnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      // Make bullets larger
      bullet.size = Vector2(bulletSize, bulletSize);

      gameRef.world.add(bullet);
    }

    print('[SummonerBoss] Fired 3-bullet spread');
  }

  /// Summon 2-4 random enemies around the boss
  void summonMinions() {
    // Stop moving while summoning
    isSummoning = true;
    summoningTimer = 0;

    final random = Random();
    final count = minMinionsPerSummon +
        random.nextInt(maxMinionsPerSummon - minMinionsPerSummon + 1);

    // Determine which enemy types to summon based on health
    final List<String> enemyPool;
    if (isBelowHalfHealth) {
      // Below 50% health: mix of elite and normal enemies (favor elites)
      enemyPool = [...eliteEnemyTypes, ...normalEnemyTypes];
    } else {
      // Above 50% health: only normal enemies
      enemyPool = normalEnemyTypes;
    }

    // Filter to only registered enemies
    final availableEnemies = enemyPool
        .where((id) => EnemyFactory.isRegistered(id))
        .toList();

    if (availableEnemies.isEmpty) {
      print('[SummonerBoss] No enemies available for summoning!');
      return;
    }

    // Summon enemies in a circle around the boss
    for (int i = 0; i < count; i++) {
      if (aliveMinionsCount >= maxActiveMinions) break;

      final angle = (i * 2 * pi / count) + glowPulse; // Rotate based on glow
      final offset = Vector2(
        cos(angle) * summonRange,
        sin(angle) * summonRange,
      );
      final spawnPos = position + offset;

      // Pick random enemy from available pool
      final enemyId = availableEnemies[random.nextInt(availableEnemies.length)];

      try {
        // Create enemy with 75% scale (affects both size and health)
        final minion = EnemyFactory.create(
          enemyId,
          player,
          wave,
          spawnPos,
          scale: minionScale,
        );

        // Scale health to 75%
        minion.health = minion.health * minionScale;

        // Add to world and track
        gameRef.world.add(minion);
        summonedMinions.add(minion);

        print('[SummonerBoss] Summoned $enemyId minion (${aliveMinionsCount}/$maxActiveMinions)');
      } catch (e) {
        print('[SummonerBoss] Failed to summon $enemyId: $e');
      }
    }
  }

  /// Teleport to random position around player
  void teleportToRandomPosition() {
    final random = Random();

    // Generate random angle
    final angle = random.nextDouble() * 2 * pi;

    // Random distance from player (200-400 units)
    final distance = 200 + random.nextDouble() * 200;

    // Calculate new position
    final offset = Vector2(
      cos(angle) * distance,
      sin(angle) * distance,
    );

    position = player.position + offset;

    print('[SummonerBoss] Teleported to new position! Health: ${health.toInt()}/${maxHealth.toInt()}');
  }

  @override
  void onDeath() {
    // Summon 6 kamikaze enemies as final attack
    const kamikazeCount = 6;

    if (!EnemyFactory.isRegistered('kamikaze')) {
      print('[SummonerBoss] Kamikaze enemy not registered, skipping final summon');
      return;
    }

    print('[SummonerBoss] Final summon - spawning $kamikazeCount kamikaze enemies!');

    for (int i = 0; i < kamikazeCount; i++) {
      final angle = (i * 2 * pi / kamikazeCount);
      final offset = Vector2(
        cos(angle) * 80, // Closer spawn range for dramatic effect
        sin(angle) * 80,
      );
      final spawnPos = position + offset;

      try {
        final kamikaze = EnemyFactory.create(
          'kamikaze',
          player,
          wave,
          spawnPos,
          scale: 1.0, // Full size kamikaze for final attack
        );

        gameRef.world.add(kamikaze);
        print('[SummonerBoss] Spawned kamikaze $i/$kamikazeCount');
      } catch (e) {
        print('[SummonerBoss] Failed to spawn kamikaze: $e');
      }
    }
  }

  @override
  void renderShape(Canvas canvas) {
    // Glow pulse effect
    final pulseEffect = sin(glowPulse) * 0.3;
    final glowIntensity = 1.0 + pulseEffect;

    // Draw outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.3 + pulseEffect * 0.2)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    final glowPath = createPentagonPath(size.x / 2 + 8, size.y / 2 + 8);
    canvas.drawPath(glowPath, glowPaint);

    // Draw main pentagon
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = createPentagonPath(size.x / 2, size.y / 2);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw glowing center core
    final corePaint = Paint()
      ..color = Color.fromRGBO(
        0,
        (255 * glowIntensity).clamp(0, 255).toInt(),
        0,
        1.0,
      )
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      10 + pulseEffect * 3,
      corePaint,
    );

    // Draw summoning indicator
    if (isSummoning) {
      final summonPaint = Paint()
        ..color = const Color(0xFF00FF00).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw expanding circle
      final summonProgress = summoningTimer / summoningDuration;
      final summonRadius = (size.x / 2) + (20 * summonProgress);

      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        summonRadius,
        summonPaint,
      );
    }

    // Draw minion count indicator
    if (aliveMinionsCount > 0) {
      final minionPaint = Paint()
        ..color = const Color(0xFFFFFF00)
        ..style = PaintingStyle.fill;

      // Draw small circles indicating minion count
      final markerSize = 2.0;
      final markerSpacing = 5.0;
      final totalWidth = (aliveMinionsCount - 1) * markerSpacing;
      final startX = (size.x / 2) - (totalWidth / 2);

      for (int i = 0; i < aliveMinionsCount; i++) {
        canvas.drawCircle(
          Offset(startX + (i * markerSpacing), size.y + 5),
          markerSize,
          minionPaint,
        );
      }
    }

    // Draw boss indicator (red outline)
    final bossPaint = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 8,
      bossPaint,
    );

    // Draw status effects
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  /// Helper to create pentagon path
  Path createPentagonPath(double radiusX, double radiusY) {
    final sides = 5;
    final path = Path();
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = centerX + cos(angle) * radiusX;
      final y = centerY + sin(angle) * radiusY;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return SummonerBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 20 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 20) return 1.0;
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
