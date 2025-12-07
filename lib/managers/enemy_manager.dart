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

class EnemyManager extends Component with HasGameReference<SpaceShooterGame> {
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
  double waveDelay = 0.3; // Very fast wave transitions for better pacing
  double waveTimer = 0;

  // Debug tracking
  int _lastEnemyCount = -1;

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
    _lastEnemyCount = -1; // Reset debug tracker

    // Every 5th wave is a boss wave
    isBossWave = currentWave % 5 == 0;

    if (isBossWave) {
      // For multi-boss waves (55+), we need to count each boss separately
      enemiesToSpawnInWave = getBossCountForWave(currentWave);

      // Switch to boss music and play boss appearance sound (MUSIC DISABLED)
      // game.audioManager.playMusic(boss: true);
      game.audioManager.playBossAppear();
    } else {
      // Reduced enemy count for faster pacing: 5 + (wave * 1)
      // Wave 1: 6 enemies, Wave 2: 7 enemies, Wave 10: 15 enemies
      enemiesToSpawnInWave = 5 + currentWave;

      // Switch back to normal music (DISABLED)
      // game.audioManager.playMusic(boss: false);
    }

    game.statsManager.startWave(currentWave, enemiesToSpawnInWave);

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

        // Skip wave completion check this frame (enemy just spawned, not mounted yet)
        return;
      }

      // Check if wave is complete (all enemies killed)
      // Use cached enemy list for consistency (refreshed once per frame)
      final totalEnemyCount = game.activeEnemies.length;
      final allEnemiesKilled = (totalEnemyCount == 0);

      // Debug: Log when enemy count changes
      if (totalEnemyCount != _lastEnemyCount) {
        final enemyTypes = game.activeEnemies.map((e) => e.runtimeType.toString()).join(', ');
        print('[EnemyManager] Enemy count changed: wave=$currentWave, spawned=$enemiesSpawnedInWave/$enemiesToSpawnInWave, alive=$totalEnemyCount (was $_lastEnemyCount)');
        print('[EnemyManager] Active enemies: [$enemyTypes]');
        GameLogger.debug(
          'Enemy count changed: wave=$currentWave, spawned=$enemiesSpawnedInWave/$enemiesToSpawnInWave, alive=$totalEnemyCount (was $_lastEnemyCount)',
          tag: 'EnemyManager',
        );
        _lastEnemyCount = totalEnemyCount;
      }

      // Wave completes when: all enemies spawned AND all killed
      if (enemiesSpawnedInWave >= enemiesToSpawnInWave && allEnemiesKilled) {
        // Wave complete - all enemies defeated
        print('[EnemyManager] *** WAVE COMPLETING *** wave=$currentWave, spawned=$enemiesSpawnedInWave/$enemiesToSpawnInWave, alive=$totalEnemyCount, isBoss=$isBossWave');
        isWaveActive = false;
        waveTimer = 0;
        currentWave++;

        GameLogger.event(
          'Wave ${currentWave - 1} completed - ALL ENEMIES DEFEATED',
          tag: 'EnemyManager',
          data: {
            'spawned': enemiesToSpawnInWave,
            'required': enemiesToSpawnInWave,
            'remaining': totalEnemyCount,
            'isBossWave': isBossWave,
          },
        );

        // Trigger wave complete callback (for XP auto-collect)
        onWaveComplete?.call();
      } else if (enemiesSpawnedInWave >= enemiesToSpawnInWave && !allEnemiesKilled) {
        // Waiting for enemies to be killed - log every 2 seconds
        if (spawnTimer.remainder(2.0) < dt) {
          GameLogger.debug(
            'Wave $currentWave waiting for enemies: spawned=$enemiesSpawnedInWave/$enemiesToSpawnInWave, alive=$totalEnemyCount, isBoss=$isBossWave',
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
    final spawnPos = Vector2(playerPos.x, playerPos.y - game.size.y / 2 - 100);

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
      game.world.add(boss);
      GameLogger.debug('Spawned fallback BossShip at wave $currentWave', tag: 'EnemyManager');
      return;
    }

    // Create boss using factory with weighted random selection
    final boss = EnemyFactory.createWeightedRandom(
      player,
      currentWave,
      spawnPos,
      bossWeights,
      scale: game.entityScale,
    );
    game.world.add(boss);
    print('[EnemyManager] *** BOSS SPAWNED *** ${boss.runtimeType} at wave $currentWave, isMounted=${boss.isMounted}');
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
    final xVariance = (random.nextDouble() - 0.5) * game.size.x * 0.4;
    final spawnPos = Vector2(
      playerPos.x + xVariance,
      playerPos.y - game.size.y / 2 - 100,
    );

    // Create boss using factory
    final boss = EnemyFactory.create(
      bossId,
      player,
      currentWave,
      spawnPos,
      scale: game.entityScale,
    );

    game.world.add(boss);
    GameLogger.debug(
      'Spawned ${boss.runtimeType} ($bossId) at wave $currentWave (${enemiesSpawnedInWave + 1}/$enemiesToSpawnInWave)',
      tag: 'EnemyManager',
    );
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
          playerPos.x + (random.nextDouble() * game.size.x) - (game.size.x / 2),
          playerPos.y - game.size.y / 2 - 50
        );
        break;
      case 1: // Right
        spawnPos = Vector2(
          playerPos.x + game.size.x / 2 + 50,
          playerPos.y + (random.nextDouble() * game.size.y) - (game.size.y / 2),
        );
        break;
      case 2: // Bottom
        spawnPos = Vector2(
          playerPos.x + (random.nextDouble() * game.size.x) - (game.size.x / 2),
          playerPos.y + game.size.y / 2 + 50,
        );
        break;
      case 3: // Left
        spawnPos = Vector2(
          playerPos.x - game.size.x / 2 - 50,
          playerPos.y + (random.nextDouble() * game.size.y) - (game.size.y / 2)
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
    final enemy = EnemyFactory.createWeightedRandom(player, currentWave, spawnPos, weights, scale: game.entityScale);

    game.world.add(enemy);
    print('[EnemyManager] Spawned ${enemy.runtimeType} (${enemiesSpawnedInWave + 1}/$enemiesToSpawnInWave) at wave $currentWave');
    GameLogger.debug(
      'Spawned ${enemy.runtimeType} at wave $currentWave with scale ${game.entityScale}',
      tag: 'EnemyManager',
    );
  }

  int getCurrentWave() => currentWave;
  bool isInBossWave() => isBossWave;
}
