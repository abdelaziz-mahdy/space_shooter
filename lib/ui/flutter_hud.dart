import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

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
    final statsManager = widget.game.statsManager;

    return LayoutBuilder(
        builder: (context, constraints) {
          // Percentage-based responsive sizing (follows claude.md principles)
          final titleSize = constraints.maxWidth * 0.03; // 3% of screen width
          final textSize = constraints.maxWidth * 0.02; // 2% of screen width
          final iconSize = constraints.maxWidth * 0.04; // 4% of screen width
          final spacing1 = constraints.maxWidth * 0.015; // 1.5% spacing
          final spacing2 = constraints.maxWidth * 0.01; // 1% spacing
          final spacing3 = constraints.maxWidth * 0.005; // 0.5% spacing
          final padding = constraints.maxWidth * 0.025; // 2.5% padding

          // Get wave data from stats manager (single source of truth)
          final totalEnemies = statsManager.enemiesInWave;
          final enemiesKilled = statsManager.getEnemiesKilledThisWave();

          // Progress fills up as you kill enemies (0% -> 100%)
          final progress = totalEnemies > 0 ? (enemiesKilled / totalEnemies).clamp(0.0, 1.0) : 0.0;

          return SafeArea(
            child: Stack(
              children: [
                // Top left - Wave info with progress bar
                Positioned(
                  left: padding,
                  top: padding,
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
                      SizedBox(height: spacing2),
                      // Wave progress bar
                      Container(
                        width: constraints.maxWidth * 0.25,
                        height: constraints.maxWidth * 0.01,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(constraints.maxWidth * 0.005),
                          border: Border.all(
                            color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(constraints.maxWidth * 0.004),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              // Cyan/Red for progress - fills as you kill
                              enemyManager.isInBossWave()
                                  ? const Color(0xFFFF0000) // Red for boss
                                  : const Color(0xFF00FFFF), // Cyan for normal
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacing3),
                      // Enemy count text - show kills
                      Text(
                        enemiesKilled >= totalEnemies
                            ? 'Wave Complete!'
                            : '$enemiesKilled / $totalEnemies killed',
                        style: TextStyle(
                          color: enemiesKilled >= totalEnemies
                              ? const Color(0xFF00FF00)
                              : const Color(0xFFCCCCCC),
                          fontSize: textSize * 0.8,
                          fontWeight: enemiesKilled >= totalEnemies
                              ? FontWeight.bold
                              : FontWeight.normal,
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

                // Top right corner - Settings button first, then stats below
                Positioned(
                  right: padding,
                  top: padding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Settings button at the TOP
                      IgnorePointer(
                        ignoring: false,
                        child: IconButton(
                          iconSize: iconSize,
                          padding: EdgeInsets.all(padding * 0.3),
                          icon: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00FFFF).withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            padding: EdgeInsets.all(padding * 0.3),
                            child: Icon(
                              Icons.settings,
                              color: const Color(0xFF00FFFF),
                              size: iconSize * 0.75,
                            ),
                          ),
                          onPressed: widget.onSettingsPressed,
                        ),
                      ),
                      SizedBox(height: spacing1),
                      // Score (gold, prominent)
                      Text(
                        'Score: ${statsManager.getCurrentScore()}',
                        style: TextStyle(
                          color: const Color(0xFFFFD700), // Gold
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
                      SizedBox(height: spacing2),
                      // Time alive
                      Text(
                        'Time: ${statsManager.getTimeAliveFormatted()}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
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
                      SizedBox(height: spacing3),
                      // Kills
                      Text(
                        'Kills: ${statsManager.enemiesKilled}',
                        style: TextStyle(
                          color: const Color(0xFFCCCCCC),
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
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
  }
}
