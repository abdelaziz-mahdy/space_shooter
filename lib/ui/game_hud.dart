import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class GameHUD extends PositionComponent with HasGameRef<SpaceShooterGame> {
  late TextPaint levelText;
  late TextPaint xpText;
  late TextPaint waveText;
  late TextPaint statsText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final levelManager = gameRef.levelManager;
    final statsManager = gameRef.statsManager;
    final enemyManager = gameRef.enemyManager;

    // Level display
    levelText.render(
      canvas,
      'Level ${levelManager.getLevel()}',
      Vector2(20, 20),
    );

    // XP bar
    final barWidth = 300.0;
    final barHeight = 20.0;
    final barX = 20.0;
    final barY = 50.0;

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
  }
}
