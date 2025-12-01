import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../upgrades/upgrade.dart';
import '../upgrades/weapon_upgrade.dart';

/// Toggleable stats panel that shows detailed player statistics
/// Can be shown/hidden with a button or key press
class StatsPanel extends StatelessWidget {
  final SpaceShooterGame game;
  final bool isVisible;
  final VoidCallback? onClose;

  const StatsPanel({
    super.key,
    required this.game,
    this.isVisible = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final player = game.player;

    return GestureDetector(
      onTap: () {
        // Close stats panel when clicking outside
        if (onClose != null) {
          onClose!();
        }
      },
      child: Container(
        color: Colors.transparent, // Makes entire background tappable
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive scale based on screen width
            final scale = (constraints.maxWidth / 800).clamp(0.6, 1.2);
            final panelWidth = (280.0 * scale).clamp(200.0, 350.0);
            final maxHeight = constraints.maxHeight * 0.8; // Max 80% of screen height

            return Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(right: 10 * scale, top: 100 * scale),
                child: GestureDetector(
                  onTap: () {
                    // Stop propagation - clicking inside panel shouldn't close it
                  },
                  child: Container(
            width: panelWidth,
            constraints: BoxConstraints(
              maxHeight: maxHeight,
            ),
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(color: const Color(0xFF00FFFF), width: 2 * scale),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FFFF).withOpacity(0.3),
                  blurRadius: 10 * scale,
                  spreadRadius: 2 * scale,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STATS',
                        style: TextStyle(
                          fontSize: 20 * scale,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00FFFF),
                          letterSpacing: 2 * scale,
                        ),
                      ),
                      Icon(
                        Icons.analytics,
                        color: const Color(0xFF00FFFF),
                        size: 24 * scale,
                      ),
                    ],
                  ),
                  Divider(color: const Color(0xFF00FFFF), height: 20 * scale, thickness: 2 * scale),

                  // Offensive Stats
                  _buildSectionHeader('OFFENSE', scale),
                  _buildStat('Damage', player.damage.toStringAsFixed(1), scale),
                  _buildStat('Fire Rate', '${(1 / player.shootInterval).toStringAsFixed(2)}/s', scale),
                  _buildStat('Crit Chance', '${(player.critChance * 100).toStringAsFixed(1)}%', scale),
                  _buildStat('Crit Damage', '${(player.critDamage * 100).toStringAsFixed(0)}%', scale),
                  _buildStat('Projectiles', '${player.projectileCount}', scale),
                  _buildStat('Pierce', '${player.bulletPierce}', scale),

                  SizedBox(height: 12 * scale),

                  // Defensive Stats
                  _buildSectionHeader('DEFENSE', scale),
                  _buildStat('Max Health', player.maxHealth.toStringAsFixed(0), scale),
                  _buildStat('Health Regen', '+${player.healthRegen.toStringAsFixed(1)}/s', scale),
                  _buildStat('Armor', '${(player.damageReduction * 100).toStringAsFixed(1)}%', scale),
                  _buildStat('Shield Layers', '${player.shieldLayers}/${player.maxShieldLayers}', scale),
                  _buildStat('Max Shield Layers', '${player.maxShieldLayers}', scale),

                  SizedBox(height: 12 * scale),

                  // Utility Stats
                  _buildSectionHeader('UTILITY', scale),
                  _buildStat('Move Speed', player.moveSpeed.toStringAsFixed(0), scale),
                  _buildStat('Lifesteal', '${(player.lifesteal * 100).toStringAsFixed(1)}%', scale),
                  _buildStat('XP Multiplier', '${player.xpMultiplier.toStringAsFixed(2)}x', scale),
                  _buildStat('Luck', '${(player.luck * 100).toStringAsFixed(0)}%', scale),
                  _buildStat('Magnet Range', player.magnetRadius.toStringAsFixed(0), scale),

                  SizedBox(height: 12 * scale),

                  // Special Stats
                  _buildSectionHeader('SPECIAL', scale),
                  if (player.explosionRadius > 0)
                    _buildStat('Explosion Radius', player.explosionRadius.toStringAsFixed(0), scale),
                  if (player.freezeChance > 0)
                    _buildStat('Freeze Chance', '${(player.freezeChance * 100).toStringAsFixed(1)}%', scale),
                  if (player.orbitalCount > 0)
                    _buildStat('Orbital Shooters', '${player.orbitalCount}', scale),
                  if (player.resurrectionChance > 0)
                    _buildStat('Resurrection', '${(player.resurrectionChance * 100).toStringAsFixed(0)}%', scale),

                  // Current weapon
                  SizedBox(height: 12 * scale),
                  _buildSectionHeader('WEAPON', scale),
                  _buildStat('Current', player.weaponManager.getCurrentWeaponName(), scale),

                  // Upgrades section
                  if (player.appliedUpgrades.isNotEmpty) ...[
                    SizedBox(height: 12 * scale),
                    _buildSectionHeader('UPGRADES (${player.appliedUpgrades.length})', scale),
                    SizedBox(height: 6 * scale),
                    ..._buildUpgradesList(player.appliedUpgrades, scale),
                  ],
                ],
              ),
            ),
          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildUpgradesList(List<String> upgradeIds, double scale) {
    // Get all available upgrades
    final allUpgrades = UpgradeFactory.getAllUpgrades();
    final allWeaponUpgrades = UpgradeFactory.getAllWeaponUpgrades();

    return upgradeIds.map((id) {
      // Find upgrade by ID
      Upgrade? upgrade;
      try {
        upgrade = allUpgrades.firstWhere((u) => u.id == id);
      } catch (e) {
        try {
          upgrade = allWeaponUpgrades.firstWhere((u) => u.id == id);
        } catch (e) {
          // Upgrade not found, skip it
          return const SizedBox.shrink();
        }
      }

      if (upgrade == null) return const SizedBox.shrink();

      // Get rarity color
      Color rarityColor;
      switch (upgrade.rarity) {
        case UpgradeRarity.common:
          rarityColor = Colors.white70;
          break;
        case UpgradeRarity.rare:
          rarityColor = const Color(0xFF4169E1); // Royal blue
          break;
        case UpgradeRarity.epic:
          rarityColor = const Color(0xFF9370DB); // Medium purple
          break;
        case UpgradeRarity.legendary:
          rarityColor = const Color(0xFFFFD700); // Gold
          break;
      }

      return Padding(
        padding: EdgeInsets.symmetric(vertical: 3 * scale),
        child: Row(
          children: [
            Text(
              upgrade.icon,
              style: TextStyle(fontSize: 16 * scale),
            ),
            SizedBox(width: 8 * scale),
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
          ],
        ),
      );
    }).toList();
  }

  Widget _buildSectionHeader(String title, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6 * scale, top: 4 * scale),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFFF00),
          letterSpacing: 1.5 * scale,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13 * scale,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: const Color(0xFF00FFFF),
              fontSize: 13 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
