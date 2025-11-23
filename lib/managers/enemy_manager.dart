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
      // We spawn all bosses at once, so count as 1 spawn event
      enemiesToSpawnInWave = 1;

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
          // Determine boss count and spawn accordingly
          final bossCount = getBossCountForWave(currentWave);
          if (currentWave > 50) {
            // Multi-boss spawn for waves 55+
            spawnMultipleBosses(bossCount);
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

  /// Spawn multiple bosses from the boss pool for waves 55+
  /// Bosses are positioned with spacing to avoid overlap
  void spawnMultipleBosses(int count) {
    if (count <= 0) return;

    // Get player position for spawn reference
    final playerPos = player.position;

    // Select random bosses from pool without duplicates
    final selectedBosses = _selectRandomBosses(count);

    // Calculate spacing between bosses (horizontal spread)
    final totalWidth = gameRef.size.x * 0.6; // Use 60% of screen width
    final spacing = selectedBosses.length > 1
        ? totalWidth / (selectedBosses.length - 1)
        : 0.0;

    // Starting X position (centered)
    final startX = playerPos.x - (totalWidth / 2);

    // Base Y position (top of screen)
    final baseY = playerPos.y - gameRef.size.y / 2 - 100;

    print('[EnemyManager] Spawning ${selectedBosses.length} bosses at wave $currentWave');

    // Spawn each selected boss with proper spacing
    for (int i = 0; i < selectedBosses.length; i++) {
      final bossId = selectedBosses[i];

      // Calculate position for this boss
      final xOffset = selectedBosses.length > 1 ? i * spacing : 0.0;
      final spawnPos = Vector2(startX + xOffset, baseY);

      // Create boss directly using factory
      final boss = EnemyFactory.create(
        bossId,
        player,
        currentWave,
        spawnPos,
        scale: gameRef.entityScale,
      );

      gameRef.world.add(boss);
      print('[EnemyManager]   - Spawned ${boss.runtimeType} ($bossId) at position ${spawnPos.x.toStringAsFixed(1)}, ${spawnPos.y.toStringAsFixed(1)}');
    }
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
    print('[EnemyManager] Spawned ${enemy.runtimeType} at wave $currentWave with scale ${gameRef.entityScale}');
  }

  int getCurrentWave() => currentWave;
  bool isInBossWave() => isBossWave;
}
