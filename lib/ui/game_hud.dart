import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class GameHUD extends PositionComponent with HasGameRef<SpaceShooterGame> {
  late TextPaint levelText;
  late TextPaint xpText;
  late TextPaint waveText;
  late TextPaint statsText;
  late TextPaint shieldText;
  late TextPaint weaponText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.topLeft;
    position = Vector2.zero();
    size = gameRef.camera.viewport.size;

    levelText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    xpText = TextPaint(
      style: TextStyle(color: Color(0xFF00FFFF), fontSize: 16),
    );

    waveText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFF00),
        fontSize: 26,
        fontWeight: FontWeight.bold,
      ),
    );

    statsText = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
    );

    shieldText = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FFFF),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );

    weaponText = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FF00),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Continuously sync size with viewport for window resizing
    size = gameRef.camera.viewport.size;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final levelManager = gameRef.levelManager;
    final statsManager = gameRef.statsManager;
    final enemyManager = gameRef.enemyManager;
    final player = gameRef.player;

    // Responsive scaling
    final scale = (size.x / 1920).clamp(0.8, 1.5);
    final padding = 20.0 * scale;

    // === TOP LEFT CORNER - Player Info ===
    final hpBarWidth = (300.0 * scale).clamp(250.0, 350.0);
    final hpBarHeight = 24.0 * scale;
    final xpBarWidth = (250.0 * scale).clamp(200.0, 300.0);
    final xpBarHeight = 18.0 * scale;

    var currentY = padding;

    // HP Bar - Red gradient, prominent
    final hpBarX = padding;
    final hpBarY = currentY;

    // HP Background
    final hpBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth, hpBarHeight),
        Radius.circular(12 * scale),
      ),
      hpBgPaint,
    );

    // HP Progress with red gradient
    final hpPercent = player.health / player.maxHealth;
    final hpGradient = LinearGradient(
      colors: [
        Color(0xFFFF0000),
        Color(0xFFFF6666),
      ],
    );
    final hpPaint = Paint()
      ..shader = hpGradient.createShader(
        Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth * hpPercent, hpBarHeight),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hpBarX, hpBarY, hpBarWidth * hpPercent, hpBarHeight),
        Radius.circular(12 * scale),
      ),
      hpPaint,
    );

    // HP Text
    final hpTextPaint = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 14 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    hpTextPaint.render(
      canvas,
      '${player.health.toInt()} / ${player.maxHealth.toInt()} HP',
      Vector2(hpBarX + hpBarWidth / 2, hpBarY + hpBarHeight / 2),
      anchor: Anchor.center,
    );

    currentY += hpBarHeight + (8 * scale);

    // Level label
    levelText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 18 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    levelText.render(
      canvas,
      'Level ${levelManager.getLevel()}',
      Vector2(padding, currentY),
    );

    currentY += (25 * scale);

    // XP Bar - Cyan gradient
    final xpBarX = padding;
    final xpBarY = currentY;

    // XP Background
    final xpBgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(xpBarX, xpBarY, xpBarWidth, xpBarHeight),
        Radius.circular(10 * scale),
      ),
      xpBgPaint,
    );

    // XP Progress with cyan gradient
    final xpProgress = levelManager.getXPProgress();
    final xpGradient = LinearGradient(
      colors: [
        Color(0xFF00FFFF),
        Color(0xFF66FFFF),
      ],
    );
    final xpPaint = Paint()
      ..shader = xpGradient.createShader(
        Rect.fromLTWH(xpBarX, xpBarY, xpBarWidth * xpProgress, xpBarHeight),
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(xpBarX, xpBarY, xpBarWidth * xpProgress, xpBarHeight),
        Radius.circular(10 * scale),
      ),
      xpPaint,
    );

    // XP Text
    xpText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 13 * scale,
      ),
    );
    xpText.render(
      canvas,
      '${levelManager.getXP()} / ${levelManager.getXPToNextLevel()} XP',
      Vector2(xpBarX + xpBarWidth / 2, xpBarY + xpBarHeight / 2),
      anchor: Anchor.center,
    );

    currentY += xpBarHeight + (8 * scale);

    // Shield indicator
    final shieldX = padding;
    final shieldY = currentY;

    shieldText = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FFFF),
        fontSize: 16 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    shieldText.render(
      canvas,
      '🛡️ ${player.shieldLayers}/${player.maxShieldLayers}',
      Vector2(shieldX, shieldY),
    );

    // === LEFT SIDE - Wave Info (Vertically Centered) ===
    final waveDisplay = enemyManager.isInBossWave()
        ? 'BOSS WAVE ${enemyManager.getCurrentWave()}'
        : 'Wave ${enemyManager.getCurrentWave()}';

    final leftSideX = padding;
    final leftSideY = size.y / 2;

    waveText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFF00),
        fontSize: 26 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    waveText.render(
      canvas,
      waveDisplay,
      Vector2(leftSideX, leftSideY),
      anchor: Anchor.centerLeft,
    );

    // Wave timer below wave number
    statsText = TextPaint(
      style: TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 16 * scale,
      ),
    );
    statsText.render(
      canvas,
      'Time: ${statsManager.getWaveTimeFormatted()}',
      Vector2(leftSideX, leftSideY + (30 * scale)),
      anchor: Anchor.centerLeft,
    );

    // === TOP RIGHT CORNER - Stats ===
    final rightX = size.x - padding;
    var rightY = padding;

    final rightStatsText = TextPaint(
      style: TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 16 * scale,
        fontWeight: FontWeight.bold,
      ),
    );

    // Total time alive
    rightStatsText.render(
      canvas,
      'Total Time: ${statsManager.getTimeAliveFormatted()}',
      Vector2(rightX, rightY),
      anchor: Anchor.topRight,
    );

    rightY += (25 * scale);

    // Kill count
    rightStatsText.render(
      canvas,
      'Kills: ${statsManager.enemiesKilled}',
      Vector2(rightX, rightY),
      anchor: Anchor.topRight,
    );

    // === BOTTOM CENTER - Current Weapon ===
    final weaponName = player.weaponManager.getCurrentWeaponName();
    weaponText = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FF00),
        fontSize: 20 * scale,
        fontWeight: FontWeight.bold,
      ),
    );
    weaponText.render(
      canvas,
      weaponName,
      Vector2(size.x / 2, size.y - (30 * scale)),
      anchor: Anchor.center,
    );
  }
}
