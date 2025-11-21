import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../components/player_ship.dart';
import '../components/star_particle.dart';
import '../components/debug_overlay.dart';
import '../managers/enemy_manager.dart';
import '../managers/loot_manager.dart';
import '../managers/level_manager.dart';
import '../managers/stats_manager.dart';
import '../managers/star_manager.dart';
import '../ui/touch_joystick.dart';

class SpaceShooterGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  late PlayerShip player;
  late EnemyManager enemyManager;
  late LootManager lootManager;
  late LevelManager levelManager;
  late StatsManager statsManager;
  late StarManager starManager;
  TouchJoystick? joystick;

  bool isGameOver = false;
  bool isPaused = false; // Used for upgrades and game over

  // Callbacks for Flutter UI
  VoidCallback? onShowUpgrade;
  VoidCallback? onHideUpgrade;
  VoidCallback? onShowGameOver;
  VoidCallback? onReturnToMenu;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await initializeGame();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Manually update camera to follow player with no lag
    if (player.isMounted) {
      camera.viewfinder.position = player.position;
    }
  }

  Future<void> initializeGame() async {
    isGameOver = false;

    // Initialize player in the center of the world
    player = PlayerShip(position: Vector2.zero());
    world.add(player);

    // Set up camera to follow player smoothly
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.visibleGameSize = size;
    camera.viewport.anchor = Anchor.center;
    camera.viewport.position = size / 2; // Center the viewport

    // Use a fixed viewfinder that always keeps player centered
    camera.viewfinder.position = player.position;
    // Don't use camera.follow() as it can have lag

    // Initialize star manager for infinite star spawning
    starManager = StarManager(player: player);
    world.add(starManager);

    // Initialize managers
    statsManager = StatsManager(game: this);
    world.add(statsManager);

    lootManager = LootManager(game: this);
    world.add(lootManager);

    levelManager = LevelManager(game: this);
    world.add(levelManager);

    enemyManager = EnemyManager(game: this, player: player);
    world.add(enemyManager);

    // Add touch joystick for mobile/touch devices
    if (_isMobile()) {
      joystick = TouchJoystick();
      camera.viewport.add(joystick!);
    }

    // Start spawning enemies
    enemyManager.startSpawning();
  }

  bool _isMobile() {
    // Check if running on mobile platform
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      player.handleKeyDown(event.logicalKey);
    } else if (event is KeyUpEvent) {
      player.handleKeyUp(event.logicalKey);
    }
    return KeyEventResult.handled;
  }

  void pauseForUpgrade() {
    // Don't actually pause the engine - just set a flag
    // The overlay will block interactions and we stop spawning enemies
    isPaused = true;
    enemyManager.stopSpawning();
    print('[SpaceShooterGame] Game paused for upgrade');

    // Trigger Flutter UI to show upgrade dialog
    if (onShowUpgrade != null) {
      onShowUpgrade!();
    }
  }

  void resumeFromUpgrade() {
    // Resume spawning
    isPaused = false;
    enemyManager.startSpawning();
    print('[SpaceShooterGame] Game resumed from upgrade');
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;

    // Pause the game to stop all movement and updates
    isPaused = true;
    enemyManager.stopSpawning();

    // Trigger Flutter UI to show game over screen
    if (onShowGameOver != null) {
      onShowGameOver!();
    }
  }

  void returnToMainMenu() {
    // This will be called from Flutter layer
    print('[Game] Returning to main menu');
    if (onReturnToMenu != null) {
      onReturnToMenu!();
    }
  }

  Future<void> restart() async {
    // Reset flags
    isGameOver = false;
    isPaused = false;

    // Remove all components from world and viewport
    world.removeAll(world.children);
    camera.viewport.removeAll(camera.viewport.children);

    // Reinitialize the game
    await initializeGame();
  }
}
