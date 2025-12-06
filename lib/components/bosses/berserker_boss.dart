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

/// The Berserker Boss - Wave 35
/// - Aggressive triangle shape (pointing down), blood red
/// - Health: 480 + (wave * 70), Speed: 35 + (wave * 0.9) base
/// - Contact damage: 30 base, scales with rage
/// - Charges directly at player in straight lines
/// - Enters rage mode at 60%, 35%, and 15% health
/// - Each rage stack increases speed +50%, damage +50%, fire rate 2x, size +15%
class BerserkerBoss extends BaseEnemy {
  static const String ID = 'berserker';

  // Base stats
  static const double baseContactDamage = 30.0;
  static const double bulletDamage = 20.0;
  static const double bulletSpeed = 180.0;

  // Movement behavior
  static const double chargeSpeed = 1.0; // Multiplier during charge
  static const double pauseDuration = 1.2; // Pause between charges
  static const double chargeDuration = 2.5; // How long to charge

  // Attack patterns
  static const double pauseShootInterval = 0.3; // Fire rate during pause
  static const double chargeTrailInterval = 0.15; // Bullet trail during charge
  static const int pauseSpreadCount = 5; // Number of bullets in spread
  static const double spreadAngle = pi / 4; // 45 degree spread

  // Rage thresholds (percentage of max health)
  static const List<double> rageThresholds = [0.60, 0.35, 0.15];

  // Rage bonuses per stack
  static const double rageSpeedMultiplier = 1.5; // +50% per stack
  static const double rageDamageMultiplier = 1.5; // +50% per stack
  static const double rageFireRateMultiplier = 2.0; // 2x per stack
  static const double rageSizeMultiplier = 1.15; // +15% per stack

  // State tracking
  bool isCharging = false;
  double stateTimer = 0;
  Vector2? chargeDirection;
  int rageLevel = 0;
  double shootTimer = 0;

  // Visual effects
  double glowPulse = 0;

  BerserkerBoss({
    required Vector2 position,
    required PlayerShip player,
    required int wave,
    double scale = 1.0,
  }) : super(
          position: position,
          player: player,
          wave: wave,
          health: 480 + (wave * 70),
          speed: 35 + (wave * 0.9),
          lootValue: 43,
          color: const Color(0xFF8B0000), // Blood red (DarkRed)
          size: Vector2(45, 45) * scale,
          contactDamage: baseContactDamage,
        );

  @override
  Future<void> addHitbox() async {
    // Triangle hitbox pointing down
    final points = <Vector2>[
      Vector2(size.x / 2, size.y), // Bottom point (down)
      Vector2(0, 0), // Top-left
      Vector2(size.x, 0), // Top-right
    ];
    add(PolygonHitbox(points));
  }

  /// Get current speed with rage multipliers
  double getCurrentSpeed() {
    final baseSpeed = getEffectiveSpeed();
    final rageMultiplier = pow(rageSpeedMultiplier, rageLevel).toDouble();
    return baseSpeed * rageMultiplier;
  }

  /// Get current contact damage with rage multipliers
  double getCurrentContactDamage() {
    final rageMultiplier = pow(rageDamageMultiplier, rageLevel).toDouble();
    return baseContactDamage * rageMultiplier;
  }

  /// Get current size with rage multipliers
  Vector2 getCurrentSize() {
    final rageMultiplier = pow(rageSizeMultiplier, rageLevel).toDouble();
    return Vector2(45, 45) * rageMultiplier;
  }

  /// Get current fire rate with rage multipliers
  double getCurrentFireInterval(double baseInterval) {
    final rageMultiplier = pow(rageFireRateMultiplier, rageLevel).toDouble();
    return baseInterval / rageMultiplier;
  }

  @override
  void takeDamage(double damage, {bool isCrit = false, bool showDamageNumber = true}) {
    final previousHealth = health;
    super.takeDamage(damage, isCrit: isCrit, showDamageNumber: showDamageNumber);

    // Check if crossed any rage thresholds
    checkRageThresholds(previousHealth);
  }

