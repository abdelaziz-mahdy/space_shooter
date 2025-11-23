import 'package:flutter/material.dart';
import 'ui/main_menu.dart';
import 'ui/game_screen.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const MainMenu(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}
