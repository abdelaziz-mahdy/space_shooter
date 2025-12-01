import 'package:flutter/material.dart';
import '../game/space_shooter_game.dart';
import '../services/score_service.dart';
import '../services/leaderboard_service.dart';
import '../config/env_config.dart';
import '../managers/audio_manager.dart';

class FlutterGameOverScreen extends StatefulWidget {
  final SpaceShooterGame game;
  final VoidCallback onRestart;
  final VoidCallback onMainMenu;

  const FlutterGameOverScreen({
    super.key,
    required this.game,
    required this.onRestart,
    required this.onMainMenu,
  });

  @override
  State<FlutterGameOverScreen> createState() => _FlutterGameOverScreenState();
}

class _FlutterGameOverScreenState extends State<FlutterGameOverScreen> {
  bool _localScoreSaved = false;
  bool _isSubmittingToLeaderboard = false;
  bool _leaderboardSubmitted = false;
  String? _leaderboardError;
  int? _leaderboardRank;
  int? _predictedRank;
  bool _isPredictingRank = false;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _saveLocalScore();
    _loadSavedPlayerName();
    _fetchPredictedRank();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSavedPlayerName() async {
    final savedName = await LeaderboardService.getSavedPlayerName();
    if (savedName != null && savedName.isNotEmpty) {
      _nameController.text = savedName;
    }
  }

  Future<void> _fetchPredictedRank() async {
    if (!EnvConfig.isLeaderboardEnabled) return;

    setState(() {
      _isPredictingRank = true;
    });

    try {
      final currentScore = _calculateScore();

      // Get predicted rank from backend
      final rank = await LeaderboardService.getPredictedRank(currentScore);

      if (rank != null) {
        setState(() {
          _predictedRank = rank;
          _isPredictingRank = false;
        });
      } else {
        setState(() {
          _isPredictingRank = false;
        });
      }
    } catch (e) {
      print('[GameOver] Error predicting rank: $e');
      setState(() {
        _isPredictingRank = false;
      });
    }
  }

  Future<void> _saveLocalScore() async {
    if (_localScoreSaved) return;

    final scoreService = ScoreService();
    await scoreService.loadScores();

    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;
    final player = widget.game.player;

    final enemiesKilled = statsManager.enemiesKilled;
    final wavesCompleted = enemyManager.getCurrentWave() - 1;
    final timeAliveSeconds = statsManager.timeAlive;

    // Calculate score: kills * 10 + waves * 100 + time bonus
    final score = (enemiesKilled * 10) + (wavesCompleted * 100) + timeAliveSeconds.toInt();

    final gameScore = GameScore(
      score: score,
      wave: wavesCompleted,
      kills: enemiesKilled,
      timeAlive: timeAliveSeconds,
      timestamp: DateTime.now(),
      upgrades: List<String>.from(player.appliedUpgrades),
      weaponUsed: player.weaponManager.getCurrentWeaponId(),
    );

    await scoreService.saveScore(gameScore);
    setState(() {
      _localScoreSaved = true;
    });
    print('[GameOver] Local score saved: $score');
  }

  int _calculateScore() {
    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;
    final enemiesKilled = statsManager.enemiesKilled;
    final wavesCompleted = enemyManager.getCurrentWave() - 1;
    final timeAliveSeconds = statsManager.timeAlive;
    return (enemiesKilled * 10) + (wavesCompleted * 100) + timeAliveSeconds.toInt();
  }

  Future<void> _submitToLeaderboard() async {
    final playerName = _nameController.text.trim();

    // Validate name
    if (playerName.isEmpty) {
      setState(() {
        _leaderboardError = 'Please enter your name';
      });
      return;
    }

    if (playerName.length > 20) {
      setState(() {
        _leaderboardError = 'Name must be 20 characters or less';
      });
      return;
    }

    // Check for valid characters (alphanumeric + spaces)
    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(playerName)) {
      setState(() {
        _leaderboardError = 'Name can only contain letters, numbers, and spaces';
      });
      return;
    }

    setState(() {
      _isSubmittingToLeaderboard = true;
      _leaderboardError = null;
    });

    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;
    final player = widget.game.player;

    final entry = LeaderboardEntry(
      playerName: playerName,
      score: _calculateScore(),
      wave: enemyManager.getCurrentWave() - 1,
      kills: statsManager.enemiesKilled,
      timeAlive: statsManager.timeAlive,
      upgrades: List<String>.from(player.appliedUpgrades),
      weaponUsed: player.weaponManager.getCurrentWeaponId(),
    );

    final result = await LeaderboardService.submitScore(entry);

    setState(() {
      _isSubmittingToLeaderboard = false;
      if (result.success) {
        _leaderboardSubmitted = true;
        _leaderboardRank = result.entry?.rank;
      } else {
        _leaderboardError = result.error ?? 'Failed to submit score';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsManager = widget.game.statsManager;
    final enemyManager = widget.game.enemyManager;
    final isLeaderboardEnabled = EnvConfig.isLeaderboardEnabled;

    return Container(
      color: const Color(0xDD000000),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'GAME OVER',
                style: TextStyle(
                  color: Color(0xFFFF0000),
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              // Score display
              Text(
                'Score: ${_calculateScore()}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard('Time', statsManager.getTimeAliveFormatted()),
                  const SizedBox(width: 20),
                  _buildStatCard('Kills', '${statsManager.enemiesKilled}'),
                  const SizedBox(width: 20),
                  _buildStatCard('Waves', '${enemyManager.getCurrentWave() - 1}'),
                ],
              ),
              const SizedBox(height: 30),

              // Predicted global rank
              if (isLeaderboardEnabled && !_leaderboardSubmitted) ...[
                if (_isPredictingRank)
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00FFFF),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Calculating rank...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  )
                else if (_predictedRank != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFD700),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Predicted Global Rank',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#$_predictedRank',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  // Fallback when prediction fails - still show encouragement
                  const Text(
                    'Submit your score to see your global rank!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              // View Leaderboard button
              if (isLeaderboardEnabled && !_leaderboardSubmitted) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    AudioManager().playButtonClick();
                    Navigator.of(context).pushNamed('/leaderboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9370DB).withOpacity(0.2),
                    foregroundColor: const Color(0xFF9370DB),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFF9370DB),
                        width: 2,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.leaderboard, size: 20),
                  label: const Text(
                    'VIEW LEADERBOARD',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Leaderboard section
              if (isLeaderboardEnabled) ...[
                if (!_leaderboardSubmitted) ...[
                  // Name input
                  const Text(
                    'Submit to Global Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      maxLength: 20,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF333333),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00FFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 2),
                        ),
                        counterStyle: const TextStyle(color: Colors.grey),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_leaderboardError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _leaderboardError!,
                      style: const TextStyle(
                        color: Color(0xFFFF6666),
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isSubmittingToLeaderboard ? null : _submitToLeaderboard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF00),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmittingToLeaderboard
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'SUBMIT SCORE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ] else ...[
                  // Success message
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00FF00),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Score Submitted!',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_leaderboardRank != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Global Rank: #$_leaderboardRank',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 30),
              ],

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      AudioManager().playButtonClick();
                      widget.onRestart();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFFF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'RESTART',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      AudioManager().playButtonClick();
                      widget.onMainMenu();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8800),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'MAIN MENU',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF444444)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00FFFF),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