  void checkRageThresholds(double previousHealth) {
    final previousPercent = previousHealth / maxHealth;
    final currentPercent = health / maxHealth;

    for (int i = 0; i < rageThresholds.length; i++) {
      final threshold = rageThresholds[i];

      // Check if we crossed this threshold going downward
      if (previousPercent > threshold && currentPercent <= threshold) {
        enterRage();
        print('[BerserkerBoss] Entered RAGE mode! Level: $rageLevel');
        break; // Only one rage level per damage instance
      }
    }
  }

  void enterRage() {
    rageLevel++;

    // Update size immediately
    size = getCurrentSize();

    // Update contact damage field for collision handling
    contactDamage = getCurrentContactDamage();

    // Play rage sound effect if available
    // TODO: Add rage sound effect

    print('[BerserkerBoss] RAGE LEVEL $rageLevel! Speed: ${getCurrentSpeed()}, Damage: ${contactDamage}');
  }

  @override
  void updateMovement(double dt) {
    glowPulse += dt * 3;
    stateTimer += dt;
    shootTimer += dt;

    if (isCharging) {
      updateChargingBehavior(dt);
    } else {
      updatePauseBehavior(dt);
    }
  }

  void updateChargingBehavior(double dt) {
    // Continue charging in current direction
    if (chargeDirection != null) {
      position += chargeDirection! * getCurrentSpeed() * chargeSpeed * dt;

      // Rotate to face charge direction
      angle = atan2(chargeDirection!.y, chargeDirection!.x) + pi / 2;

      // Leave bullet trail
      final trailInterval = getCurrentFireInterval(chargeTrailInterval);
      if (shootTimer >= trailInterval) {
        shootBulletTrail();
        shootTimer = 0;
      }

      // In rage mode, fire bullets in all directions while charging
      if (rageLevel > 0 && shootTimer >= trailInterval * 0.5) {
        shootOmnidirectional();
      }
    }

    // Switch to pause after charge duration
    if (stateTimer >= chargeDuration) {
      isCharging = false;
      stateTimer = 0;
      chargeDirection = null;
      shootTimer = 0;
    }
  }

  void updatePauseBehavior(double dt) {
    // Pause briefly and shoot spread at player
    final shootInterval = getCurrentFireInterval(pauseShootInterval);
    if (shootTimer >= shootInterval) {
      shootSpread();
      shootTimer = 0;
    }

    // Switch to charging after pause duration
    if (stateTimer >= pauseDuration) {
      isCharging = true;
      stateTimer = 0;
      shootTimer = 0;

      // Set charge direction toward player
      chargeDirection = PositionUtil.getDirectionTo(this, player);
    }
  }

  /// Shoot 5-bullet spread during pause
  void shootSpread() {
    final directionToPlayer = PositionUtil.getDirectionTo(this, player);
    final baseAngle = atan2(directionToPlayer.y, directionToPlayer.x);

    // Calculate spread angles
    final angleStep = spreadAngle / (pauseSpreadCount - 1);
    final startAngle = baseAngle - (spreadAngle / 2);

    for (int i = 0; i < pauseSpreadCount; i++) {
      final angle = startAngle + (angleStep * i);
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      game.world.add(bullet);
    }

    print('[BerserkerBoss] Fired spread shot ($pauseSpreadCount bullets)');
  }

  /// Shoot bullet trail during charge
  void shootBulletTrail() {
    if (chargeDirection == null) return;

    // Shoot backwards while charging (trail effect)
    final trailDirection = chargeDirection! * -1;

    final bullet = EnemyBullet(
      position: position.clone(),
      direction: trailDirection,
      damage: bulletDamage,
      speed: bulletSpeed * 0.7, // Slower bullets for trail
    );

    game.world.add(bullet);
  }

