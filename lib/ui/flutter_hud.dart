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

    final levelManager = widget.game.levelManager;
    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale font sizes based on screen width
          final scale = (constraints.maxWidth / 800).clamp(0.7, 1.5);
          final titleSize = 24.0 * scale;
          final textSize = 16.0 * scale;
          final smallTextSize = 14.0 * scale;
          final miniTextSize = 12.0 * scale;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20.0 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - HP Bar and Level/XP stacked vertically
                      Flexible(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // HP Bar
                            Container(
                              constraints: BoxConstraints(
                                minWidth: 150 * scale,
                                maxWidth: 250 * scale,
                              ),
                              height: 24 * scale,
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(12 * scale),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  FractionallySizedBox(
                                    widthFactor: (widget.game.player.health / widget.game.player.maxHealth).clamp(0.0, 1.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFF0000),
                                            const Color(0xFFFF6666),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12 * scale),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '${widget.game.player.health.toInt()} / ${widget.game.player.maxHealth.toInt()} HP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: smallTextSize,
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
                                ],
                              ),
                            ),
                            SizedBox(height: 6 * scale),

                            // Level and XP Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level ${levelManager.getLevel()}',
                                  style: TextStyle(
                                    color: Colors.white,
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
                                SizedBox(height: 4 * scale),
                                Container(
                                  constraints: BoxConstraints(
                                    minWidth: 150 * scale,
                                    maxWidth: 250 * scale,
                                  ),
                                  height: 18 * scale,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF333333),
                                    borderRadius: BorderRadius.circular(9 * scale),
                                  ),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: levelManager.getXPProgress(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF00FFFF),
                                                const Color(0xFF00CCCC),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(9 * scale),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${levelManager.getXP()} / ${levelManager.getXPToNextLevel()} XP',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: miniTextSize,
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
                                    ],
                                  ),
                                ),
                              ],
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
                              style: TextStyle(
                                color: const Color(0xFFFFFF00),
                                fontSize: titleSize * 1.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Wave Time: ${statsManager.getWaveTimeFormatted()}',
                              style: TextStyle(
                                color: const Color(0xFFCCCCCC),
                                fontSize: textSize,
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
                              style: TextStyle(
                                color: const Color(0xFFCCCCCC),
                                fontSize: textSize,
                              ),
                            ),
                            SizedBox(height: 4 * scale),
                            Text(
                              'Kills: ${statsManager.enemiesKilled}',
                              style: TextStyle(
                                color: const Color(0xFFCCCCCC),
                                fontSize: textSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),

                  // Additional mini stats bar at the bottom left
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0 * scale),
                    child: _buildMiniStatsBar(scale, miniTextSize),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMiniStatsBar(double scale, double fontSize) {
    final player = widget.game.player;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.3), width: 1),
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Regen and Armor
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Health Regen
                _buildCompactStat(
                  Icons.favorite,
                  Colors.red,
                  'Regen',
                  '+${player.healthRegen.toStringAsFixed(1)}/s',
                  scale,
                  fontSize,
                ),
                SizedBox(width: 12 * scale),

                // Armor
                _buildCompactStat(
                  Icons.shield,
                  const Color(0xFF00FFFF),
                  'Armor',
                  '${(player.damageReduction * 100).toStringAsFixed(0)}%',
                  scale,
                  fontSize,
                ),
              ],
            ),
            SizedBox(height: 8 * scale),

            // Second row: Shield and Damage
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shield Layers
                _buildCompactStat(
                  Icons.shield_outlined,
                  const Color(0xFF00FFFF),
                  'Shield',
                  '${player.shieldLayers}/${player.maxShieldLayers}',
                  scale,
                  fontSize,
                ),
                SizedBox(width: 12 * scale),

                // Damage
                _buildCompactStat(
                  Icons.dangerous,
                  const Color(0xFFFF8800),
                  'DMG',
                  '${player.damage.toStringAsFixed(1)}',
                  scale,
                  fontSize,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
    IconData icon,
    Color color,
    String label,
    String value,
    double scale,
    double fontSize,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14 * scale),
          SizedBox(width: 4 * scale),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: fontSize * 0.75,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize * 0.85,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
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
        ],
      ),
    );
  }
}
