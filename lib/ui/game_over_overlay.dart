import 'dart:ui' hide TextStyle;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../services/score_service.dart';

class GameOverOverlay extends PositionComponent
    with HasGameRef<SpaceShooterGame>, TapCallbacks {
  final int enemiesKilled;
  final String timeAlive;
  final double timeAliveSeconds;
  final int wavesCompleted;
  final List<String> upgrades;
  final String? weaponUsed;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;
  bool _scoreSaved = false;

  GameOverOverlay({
    required this.enemiesKilled,
    required this.timeAlive,
    required this.timeAliveSeconds,
    required this.wavesCompleted,
    required this.upgrades,
    this.weaponUsed,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.topLeft;
    size = gameRef.camera.viewport.size;
    position = Vector2.zero();

    // Save score once when overlay loads
    if (!_scoreSaved) {
      _saveScore();
      _scoreSaved = true;
    }
  }

  Future<void> _saveScore() async {
    final scoreService = ScoreService();
    await scoreService.loadScores();

    // Calculate score: kills * 10 + waves * 100 + time bonus
    final score = (enemiesKilled * 10) + (wavesCompleted * 100) + timeAliveSeconds.toInt();

    final gameScore = GameScore(
      score: score,
      wave: wavesCompleted,
      kills: enemiesKilled,
      timeAlive: timeAliveSeconds,
      timestamp: DateTime.now(),
      upgrades: upgrades,
      weaponUsed: weaponUsed,
    );

    await scoreService.saveScore(gameScore);
    print('[GameOver] Score saved: $score');
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapPos = event.localPosition;

    // Check if tap is on restart button
    final restartButtonRect = Rect.fromCenter(
      center: Offset(size.x / 2 - 110, size.y / 2 + 200),
      width: 180,
      height: 50,
    );

    // Check if tap is on main menu button
    final menuButtonRect = Rect.fromCenter(
      center: Offset(size.x / 2 + 110, size.y / 2 + 200),
      width: 180,
      height: 50,
    );

    if (restartButtonRect.contains(tapPos.toOffset())) {
      onRestart();
      removeFromParent();
    } else if (menuButtonRect.contains(tapPos.toOffset())) {
      onMainMenu();
      removeFromParent();
    }
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

    // Dark overlay
    final bgPaint = Paint()..color = const Color(0xDD000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), bgPaint);

    // Title
    final titleStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFF0000),
        fontSize: 64,
        fontWeight: FontWeight.bold,
      ),
    );

    titleStyle.render(
      canvas,
      'GAME OVER',
      Vector2(size.x / 2, 100),
      anchor: Anchor.center,
    );

    // Stats
    final statsStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    );

    final valueStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFF00FFFF),
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
    );

    // Time Alive
    statsStyle.render(
      canvas,
      'Time Survived',
      Vector2(size.x / 2, size.y / 2 - 100),
      anchor: Anchor.center,
    );

    valueStyle.render(
      canvas,
      timeAlive,
      Vector2(size.x / 2, size.y / 2 - 60),
      anchor: Anchor.center,
    );

    // Enemies Killed
    statsStyle.render(
      canvas,
      'Enemies Killed',
      Vector2(size.x / 2, size.y / 2 - 10),
      anchor: Anchor.center,
    );

    valueStyle.render(
      canvas,
      enemiesKilled.toString(),
      Vector2(size.x / 2, size.y / 2 + 30),
      anchor: Anchor.center,
    );

    // Waves Completed
    statsStyle.render(
      canvas,
      'Waves Completed',
      Vector2(size.x / 2, size.y / 2 + 80),
      anchor: Anchor.center,
    );

    valueStyle.render(
      canvas,
      wavesCompleted.toString(),
      Vector2(size.x / 2, size.y / 2 + 120),
      anchor: Anchor.center,
    );

    // Restart button
    final restartButtonRect = Rect.fromCenter(
      center: Offset(size.x / 2 - 110, size.y / 2 + 200),
      width: 180,
      height: 50,
    );

    final restartButtonPaint = Paint()
      ..color = const Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(restartButtonRect, const Radius.circular(10)),
      restartButtonPaint,
    );

    final buttonTextStyle = TextPaint(
      style: TextStyle(
        color: Color(0xFF000000),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );

    buttonTextStyle.render(
      canvas,
      'RESTART',
      Vector2(size.x / 2 - 110, size.y / 2 + 200),
      anchor: Anchor.center,
    );

    // Main Menu button
    final menuButtonRect = Rect.fromCenter(
      center: Offset(size.x / 2 + 110, size.y / 2 + 200),
      width: 180,
      height: 50,
    );

    final menuButtonPaint = Paint()
      ..color = const Color(0xFFFF8800)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(menuButtonRect, const Radius.circular(10)),
      menuButtonPaint,
    );

    buttonTextStyle.render(
      canvas,
      'MAIN MENU',
      Vector2(size.x / 2 + 110, size.y / 2 + 200),
      anchor: Anchor.center,
    );
  }
}
