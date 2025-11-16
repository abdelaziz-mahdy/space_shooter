import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import '../components/player_ship.dart';
import '../components/enemy_ship.dart';
import '../managers/enemy_manager.dart';
import '../managers/loot_manager.dart';
import '../managers/level_manager.dart';

class SpaceShooterGame extends FlameGame with HasCollisionDetection {
  late PlayerShip player;
  late EnemyManager enemyManager;
  late LootManager lootManager;
  late LevelManager levelManager;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initialize player in the center
    player = PlayerShip(
      position: size / 2,
    );
    await add(player);

    // Initialize managers
    lootManager = LootManager(game: this);
    await add(lootManager);

    levelManager = LevelManager(game: this);
    await add(levelManager);

    enemyManager = EnemyManager(
      game: this,
      player: player,
    );
    await add(enemyManager);

    // Start spawning enemies
    enemyManager.startSpawning();
  }

  void pauseForUpgrade() {
    pauseEngine();
  }

  void resumeFromUpgrade() {
    resumeEngine();
  }
}
