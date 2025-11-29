import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/leaderboard_service.dart';
import '../config/env_config.dart';
import '../managers/audio_manager.dart';
import '../utils/upgrade_lookup.dart';
import '../upgrades/upgrade.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScoreService _scoreService = ScoreService();

  // Local scores
  List<GameScore> _localScores = [];
  bool _localLoading = true;

  // Global scores
  List<LeaderboardEntry> _globalScores = [];
  bool _globalLoading = true;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    // If global leaderboard is disabled, only show local tab
    final tabCount = EnvConfig.isLeaderboardEnabled ? 2 : 1;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadLocalScores();
    if (EnvConfig.isLeaderboardEnabled) {
      _loadGlobalScores();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalScores() async {
    await _scoreService.loadScores();
    setState(() {
      _localScores = _scoreService.getRecentScores(20);
      _localLoading = false;
    });
  }

  Future<void> _loadGlobalScores() async {
    setState(() {
      _globalLoading = true;
      _globalError = null;
    });

    final result = await LeaderboardService.getTopScores(limit: 50);

    setState(() {
      _globalLoading = false;
      if (result.success) {
        _globalScores = result.entries;
      } else {
        _globalError = result.error ?? 'Failed to load leaderboard';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000033), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        AudioManager().playButtonClick();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF00FFFF),
                        size: 32,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '🏆 LEADERBOARD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00FFFF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Tab bar
              if (EnvConfig.isLeaderboardEnabled)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF00FFFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: const Color(0xFF00FFFF),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    tabs: const [
                      Tab(text: '🌍 GLOBAL'),
                      Tab(text: '📱 LOCAL'),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Tab content
              Expanded(
                child: EnvConfig.isLeaderboardEnabled
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _buildGlobalLeaderboard(),
                          _buildLocalLeaderboard(),
                        ],
                      )
                    : _buildLocalLeaderboard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    if (_globalLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FFFF),
        ),
      );
    }

    if (_globalError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              color: Color(0xFFFF6666),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _globalError!,
              style: const TextStyle(
                color: Color(0xFFFF6666),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadGlobalScores,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFFF),
                foregroundColor: Colors.black,
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      );
    }

    if (_globalScores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF888888),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No scores yet',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to submit!',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGlobalScores,
      color: const Color(0xFF00FFFF),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _globalScores.length,
        itemBuilder: (context, index) {
          final entry = _globalScores[index];
          return _buildGlobalScoreCard(entry, index + 1);
        },
      ),
    );
  }

  void _showGlobalScoreDetails(LeaderboardEntry entry, int rank) {
    AudioManager().playButtonClick();
    showDialog(
      context: context,
      builder: (context) => _ScoreDetailsDialog(
        playerName: entry.playerName,
        score: entry.score,
        wave: entry.wave,
        kills: entry.kills,
        timeAlive: entry.timeAlive,
        upgrades: entry.upgrades,
        weaponUsed: entry.weaponUsed,
        platform: entry.platform,
        rank: rank,
      ),
    );
  }

  Widget _buildGlobalScoreCard(LeaderboardEntry entry, int rank) {
    Color rankColor;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      rankIcon = Icons.emoji_events;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankIcon = Icons.emoji_events;
    } else {
      rankColor = const Color(0xFF00FFFF);
      rankIcon = null;
    }

    return GestureDetector(
      onTap: () => _showGlobalScoreDetails(entry, rank),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rank <= 3 ? rankColor : const Color(0xFF333333),
            width: rank <= 3 ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 50,
              child: rankIcon != null
                  ? Icon(rankIcon, color: rankColor, size: 32)
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wave ${entry.wave} • ${entry.kills} kills • ${_formatTime(entry.timeAlive)}',
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Score and tap hint
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.score}',
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'pts',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 12,
                      ),
                    ),
                    if (entry.upgrades.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF666666),
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalLeaderboard() {
    if (_localLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00FFFF),
        ),
      );
    }

    if (_localScores.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gamepad_outlined,
              color: Color(0xFF888888),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No games played yet',
              style: TextStyle(
                color: Color(0xFF888888),
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Play a game to see your scores here!',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _localScores.length,
      itemBuilder: (context, index) {
        final score = _localScores[index];
        return _buildLocalScoreCard(score, index + 1);
      },
    );
  }

  Widget _buildLocalScoreCard(GameScore score, int rank) {
    final isTopScore = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTopScore ? const Color(0xFFFFD700) : const Color(0xFF333333),
          width: isTopScore ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 50,
            child: isTopScore
                ? const Icon(Icons.star, color: Color(0xFFFFD700), size: 32)
                : Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),

          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wave ${score.wave} • ${score.kills} kills',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${score.formattedTime} • ${_formatDate(score.timestamp)}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${score.score}',
                style: TextStyle(
                  color: isTopScore
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF00FFFF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'pts',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins}m ${secs}s';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog showing detailed score information with upgrades
class _ScoreDetailsDialog extends StatelessWidget {
  final String playerName;
  final int score;
  final int wave;
  final int kills;
  final double timeAlive;
  final List<String> upgrades;
  final String? weaponUsed;
  final String? platform;
  final int rank;

