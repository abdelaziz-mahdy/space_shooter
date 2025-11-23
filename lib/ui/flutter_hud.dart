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
    final player = widget.game.player;

    return LayoutBuilder(
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
                  child: Text(
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
