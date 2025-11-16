import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/space_shooter_game.dart';
import '../services/score_service.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  final ScoreService _scoreService = ScoreService();
  List<GameScore> _recentScores = [];
  GameScore? _bestScore;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    await _scoreService.loadScores();
    setState(() {
      _recentScores = _scoreService.getRecentScores(5);
      _bestScore = _scoreService.getBestScore();
    });
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameWidget(
          game: SpaceShooterGame(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000033), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                const Text(
                  'SPACE SHOOTER',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Color(0xFF00FFFF),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '⚡ Survive • Upgrade • Dominate ⚡',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color(0xFF00FFFF),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 60),

                // Play Button
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 20,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('PLAY'),
                ),
                const SizedBox(height: 80),

                // Leaderboard Section
                Container(
                  width: 600,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00FFFF),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🏆 LEADERBOARD 🏆',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00FFFF),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Best Score
                      if (_bestScore != null) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '👑 BEST SCORE',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Score: ${_bestScore!.score}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Wave ${_bestScore!.wave} • ${_bestScore!.formattedTime}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Recent Scores
                      const Text(
                        'RECENT GAMES',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (_recentScores.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No games played yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF888888),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...List.generate(_recentScores.length, (index) {
                          final score = _recentScores[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF00FFFF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Score: ${score.score}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Wave ${score.wave}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                                Text(
                                  score.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
