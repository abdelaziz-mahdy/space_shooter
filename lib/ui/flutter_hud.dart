import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

class FlutterHUD extends StatefulWidget {
  final SpaceShooterGame game;

  const FlutterHUD({super.key, required this.game});

  @override
  State<FlutterHUD> createState() => _FlutterHUDState();
}

class _FlutterHUDState extends State<FlutterHUD> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Create a ticker to rebuild the UI at 60fps to reflect game state changes
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if game is ready
    if (!widget.game.hasLoaded) {
      return const SizedBox.shrink();
    }

    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;
    final player = widget.game.player;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale font sizes based on screen width
          final scale = (constraints.maxWidth / 800).clamp(0.7, 1.5);
          final titleSize = 24.0 * scale;
          final textSize = 16.0 * scale;

          return SafeArea(
            child: Stack(
              children: [
                // Top left - Wave info
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        enemyManager.isInBossWave()
                            ? 'BOSS WAVE ${enemyManager.getCurrentWave()}'
                            : 'Wave ${enemyManager.getCurrentWave()}',
                        style: TextStyle(
                          color: const Color(0xFFFFFF00),
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        'Wave Time: ${statsManager.getWaveTimeFormatted()}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
                          fontSize: textSize,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Top right corner - Stats
                Positioned(
                  right: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Time: ${statsManager.getTimeAliveFormatted()}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
                          fontSize: textSize,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      Text(
                        'Kills: ${statsManager.enemiesKilled}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
                          fontSize: textSize,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom center - Current weapon
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * scale,
                        vertical: 8 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(
                          color: const Color(0xFF00FFFF).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        player.weaponManager.currentWeapon.name.toUpperCase(),
                        style: TextStyle(
                          color: const Color(0xFF00FFFF),
                          fontSize: textSize,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
