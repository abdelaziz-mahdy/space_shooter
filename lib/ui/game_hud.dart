import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class GameHUD extends PositionComponent with HasGameRef<SpaceShooterGame> {
  late TextPaint levelText;
  late TextPaint xpText;
  late TextPaint waveText;
  late TextPaint statsText;

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
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );

    xpText = TextPaint(
      style: TextStyle(color: Color(0xFF00FFFF), fontSize: 18),
    );

    waveText = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFF00),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    statsText = TextPaint(
      style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16),
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

    // Responsive positioning and sizing
    final padding = 20.0;
    final barWidth = (size.x * 0.3).clamp(200.0, 400.0); // 30% of width, clamped
    final barHeight = 20.0;

    // Level display (top left)
    levelText.render(
      canvas,
      'Level ${levelManager.getLevel()}',
      Vector2(padding, padding),
    );

    // XP bar (below level)
    final barX = padding;
    final barY = padding + 30;

    // Background
    final bgPaint = Paint()..color = const Color(0xFF333333);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth, barHeight),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    // Progress
    final progress = levelManager.getXPProgress();
    final progressPaint = Paint()..color = const Color(0xFF00FFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barWidth * progress, barHeight),
        const Radius.circular(10),
      ),
      progressPaint,
    );

    // XP text
    xpText.render(
      canvas,
      '${levelManager.getXP()} / ${levelManager.getXPToNextLevel()} XP',
      Vector2(barX + barWidth / 2, barY + barHeight / 2),
      anchor: Anchor.center,
    );

    // Wave number with timer (center top)
    final waveDisplay = enemyManager.isInBossWave()
        ? 'BOSS WAVE ${enemyManager.getCurrentWave()}'
        : 'Wave ${enemyManager.getCurrentWave()}';

    waveText.render(
      canvas,
      waveDisplay,
      Vector2(size.x / 2, 20),
      anchor: Anchor.center,
    );

    // Wave timer (below wave number)
    statsText.render(
      canvas,
      'Wave Time: ${statsManager.getWaveTimeFormatted()}',
      Vector2(size.x / 2, 45),
      anchor: Anchor.center,
    );

    // Stats (top right)
    statsText.render(
      canvas,
      'Total Time: ${statsManager.getTimeAliveFormatted()}',
      Vector2(size.x - 20, 20),
      anchor: Anchor.topRight,
    );

    statsText.render(
      canvas,
      'Kills: ${statsManager.enemiesKilled}',
      Vector2(size.x - 20, 45),
      anchor: Anchor.topRight,
    );

    // Current weapon (bottom center)
    final player = gameRef.player;
    final weaponId = player.weaponManager.getCurrentWeaponId();
    final weaponName = player.weaponManager.getCurrentWeaponName();
    final weaponIcon = gameRef.statsManager.gameRef.player.weaponManager.weaponInstances[weaponId]?.id ?? '🔫';
    weaponText.render(
      canvas,
      weaponName,
      Vector2(size.x / 2, size.y - 30),
      anchor: Anchor.center,
    );
  }
}
