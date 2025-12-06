import 'package:flutter/material.dart';
import '../../upgrades/upgrade.dart';
import '../../utils/upgrade_lookup.dart';

/// Shared widget for displaying upgrades with count badges
/// Used by stats panel, leaderboard, and debug UI
class UpgradeDisplayWidget extends StatelessWidget {
  final Map<String, int> upgrades;
  final double scale;
  final bool showTooltip;
  final DisplayMode displayMode;

  const UpgradeDisplayWidget({
    super.key,
    required this.upgrades,
    this.scale = 1.0,
    this.showTooltip = true,
    this.displayMode = DisplayMode.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (upgrades.isEmpty) {
      return Text(
        'No upgrades',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12 * scale,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Get all upgrade infos
    final upgradeEntries = upgrades.entries.toList();
    final allGenericUpgrades = UpgradeFactory.getAllUpgrades();
    final allWeaponUpgrades = UpgradeFactory.getAllWeaponUpgrades();
    final allUpgrades = [...allGenericUpgrades, ...allWeaponUpgrades];

    switch (displayMode) {
      case DisplayMode.compact:
        return _buildCompactList(upgradeEntries, allUpgrades);
      case DisplayMode.wrap:
        return _buildWrap(upgradeEntries, allUpgrades);
      case DisplayMode.grid:
        return _buildGrid(upgradeEntries, allUpgrades);
    }
  }

  /// Compact list with icon, name, and count badge
  Widget _buildCompactList(List<MapEntry<String, int>> entries, List<Upgrade> allUpgrades) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final upgrade = _findUpgrade(entry.key, allUpgrades);
        if (upgrade == null) return const SizedBox.shrink();

        final count = entry.value;
        final rarityColor = _getRarityColor(upgrade.rarity);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 3 * scale),
          child: Row(
            children: [
              // Icon
              Text(
                upgrade.icon,
                style: TextStyle(fontSize: 16 * scale),
              ),
              SizedBox(width: 8 * scale),
              // Name
              Expanded(
                child: Text(
                  upgrade.name,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Count badge
              if (count > 1) ...[
                SizedBox(width: 4 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10 * scale),
                    border: Border.all(
                      color: rarityColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'x$count',
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Wrap layout for dialogs/details
  Widget _buildWrap(List<MapEntry<String, int>> entries, List<Upgrade> allUpgrades) {
    return Wrap(
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: entries.map((entry) {
        final upgrade = _findUpgrade(entry.key, allUpgrades);
        if (upgrade == null) return const SizedBox.shrink();

        final count = entry.value;
        final rarityColor = _getRarityColor(upgrade.rarity);

        final widget = Container(
          padding: EdgeInsets.symmetric(
            horizontal: 10 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: rarityColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: rarityColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                upgrade.icon,
                style: TextStyle(fontSize: 16 * scale),
              ),
              SizedBox(width: 6 * scale),
              Text(
                upgrade.name,
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (count > 1) ...[
                SizedBox(width: 6 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * scale,
                    vertical: 2 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Text(
                    'x$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

        // Wrap with tooltip if enabled
        if (showTooltip) {
          return Tooltip(
            message: upgrade.description,
            child: widget,
          );
        }
        return widget;
      }).toList(),
    );
  }

  /// Grid layout for larger displays
  Widget _buildGrid(List<MapEntry<String, int>> entries, List<Upgrade> allUpgrades) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      crossAxisSpacing: 8 * scale,
      mainAxisSpacing: 8 * scale,
      children: entries.map((entry) {
        final upgrade = _findUpgrade(entry.key, allUpgrades);
        if (upgrade == null) return const SizedBox.shrink();

        final count = entry.value;
        final rarityColor = _getRarityColor(upgrade.rarity);

        return Container(
          padding: EdgeInsets.all(8 * scale),
          decoration: BoxDecoration(
            color: rarityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8 * scale),
            border: Border.all(
              color: rarityColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                upgrade.icon,
                style: TextStyle(fontSize: 20 * scale),
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      upgrade.name,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 11 * scale,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (count > 1)
                      Text(
                        'x$count',
                        style: TextStyle(
                          color: rarityColor.withValues(alpha: 0.7),
                          fontSize: 9 * scale,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Upgrade? _findUpgrade(String id, List<Upgrade> allUpgrades) {
    try {
      return allUpgrades.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  Color _getRarityColor(UpgradeRarity rarity) {
    switch (rarity) {
      case UpgradeRarity.common:
        return Colors.white70;
      case UpgradeRarity.rare:
        return const Color(0xFF4169E1); // Royal blue
      case UpgradeRarity.epic:
        return const Color(0xFF9370DB); // Medium purple
      case UpgradeRarity.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }
}

/// Display modes for the widget
enum DisplayMode {
  compact, // Vertical list (stats panel)
  wrap, // Wrapped chips (leaderboard dialog)
  grid, // Grid layout (large displays)
}
