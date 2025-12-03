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
    // Track upgrade count for leaderboard
    final upgrades = widget.game.player.appliedUpgrades;
    upgrades[upgrade.id] = (upgrades[upgrade.id] ?? 0) + 1;
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
          // Percentage-based responsive sizing (follows claude.md principles)
          final titleSize = constraints.maxWidth * 0.05; // 5% of screen width
          final subtitleSize = constraints.maxWidth * 0.025; // 2.5% of screen width

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
                // Use Expanded for responsive layout without manual calculations
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.08, // 8% padding on each side
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(upgrades.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.02, // 2% spacing between cards
                          ),
                          child: UpgradeCardWidget(
                            upgrade: upgrades[index],
                            onSelected: () => _selectUpgrade(upgrades[index]),
                          ),
                        ),
                      );
                    }),
                  ),
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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AspectRatio(
          aspectRatio: 0.7, // Card aspect ratio (taller cards for more text space)
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Responsive font sizes based on available width
              final cardWidth = constraints.maxWidth;
              final cardHeight = constraints.maxHeight;
              final iconSize = cardWidth * 0.3;
              final nameSize = cardWidth * 0.11;
              final descSize = cardWidth * 0.08;
              final raritySize = cardWidth * 0.065;
              final borderWidth = cardWidth * 0.015;
              final padding = cardWidth * 0.06;
              final spacing = cardHeight * 0.025;

              return Container(
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
                  borderRadius: BorderRadius.circular(cardWidth * 0.05),
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
                            borderRadius: BorderRadius.circular(cardWidth * 0.03),
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
                    // Main content - consistent spacing across all cards
                    Padding(
                      padding: EdgeInsets.only(
                        top: cardHeight * 0.12, // Space for rarity badge
                        left: padding,
                        right: padding,
                        bottom: padding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Icon - contained to fit properly
                          Expanded(
                            flex: 3,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                widget.upgrade.icon,
                                style: TextStyle(fontSize: iconSize),
                              ),
                            ),
                          ),
                          SizedBox(height: spacing),
                          // Name - takes proportional space
                          Expanded(
                            flex: 2,
                            child: Center(
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
                          ),
                          SizedBox(height: spacing * 0.5),
                          // Description - takes proportional space
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                widget.upgrade.description,
                                style: TextStyle(
                                  color: const Color(0xFFCCCCCC),
                                  fontSize: descSize,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
