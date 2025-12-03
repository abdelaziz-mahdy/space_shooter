import 'dart:math';
import 'package:flame/components.dart';
import '../game/space_shooter_game.dart';
import '../components/player_ship.dart';
import '../components/loot.dart';
import '../factories/enemy_factory.dart';
import '../factories/weapon_factory.dart';
import '../upgrades/upgrade.dart';

/// Manager for testing/debug functionality
/// Provides methods to:
/// - Jump to specific waves
/// - Spawn enemies/bosses on demand
/// - Grant upgrades
/// - Modify player state (health, resources, invincibility)
class DebugManager extends Component with HasGameRef<SpaceShooterGame> {
  final PlayerShip player;

  bool isInvincible = false;
  bool showHitboxes = false; // Toggle hitbox rendering

  DebugManager({required this.player});

  /// Jump to a specific wave
  void jumpToWave(int targetWave) {
    if (targetWave < 1) return;

    // Update enemy manager - set directly to target wave
    gameRef.enemyManager.currentWave = targetWave;
    gameRef.enemyManager.isWaveActive = false;
    gameRef.enemyManager.waveTimer = 0;

    // Clear all enemies (use gameRef.activeEnemies which is the cached enemy list)
    for (final enemy in gameRef.activeEnemies.toList()) {
      enemy.removeFromParent();
    }

    // Start the wave (startNextWave uses currentWave directly, doesn't increment)
    gameRef.enemyManager.startNextWave();

    print('[DebugManager] Jumped to wave $targetWave');
  }

  /// Spawn a specific enemy by ID
  void spawnEnemy(String enemyId, {Vector2? position}) {
    final spawnPos = position ?? _getSpawnPositionNearPlayer();

    try {
      final enemy = EnemyFactory.create(
        enemyId,
        player,
        gameRef.enemyManager.currentWave,
        spawnPos,
        scale: gameRef.entityScale,
      );

      gameRef.world.add(enemy);
      print('[DebugManager] Spawned $enemyId at $spawnPos');
    } catch (e) {
      print('[DebugManager] Failed to spawn $enemyId: $e');
    }
  }

  /// Grant a specific upgrade to the player
  void grantUpgrade(String upgradeId) {
    try {
      // Get upgrade from factory by ID
      final allUpgrades = UpgradeFactory.getAllUpgrades();
      final upgrade = allUpgrades.firstWhere(
        (u) => u.id == upgradeId,
        orElse: () => throw Exception('Upgrade not found: $upgradeId'),
      );

      upgrade.apply(player);
      // Track upgrade count
      player.appliedUpgrades[upgradeId] = (player.appliedUpgrades[upgradeId] ?? 0) + 1;
      print('[DebugManager] Granted upgrade: ${upgrade.name} (count: ${player.appliedUpgrades[upgradeId]})');
    } catch (e) {
      print('[DebugManager] Failed to grant upgrade $upgradeId: $e');
    }
  }

  /// Add XP to player
  void addXP(int amount) {
    gameRef.levelManager.addXP(amount);
    print('[DebugManager] Added $amount XP');
  }

  /// Add loot (currency) to player
  void addLoot(int amount) {
    // Note: Loot is collected automatically by LootManager
    // This is just for testing, so we'll spawn loot near player
    for (int i = 0; i < amount ~/ 10; i++) {
      final loot = Loot(
        position: player.position + Vector2(
          (Random().nextDouble() - 0.5) * 100,
          (Random().nextDouble() - 0.5) * 100,
        ),
        xpValue: 10,
      );
      gameRef.world.add(loot);
    }
    print('[DebugManager] Spawned loot worth $amount XP');
  }

  /// Set player health
  void setHealth(double health) {
    player.health = health.clamp(0, player.maxHealth);
    print('[DebugManager] Set health to ${player.health}');
  }

  /// Toggle invincibility
  void toggleInvincibility() {
    isInvincible = !isInvincible;
    print('[DebugManager] Invincibility: $isInvincible');
  }

  /// Toggle hitbox rendering
  void toggleHitboxes() {
    showHitboxes = !showHitboxes;
    gameRef.debugMode = showHitboxes; // Flame's built-in debug mode
    print('[DebugManager] Hitboxes: $showHitboxes');
  }

  /// Heal player to full
  void healToFull() {
    player.health = player.maxHealth;
    print('[DebugManager] Healed to full health');
  }

  /// Kill all enemies
  void killAllEnemies() {
    final enemies = gameRef.activeEnemies.toList();
    int count = 0;
    for (final enemy in enemies) {
      enemy.takeDamage(999999);
      count++;
    }
    print('[DebugManager] Killed $count enemies');
  }

  /// Change weapon
  void changeWeapon(String weaponId) {
    try {
      final weapon = WeaponFactory.create(weaponId);
      player.weaponManager.currentWeapon = weapon;
      print('[DebugManager] Changed weapon to: ${weapon.name}');
    } catch (e) {
      print('[DebugManager] Failed to change weapon to $weaponId: $e');
    }
  }

  Vector2 _getSpawnPositionNearPlayer() {
    // Spawn 200 units above player
    return player.position + Vector2(0, -200);
  }

  /// Get list of all available enemy IDs
  static List<String> getAllEnemyIds() {
    return [
      // Basic enemies
      'basic_enemy',
      'fast_enemy',
      'tank_enemy',
      'sniper_enemy',
      'burst_enemy',
      'scatter_enemy',
      'kamikaze',

      // Bosses (waves 5-50)
      'shielder_boss',      // Wave 5
      'splitter_boss',      // Wave 10
      'gunship_boss',       // Wave 15
      'summoner',           // Wave 20
      'vortex_boss',        // Wave 25
      'fortress_boss',      // Wave 30
      'berserker',          // Wave 35
      'architect_boss',     // Wave 40
      'hydra_boss',         // Wave 45
      'nexus_boss',         // Wave 50
    ];
  }

  /// Get all upgrades grouped by rarity (automatically synced with UpgradeFactory)
  static Map<UpgradeRarity, List<Upgrade>> getAllUpgradesByRarity() {
    final allUpgrades = UpgradeFactory.getAllUpgrades();
    final grouped = <UpgradeRarity, List<Upgrade>>{
      UpgradeRarity.common: [],
      UpgradeRarity.rare: [],
      UpgradeRarity.epic: [],
      UpgradeRarity.legendary: [],
    };

    for (final upgrade in allUpgrades) {
      grouped[upgrade.rarity]?.add(upgrade);
    }

    return grouped;
  }

  /// Get list of all available weapon IDs
  static List<String> getAllWeaponIds() {
    return [
      'pulse_cannon',
      'laser_beam',
      'plasma_spreader',
      'railgun',
      'ion_blaster',
    ];
  }
}