  /// Shoot in all directions (rage mode)
  void shootOmnidirectional() {
    const directions = 8; // 8-way spread
    final angleStep = (2 * pi) / directions;

    for (int i = 0; i < directions; i++) {
      final angle = angleStep * i;
      final direction = Vector2(cos(angle), sin(angle));

      final bullet = EnemyBullet(
        position: position.clone(),
        direction: direction,
        damage: bulletDamage,
        speed: bulletSpeed,
      );

      game.world.add(bullet);
    }

    print('[BerserkerBoss] Fired omnidirectional burst! ($directions bullets)');
  }

  @override
  void renderShape(Canvas canvas) {
    // Calculate glow intensity based on rage level
    final glowIntensity = 1.0 + (rageLevel * 0.3);
    final pulseEffect = sin(glowPulse) * 0.2;

    // Determine color intensity (brighter when enraged)
    final colorIntensity = (glowIntensity + pulseEffect).clamp(0.0, 2.0);
    final renderColor = Color.fromRGBO(
      (color.red * colorIntensity).clamp(0, 255).toInt(),
      (color.green * colorIntensity).clamp(0, 255).toInt(),
      (color.blue * colorIntensity).clamp(0, 255).toInt(),
      1.0,
    );

    // Draw glow effect when enraged
    if (rageLevel > 0) {
      final glowPaint = Paint()
        ..color = renderColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      final glowPath = Path();
      glowPath.moveTo(size.x / 2, size.y + 5); // Bottom point (with glow expansion)
      glowPath.lineTo(-5, -5); // Top-left
      glowPath.lineTo(size.x + 5, -5); // Top-right
      glowPath.close();

      canvas.drawPath(glowPath, glowPaint);
    }

    // Draw main triangle
    final paint = Paint()
      ..color = renderColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    path.moveTo(size.x / 2, size.y); // Bottom point (pointing down)
    path.lineTo(0, 0); // Top-left
    path.lineTo(size.x, 0); // Top-right
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Draw rage indicator (stacks)
    if (rageLevel > 0) {
      final ragePaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.fill;

      // Draw rage level markers
      final markerSize = 3.0;
      final markerSpacing = 6.0;
      final startX = (size.x / 2) - ((rageLevel - 1) * markerSpacing / 2);

      for (int i = 0; i < rageLevel; i++) {
        canvas.drawCircle(
          Offset(startX + (i * markerSpacing), size.y / 2),
          markerSize,
          ragePaint,
        );
      }
    }

    // Draw charge indicator
    if (isCharging && chargeDirection != null) {
      final chargePaint = Paint()
        ..color = const Color(0xFFFFFF00).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      // Draw speed lines
      for (int i = 1; i <= 3; i++) {
        final offset = chargeDirection! * (-10.0 * i);
        final trailPath = Path();
        trailPath.moveTo(size.x / 2 + offset.x, size.y / 2 + offset.y);
        trailPath.lineTo(size.x / 2 + offset.x - 5, size.y / 2 + offset.y);

        canvas.drawPath(trailPath, chargePaint);
      }
    }

    // Draw status effects
    renderFreezeEffect(canvas);
    renderBleedEffect(canvas);

    // Draw health bar
    renderHealthBar(canvas);
  }

  // Factory registration methods
  static void registerFactory() {
    EnemyFactory.register(ID, (player, wave, spawnPos, scale) {
      return BerserkerBoss(
        position: spawnPos,
        player: player,
        wave: wave,
        scale: scale,
      );
    });
  }

  static double getSpawnWeight(int wave) {
    // Boss spawns at wave 35 only (for unique boss rotation)
    // After wave 50, available in boss pool for multi-boss waves
    if (wave == 35) return 1.0;
    return 0.0;
  }

  static void init() {
    registerFactory();
    EnemySpawnConfig.registerSpawnWeight(ID, getSpawnWeight);
  }
}
