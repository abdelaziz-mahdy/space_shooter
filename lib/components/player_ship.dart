import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import '../utils/position_util.dart';
import 'enemy_ship.dart';
import 'bullet.dart';
import '../game/space_shooter_game.dart';

class PlayerShip extends PositionComponent
    with HasGameRef<SpaceShooterGame>, CollisionCallbacks {
  static const double baseShootInterval = 0.5;
  double shootTimer = 0;
  double shootInterval = baseShootInterval;

  EnemyShip? targetEnemy;
  double targetRange = 300;

  // Movement
  double moveSpeed = 250;
  Vector2 velocity = Vector2.zero();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Touch controls
  Vector2? touchStartPosition;
  Vector2? currentTouchPosition;

  // Upgradeable stats
  double damage = 10;
  double bulletSpeed = 400;
  int projectileCount = 1;
  double maxHealth = 100;
  double health = 100;
  double magnetRadius = 100; // Default attraction radius

  PlayerShip({required Vector2 position})
    : super(position: position, size: Vector2(30, 30));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;

    // Add collision detection
    add(
      PolygonHitbox([
        Vector2(0, -size.y / 2),
        Vector2(size.x / 2, size.y / 2),
        Vector2(-size.x / 2, size.y / 2),
      ]),
    );
  }

  void handleKeyDown(LogicalKeyboardKey key) {
    _pressedKeys.add(key);
  }

  void handleKeyUp(LogicalKeyboardKey key) {
    _pressedKeys.remove(key);
  }

  void handleTouchStart(Vector2 touchPosition) {
    touchStartPosition = touchPosition;
    currentTouchPosition = touchPosition;
  }

  void handleTouchMove(Vector2 touchPosition) {
    currentTouchPosition = touchPosition;
  }

  void handleTouchEnd() {
    touchStartPosition = null;
    currentTouchPosition = null;
    velocity = Vector2.zero();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Don't update if game is paused for upgrade
    if (gameRef.isPausedForUpgrade) return;

    // Handle keyboard movement
    velocity = Vector2.zero();

    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      velocity.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      velocity.y += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      velocity.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      velocity.x += 1;
    }

    // Handle touch movement (virtual joystick)
    if (touchStartPosition != null && currentTouchPosition != null) {
      final offset = currentTouchPosition! - touchStartPosition!;
      final maxOffset = 50.0;

      velocity = Vector2(
        (offset.x / maxOffset).clamp(-1.0, 1.0),
        (offset.y / maxOffset).clamp(-1.0, 1.0),
      );
    }

    // Normalize and apply velocity
    if (velocity.length > 0) {
      velocity.normalize();
      position += velocity * moveSpeed * dt;
      // No bounds clamping - infinite world with camera following player
    }

    // Find nearest enemy
    findNearestEnemy();

    // Auto-shoot at target
    shootTimer += dt;
    if (shootTimer >= shootInterval && targetEnemy != null) {
      shoot();
      shootTimer = 0;
    }

    // Rotate to face target with smooth animation
    if (targetEnemy != null) {
      // Use PositionUtil for consistent direction calculation
      final direction = PositionUtil.getRelativePosition(this, targetEnemy!);
      final targetAngle = atan2(direction.y, direction.x) + pi / 2;

      // Smooth rotation
      final angleDiff = targetAngle - angle;
      final normalizedDiff = (angleDiff + pi) % (2 * pi) - pi;
      angle += normalizedDiff * 10 * dt; // Adjust rotation speed
    }
  }

  void findNearestEnemy() {
    EnemyShip? nearest;
    double nearestDistance = double.infinity;

    final enemies = gameRef.world.children.whereType<EnemyShip>();
    for (final enemy in enemies) {
      // Use PositionUtil for consistent distance calculation
      final distance = PositionUtil.getDistance(this, enemy);
      if (distance < nearestDistance && distance <= targetRange) {
        nearestDistance = distance;
        nearest = enemy;
      }
    }

    targetEnemy = nearest;
  }

  void shoot() {
    if (targetEnemy == null) return;

    // Use PositionUtil for consistent direction calculation
    final direction = PositionUtil.getDirectionTo(this, targetEnemy!);

    // Calculate the tip of the triangle in world coordinates
    // The tip is at (0, -size.y/2) in local space
    // Use positionOf to transform local coordinates to absolute world coordinates
    final tipInLocal = Vector2(0, -size.y / 2);
    final bulletSpawnPosition = positionOf(tipInLocal);

    if (projectileCount == 1) {
      final bullet = Bullet(
        position: bulletSpawnPosition,
        direction: direction,
        damage: damage,
        speed: bulletSpeed,
      );
      gameRef.world.add(bullet);
    } else {
      // Multiple projectiles in a spread pattern
      final angleSpread = 0.2;
      final baseAngle = atan2(direction.y, direction.x);

      for (int i = 0; i < projectileCount; i++) {
        final offset = (i - (projectileCount - 1) / 2) * angleSpread;
        final bulletAngle = baseAngle + offset;
        final bulletDirection = Vector2(cos(bulletAngle), sin(bulletAngle));

        final bullet = Bullet(
          position: bulletSpawnPosition.clone(),
          direction: bulletDirection,
          damage: damage,
          speed: bulletSpeed,
        );
        gameRef.world.add(bullet);
      }
    }
  }

  void takeDamage(double damage) {
    health -= damage;
    if (health <= 0) {
      health = 0;
      gameRef.gameOver();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw white triangle
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, -size.y / 2)
      ..lineTo(size.x / 2, size.y / 2)
      ..lineTo(-size.x / 2, size.y / 2)
      ..close();

    canvas.drawPath(path, paint);

    // Draw health bar
    final healthBarWidth = size.x + 20;
    final healthBarHeight = 4.0;
    final healthBarY = size.y / 2 + 10;

    final healthBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRect(
      Rect.fromLTWH(
        -healthBarWidth / 2,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      healthBgPaint,
    );

    final healthPercent = health / maxHealth;
    final healthPaint = Paint()
      ..color = healthPercent > 0.5
          ? const Color(0xFF00FF00)
          : healthPercent > 0.25
          ? const Color(0xFFFFFF00)
          : const Color(0xFFFF0000);
    canvas.drawRect(
      Rect.fromLTWH(
        -healthBarWidth / 2,
        healthBarY,
        healthBarWidth * healthPercent,
        healthBarHeight,
      ),
      healthPaint,
    );
  }

}
