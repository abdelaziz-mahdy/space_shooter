import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../components/boss_ship.dart';
import '../components/player_ship.dart';
import '../components/enemies/base_enemy.dart';
import '../factories/enemy_factory.dart';
import '../config/enemy_spawn_config.dart';
import '../utils/game_logger.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  final PlayerShip player;
  final Random random = Random();

  double spawnTimer = 0;
  double spawnInterval = 1.5; // Faster initial spawn rate (was 2.0)
  bool isSpawning = false;

  // Wave system
  int currentWave = 1;
  int enemiesSpawnedInWave = 0;
  int enemiesToSpawnInWave = 10;
  bool isWaveActive = false;
  bool isBossWave = false;
  double waveDelay = 1.0; // Faster wave transitions (was 2.0)
  double waveTimer = 0;

  // Callback when wave completes (for XP auto-collect)
  VoidCallback? onWaveComplete;

  // Boss pool for waves 55+ (excludes Nexus which only appears at wave 50)
  static const List<String> bossPool = [
    'shielder_boss',     // Wave 5
    'splitter_boss',     // Wave 10
    'gunship_boss',      // Wave 15
    'summoner',          // Wave 20
    'vortex_boss',       // Wave 25
    'fortress_boss',     // Wave 30
    'berserker',         // Wave 35
    'architect_boss',    // Wave 40
    'hydra_boss',        // Wave 45
  ];

  EnemyManager({required this.player, required SpaceShooterGame game});

  void startSpawning() {
    isSpawning = true;
    startNextWave();
  }

  /// Resume spawning without starting a new wave (for unpause/settings)
  void resumeSpawning() {
    isSpawning = true;
  }

  void stopSpawning() {
    isSpawning = false;
  }

  void startNextWave() {
    isWaveActive = true;
    enemiesSpawnedInWave = 0;
    spawnTimer = 0; // Reset spawn timer to start spawning immediately

    // Every 5th wave is a boss wave
    isBossWave = currentWave % 5 == 0;

    if (isBossWave) {
      // For multi-boss waves (55+), we need to count each boss separately
      enemiesToSpawnInWave = getBossCountForWave(currentWave);

      // Switch to boss music and play boss appearance sound (MUSIC DISABLED)
      // gameRef.audioManager.playMusic(boss: true);
      gameRef.audioManager.playBossAppear();
    } else {
      // Reduced enemy count for faster pacing: 5 + (wave * 1)
      // Wave 1: 6 enemies, Wave 2: 7 enemies, Wave 10: 15 enemies
      enemiesToSpawnInWave = 5 + currentWave;

      // Switch back to normal music (DISABLED)
      // gameRef.audioManager.playMusic(boss: false);
    }

    gameRef.statsManager.startWave(currentWave, enemiesToSpawnInWave);

    GameLogger.event('Wave $currentWave started - Enemies: $enemiesToSpawnInWave', tag: 'EnemyManager');
  }

  /// Determine how many bosses to spawn based on wave number
  int getBossCountForWave(int wave) {
    if (wave <= 50) {
      return 1; // Waves 5-50: Single unique boss
    } else if (wave <= 60) {
      return 2; // Waves 55-60: 2 random bosses
    } else {
      return 3; // Waves 65+: 3 random bosses
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    if (!isSpawning) return;

    if (isWaveActive) {
      // Spawn enemies for current wave
      spawnTimer += dt;
      if (spawnTimer >= spawnInterval &&
          enemiesSpawnedInWave < enemiesToSpawnInWave) {
        if (isBossWave) {
          // For multi-boss waves (55+), spawn one boss at a time
          if (currentWave > 50) {
            // Spawn a single boss from the pool
            spawnSingleBossFromPool();
          } else {
            // Single boss spawn for waves 5-50
            spawnBoss();
          }
        } else {
          spawnEnemy();
        }
        enemiesSpawnedInWave++;
        spawnTimer = 0;
      }

      // Check if wave is complete (all enemies killed)
      // CRITICAL: Only count enemies that are still mounted (not in process of being removed)
      // BossShip extends BaseEnemy, so we only need to count BaseEnemy (includes all bosses)
      final totalEnemyCount = gameRef.world.children
          .whereType<BaseEnemy>()
          .where((enemy) => enemy.isMounted)
          .length;
      final allEnemiesKilled = (totalEnemyCount == 0);

      // Wave completes when: all enemies spawned AND all killed
      if (enemiesSpawnedInWave >= enemiesToSpawnInWave && allEnemiesKilled) {
        // Wave complete - all enemies defeated
        isWaveActive = false;
        waveTimer = 0;
        currentWave++;

        GameLogger.event(
          'Wave ${currentWave - 1} completed - ALL ENEMIES DEFEATED',
          tag: 'EnemyManager',
          data: {'spawned': enemiesToSpawnInWave, 'remaining': totalEnemyCount},
        );

        // Trigger wave complete callback (for XP auto-collect)
        onWaveComplete?.call();
      }

      // Debug: Log if wave should be complete but isn't
      if (enemiesSpawnedInWave >= enemiesToSpawnInWave && totalEnemyCount > 0) {
        // This helps debug when wave doesn't complete properly
        // Only log occasionally to avoid spam
        if (spawnTimer < dt * 2) { // Log roughly once per second
          GameLogger.debug(
            'Wave $currentWave waiting: spawned $enemiesSpawnedInWave/$enemiesToSpawnInWave, alive: $totalEnemyCount',
            tag: 'EnemyManager',
          );
        }
      }
    } else {
      // Delay between waves
      waveTimer += dt;
      if (waveTimer >= waveDelay && !isWaveActive) {
        startNextWave();
      }
    }

    // Gradually increase spawn rate (faster spawns as waves progress)
    // Start at 0.8s and decrease to 0.3s minimum for better pacing
    spawnInterval = max(0.3, 0.8 - (currentWave * 0.02));
  }

  void spawnBoss() {
    // Spawn boss at top center relative to player position in world coordinates
    final playerPos = player.position;
    final spawnPos = Vector2(playerPos.x, playerPos.y - gameRef.size.y / 2 - 100);

    // Get spawn weights for current wave from config
    final weights = EnemySpawnConfig.getWeightsForWave(currentWave);

    // Filter to only boss enemies (those with weight > 0 for this wave)
    final bossWeights = <String, double>{};
    for (final entry in weights.entries) {
      if (entry.value > 0 && entry.key.contains('boss')) {
        bossWeights[entry.key] = entry.value;
      }
    }

    // If no boss is registered for this wave, spawn fallback
    if (bossWeights.isEmpty) {
      final boss = BossShip(
        position: spawnPos,
        player: player,
        wave: currentWave,
        color: const Color(0xFFFF0000),
      );
      gameRef.world.add(boss);
      GameLogger.debug('Spawned fallback BossShip at wave $currentWave', tag: 'EnemyManager');
      return;
    }

    // Create boss using factory with weighted random selection
    final boss = EnemyFactory.createWeightedRandom(
      player,
      currentWave,
      spawnPos,
      bossWeights,
      scale: gameRef.entityScale,
    );
    gameRef.world.add(boss);
    GameLogger.debug('Spawned ${boss.runtimeType} at wave $currentWave', tag: 'EnemyManager');
  }

  /// Spawn a single boss from the pool for waves 55+
  /// Used when spawning bosses one at a time (proper enemy counting)
  void spawnSingleBossFromPool() {
    // Get player position for spawn reference
    final playerPos = player.position;

    // Select a random boss from pool
    final bossId = bossPool[random.nextInt(bossPool.length)];

    // Calculate spawn position (top center with some horizontal variance)
    final xVariance = (random.nextDouble() - 0.5) * gameRef.size.x * 0.4;
    final spawnPos = Vector2(
      playerPos.x + xVariance,
      playerPos.y - gameRef.size.y / 2 - 100,
    );

    // Create boss using factory
    final boss = EnemyFactory.create(
      bossId,
      player,
      currentWave,
      spawnPos,
      scale: gameRef.entityScale,
    );

    gameRef.world.add(boss);
    GameLogger.debug(
      'Spawned ${boss.runtimeType} ($bossId) at wave $currentWave (${enemiesSpawnedInWave + 1}/$enemiesToSpawnInWave)',
      tag: 'EnemyManager',
    );
  }

  /// Select random bosses from the pool without duplicates
  List<String> _selectRandomBosses(int count) {
    // Create a shuffled copy of the boss pool
    final shuffled = List<String>.from(bossPool)..shuffle(random);

    // Take the requested count (or all if count > pool size)
    final selectedCount = count.clamp(0, shuffled.length);
    return shuffled.take(selectedCount).toList();
  }


  Vector2 getRandomSpawnPosition() {
    // Random spawn position around player in world coordinates
    final side = random.nextInt(4);
    Vector2 spawnPos;

    // Get player position in world coordinates
    final playerPos = player.position;

    switch (side) {
      case 0: // Top
        spawnPos = Vector2(
          playerPos.x + (random.nextDouble() * gameRef.size.x) - (gameRef.size.x / 2),
          playerPos.y - gameRef.size.y / 2 - 50
        );
        break;
      case 1: // Right
        spawnPos = Vector2(
          playerPos.x + gameRef.size.x / 2 + 50,
          playerPos.y + (random.nextDouble() * gameRef.size.y) - (gameRef.size.y / 2),
        );
        break;
      case 2: // Bottom
        spawnPos = Vector2(
          playerPos.x + (random.nextDouble() * gameRef.size.x) - (gameRef.size.x / 2),
          playerPos.y + gameRef.size.y / 2 + 50,
        );
        break;
      case 3: // Left
        spawnPos = Vector2(
          playerPos.x - gameRef.size.x / 2 - 50,
          playerPos.y + (random.nextDouble() * gameRef.size.y) - (gameRef.size.y / 2)
        );
        break;
      default:
        spawnPos = playerPos.clone();
    }

    return spawnPos;
  }

  void spawnEnemy() {
    final spawnPos = getRandomSpawnPosition();

    // Get spawn weights for current wave from config
    final weights = EnemySpawnConfig.getWeightsForWave(currentWave);

    // Create enemy using factory with weighted random selection and entity scale
    final enemy = EnemyFactory.createWeightedRandom(player, currentWave, spawnPos, weights, scale: gameRef.entityScale);

    gameRef.world.add(enemy);
    GameLogger.debug(
      'Spawned ${enemy.runtimeType} at wave $currentWave with scale ${gameRef.entityScale}',
      tag: 'EnemyManager',
    );
  }

  int getCurrentWave() => currentWave;
  bool isInBossWave() => isBossWave;
}
