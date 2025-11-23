import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../components/enemies/base_enemy.dart';

class FlutterHUD extends StatefulWidget {
  final SpaceShooterGame game;
  final VoidCallback? onSettingsPressed;

  const FlutterHUD({super.key, required this.game, this.onSettingsPressed});

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

    final enemyManager = widget.game.enemyManager;
    final player = widget.game.player;

    return LayoutBuilder(
        builder: (context, constraints) {
          // Scale font sizes based on screen width
          // Desktop: max 1.0, Mobile: max 1.3
          final isMobile = constraints.maxWidth < 800;
          final scale = (constraints.maxWidth / 800).clamp(0.7, isMobile ? 1.3 : 1.0);
          final titleSize = 24.0 * scale;
          final textSize = 16.0 * scale;

          // Calculate wave progress
          final currentEnemyCount = widget.game.world.children.whereType<BaseEnemy>().length;
          final totalEnemies = enemyManager.enemiesToSpawnInWave;
          final spawnedEnemies = enemyManager.enemiesSpawnedInWave;

          // Calculate enemies remaining (what's left to kill)
          final enemiesRemaining = currentEnemyCount.clamp(0, totalEnemies);
          final enemiesKilled = (totalEnemies - enemiesRemaining).clamp(0, totalEnemies);
          final progress = totalEnemies > 0 ? enemiesKilled / totalEnemies : 0.0;

          return SafeArea(
            child: Stack(
              children: [
                // Top left - Wave info with progress bar
                Positioned(
                  left: 20,
                  top: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Wave progress bar
                      Container(
                        width: 200 * scale,
                        height: 8 * scale,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4 * scale),
                          border: Border.all(
                            color: const Color(0xFF00FFFF).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3 * scale),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              enemyManager.isInBossWave()
                                  ? const Color(0xFFFF0000)
                                  : const Color(0xFF00FFFF),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4 * scale),
                      // Enemy count text - show remaining enemies
                      Text(
                        enemiesRemaining > 0
                            ? '$enemiesRemaining ${enemiesRemaining == 1 ? "enemy" : "enemies"} remaining'
                            : 'Wave Complete!',
                        style: TextStyle(
                          color: enemiesRemaining > 0
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF00FF00),
                          fontSize: textSize * 0.8,
                          fontWeight: enemiesRemaining > 0
                              ? FontWeight.normal
                              : FontWeight.bold,
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

                // Top right corner - Settings button
                Positioned(
                  right: 20,
                  top: 20,
                  child: IgnorePointer(
                    ignoring: false,
                    child: IconButton(
                      iconSize: 32 * scale,
                      padding: EdgeInsets.all(8 * scale),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00FFFF).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        padding: EdgeInsets.all(8 * scale),
                        child: Icon(
                          Icons.settings,
                          color: const Color(0xFF00FFFF),
                          size: 24 * scale,
                        ),
                      ),
                      onPressed: widget.onSettingsPressed,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
}
