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
                Builder(
                  builder: (context) {
                    // Get the full screen width from the outer LayoutBuilder
                    final screenWidth = constraints.maxWidth;
                    // Responsive sizing with maximum width for desktop
                    // On desktop, limit to 60% of screen or 900px max
                    // On mobile, use 90% of screen
                    final maxDialogWidth = isMobile ? screenWidth * 0.9 : 900.0;
                    final availableWidth = (screenWidth * (isMobile ? 0.9 : 0.6)).clamp(300.0, maxDialogWidth);
                    final spacing = availableWidth * 0.03;
                    final totalSpacing = spacing * (upgrades.length - 1);
                    final cardWidth = (availableWidth - totalSpacing) / upgrades.length;
                    final cardHeight = cardWidth * 1.25;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
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

  Color _getRarityColor(UpgradeRarity rarity) {
    switch (rarity) {
      case UpgradeRarity.common:
        return const Color(0xFF888888); // Gray
      case UpgradeRarity.rare:
        return const Color(0xFF00AAFF); // Blue
      case UpgradeRarity.epic:
        return const Color(0xFFAA00FF); // Purple
      case UpgradeRarity.legendary:
        return const Color(0xFFFFAA00); // Orange/Gold
    }
  }

  String _getRarityName(UpgradeRarity rarity) {
    switch (rarity) {
      case UpgradeRarity.common:
        return 'COMMON';
      case UpgradeRarity.rare:
        return 'RARE';
      case UpgradeRarity.epic:
        return 'EPIC';
      case UpgradeRarity.legendary:
        return 'LEGENDARY';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarity = widget.upgrade.rarity;
    final rarityColor = _getRarityColor(rarity);

    // Responsive font sizes based on card width
    final iconSize = widget.width * 0.28;
    final nameSize = widget.width * 0.10;
    final descSize = widget.width * 0.07;
    final raritySize = widget.width * 0.06;
    final borderWidth = widget.width * 0.02;
    final padding = widget.width * 0.08;
    final spacing = widget.height * 0.03;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _isHovered
                    ? rarityColor.withValues(alpha: 0.25)
                    : rarityColor.withValues(alpha: 0.15),
                _isHovered
                    ? const Color(0xFF333333)
                    : const Color(0xFF222222),
              ],
            ),
            border: Border.all(
              color: rarityColor,
              width: borderWidth,
            ),
            borderRadius: BorderRadius.circular(widget.width * 0.05),
            boxShadow: rarity != UpgradeRarity.common
                ? [
                    BoxShadow(
                      color: rarityColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Rarity badge at top
              Positioned(
                top: spacing,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: padding * 0.6,
                      vertical: spacing * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(widget.width * 0.03),
                      border: Border.all(
                        color: rarityColor.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _getRarityName(rarity),
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: raritySize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: spacing * 2),
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
                  SizedBox(height: spacing * 0.5),
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
            ],
          ),
        ),
      ),
    );
  }
}
