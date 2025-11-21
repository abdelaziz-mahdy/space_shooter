import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import 'flutter_hud.dart';
import 'flutter_upgrade_dialog.dart';
import 'flutter_game_over_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SpaceShooterGame game;
  bool _showUpgradeDialog = false;
  bool _showGameOver = false;

  @override
  void initState() {
    super.initState();
    game = SpaceShooterGame();

    // Set up callbacks for UI state changes
    game.onShowUpgrade = () {
      setState(() {
        _showUpgradeDialog = true;
      });
    };

    game.onHideUpgrade = () {
      setState(() {
        _showUpgradeDialog = false;
      });
    };

    game.onShowGameOver = () {
      setState(() {
        _showGameOver = true;
      });
    };

    game.onReturnToMenu = _returnToMainMenu;
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
      body: Stack(
        children: [
          // The Flame game
          GameWidget(game: game),

          // HUD overlay (always visible during gameplay)
          if (!_showGameOver)
            FlutterHUD(game: game),

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
    );
  }
}
