import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';

/// Displays the current combo/kill streak and time until reset
class ComboMeter extends StatelessWidget {
  final SpaceShooterGame game;

  const ComboMeter({super.key, required this.game});

  Color _getComboColor(int combo) {
    if (combo >= 200) return const Color(0xFFFF00FF); // Magenta
    if (combo >= 100) return const Color(0xFF9400D3); // Purple
    if (combo >= 50) return const Color(0xFFFF0000); // Red
    if (combo >= 25) return const Color(0xFFFF8800); // Orange
    if (combo >= 10) return const Color(0xFFFFFF00); // Yellow
    return Colors.white; // Default white
  }

  String _getComboRank(int combo) {
    if (combo >= 200) return 'LEGENDARY';
    if (combo >= 100) return 'INSANE';
    if (combo >= 50) return 'AMAZING';
    if (combo >= 25) return 'GREAT';
    if (combo >= 10) return 'GOOD';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Check if game is ready
    if (!game.hasLoaded) {
      return const SizedBox.shrink();
    }

    final combo = game.comboManager.combo;
    final timeUntilReset = game.comboManager.getTimeUntilReset();
    final resetProgress = game.comboManager.getResetProgress();

    // Don't show until combo is at least 5
    if (combo < 5) {
      return const SizedBox.shrink();
    }

    final comboColor = _getComboColor(combo);
    final comboRank = _getComboRank(combo);

    return Positioned(
      right: 20,
      top: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Combo number
          Text(
            '$combo',
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: comboColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
                Shadow(
                  color: comboColor.withValues(alpha: 0.5),
                  offset: const Offset(0, 0),
                  blurRadius: 20,
                ),
              ],
            ),
          ),

          // "COMBO" text
          Text(
            'COMBO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),

          // Combo rank (if applicable)
          if (comboRank.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              comboRank,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: comboColor,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Timer bar
          Container(
            width: 120,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: resetProgress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        comboColor,
                        comboColor.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Time remaining text
          const SizedBox(height: 4),
          Text(
            '${timeUntilReset.toStringAsFixed(1)}s',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white60,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),

          // XP Multiplier
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: comboColor, width: 2),
            ),
            child: Text(
              '${game.comboManager.getXPMultiplier().toStringAsFixed(2)}x XP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: comboColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