  const _ScoreDetailsDialog({
    required this.playerName,
    required this.score,
    required this.wave,
    required this.kills,
    required this.timeAlive,
    required this.upgrades,
    this.weaponUsed,
    this.platform,
    required this.rank,
  });

  Color _getRarityColor(UpgradeRarity rarity) {
    switch (rarity) {
      case UpgradeRarity.common:
        return const Color(0xFFCCCCCC);
      case UpgradeRarity.rare:
        return const Color(0xFF00AAFF);
      case UpgradeRarity.epic:
        return const Color(0xFFAA00FF);
      case UpgradeRarity.legendary:
        return const Color(0xFFFFAA00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upgradeInfos = UpgradeLookup.getUpgradesForIds(upgrades);
    final mins = (timeAlive / 60).floor();
    final secs = (timeAlive % 60).floor();
    final timeStr = '${mins}m ${secs}s';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00FFFF),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF333333)),
                ),
              ),
              child: Column(
                children: [
                  // Rank badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                          : const Color(0xFF00FFFF).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: rank <= 3
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF00FFFF),
                      ),
                    ),
                    child: Text(
                      'RANK #$rank',
                      style: TextStyle(
                        color: rank <= 3
                            ? const Color(0xFFFFD700)
                            : const Color(0xFF00FFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score pts',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(Icons.waves, 'Wave', '$wave'),
                  _buildStatItem(Icons.dangerous, 'Kills', '$kills'),
                  _buildStatItem(Icons.timer, 'Time', timeStr),
                ],
              ),
            ),

            // Weapon and Platform row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Weapon used
                  if (weaponUsed != null && weaponUsed!.isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.rocket_launch,
                              color: Color(0xFF00FFFF),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _formatWeaponName(weaponUsed!),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (weaponUsed != null && weaponUsed!.isNotEmpty && platform != null)
                    const SizedBox(width: 8),
                  // Platform
                  if (platform != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPlatformIcon(platform!),
                            color: const Color(0xFF888888),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatPlatformName(platform!),
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Upgrades section
            if (upgradeInfos.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.upgrade,
                      color: Color(0xFF00FFFF),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'UPGRADES',
                      style: TextStyle(
                        color: Color(0xFF00FFFF),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: upgradeInfos.map((info) {
                        return Tooltip(
                          message: info.description,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getRarityColor(info.rarity)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getRarityColor(info.rarity)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  info.icon,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  info.name,
                                  style: TextStyle(
                                    color: _getRarityColor(info.rarity),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No upgrade data available',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FFFF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF888888), size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatWeaponName(String weaponId) {
    // Convert snake_case to Title Case
    return weaponId
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  IconData _getPlatformIcon(String platform) {
    final lowerPlatform = platform.toLowerCase();
    if (lowerPlatform.contains('ios')) {
      return Icons.phone_iphone;
    } else if (lowerPlatform.contains('android')) {
      return Icons.phone_android;
    } else if (lowerPlatform.contains('macos')) {
      return Icons.laptop_mac;
    } else if (lowerPlatform.contains('windows')) {
      return Icons.desktop_windows;
    } else if (lowerPlatform.contains('linux')) {
      return Icons.computer;
    } else if (lowerPlatform.contains('web')) {
      return Icons.language;
    }
    return Icons.devices;
  }

  String _formatPlatformName(String platform) {
    final lowerPlatform = platform.toLowerCase();
    if (lowerPlatform == 'ios') {
      return 'iOS';
    } else if (lowerPlatform == 'ios-web') {
      return 'iOS Web';
    } else if (lowerPlatform == 'android') {
      return 'Android';
    } else if (lowerPlatform == 'android-web') {
      return 'Android Web';
    } else if (lowerPlatform == 'macos') {
      return 'macOS';
    } else if (lowerPlatform == 'macos-web') {
      return 'macOS Web';
    } else if (lowerPlatform == 'windows') {
      return 'Windows';
    } else if (lowerPlatform == 'windows-web') {
      return 'Windows Web';
    } else if (lowerPlatform == 'linux') {
      return 'Linux';
    } else if (lowerPlatform == 'linux-web') {
      return 'Linux Web';
    } else if (lowerPlatform == 'web') {
      return 'Web';
    }
    return platform;
  }
}
