import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../components/player_ship.dart';
import '../components/star_particle.dart';
import '../components/debug_overlay.dart';
import '../managers/enemy_manager.dart';
import '../managers/loot_manager.dart';
import '../managers/level_manager.dart';
import '../managers/stats_manager.dart';
import '../managers/star_manager.dart';
import '../managers/combo_manager.dart';
import '../managers/audio_manager.dart';
import '../ui/touch_joystick.dart';

// Import all enemies for factory registration
import '../components/enemies/triangle_enemy.dart';
import '../components/enemies/square_enemy.dart';
import '../components/enemies/pentagon_enemy.dart';
import '../components/enemies/scout_enemy.dart';
import '../components/enemies/tank_enemy.dart';
import '../components/enemies/ranger_enemy.dart';
import '../components/enemies/kamikaze_enemy.dart';

// Import all bosses for factory registration
import '../components/bosses/shielder_boss.dart';
import '../components/bosses/berserker_boss.dart';
import '../components/bosses/gunship_boss.dart';
import '../components/bosses/splitter_boss.dart';
import '../components/bosses/summoner_boss.dart';
import '../components/bosses/vortex_boss.dart';
import '../components/bosses/fortress_boss.dart';
import '../components/bosses/architect_boss.dart';
import '../components/bosses/hydra_boss.dart';
import '../components/bosses/nexus_boss.dart';

// Import all weapons for factory registration
import '../weapons/pulse_cannon.dart';
import '../weapons/plasma_spreader.dart';
import '../weapons/railgun.dart';
import '../weapons/missile_launcher.dart';
import '../weapons/laser_beam.dart';
import '../weapons/shotgun_blaster.dart';
import '../weapons/tesla_coil.dart';

class SpaceShooterGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  late PlayerShip player;
  late EnemyManager enemyManager;
  late LootManager lootManager;
  late LevelManager levelManager;
  late StatsManager statsManager;
  late StarManager starManager;
  late ComboManager comboManager;
  late AudioManager audioManager;
  TouchJoystick? joystick;

  bool isGameOver = false;
  bool isPaused = false; // Used for upgrades and game over
  bool hasLoaded = false; // Track if game has completed initialization
  bool isAudioMuted = false; // Audio mute state

  // Entity scale factor based on screen size (smaller on mobile)
  double entityScale = 1.0;

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

    // Initialize audio manager
    audioManager = AudioManager();
    await audioManager.initialize();

    // Register all factories on first load
    _registerFactories();

    await initializeGame();
  }

  /// Register all enemy and weapon factories
  /// This is called once when the game is loaded
  void _registerFactories() {
    // Register all enemies
    TriangleEnemy.init();
    SquareEnemy.init();
    PentagonEnemy.init();
    ScoutEnemy.init();
    TankEnemy.init();
    RangerEnemy.init();
    KamikazeEnemy.init();

    // Register all bosses
    ShielderBoss.init();
    BerserkerBoss.init();
    GunshipBoss.init();
    SplitterBoss.init();
    SummonerBoss.init();
    VortexBoss.init();
    FortressBoss.init();
    ArchitectBoss.init();
    HydraBoss.init();
    NexusBoss.init();

    // Register all weapons
    PulseCannon.init();
    PlasmaSpreader.init();
    Railgun.init();
    MissileLauncher.init();
    LaserBeam.init();
    ShotgunBlaster.init();
    TeslaCoil.init();

    print('[SpaceShooterGame] All factories registered successfully');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Manually update camera to follow player with no lag
    if (player.isMounted) {
      camera.viewfinder.position = player.position;
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Update camera viewport when game is resized to keep player centered
    camera.viewfinder.visibleGameSize = size;
    camera.viewport.position = size / 2;
  }

  Future<void> initializeGame() async {
    isGameOver = false;

    // Calculate entity scale based on screen size
    // Smaller screens (mobile) get smaller entities
    final screenWidth = size.x;
    entityScale = (screenWidth / 800.0).clamp(0.6, 1.0);
    print('[SpaceShooterGame] Entity scale set to: $entityScale (screen width: $screenWidth)');

    // Initialize player in the center of the world with scaled size
    player = PlayerShip(position: Vector2.zero(), scale: entityScale);
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

    comboManager = ComboManager();
    world.add(comboManager);

    enemyManager = EnemyManager(game: this, player: player);
    world.add(enemyManager);

    // Add touch joystick for mobile/touch devices
    if (_isMobilePlatform()) {
      joystick = TouchJoystick();
      camera.viewport.add(joystick!);
    }

    // Start spawning enemies
    enemyManager.startSpawning();

    // Start background music (DISABLED - only sound effects enabled)
    // await audioManager.playMusic(boss: false);

    // Mark game as loaded
    hasLoaded = true;
  }

  /// Check if running on a mobile platform (runtime detection)
  /// Works correctly for both native apps and web
  /// On web, defaultTargetPlatform detects the browser's OS (iOS/Android for mobile browsers)
  bool _isMobilePlatform() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
           defaultTargetPlatform == TargetPlatform.android;
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

    // Play game over sound and stop music
    audioManager.playGameOver();
    audioManager.stopMusic();

    // Trigger Flutter UI to show game over screen
    if (onShowGameOver != null) {
      onShowGameOver!();
    }
  }

  void returnToMainMenu() {
    // This will be called from Flutter layer
    print('[Game] Returning to main menu');

    // Stop music when returning to menu
    audioManager.stopMusic();

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
