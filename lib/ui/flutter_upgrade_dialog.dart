import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';

class FlutterUpgradeDialog extends StatelessWidget {
  final SpaceShooterGame game;

  const FlutterUpgradeDialog({super.key, required this.game});

  void _selectUpgrade(Upgrade upgrade) {
    upgrade.apply(game.player);
    game.resumeFromUpgrade();
    if (game.onHideUpgrade != null) {
      game.onHideUpgrade!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgrades = game.levelManager.getRandomUpgrades(3);

    return Container(
      color: const Color(0xCC000000),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'LEVEL UP!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an upgrade',
              style: TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: upgrades.map((upgrade) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: UpgradeCardWidget(
                    upgrade: upgrade,
                    onSelected: () => _selectUpgrade(upgrade),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class UpgradeCardWidget extends StatefulWidget {
  final Upgrade upgrade;
  final VoidCallback onSelected;

  const UpgradeCardWidget({
    super.key,
    required this.upgrade,
    required this.onSelected,
  });

  @override
  State<UpgradeCardWidget> createState() => _UpgradeCardWidgetState();
}

class _UpgradeCardWidgetState extends State<UpgradeCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          width: 200,
          height: 250,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF333333) : const Color(0xFF222222),
            border: Border.all(
              color: const Color(0xFF00FFFF),
              width: 3,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.upgrade.icon,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 20),
              Text(
                widget.upgrade.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.upgrade.description,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
