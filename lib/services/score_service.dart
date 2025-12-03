import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameScore {
  final int score;
  final int wave;
  final int kills;
  final double timeAlive;
  final DateTime timestamp;
  final Map<String, int> upgrades; // upgradeId -> count
  final String? weaponUsed;

  GameScore({
    required this.score,
    required this.wave,
    required this.kills,
    required this.timeAlive,
    required this.timestamp,
    this.upgrades = const {},
    this.weaponUsed,
  });

  String get formattedTime {
    final minutes = (timeAlive / 60).floor();
    final seconds = (timeAlive % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'wave': wave,
        'kills': kills,
        'timeAlive': timeAlive,
        'timestamp': timestamp.toIso8601String(),
        'upgrades': upgrades, // Map<String, int>
        'weaponUsed': weaponUsed,
      };

  factory GameScore.fromJson(Map<String, dynamic> json) {
    // Handle backward compatibility: old format was List<String>, new is Map<String, int>
    Map<String, int> upgradesMap = {};
    final upgradesData = json['upgrades'];

    if (upgradesData is List) {
      // Old format: convert List<String> to Map with count=1 for each
      for (final id in upgradesData) {
        upgradesMap[id.toString()] = (upgradesMap[id.toString()] ?? 0) + 1;
      }
    } else if (upgradesData is Map) {
      // New format: already a map, convert values to int
      upgradesMap = (upgradesData as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, value as int),
      );
    }

    return GameScore(
      score: json['score'] as int,
      wave: json['wave'] as int,
      kills: json['kills'] as int,
      timeAlive: (json['timeAlive'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      upgrades: upgradesMap,
      weaponUsed: json['weaponUsed'] as String?,
    );
  }
}

class ScoreService {
  static const String _scoresKey = 'game_scores';
  static const int _maxScores = 50;

  List<GameScore> _scores = [];

  Future<void> loadScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getString(_scoresKey);

    if (scoresJson != null) {
      final List<dynamic> decoded = jsonDecode(scoresJson);
      _scores = decoded.map((json) => GameScore.fromJson(json)).toList();
      _scores.sort((a, b) => b.score.compareTo(a.score));
    }
  }

  Future<void> saveScore(GameScore score) async {
    _scores.add(score);
    _scores.sort((a, b) => b.score.compareTo(a.score));

    // Keep only top scores
    if (_scores.length > _maxScores) {
      _scores = _scores.take(_maxScores).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    final scoresJson = jsonEncode(_scores.map((s) => s.toJson()).toList());
    await prefs.setString(_scoresKey, scoresJson);
  }

  List<GameScore> getRecentScores(int count) {
    final sorted = List<GameScore>.from(_scores);
    sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(count).toList();
  }

  GameScore? getBestScore() {
    if (_scores.isEmpty) return null;
    return _scores.first; // Already sorted by score
  }

  List<GameScore> getTopScores(int count) {
    return _scores.take(count).toList();
  }
}
