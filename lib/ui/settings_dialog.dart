import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../managers/audio_manager.dart';

/// Settings dialog overlay that appears when the settings button is pressed
/// Pauses the game and provides options for audio, stats, and returning to menu
class SettingsDialog extends StatelessWidget {
  final SpaceShooterGame game;
  final VoidCallback onClose;
  final VoidCallback onBackToMenu;
  final VoidCallback onViewStats;
  final bool isAudioMuted;
  final ValueChanged<bool> onAudioMuteChanged;

  const SettingsDialog({
    super.key,
    required this.game,
    required this.onClose,
    required this.onBackToMenu,
    required this.onViewStats,
    required this.isAudioMuted,
    required this.onAudioMuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive scale based on screen width
          final scale = (constraints.maxWidth / 800).clamp(0.6, 1.5);
          final dialogWidth = (400.0 * scale).clamp(280.0, 500.0);

          return Center(
            child: Container(
              width: dialogWidth,
              padding: EdgeInsets.all(24 * scale),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16 * scale),
                border: Border.all(
                  color: const Color(0xFF00FFFF),
                  width: 3 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.4),
                    blurRadius: 20 * scale,
                    spreadRadius: 4 * scale,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SETTINGS',
                        style: TextStyle(
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00FFFF),
                          letterSpacing: 3 * scale,
                        ),
                      ),
                      IconButton(
                        iconSize: 28 * scale,
                        padding: EdgeInsets.all(8 * scale),
                        onPressed: () {
                          AudioManager().playButtonClick();
                          onClose();
                        },
                        icon: Icon(
                          Icons.close,
                          color: const Color(0xFFFF0000),
                          size: 28 * scale,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8 * scale),
                  Divider(
                    color: const Color(0xFF00FFFF),
                    height: 20 * scale,
                    thickness: 2 * scale,
                  ),
                  SizedBox(height: 16 * scale),

                  // Audio Mute Toggle
                  _buildSettingRow(
                    scale: scale,
                    icon: isAudioMuted ? Icons.volume_off : Icons.volume_up,
                    label: 'Audio',
                    trailing: Switch(
                      value: !isAudioMuted,
                      onChanged: (value) => onAudioMuteChanged(!value),
                      activeColor: const Color(0xFF00FFFF),
                      activeTrackColor: const Color(0xFF00FFFF).withOpacity(0.5),
                    ),
                  ),

                  SizedBox(height: 12 * scale),

                  // View Stats Button
                  _buildButton(
                    scale: scale,
                    label: 'VIEW STATS',
                    icon: Icons.analytics,
                    onPressed: onViewStats,
                    color: const Color(0xFF00FFFF),
                  ),

                  SizedBox(height: 12 * scale),

                  // Back to Main Menu Button
                  _buildButton(
                    scale: scale,
                    label: 'BACK TO MENU',
                    icon: Icons.home,
                    onPressed: onBackToMenu,
                    color: const Color(0xFFFF0000),
                  ),

                  SizedBox(height: 16 * scale),

                  // Game paused indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale,
                      vertical: 6 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFF00).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8 * scale),
                      border: Border.all(
                        color: const Color(0xFFFFFF00),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause,
                          color: const Color(0xFFFFFF00),
                          size: 16 * scale,
                        ),
                        SizedBox(width: 8 * scale),
                        Text(
                          'Game Paused',
                          style: TextStyle(
                            color: const Color(0xFFFFFF00),
                            fontSize: 14 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingRow({
    required double scale,
    required IconData icon,
    required String label,
    required Widget trailing,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scale,
        vertical: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(
          color: const Color(0xFF00FFFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF00FFFF),
            size: 24 * scale,
          ),
          SizedBox(width: 12 * scale),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18 * scale,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  Widget _buildButton({
    required double scale,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          AudioManager().playButtonClick();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          padding: EdgeInsets.symmetric(
            horizontal: 20 * scale,
            vertical: 16 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            side: BorderSide(
              color: color,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22 * scale),
            SizedBox(width: 12 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
