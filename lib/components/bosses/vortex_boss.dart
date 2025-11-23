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
import '../enemy_homing_missile.dart';

/// The Vortex Boss: Phase-shifting teleportation boss
/// - Wave 25 boss
/// - Hexagram (6-pointed star), cyan (#00FFFF) with dark blue trail
/// - Health: 420 + (wave * 62)
/// - Speed: 60 + (wave * 1.2) - fast
/// - Contact damage: 32
/// - Loot: 40
///
/// Movement:
/// - Teleports to random position around player every 3-5 seconds
/// - Moves rapidly between teleports
/// - Leaves afterimage trail
///
/// Attack:
/// - Immediately after teleporting: fires 6-way radial burst
/// - While moving: fires seeking missiles at player (1 per second)
/// - Teleports more frequently when below 40% health
///
/// Special Mechanic - Phase Shift Teleportation:
/// - Teleports to random position within 400px of player
/// - During teleport (0.5s): becomes invulnerable
/// - Visual portal effect at departure/arrival
/// - After 3 teleports: 6 second cooldown (vulnerable, no teleport)
/// - Can teleport through player to escape corners
class VortexBoss extends BaseEnemy {
  static const String ID = 'vortex_boss';

  // Teleportation mechanics
  static const double minTeleportInterval = 3.0;
  static const double maxTeleportInterval = 5.0;
  static const double teleportRadius = 400.0; // Max distance from player
  static const double teleportDuration = 0.5; // Invulnerable animation time
  static const int maxTeleportsBeforeCooldown = 3;
  static const double cooldownDuration = 6.0;

  // Attack mechanics
  static const double missileInterval = 1.0;
  static const int radialBurstCount = 6;
  static const double bulletSpeed = 200.0;
  static const double bulletDamage = 18.0;
  static const double missileSpeed = 150.0;
  static const double missileDamage = 22.0;

  // Visual effects
  static const double afterimageInterval = 0.05;
  static const int maxAfterimages = 8;

  // State tracking
  double teleportTimer = 0;
  double nextTeleportDelay = 0;
  bool isTeleporting = false;
  double teleportAnimTimer = 0;
  int teleportCount = 0;
  bool isInCooldown = false;
  double cooldownTimer = 0;

  // Attack timers
  double missileTimer = 0;

  // Visual effects
  final List<_Afterimage> afterimages = [];
  double afterimageTimer = 0;
  double portalEffect = 0;
  double glowPulse = 0;

  // Teleport locations
  Vector2? teleportTargetPos;

  VortexBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 420 + (wave * 62),
          speed: 60 + (wave * 1.2),
          lootValue: 40,
          color: const Color(0xFF00FFFF), // Cyan
          size: Vector2(55, 55) * scale,
          contactDamage: 32.0,
        ) {
    // Initialize first teleport delay
    final random = Random();
    nextTeleportDelay = minTeleportInterval +
        random.nextDouble() * (maxTeleportInterval - minTeleportInterval);
  }

  @override
  Future<void> addHitbox() async {
    // Hexagram (6-pointed star) hitbox
    // A hexagram is two overlapping triangles (Star of David shape)
    final points = <Vector2>[];
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;

    // Create 12 points (6 outer points, 6 inner points)
    for (int i = 0; i < 12; i++) {
      final angle = (i * pi / 6) - pi / 2; // 30 degrees per step
      final radius = i.isEven ? outerRadius : outerRadius * 0.5;
      points.add(Vector2(
        centerX + cos(angle) * radius,
        centerY + sin(angle) * radius,
      ));
    }

    add(PolygonHitbox(points));
  }

  @override
  double modifyIncomingDamage(double damage) {
    // Invulnerable during teleport animation
    return isTeleporting ? 0.0 : damage;
  }

  @override
  void updateMovement(double dt) {
    glowPulse += dt * 4;

    // Update afterimages
    _updateAfterimages(dt);

    // Update cooldown state
    if (isInCooldown) {
      cooldownTimer += dt;
      if (cooldownTimer >= cooldownDuration) {
        isInCooldown = false;
        cooldownTimer = 0;
        teleportCount = 0;
        print('[VortexBoss] Cooldown ended, reset teleport count');
      }
    }

    // Handle teleportation
    if (isTeleporting) {
      _updateTeleportAnimation(dt);
      return; // Don't move during teleport
    }

    // Update teleport timer
    teleportTimer += dt;

    // Check if low health (teleport more frequently)
    final healthPercent = health / maxHealth;
    final adjustedDelay = healthPercent < 0.4 ? nextTeleportDelay * 0.6 : nextTeleportDelay;

    // Teleport if timer is up and not in cooldown
    if (teleportTimer >= adjustedDelay && !isInCooldown) {
      _startTeleport();
      return;
    }

    // Normal movement - move toward player
    final direction = PositionUtil.getDirectionTo(this, player);
    position += direction * getEffectiveSpeed() * dt;

    // Rotate to face player
    angle = atan2(direction.y, direction.x) + pi / 2;

    // Create afterimages while moving
    afterimageTimer += dt;
    if (afterimageTimer >= afterimageInterval) {
      _addAfterimage();
      afterimageTimer = 0;
    }

    // Fire homing missiles
    missileTimer += dt;
    if (missileTimer >= missileInterval) {
      _fireHomingMissile();
      missileTimer = 0;
    }
  }

  void _startTeleport() {
    isTeleporting = true;
    teleportAnimTimer = 0;
    portalEffect = 0;

    // Calculate teleport target position
    final random = Random();
    final angle = random.nextDouble() * 2 * pi;
    final distance = random.nextDouble() * teleportRadius;

    teleportTargetPos = player.position.clone() + Vector2(
      cos(angle) * distance,
      sin(angle) * distance,
    );

    print('[VortexBoss] Starting teleport to position near player');
  }

  void _updateTeleportAnimation(double dt) {
    teleportAnimTimer += dt;
    portalEffect = (teleportAnimTimer / teleportDuration).clamp(0.0, 1.0);

    // Halfway through animation, actually teleport
    if (teleportAnimTimer >= teleportDuration / 2 && teleportTargetPos != null) {
      position = teleportTargetPos!;
      teleportTargetPos = null;
    }

    // Complete teleport
    if (teleportAnimTimer >= teleportDuration) {
      isTeleporting = false;
      teleportAnimTimer = 0;
      portalEffect = 0;
      teleportTimer = 0;

      // Increment teleport count
      teleportCount++;

      // Fire 6-way radial burst
      _fireRadialBurst();

      // Check if cooldown should start
      if (teleportCount >= maxTeleportsBeforeCooldown) {
        isInCooldown = true;
        cooldownTimer = 0;
        print('[VortexBoss] Entered cooldown after $teleportCount teleports');
      }

      // Set next teleport delay
      final random = Random();
      nextTeleportDelay = minTeleportInterval +
          random.nextDouble() * (maxTeleportInterval - minTeleportInterval);
    }
  }

  void _fireRadialBurst() {
    // Fire 6 bullets in all directions
    for (int i = 0; i < radialBurstCount; i++) {
      final angle = (i * 2 * pi / radialBurstCount);
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      gameRef.world.add(bullet);
    }

    print('[VortexBoss] Fired 6-way radial burst after teleport');
  }

  void _fireHomingMissile() {
    final direction = PositionUtil.getDirectionTo(this, player);

    final missile = EnemyHomingMissile(
      position: position.clone(),
      direction: direction,
      damage: missileDamage,
      speed: missileSpeed,
    );

    gameRef.world.add(missile);
  }

  void _addAfterimage() {
    afterimages.add(_Afterimage(
      position: position.clone(),
      angle: angle,
      opacity: 0.3,
    ));

    // Limit number of afterimages
    if (afterimages.length > maxAfterimages) {
      afterimages.removeAt(0);
    }
  }

  void _updateAfterimages(double dt) {
    // Fade out afterimages
    for (final afterimage in afterimages) {
      afterimage.opacity -= dt * 2;
    }

    // Remove faded afterimages
    afterimages.removeWhere((afterimage) => afterimage.opacity <= 0);
  }

  @override
  void renderShape(Canvas canvas) {
    // Draw afterimages first (behind boss)
    for (final afterimage in afterimages) {
      canvas.save();
      canvas.translate(
        afterimage.position.x - position.x,
        afterimage.position.y - position.y,
      );
      canvas.rotate(afterimage.angle);
      _drawHexagram(canvas, color.withOpacity(afterimage.opacity * 0.5));
      canvas.restore();
    }

    // Draw portal effect during teleport
    if (isTeleporting) {
      _drawPortalEffect(canvas);
    }

    // Draw main hexagram
    final mainOpacity = isTeleporting ? (1.0 - portalEffect * 0.7) : 1.0;
    _drawHexagram(canvas, color.withOpacity(mainOpacity));

    // Draw glow effect
    if (!isTeleporting) {
      final glowIntensity = (sin(glowPulse) + 1) / 2;
      final glowPaint = Paint()
        ..color = color.withOpacity(glowIntensity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final centerX = size.x / 2;
      final centerY = size.y / 2;
      final outerRadius = size.x / 2;

      canvas.drawCircle(
        Offset(centerX, centerY),
        outerRadius + 5,
        glowPaint,
      );
    }

    // Draw cooldown indicator
    if (isInCooldown) {
      final cooldownPercent = cooldownTimer / cooldownDuration;
      final indicatorPaint = Paint()
        ..color = const Color(0xFFFFFF00).withOpacity(0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      final centerX = size.x / 2;
      final centerY = size.y / 2;
      final radius = size.x / 2 + 8;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        -pi / 2,
        2 * pi * cooldownPercent,
        false,
        indicatorPaint,
      );
    }

    // Draw freeze effect and health bar
    renderFreezeEffect(canvas);
    renderHealthBar(canvas);
  }

  void _drawHexagram(Canvas canvas, Color hexagramColor) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    final outerRadius = size.x / 2;

    // Draw two overlapping triangles to form hexagram
    final path = Path();

    // First triangle (pointing up)
    for (int i = 0; i < 6; i += 2) {
      final angle = (i * pi / 3) - pi / 2;
      final x = centerX + cos(angle) * outerRadius;
      final y = centerY + sin(angle) * outerRadius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Second triangle (pointing down)
    for (int i = 1; i < 6; i += 2) {
      final angle = (i * pi / 3) - pi / 2;
      final x = centerX + cos(angle) * outerRadius;
      final y = centerY + sin(angle) * outerRadius;

      if (i == 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = hexagramColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = const Color(0xFF0000AA) // Dark blue border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);
  }

  void _drawPortalEffect(Canvas canvas) {
    final centerX = size.x / 2;
    final centerY = size.y / 2;

    // Draw expanding/contracting portal rings
    for (int i = 0; i < 3; i++) {
      final ringProgress = (portalEffect + i * 0.3) % 1.0;
      final ringRadius = size.x / 2 * (1 + ringProgress * 2);
      final ringOpacity = (1.0 - ringProgress) * 0.6;

      final ringPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(centerX, centerY),
        ringRadius,
        ringPaint,
      );
    }

    // Draw energy particles
    final random = Random(portalEffect.hashCode);
    for (int i = 0; i < 12; i++) {
      final particleAngle = random.nextDouble() * 2 * pi;
      final particleDistance = random.nextDouble() * size.x;
      final particleX = centerX + cos(particleAngle) * particleDistance;
      final particleY = centerY + sin(particleAngle) * particleDistance;

      final particlePaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particleX, particleY),
        2,
        particlePaint,
      );
    }
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return VortexBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 25 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 25) {
      return 100.0; // High weight to ensure boss spawns
    }
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}

/// Helper class for afterimage visual effect
class _Afterimage {
  final Vector2 position;
  final double angle;
  double opacity;

  _Afterimage({
    required this.position,
    required this.angle,
    required this.opacity,
  });
}
