import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../components/enemy_ship.dart';
import '../components/boss_ship.dart';
import '../components/player_ship.dart';

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
  static const double waveDuration = 120.0; // 2 minutes per wave

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

    // Every 10th wave is a boss wave
    isBossWave = currentWave % 10 == 0;

    if (isBossWave) {
      enemiesToSpawnInWave = 1; // Only spawn boss
    } else {
      enemiesToSpawnInWave =
          10 + (currentWave * 2); // Increase enemies per wave
    }

    gameRef.statsManager.startWave(currentWave, enemiesToSpawnInWave, waveDuration);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

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
      final enemyCount = gameRef.world.children.whereType<EnemyShip>().length;
      final bossCount = gameRef.world.children.whereType<BossShip>().length;

      if (enemiesSpawnedInWave >= enemiesToSpawnInWave &&
          enemyCount == 0 &&
          bossCount == 0) {
        // Wave complete
        isWaveActive = false;
        waveTimer = 0;
        currentWave++;
      }
    } else {
      // Delay between waves
      waveTimer += dt;
      if (waveTimer >= waveDelay) {
        startNextWave();
      }
    }

    // Gradually increase difficulty
    spawnInterval = max(0.3, 2.0 - (currentWave * 0.05));
  }

  void spawnBoss() {
    // Spawn boss at top center relative to player position in world coordinates
    final playerPos = player.position;
    final spawnPos = Vector2(playerPos.x, playerPos.y - gameRef.size.y / 2 - 100);

    final boss = BossShip(
      position: spawnPos,
      player: player,
      color: const Color(0xFFFF0000),
      health: 300 + (currentWave * 50), // Boss gets stronger each time
      speed: 30,
      lootValue: 25,
    );

    gameRef.world.add(boss);
  }

  void spawnEnemy() {
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

    // Random enemy type
    final shapes = EnemyShape.values;
    final shape = shapes[random.nextInt(shapes.length)];

    // Different colors for different shapes
    Color color;
    double health;
    int lootValue;
    double speed;

    switch (shape) {
      case EnemyShape.triangle:
        color = const Color(0xFFFF0000);
        health = 20 + (currentWave * 2);
        lootValue = 1;
        speed = 60 + (currentWave * 2);
        break;
      case EnemyShape.square:
        color = const Color(0xFFFF8800);
        health = 40 + (currentWave * 3);
        lootValue = 2;
        speed = 40 + (currentWave * 1.5);
        break;
      case EnemyShape.pentagon:
        color = const Color(0xFFFF00FF);
        health = 60 + (currentWave * 4);
        lootValue = 3;
        speed = 30 + currentWave.toDouble();
        break;
    }

    final enemy = EnemyShip(
      position: spawnPos,
      player: player,
      shape: shape,
      color: color,
      health: health,
      lootValue: lootValue,
      speed: speed,
    );

    gameRef.world.add(enemy);
  }

  int getCurrentWave() => currentWave;
  bool isInBossWave() => isBossWave;
}
