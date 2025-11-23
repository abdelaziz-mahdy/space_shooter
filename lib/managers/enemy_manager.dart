import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../components/boss_ship.dart';
import '../components/player_ship.dart';
import '../components/enemies/base_enemy.dart';
import '../factories/enemy_factory.dart';
import '../config/enemy_spawn_config.dart';

class EnemyManager extends Component with HasGameRef<SpaceShooterGame> {
  final PlayerShip player;
  final Random random = Random();

  double spawnTimer = 0;
  double spawnInterval = 2.0;
  bool isSpawning = false;

  // Wave system
  int currentWave = 1;
  int enemiesSpawnedInWave = 0;
  int enemiesToSpawnInWave = 10;
  bool isWaveActive = false;
  bool isBossWave = false;
  double waveDelay = 3.0;
  double waveTimer = 0;

  EnemyManager({required this.player, required SpaceShooterGame game});

  void startSpawning() {
    isSpawning = true;
    startNextWave();
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
      enemiesToSpawnInWave = 1; // Only spawn boss

      // Switch to boss music and play boss appearance sound
      gameRef.audioManager.playMusic(boss: true);
      gameRef.audioManager.playBossAppear();
    } else {
      enemiesToSpawnInWave =
          10 + (currentWave * 2); // Increase enemies per wave

      // Switch back to normal music
      gameRef.audioManager.playMusic(boss: false);
    }

    gameRef.statsManager.startWave(currentWave, enemiesToSpawnInWave);

    print('[EnemyManager] Wave $currentWave started - Enemies: $enemiesToSpawnInWave');
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
          spawnBoss();
        } else {
          spawnEnemy();
        }
        enemiesSpawnedInWave++;
        spawnTimer = 0;
      }

      // Check if wave is complete (all enemies killed)
      final enemyCount = gameRef.world.children.whereType<BaseEnemy>().length;
      final bossCount = gameRef.world.children.whereType<BossShip>().length;
      final allEnemiesKilled = (enemyCount == 0 && bossCount == 0);

      // Wave completes when: all enemies spawned AND all killed
      if (enemiesSpawnedInWave >= enemiesToSpawnInWave && allEnemiesKilled) {
        // Wave complete - all enemies defeated
        isWaveActive = false;
        waveTimer = 0;
        currentWave++;

        print('[EnemyManager] Wave ${currentWave - 1} completed - ALL ENEMIES DEFEATED');
      }
    } else {
      // Delay between waves
      waveTimer += dt;
      if (waveTimer >= waveDelay && !isWaveActive) {
        startNextWave();
      }
    }

    // Gradually increase spawn rate (faster spawns as waves progress)
    // Start at 1.0s and decrease to 0.2s minimum
    spawnInterval = max(0.2, 1.0 - (currentWave * 0.03));
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
      print('[EnemyManager] Spawned fallback BossShip at wave $currentWave');
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
    print('[EnemyManager] Spawned ${boss.runtimeType} at wave $currentWave');
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
    print('[EnemyManager] Spawned ${enemy.runtimeType} at wave $currentWave with scale ${gameRef.entityScale}');
  }

  int getCurrentWave() => currentWave;
  bool isInBossWave() => isBossWave;
}
