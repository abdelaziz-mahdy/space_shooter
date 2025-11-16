import 'package:flutter/material.dart';
import 'ui/main_menu.dart';

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
      home: const MainMenu(),
    );
  }
}
