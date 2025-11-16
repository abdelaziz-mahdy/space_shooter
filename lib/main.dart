import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/space_shooter_game.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Shooter',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: GameWidget(
          game: SpaceShooterGame(),
        ),
      ),
    );
  }
}
