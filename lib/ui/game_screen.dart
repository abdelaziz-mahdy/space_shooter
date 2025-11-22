import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/space_shooter_game.dart';
import 'flutter_hud.dart';
import 'flutter_upgrade_dialog.dart';
import 'flutter_game_over_screen.dart';
import 'combo_meter.dart';
import 'stats_panel.dart';

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
              FlutterHUD(game: game),

            // Combo Meter (shows during gameplay)
            if (!_showGameOver && !_showUpgradeDialog)
              ComboMeter(game: game),

            // Stats Panel (toggleable with TAB key)
            if (!_showGameOver && !_showUpgradeDialog)
              StatsPanel(game: game, isVisible: _showStatsPanel),

            // Stats Panel toggle button (bottom right)
            if (!_showGameOver && !_showUpgradeDialog)
              Positioned(
                right: 10,
                bottom: 10,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: _showStatsPanel
                      ? const Color(0xFF00FFFF)
                      : Colors.black.withOpacity(0.6),
                  onPressed: _toggleStatsPanel,
                  child: Icon(
                    Icons.analytics,
                    color: _showStatsPanel ? Colors.black : const Color(0xFF00FFFF),
                  ),
                ),
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
