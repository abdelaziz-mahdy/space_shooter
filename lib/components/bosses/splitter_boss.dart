import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../homing_enemy_bullet.dart';

/// The Splitter Boss: Splits into smaller clones when damaged
/// - Wave 10 boss
/// - Diamond shape (rotated square)
/// - Purple (#9900FF) with pink outline
/// - Health: 400 + (wave * 60)
/// - Speed: 45 + (wave * 1.0)
/// - Contact damage: 30 (20 for medium, 15 for small)
/// - Loot: 35
///
/// Movement:
/// - Erratic zigzag pattern toward player
/// - Changes direction randomly every 1-2 seconds
/// - Moves faster when below 50% health
///
/// Attack:
/// - Triple-shot spread at player every 1 second
/// - Bullets have slight homing capability
/// - Fire rate increases when health is low
///
/// Special Mechanic - Split on Damage:
/// - At 66% health: splits into 2 medium clones (60x60)
/// - At 33% health: each medium clone splits into 2 small clones (40x40)
/// - Each split creates clones with 30% of original boss's remaining health
/// - Smaller clones move 1.5x faster
/// - All clones must be destroyed to complete wave
/// - Max 2 split levels (no infinite splitting)
class SplitterBoss extends BaseEnemy {
  static const String ID = 'splitter_boss';

  // Split state tracking
  final SplitLevel splitLevel;
  bool hasSplit66 = false;
  bool hasSplit33 = false;

  // Movement constants
  static const double zigzagDuration = 1.5; // Changes direction every 1-2 sec
  double zigzagTimer = 0;
  Vector2 currentZigzagDirection = Vector2(0, 1);
  final Random _random = Random();

  // Attack timing
  static const double normalFireRate = 1.0; // 1 second
  static const double lowHealthFireRate = 0.6; // Faster when low health
  double fireTimer = 0;

  SplitterBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
    this.splitLevel = SplitLevel.original,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: _calculateHealth(wave, splitLevel),
          speed: _calculateSpeed(wave, splitLevel),
          lootValue: splitLevel == SplitLevel.original ? 35 : 0, // Only original drops loot
          color: const Color(0xFF9900FF), // Purple
          size: _calculateSize(splitLevel) * scale,
          contactDamage: _calculateContactDamage(splitLevel),
        );

  static double _calculateHealth(int wave, SplitLevel level) {
    final baseHealth = 400.0 + (wave * 60.0);
    switch (level) {
      case SplitLevel.original:
        return baseHealth;
      case SplitLevel.medium:
      case SplitLevel.small:
        // Clones will get 30% of remaining health when split
        return baseHealth * 0.3;
    }
  }

  static double _calculateSpeed(int wave, SplitLevel level) {
    final baseSpeed = 45.0 + (wave * 1.0);
    switch (level) {
      case SplitLevel.original:
        return baseSpeed;
      case SplitLevel.medium:
      case SplitLevel.small:
        return baseSpeed * 1.5; // 1.5x faster
    }
  }

  static Vector2 _calculateSize(SplitLevel level) {
    switch (level) {
      case SplitLevel.original:
        return Vector2(80, 80);
      case SplitLevel.medium:
        return Vector2(60, 60);
      case SplitLevel.small:
        return Vector2(40, 40);
    }
  }

  static double _calculateContactDamage(SplitLevel level) {
    switch (level) {
      case SplitLevel.original:
        return 30.0;
      case SplitLevel.medium:
        return 20.0;
      case SplitLevel.small:
        return 15.0;
    }
  }

  @override
  Future<void> addHitbox() async {
    // Diamond shape (rotated square) hitbox
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final halfSize = size.x / 2;

    final points = <Vector2>[
      Vector2(centerX, centerY - halfSize), // Top
      Vector2(centerX + halfSize, centerY), // Right
      Vector2(centerX, centerY + halfSize), // Bottom
      Vector2(centerX - halfSize, centerY), // Left
    ];

    add(PolygonHitbox(points));
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    final healthBefore = health;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);

    // Check for split thresholds (only for original and medium)
    if (splitLevel == SplitLevel.original) {
      final healthPercent = health / maxHealth;

      // Split at 66% health
      if (!hasSplit66 && healthPercent <= 0.66 && healthBefore / maxHealth > 0.66) {
        hasSplit66 = true;
        splitIntoClones(SplitLevel.medium);
      }
      // Split at 33% health
      else if (!hasSplit33 && healthPercent <= 0.33 && healthBefore / maxHealth > 0.33) {
        hasSplit33 = true;
        splitIntoClones(SplitLevel.medium);
      }
    } else if (splitLevel == SplitLevel.medium) {
      final healthPercent = health / maxHealth;

      // Medium clones split once at 33% health
      if (!hasSplit33 && healthPercent <= 0.33 && healthBefore / maxHealth > 0.33) {
        hasSplit33 = true;
        splitIntoClones(SplitLevel.small);
      }
    }
    // Small clones don't split anymore
  }

  void splitIntoClones(SplitLevel newLevel) {
    print('[SplitterBoss] Splitting into ${newLevel} clones at position $position');

    // Calculate clone health (30% of remaining health)
    final cloneHealth = health * 0.3;

    // Spawn 2 clones offset from current position
    final offset1 = Vector2(30, -30);
    final offset2 = Vector2(-30, 30);

    _spawnClone(position + offset1, cloneHealth, newLevel);
    _spawnClone(position + offset2, cloneHealth, newLevel);

    // Mark as dying to prevent double-death before removal
    isDying = true;
    health = 0;
    removeFromParent(); // Direct removal, no die() to avoid loot/kill count
  }

  void _spawnClone(Vector2 spawnPos, double cloneHealth, SplitLevel level) {
    final clone = SplitterBoss(
      position: spawnPos,
      player: player,
      wave: wave,
      splitLevel: level,
    );

    // Set clone health to 30% of remaining health
    clone.health = cloneHealth;

    // Add to game world
    game.world.add(clone);

    print('[SplitterBoss] Spawned ${level} clone at $spawnPos with health $cloneHealth');
  }

  @override
  void die() {
    // Only small clones (that can't split anymore) should count as kills
    // Medium and original bosses don't count because they split into more enemies
    if (splitLevel == SplitLevel.small) {
      super.die(); // Count as kill and drop loot
    } else {
      // Medium/original dying mid-split: just remove without counting
      isDying = true;
      removeFromParent();
    }
  }

  @override
  void updateMovement(double dt) {
    // Update zigzag timer
    zigzagTimer += dt;

    // Change zigzag direction randomly every 1-2 seconds (not every frame!)
    if (zigzagTimer >= zigzagDuration) {
      zigzagTimer = 0;
      _updateZigzagDirection();
    }

    // Move in current zigzag direction (set by _updateZigzagDirection, not random per-frame)
    // Move faster when below 50% health
    final healthPercent = health / maxHealth;
    final speedMultiplier = healthPercent <= 0.5 ? 1.5 : 1.0;

    position += currentZigzagDirection * getEffectiveSpeed() * speedMultiplier * dt;

    // Rotate to face direction of movement
    angle = atan2(currentZigzagDirection.y, currentZigzagDirection.x) + pi / 4; // +45deg for diamond

    // Update attack
    _updateAttack(dt);
  }

  void _updateZigzagDirection() {
    // Pick random direction toward player with variation
    final toPlayer = PositionUtil.getDirectionTo(this, player);
    final randomAngle = (_random.nextDouble() - 0.5) * pi / 2; // ±45 degrees

    final cosValue = toPlayer.x * cos(randomAngle) - toPlayer.y * sin(randomAngle);
    final sinValue = toPlayer.x * sin(randomAngle) + toPlayer.y * cos(randomAngle);

    currentZigzagDirection = Vector2(cosValue, sinValue).normalized();
  }

  void _updateAttack(double dt) {
    fireTimer += dt;

    // Determine fire rate based on health
    final healthPercent = health / maxHealth;
    final currentFireRate = healthPercent <= 0.5 ? lowHealthFireRate : normalFireRate;

    if (fireTimer >= currentFireRate) {
      fireTimer = 0;
      _fireTripleShot();
    }
  }

  void _fireTripleShot() {
    // Fire 3 bullets in a spread toward player
    final toPlayer = PositionUtil.getDirectionTo(this, player);
    final baseAngle = atan2(toPlayer.y, toPlayer.x);

    // Spread angles: -15°, 0°, +15°
    final spreadAngles = [-pi / 12, 0, pi / 12];

    for (final spreadAngle in spreadAngles) {
      final bulletAngle = baseAngle + spreadAngle;
      final bulletDirection = Vector2(cos(bulletAngle), sin(bulletAngle));

      final bullet = HomingEnemyBullet(
        position: position.clone(),
        direction: bulletDirection,
        damage: 15.0,
        speed: 150.0,
        homingStrength: 30.0, // Slight homing
      );

      game.world.add(bullet);
    }

    print('[SplitterBoss] Fired triple shot');
  }

  @override
  void renderShape(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final halfSize = size.x / 2;

    // Draw diamond shape
    final path = Path()
      ..moveTo(centerX, centerY - halfSize) // Top
      ..lineTo(centerX + halfSize, centerY) // Right
      ..lineTo(centerX, centerY + halfSize) // Bottom
      ..lineTo(centerX - halfSize, centerY) // Left
      ..close();

    // Fill with purple
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Pink outline
    final strokePaint = Paint()
      ..color = const Color(0xFFFF1493) // Deep pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return SplitterBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 10 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 10) {
      return 100.0; // High weight to ensure boss spawns
    }
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Enum to track split level (no switch statements on behavior, just for state)
enum SplitLevel {
  original,
  medium,
  small,
}
