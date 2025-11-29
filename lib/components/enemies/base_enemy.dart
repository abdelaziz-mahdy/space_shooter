import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import '../../game/space_shooter_game.dart';
import '../../utils/visual_center_mixin.dart';
import '../base_rendered_component.dart';
import '../damage_number.dart';
import '../loot.dart';
import '../../factories/power_up_factory.dart';
import '../player_ship.dart';

/// Abstract base class for all enemy types
/// Provides common functionality like health, damage, loot drops, and collision handling
abstract class BaseEnemy extends BaseRenderedComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks, HasVisualCenter {
  final PlayerShip player;
  final int wave;

  double health;
  final double maxHealth;
  final double speed;
  final int lootValue;
  final Color color;
  double contactDamage;

  // Freeze effect
  bool isFrozen = false;
  double freezeTimer = 0;
  double freezeSlowMultiplier = 1.0;

  // Bleed effect
  bool isBleeding = false;
  double bleedTimer = 0;
  double bleedDamagePerSecond = 0;
  static const double bleedDuration = 3.0; // 3 seconds

  BaseEnemy({
    required Vector2 position,
    required this.player,
    required this.wave,
    required this.health,
    required this.speed,
    required this.lootValue,
    required this.color,
    required Vector2 size,
    this.contactDamage = 10.0,
  })  : maxHealth = health,
        super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Subclasses should add their own hitboxes
    await addHitbox();
  }

  @override
  Vector2 getVisualCenter() => position.clone();

  /// Override this to add custom hitbox for each enemy type
  Future<void> addHitbox();

  /// Override this for custom movement behavior
  void updateMovement(double dt);

  /// Apply freeze effect to this enemy
  void applyFreeze(double duration) {
    isFrozen = true;
    freezeTimer = duration;
    freezeSlowMultiplier = 0.3; // Move at 30% speed when frozen
  }

  /// Apply bleed effect to this enemy
  void applyBleed(double damagePerSecond) {
    if (damagePerSecond <= 0) return;
    isBleeding = true;
    bleedTimer = bleedDuration;
    bleedDamagePerSecond = damagePerSecond;
  }

  /// Get current effective speed (accounting for freeze and global time scale)
  double getEffectiveSpeed() {
    final globalTimeScale = gameRef.player.globalTimeScale ?? 1.0;
    return speed * freezeSlowMultiplier * globalTimeScale;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused
    if (gameRef.isPaused) return;

    // Update freeze timer
    if (isFrozen) {
      freezeTimer -= dt;
      if (freezeTimer <= 0) {
        isFrozen = false;
        freezeTimer = 0;
        freezeSlowMultiplier = 1.0;
      }
    }

    // Update bleed effect
    if (isBleeding) {
      bleedTimer -= dt;
      // Apply bleed damage over time (no damage number to avoid spam)
      final bleedDamage = bleedDamagePerSecond * dt;
      health -= bleedDamage;

      if (health <= 0) {
        die();
        return;
      }

      if (bleedTimer <= 0) {
        isBleeding = false;
        bleedTimer = 0;
        bleedDamagePerSecond = 0;
      }
    }

    // Call custom movement logic
    updateMovement(dt);
  }

  /// Take damage with optional damage modification
  /// Shows damage number automatically - weapons don't need to handle this
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    final actualDamage = modifyIncomingDamage(damage);
    health -= actualDamage;

    // Show damage number (centralized - all weapons get this for free)
    if (showDamageNumber && actualDamage > 0) {
      final damageNumber = DamageNumber(
        position: position.clone(),
        damage: actualDamage,
        isCrit: isCrit,
      );
      gameRef.world.add(damageNumber);
    }

    // Apply bleed effect if player has bleed damage
    if (player.bleedDamage > 0) {
      applyBleed(player.bleedDamage);
    }

    if (health <= 0) {
      die();
    }
  }

  /// Override this to modify incoming damage (e.g., Tank's damage reduction)
  double modifyIncomingDamage(double damage) {
    return damage;
  }

  /// Override this for custom death behavior (e.g., Kamikaze's explosion)
  void onDeath() {
    // Subclasses can override for custom death effects
  }

  /// Called when enemy dies - handles loot drops and cleanup
  void die() {
    // Play explosion sound
    gameRef.audioManager.playExplosion();

    // Call custom death behavior first
    onDeath();

    // Drop XP loot
    for (int i = 0; i < lootValue; i++) {
      final loot = Loot(
        position: position.clone() + Vector2.random() * 20 - Vector2.all(10),
      );
      gameRef.world.add(loot);
    }

    // Random chance to drop power-up (affected by player luck)
    final random = Random();
    final dropChance = 0.15 + (player.luck * 0.1); // Base 15% + luck bonus

    if (random.nextDouble() < dropChance) {
      // Create random power-up using factory
      final powerUp = PowerUpFactory.createRandom(position.clone());
      gameRef.world.add(powerUp);
      print('[${runtimeType}] Dropped power-up: ${powerUp.runtimeType}');
    }

    // Increment kill count
    gameRef.statsManager.incrementKills();

    // Add kill to combo meter
    gameRef.comboManager.addKill();

    removeFromParent();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerShip) {
      other.takeDamage(contactDamage);

      // Apply thorns damage reflection
      if (player.thornsPercent > 0) {
        final thornsDamage = contactDamage * (player.thornsPercent / 100.0);
        takeDamage(thornsDamage);
      }

      die(); // Enemy dies on collision with player
    }
  }

  /// Helper method to draw health bar
  void renderHealthBar(Canvas canvas) {
    final healthBarWidth = size.x;
    final healthBarHeight = 3.0;
    final healthBarY = -5.0; // Above the component

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()..color = const Color(0xFF00FF00);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }

  /// Helper method to render freeze effect
  void renderFreezeEffect(Canvas canvas) {
    if (!isFrozen) return;

    // Blue overlay to indicate frozen state
    final freezePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw freeze overlay over the enemy
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      freezePaint,
    );

    // Draw ice crystal border
    final borderPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }

  /// Helper method to render bleed effect
  void renderBleedEffect(Canvas canvas) {
    if (!isBleeding) return;

    // Red pulsing border to indicate bleeding
    final borderPaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      borderPaint,
    );
  }
}
