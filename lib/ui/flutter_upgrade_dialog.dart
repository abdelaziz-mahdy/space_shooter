import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';

class FlutterUpgradeDialog extends StatefulWidget {
  final SpaceShooterGame game;

  const FlutterUpgradeDialog({super.key, required this.game});

  @override
  State<FlutterUpgradeDialog> createState() => _FlutterUpgradeDialogState();
}

class _FlutterUpgradeDialogState extends State<FlutterUpgradeDialog> {
  late List<Upgrade> upgrades;

  @override
  void initState() {
    super.initState();
    // Generate upgrades once when dialog is created
    upgrades = widget.game.levelManager.getRandomUpgrades(3);
  }

  void _selectUpgrade(Upgrade upgrade) {
    upgrade.apply(widget.game.player);
    // Track upgrade for leaderboard
    widget.game.player.appliedUpgrades.add(upgrade.id);
    widget.game.resumeFromUpgrade();
    if (widget.game.onHideUpgrade != null) {
      widget.game.onHideUpgrade!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC000000),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale text sizes based on screen width
          final isMobile = constraints.maxWidth < 800;
          final titleSize = isMobile ? 48.0 : 40.0;
          final subtitleSize = isMobile ? 24.0 : 20.0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose an upgrade',
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: subtitleSize,
                  ),
                ),
                const SizedBox(height: 40),
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive sizing with maximum width for desktop
                // On desktop, limit to 60% of screen or 900px max
                // On mobile, use 90% of screen
                final isMobile = constraints.maxWidth < 800;
                final maxDialogWidth = isMobile ? constraints.maxWidth * 0.9 : 900.0;
                final availableWidth = (constraints.maxWidth * (isMobile ? 0.9 : 0.6)).clamp(300.0, maxDialogWidth);
                final spacing = availableWidth * 0.03;
                final totalSpacing = spacing * (upgrades.length - 1);
                final cardWidth = (availableWidth - totalSpacing) / upgrades.length;
                final cardHeight = cardWidth * 1.25;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: upgrades.map((upgrade) {
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                      child: UpgradeCardWidget(
                        upgrade: upgrade,
                        onSelected: () => _selectUpgrade(upgrade),
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class UpgradeCardWidget extends StatefulWidget {
  final Upgrade upgrade;
  final VoidCallback onSelected;
  final double width;
  final double height;

  const UpgradeCardWidget({
    super.key,
    required this.upgrade,
    required this.onSelected,
    required this.width,
    required this.height,
  });

  @override
  State<UpgradeCardWidget> createState() => _UpgradeCardWidgetState();
}

class _UpgradeCardWidgetState extends State<UpgradeCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Responsive font sizes based on card width
    final iconSize = widget.width * 0.32;
    final nameSize = widget.width * 0.11;
    final descSize = widget.width * 0.08;
    final borderWidth = widget.width * 0.015;
    final padding = widget.width * 0.08;
    final spacing = widget.height * 0.04;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF333333) : const Color(0xFF222222),
            border: Border.all(
              color: const Color(0xFF00FFFF),
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(widget.width * 0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.upgrade.icon,
                style: TextStyle(fontSize: iconSize),
              ),
              SizedBox(height: spacing),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Text(
                  widget.upgrade.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: nameSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: spacing * 0.6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Text(
                  widget.upgrade.description,
                  style: TextStyle(
                    color: const Color(0xFFCCCCCC),
                    fontSize: descSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
