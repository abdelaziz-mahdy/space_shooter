import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/space_shooter_game.dart';
import 'flutter_hud.dart';
import 'flutter_upgrade_dialog.dart';
import 'flutter_game_over_screen.dart';
import 'combo_meter.dart';
import 'stats_panel.dart';
import 'settings_dialog.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late SpaceShooterGame game;
  bool _showUpgradeDialog = false;
  bool _showGameOver = false;
  bool _showStatsPanel = false;
  bool _showSettingsDialog = false;
  late AnimationController _uiUpdateController;

  @override
  void initState() {
    super.initState();
    game = SpaceShooterGame();

    // Create a ticker to rebuild UI for boss health bar and combo meter
    _uiUpdateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _uiUpdateController.addListener(() {
      if (mounted && !_showGameOver) {
        setState(() {});
      }
    });

    // Set up callbacks for UI state changes
    game.onShowUpgrade = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showUpgradeDialog = true;
          });
        }
      });
    };

    game.onHideUpgrade = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showUpgradeDialog = false;
          });
        }
      });
    };

    game.onShowGameOver = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _showGameOver = true;
          });
        }
      });
    };

    game.onReturnToMenu = _returnToMainMenu;
  }

  @override
  void dispose() {
    _uiUpdateController.dispose();
    super.dispose();
  }

  void _toggleStatsPanel() {
    setState(() {
      _showStatsPanel = !_showStatsPanel;

      // Pause/resume game when stats panel is toggled
      if (_showStatsPanel) {
        game.isPaused = true;
        game.enemyManager.stopSpawning();
      } else {
        game.isPaused = false;
        game.enemyManager.startSpawning();
      }
    });
  }

  void _toggleSettingsDialog() {
    setState(() {
      _showSettingsDialog = !_showSettingsDialog;

      // Pause/resume game when settings dialog is toggled
      if (_showSettingsDialog) {
        game.isPaused = true;
        game.enemyManager.stopSpawning();
      } else {
        game.isPaused = false;
        game.enemyManager.startSpawning();
      }
    });
  }

  void _openStatsFromSettings() {
    setState(() {
      _showSettingsDialog = false;
      _showStatsPanel = true;
      // Game remains paused
    });
  }

  void _toggleAudioMute(bool muted) async {
    setState(() {
      game.isAudioMuted = muted;
    });

    // Toggle the AudioManager mute state
    if (muted != game.audioManager.isMuted) {
      await game.audioManager.toggleMute();
    }
  }

  void _returnToMainMenu() {
    Navigator.of(context).pop();
  }

  void _restartGame() {
    setState(() {
      _showGameOver = false;
    });
    game.restart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          // Toggle stats panel with TAB key
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
            _toggleStatsPanel();
            return KeyEventResult.handled;
          }
          // Let other keys pass through to the game
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // The Flame game
            GameWidget(game: game),

            // HUD overlay (always visible during gameplay)
            if (!_showGameOver)
              FlutterHUD(
                game: game,
                onSettingsPressed: _toggleSettingsDialog,
              ),

            // Combo Meter (shows during gameplay)
            if (!_showGameOver && !_showUpgradeDialog)
              ComboMeter(game: game),

            // Stats Panel (toggleable with TAB key or from settings)
            if (!_showGameOver && !_showUpgradeDialog && !_showSettingsDialog)
              StatsPanel(game: game, isVisible: _showStatsPanel),

            // Settings Dialog
            if (!_showGameOver && !_showUpgradeDialog && _showSettingsDialog)
              SettingsDialog(
                game: game,
                onClose: _toggleSettingsDialog,
                onBackToMenu: _returnToMainMenu,
                onViewStats: _openStatsFromSettings,
                isAudioMuted: game.audioManager.isMuted,
                onAudioMuteChanged: _toggleAudioMute,
              ),

            // Upgrade selection dialog
            if (_showUpgradeDialog)
              FlutterUpgradeDialog(game: game),

            // Game over screen
            if (_showGameOver)
              FlutterGameOverScreen(
                game: game,
                onRestart: _restartGame,
                onMainMenu: _returnToMainMenu,
              ),
          ],
        ),
      ),
    );
  }
}
