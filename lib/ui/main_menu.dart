import 'package:flutter/material.dart';
import 'game_screen.dart';
import '../services/score_service.dart';
import '../managers/audio_manager.dart';

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
    // Play button click sound
    AudioManager().playButtonClick();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive scale based on screen height
              final scale = (constraints.maxHeight / 800).clamp(0.5, 1.2);
              final titleSize = 72.0 * scale;
              final subtitleSize = 20.0 * scale;
              final buttonTextSize = 32.0 * scale;
              final maxLeaderboardWidth = constraints.maxWidth * 0.9;
              final leaderboardWidth = (600.0 * scale).clamp(200.0, maxLeaderboardWidth.clamp(200.0, double.infinity));

              return Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'SPACE SHOOTER',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Color(0xFF00FFFF),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * scale),
                      Text(
                        '⚡ Survive • Upgrade • Dominate ⚡',
                        style: TextStyle(
                          fontSize: subtitleSize,
                          color: const Color(0xFF00FFFF),
                          letterSpacing: 2 * scale,
                        ),
                      ),
                      SizedBox(height: 60 * scale),

                      // Play Button
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFFF),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: 80 * scale,
                            vertical: 20 * scale,
                          ),
                          textStyle: TextStyle(
                            fontSize: buttonTextSize,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30 * scale),
                          ),
                        ),
                        child: const Text('PLAY'),
                      ),
                      SizedBox(height: 40 * scale),

                      // Leaderboard Section
                      Container(
                        width: leaderboardWidth,
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.5,
                        ),
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20 * scale),
                          border: Border.all(
                            color: const Color(0xFF00FFFF),
                            width: 2 * scale,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text(
                                '🏆 LEADERBOARD 🏆',
                                style: TextStyle(
                                  fontSize: 28 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00FFFF),
                                ),
                              ),
                              SizedBox(height: 20 * scale),

                              // Best Score
                              if (_bestScore != null) ...[
                                Container(
                                  padding: EdgeInsets.all(15 * scale),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10 * scale),
                                    border: Border.all(
                                      color: const Color(0xFFFFD700),
                                      width: 2 * scale,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '👑 BEST SCORE',
                                          style: TextStyle(
                                            fontSize: 20 * scale,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFFFD700),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Score: ${_bestScore!.score}',
                                            style: TextStyle(
                                              fontSize: 18 * scale,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                            Text(
                                              'Wave ${_bestScore!.wave} • ${_bestScore!.formattedTime}',
                                              style: TextStyle(
                                                fontSize: 14 * scale,
                                                color: const Color(0xFFCCCCCC),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20 * scale),
                              ],

                              // Recent Scores
                              Text(
                                'RECENT GAMES',
                                style: TextStyle(
                                  fontSize: 20 * scale,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10 * scale),

                              if (_recentScores.isEmpty)
                                Padding(
                                  padding: EdgeInsets.all(20 * scale),
                                  child: Text(
                                    'No games played yet',
                                    style: TextStyle(
                                      fontSize: 16 * scale,
                                      color: const Color(0xFF888888),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...List.generate(_recentScores.length, (index) {
                                  final score = _recentScores[index];
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 5 * scale),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '#${index + 1}',
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            color: const Color(0xFF00FFFF),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Score: ${score.score}',
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Wave ${score.wave}',
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            color: const Color(0xFFCCCCCC),
                                          ),
                                        ),
                                        Text(
                                          score.formattedTime,
                                          style: TextStyle(
                                            fontSize: 16 * scale,
                                            color: const Color(0xFFCCCCCC),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
