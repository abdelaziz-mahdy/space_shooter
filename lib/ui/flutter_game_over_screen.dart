import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../services/score_service.dart';

class FlutterGameOverScreen extends StatefulWidget {
  final SpaceShooterGame game;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const FlutterGameOverScreen({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<FlutterGameOverScreen> createState() => _FlutterGameOverScreenState();
}

class _FlutterGameOverScreenState extends State<FlutterGameOverScreen> {
  bool _scoreSaved = false;

  @override
  void initState() {
    super.initState();
    _saveScore();
  }

  Future<void> _saveScore() async {
    if (_scoreSaved) return;

    final scoreService = ScoreService();
    await scoreService.loadScores();

    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;

    final enemiesKilled = statsManager.enemiesKilled;
    final wavesCompleted = enemyManager.getCurrentWave() - 1;
    final timeAliveSeconds = statsManager.timeAlive;

    // Calculate score: kills * 10 + waves * 100 + time bonus
    final score = (enemiesKilled * 10) + (wavesCompleted * 100) + timeAliveSeconds.toInt();

    final gameScore = GameScore(
      score: score,
      wave: wavesCompleted,
      kills: enemiesKilled,
      timeAlive: timeAliveSeconds,
      timestamp: DateTime.now(),
    );

    await scoreService.saveScore(gameScore);
    setState(() {
      _scoreSaved = true;
    });
    print('[GameOver] Score saved: $score');
  }

  @override
  Widget build(BuildContext context) {
    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;

    return Container(
      color: const Color(0xDD000000),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Color(0xFFFF0000),
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),

            // Time Survived
            const Text(
              'Time Survived',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statsManager.getTimeAliveFormatted(),
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Enemies Killed
            const Text(
              'Enemies Killed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${statsManager.enemiesKilled}',
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Waves Completed
            const Text(
              'Waves Completed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${enemyManager.getCurrentWave() - 1}',
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 60),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: widget.onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'RESTART',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: widget.onMainMenu,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8800),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
