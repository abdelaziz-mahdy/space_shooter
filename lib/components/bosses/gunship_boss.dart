import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../utils/position_util.dart';
import '../../factories/enemy_factory.dart';
import '../../config/enemy_spawn_config.dart';
import '../enemies/base_enemy.dart';
import '../player_ship.dart';
import '../enemy_bullet.dart';

/// The Gunship Boss: Bullet hell boss with cycling attack patterns
/// - Wave 15 boss
/// - Star shape (5-pointed), orange-red (#FF4500) with yellow accents
/// - Health: 450 + (wave * 65)
/// - Speed: 40 + (wave * 0.8)
/// - Contact damage: 28
/// - Loot: 38
///
/// Movement:
/// - Stays at long range (400-500px from player)
/// - Strafes left/right horizontally
/// - Retreats if player gets too close (<250px)
///
/// Attack Patterns (cycles through every 8 seconds):
/// - Pattern 1 - Spiral: 12-way radial burst that rotates, every 2 seconds
/// - Pattern 2 - Wave: 5 waves of bullets toward player, 0.3s apart
/// - Pattern 3 - Shotgun: 15-bullet cone toward player
///
/// Special Mechanics:
/// - Cycles through 3 attack patterns
/// - Visual warning: star points glow different colors per pattern
/// - Between patterns: 1 second vulnerability window (takes 2x damage)
/// - Bullet speed increases with each cycle
class GunshipBoss extends BaseEnemy {
  static const String ID = 'gunship_boss';

  // Movement constants
  static const double minDistance = 400;
  static const double maxDistance = 500;
  static const double retreatDistance = 250;
  static const double strafeSpeed = 0.7;

  // Pattern timing
  static const double patternDuration = 8.0;
  static const double vulnerabilityDuration = 1.0;

  // Attack pattern timing
  static const double spiralInterval = 2.0;
  static const double waveInterval = 0.3;
  static const double waveBurstCount = 5;

  // Bullet configuration
  static const double baseBulletSpeed = 180;
  static const double bulletDamage = 20;
  static const int spiralBulletCount = 12;
  static const int shotgunBulletCount = 15;
  static const double shotgunSpreadAngle = pi / 3; // 60 degrees

  // Pattern state
  int currentPattern = 0; // 0 = spiral, 1 = wave, 2 = shotgun
  double patternTimer = 0;
  bool isVulnerable = false;
  double vulnerabilityTimer = 0;
  int cycleCount = 0;

  // Attack timers
  double spiralTimer = 0;
  double spiralRotation = 0;
  double waveTimer = 0;
  int wavesFired = 0;

  // Visual effects
  double glowIntensity = 0;
  double glowTimer = 0;

  GunshipBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 450 + (wave * 65),
          speed: 40 + (wave * 0.8),
          lootValue: 38,
          color: const Color(0xFFFF4500), // Orange-red
          size: Vector2(60, 60) * scale,
          contactDamage: 28.0,
        );

  @override
  Future<void> addHitbox() async {
    // Star shape (5 points) hitbox
    final sides = 5;
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;
    final innerRadius = outerRadius * 0.4; // Inner points for star

    for (int i = 0; i < sides * 2; i++) {
      final angle = (i * pi / sides) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      points.add(Vector2(
        centerX + cos(angle) * radius,
        centerY + sin(angle) * radius,
      ));
    }

    add(PolygonHitbox(points));
  }

  @override
  double modifyIncomingDamage(double damage) {
    // Take 2x damage during vulnerability window
    return isVulnerable ? damage * 2.0 : damage;
  }

  @override
  void updateMovement(double dt) {
    final distanceToPlayer = PositionUtil.getDistance(this, player);
    final direction = PositionUtil.getDirectionTo(this, player);

    // Update pattern state machine
    updatePatternState(dt);

    // Movement behavior based on distance
    if (distanceToPlayer < retreatDistance) {
      // Too close - retreat away from player
      position += direction * -getEffectiveSpeed() * dt;
    } else if (distanceToPlayer < minDistance) {
      // Below ideal range - back away slowly
      position += direction * -getEffectiveSpeed() * 0.5 * dt;
    } else if (distanceToPlayer > maxDistance) {
      // Too far - move closer
      position += direction * getEffectiveSpeed() * 0.6 * dt;
    } else {
      // In ideal range - strafe horizontally
      final perpendicular = Vector2(-direction.y, direction.x);
      position += perpendicular * getEffectiveSpeed() * strafeSpeed * dt;
    }

    // Rotate to face player
    angle = atan2(direction.y, direction.x) + pi / 2;

    // Update glow effect
    glowTimer += dt * 3;
    glowIntensity = (sin(glowTimer) + 1) / 2; // Oscillate between 0 and 1
  }

  void updatePatternState(double dt) {
    // Update vulnerability timer
    if (isVulnerable) {
      vulnerabilityTimer += dt;
      if (vulnerabilityTimer >= vulnerabilityDuration) {
        isVulnerable = false;
        vulnerabilityTimer = 0;
        // Move to next pattern
        currentPattern = (currentPattern + 1) % 3;
        cycleCount++;

        // Reset pattern-specific timers
        spiralTimer = 0;
        waveTimer = 0;
        wavesFired = 0;

        print('[GunshipBoss] Pattern changed to $currentPattern, cycle $cycleCount');
      }
      return; // Don't attack during vulnerability
    }

    // Update pattern timer
    patternTimer += dt;

    if (patternTimer >= patternDuration) {
      // Enter vulnerability window
      isVulnerable = true;
      patternTimer = 0;
      print('[GunshipBoss] Entering vulnerability window');
      return;
    }

    // Execute current attack pattern
    switch (currentPattern) {
      case 0:
        executeSpiral(dt);
        break;
      case 1:
        executeWave(dt);
        break;
      case 2:
        executeShotgun(dt);
        break;
    }
  }

  void executeSpiral(double dt) {
    spiralTimer += dt;

    if (spiralTimer >= spiralInterval) {
      spiralTimer = 0;

      // Fire 12-way radial burst with rotation
      final bulletSpeed = baseBulletSpeed + (cycleCount * 15);

      for (int i = 0; i < spiralBulletCount; i++) {
        final angle = (i * 2 * pi / spiralBulletCount) + spiralRotation;
        final direction = Vector2(cos(angle), sin(angle));

        final bullet = EnemyBullet(
          position: position.clone(),
          direction: direction,
          damage: bulletDamage,
          speed: bulletSpeed,
        );

        gameRef.world.add(bullet);
      }

      // Rotate spiral for next shot
      spiralRotation += pi / 6; // 30 degrees

      print('[GunshipBoss] Fired spiral burst');
    }
  }

  void executeWave(double dt) {
    waveTimer += dt;

    if (waveTimer >= waveInterval && wavesFired < waveBurstCount) {
      waveTimer = 0;
      wavesFired++;

      // Fire wave toward player
      final direction = PositionUtil.getDirectionTo(this, player);
      final bulletSpeed = baseBulletSpeed + (cycleCount * 15);

      // Fire 3 bullets in a small spread
      for (int i = -1; i <= 1; i++) {
        final spreadAngle = i * (pi / 16); // Small spread
        final rotatedDir = Vector2(
          direction.x * cos(spreadAngle) - direction.y * sin(spreadAngle),
          direction.x * sin(spreadAngle) + direction.y * cos(spreadAngle),
        );

        final bullet = EnemyBullet(
          position: position.clone(),
          direction: rotatedDir,
          damage: bulletDamage,
          speed: bulletSpeed,
        );

        gameRef.world.add(bullet);
      }

      print('[GunshipBoss] Fired wave $wavesFired');
    }

    // Reset for next cycle
    if (wavesFired >= waveBurstCount && waveTimer >= waveInterval) {
      waveTimer = 0;
      wavesFired = 0;
    }
  }

  void executeShotgun(double dt) {
    // Fire once per pattern cycle
    if (patternTimer < dt * 2) { // Only fire at the start of pattern
      final direction = PositionUtil.getDirectionTo(this, player);
      final bulletSpeed = baseBulletSpeed + (cycleCount * 15);
      final baseAngle = atan2(direction.y, direction.x);

      // Fire 15 bullets in a cone
      for (int i = 0; i < shotgunBulletCount; i++) {
        final spreadOffset = (i - shotgunBulletCount / 2) * (shotgunSpreadAngle / shotgunBulletCount);
        final bulletAngle = baseAngle + spreadOffset;
        final bulletDir = Vector2(cos(bulletAngle), sin(bulletAngle));

        final bullet = EnemyBullet(
          position: position.clone(),
          direction: bulletDir,
          damage: bulletDamage,
          speed: bulletSpeed,
        );

        gameRef.world.add(bullet);
      }

      print('[GunshipBoss] Fired shotgun burst');
    }
  }

  @override
  void renderShape(Canvas canvas) {
    final sides = 5;
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;
    final innerRadius = outerRadius * 0.4;

    // Draw star body
    final path = Path();
    for (int i = 0; i < sides * 2; i++) {
      final angle = (i * pi / sides) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = centerX + cos(angle) * radius;
      final y = centerY + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill color (different during vulnerability)
    final fillPaint = Paint()
      ..color = isVulnerable ? const Color(0xFF8B0000) : color // Dark red when vulnerable
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw glowing star points based on pattern
    if (!isVulnerable) {
      final glowColor = _getPatternColor();
      final glowPaint = Paint()
        ..color = glowColor.withOpacity(glowIntensity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw glow on outer points only
      for (int i = 0; i < sides; i++) {
        final angle = (i * 2 * pi / sides) - pi / 2;
        final x = centerX + cos(angle) * outerRadius;
        final y = centerY + sin(angle) * outerRadius;

        canvas.drawCircle(Offset(x, y), 4 + glowIntensity * 2, glowPaint);
      }
    }

    // Draw white border
    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // Draw vulnerability indicator
    if (isVulnerable) {
      final vulnPaint = Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawCircle(
        Offset(centerX, centerY),
        outerRadius + 5,
        vulnPaint,
      );
    }

    // Draw status effects and health bar
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);
    renderHealthBar(canvas);
  }

  Color _getPatternColor() {
    switch (currentPattern) {
      case 0: // Spiral - Cyan
        return const Color(0xFF00FFFF);
      case 1: // Wave - Yellow
        return const Color(0xFFFFFF00);
      case 2: // Shotgun - Red
        return const Color(0xFFFF0000);
      default:
        return const Color(0xFFFFFFFF);
    }
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return GunshipBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 15 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 15) {
      return 100.0; // High weight to ensure boss spawns
    }
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
