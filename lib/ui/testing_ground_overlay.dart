import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/space_shooter_game.dart';
import '../managers/debug_manager.dart';
import '../upgrades/upgrade.dart';
import 'widgets/upgrade_display_widget.dart';

/// Testing ground overlay for debugging and testing
/// Provides controls to:
/// - Jump to specific waves
/// - Spawn enemies/bosses
/// - Grant upgrades
/// - Modify player state
class TestingGroundOverlay extends StatefulWidget {
  final SpaceShooterGame game;

  const TestingGroundOverlay({super.key, required this.game});

  @override
  State<TestingGroundOverlay> createState() => _TestingGroundOverlayState();
}

class _TestingGroundOverlayState extends State<TestingGroundOverlay> {
  bool _isExpanded = false;
  int _selectedTab = 0;
  final TextEditingController _waveController = TextEditingController();

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  DebugManager? get debugManager => widget.game.debugManager;

  @override
  Widget build(BuildContext context) {
    if (!widget.game.hasLoaded || debugManager == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 20,
      bottom: 20,
      child: _isExpanded ? _buildExpandedPanel() : _buildCollapsedButton(),
    );
  }

  Widget _buildCollapsedButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _isExpanded = true),
      icon: const Icon(Icons.science, size: 20),
      label: const Text('Testing Ground'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple.withValues(alpha: 0.9),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.science, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Testing Ground',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _isExpanded = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                _buildTab('Wave', 0),
                _buildTab('Spawn', 1),
                _buildTab('Upgrades', 2),
                _buildTab('Player', 3),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.withValues(alpha: 0.5) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.purple : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildWaveTab();
      case 1:
        return _buildSpawnTab();
      case 2:
        return _buildUpgradesTab();
      case 3:
        return _buildPlayerTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWaveTab() {
    final currentWave = widget.game.enemyManager.currentWave;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Current Wave: $currentWave'),
        const SizedBox(height: 12),

        // Wave input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _waveController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter wave number',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final wave = int.tryParse(_waveController.text);
                if (wave != null && wave > 0) {
                  debugManager!.jumpToWave(wave);
                  _waveController.clear();
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Jump'),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Quick Jump'),
        const SizedBox(height: 8),

        // Quick jump buttons (boss waves)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickJumpButton('W5\nShielder', 5),
            _buildQuickJumpButton('W10\nSplitter', 10),
            _buildQuickJumpButton('W15\nGunship', 15),
            _buildQuickJumpButton('W20\nSummoner', 20),
            _buildQuickJumpButton('W25\nVortex', 25),
            _buildQuickJumpButton('W30\nFortress', 30),
            _buildQuickJumpButton('W35\nBerserker', 35),
            _buildQuickJumpButton('W40\nArchitect', 40),
            _buildQuickJumpButton('W45\nHydra', 45),
            _buildQuickJumpButton('W50\nNexus', 50),
          ],
        ),
      ],
    );
  }

  Widget _buildSpawnTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Basic Enemies'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSpawnButton('Basic', 'basic_enemy'),
            _buildSpawnButton('Fast', 'fast_enemy'),
            _buildSpawnButton('Tank', 'tank_enemy'),
            _buildSpawnButton('Sniper', 'sniper_enemy'),
            _buildSpawnButton('Burst', 'burst_enemy'),
            _buildSpawnButton('Scatter', 'scatter_enemy'),
            _buildSpawnButton('Kamikaze', 'kamikaze'),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Bosses'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSpawnButton('Shielder', 'shielder_boss'),
            _buildSpawnButton('Splitter', 'splitter_boss'),
            _buildSpawnButton('Gunship', 'gunship_boss'),
            _buildSpawnButton('Summoner', 'summoner'),
            _buildSpawnButton('Vortex', 'vortex_boss'),
            _buildSpawnButton('Fortress', 'fortress_boss'),
            _buildSpawnButton('Berserker', 'berserker'),
            _buildSpawnButton('Architect', 'architect_boss'),
            _buildSpawnButton('Hydra', 'hydra_boss'),
            _buildSpawnButton('Nexus', 'nexus_boss'),
          ],
        ),

        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            debugManager!.killAllEnemies();
            setState(() {});
          },
          icon: const Icon(Icons.delete_sweep, size: 18),
          label: const Text('Kill All Enemies'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withValues(alpha: 0.8),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradesTab() {
    // Auto-generate upgrade lists from factory (always in sync!)
    final upgradesByRarity = DebugManager.getAllUpgradesByRarity();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Weapon Changes'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildWeaponButton('Pulse Cannon', 'pulse_cannon'),
            _buildWeaponButton('Laser Beam', 'laser_beam'),
            _buildWeaponButton('Plasma Spreader', 'plasma_spreader'),
            _buildWeaponButton('Railgun', 'railgun'),
            _buildWeaponButton('Ion Blaster', 'ion_blaster'),
          ],
        ),

        const SizedBox(height: 16),
        const Text(
          'Tap = apply once, Long press = apply 5x',
          style: TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
        ),

        const SizedBox(height: 16),
        _buildRaritySection(
          'Common',
          Colors.grey,
          upgradesByRarity[UpgradeRarity.common]!
              .map((u) => _buildUpgradeButton(u.name, u.id))
              .toList(),
        ),

        const SizedBox(height: 12),
        _buildRaritySection(
          'Rare',
          Colors.blue,
          upgradesByRarity[UpgradeRarity.rare]!
              .map((u) => _buildUpgradeButton(u.name, u.id))
              .toList(),
        ),

        const SizedBox(height: 12),
        _buildRaritySection(
          'Epic',
          Colors.purple,
          upgradesByRarity[UpgradeRarity.epic]!
              .map((u) => _buildUpgradeButton(u.name, u.id))
              .toList(),
        ),

        const SizedBox(height: 12),
        _buildRaritySection(
          'Legendary',
          Colors.amber,
          upgradesByRarity[UpgradeRarity.legendary]!
              .map((u) => _buildUpgradeButton(u.name, u.id))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildRaritySection(String title, Color color, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: children,
        ),
      ],
    );
  }

  Widget _buildPlayerTab() {
    final player = widget.game.player;
    final invincible = debugManager!.isInvincible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Health'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  debugManager!.healToFull();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Heal to Full'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  debugManager!.toggleInvincibility();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: invincible
                      ? Colors.amber.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                ),
                child: Text(invincible ? 'Invincible ON' : 'Invincible OFF'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Hitbox visualization toggle
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              debugManager!.toggleHitboxes();
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: debugManager!.showHitboxes
                  ? Colors.cyan.withValues(alpha: 0.8)
                  : Colors.grey.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
            ),
            child: Text(debugManager!.showHitboxes ? 'Hitboxes ON' : 'Hitboxes OFF'),
          ),
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Resources'),
        const SizedBox(height: 8),

        // Add XP buttons
        const Text('Add XP:', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildResourceButton('+100 XP', () => debugManager!.addXP(100)),
            _buildResourceButton('+500 XP', () => debugManager!.addXP(500)),
            _buildResourceButton('+1000 XP', () => debugManager!.addXP(1000)),
            _buildResourceButton('+5000 XP', () => debugManager!.addXP(5000)),
          ],
        ),

        const SizedBox(height: 12),

        // Add loot buttons
        const Text('Add Loot:', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildResourceButton('+100 💎', () => debugManager!.addLoot(100)),
            _buildResourceButton('+500 💎', () => debugManager!.addLoot(500)),
            _buildResourceButton('+1000 💎', () => debugManager!.addLoot(1000)),
            _buildResourceButton('+5000 💎', () => debugManager!.addLoot(5000)),
          ],
        ),

        const SizedBox(height: 20),
        _buildSectionTitle('Player Stats'),
        const SizedBox(height: 8),

        _buildStatRow('HP', '${player.health.toInt()}/${player.maxHealth.toInt()}'),
        _buildStatRow('Level', '${widget.game.levelManager.currentLevel}'),
        _buildStatRow('Damage', '${player.damage.toInt()}'),
        _buildStatRow('Fire Rate', '${player.shootInterval.toStringAsFixed(2)}s'),
        _buildStatRow('Speed', '${player.moveSpeed.toInt()}'),

        if (player.appliedUpgrades.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildSectionTitle('Applied Upgrades (${player.appliedUpgrades.values.fold(0, (sum, count) => sum + count)})'),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: UpgradeDisplayWidget(
                upgrades: player.appliedUpgrades,
                scale: 0.9,
                showTooltip: false,
                displayMode: DisplayMode.compact,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildQuickJumpButton(String label, int wave) {
    return SizedBox(
      width: 70,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          debugManager!.jumpToWave(wave);
          setState(() {});
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.withValues(alpha: 0.7),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildSpawnButton(String label, String enemyId) {
    return ElevatedButton(
      onPressed: () {
        debugManager!.spawnEnemy(enemyId);
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildUpgradeButton(String label, String upgradeId) {
    return ElevatedButton(
      onPressed: () {
        debugManager!.grantUpgrade(upgradeId);
        setState(() {});
      },
      onLongPress: () {
        // Long press to apply 5 times
        for (int i = 0; i < 5; i++) {
          debugManager!.grantUpgrade(upgradeId);
        }
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber.withValues(alpha: 0.7),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildWeaponButton(String label, String weaponId) {
    return ElevatedButton(
      onPressed: () {
        debugManager!.changeWeapon(weaponId);
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildResourceButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
        setState(() {});
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.withValues(alpha: 0.7),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
