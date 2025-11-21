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
    final levelManager = widget.game.levelManager;
    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;

    return IgnorePointer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Level and XP
                  Flexible(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${levelManager.getLevel()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(
                            minWidth: 200,
                            maxWidth: 400,
                          ),
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: levelManager.getXPProgress(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FFFF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  '${levelManager.getXP()} / ${levelManager.getXPToNextLevel()} XP',
                                  style: const TextStyle(
                                    color: Color(0xFF00FFFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center - Wave info
                  Flexible(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          enemyManager.isInBossWave()
                              ? 'BOSS WAVE ${enemyManager.getCurrentWave()}'
                              : 'Wave ${enemyManager.getCurrentWave()}',
                          style: const TextStyle(
                            color: Color(0xFFFFFF00),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wave Time: ${statsManager.getWaveTimeFormatted()}',
                          style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right side - Stats
                  Flexible(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Time: ${statsManager.getTimeAliveFormatted()}',
                          style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kills: ${statsManager.enemiesKilled}',
                          style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
