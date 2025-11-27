import 'package:flutter/material.dart';
import '../managers/audio_manager.dart';
import 'leaderboard_screen.dart';

class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  void _startGame(BuildContext context) {
    AudioManager().playButtonClick();
    Navigator.of(context).pushReplacementNamed('/game');
  }

  void _openLeaderboard(BuildContext context) {
    AudioManager().playButtonClick();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
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
              final secondaryButtonSize = 20.0 * scale;

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
                      SizedBox(height: 80 * scale),

                      // Play Button
                      ElevatedButton(
                        onPressed: () => _startGame(context),
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
                      SizedBox(height: 24 * scale),

                      // Leaderboard Button
                      OutlinedButton.icon(
                        onPressed: () => _openLeaderboard(context),
                        icon: Icon(
                          Icons.emoji_events,
                          size: 24 * scale,
                        ),
                        label: const Text('LEADERBOARD'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFD700),
                          side: BorderSide(
                            color: const Color(0xFFFFD700),
                            width: 2 * scale,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 40 * scale,
                            vertical: 16 * scale,
                          ),
                          textStyle: TextStyle(
                            fontSize: secondaryButtonSize,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20 * scale),
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
