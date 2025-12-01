import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/env_config.dart';

/// Get the current platform as a string for leaderboard tracking
String _getPlatformString() {
  if (kIsWeb) {
    // On web, detect the specific platform
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios-web';
      case TargetPlatform.android:
        return 'android-web';
      case TargetPlatform.macOS:
        return 'macos-web';
      case TargetPlatform.windows:
        return 'windows-web';
      case TargetPlatform.linux:
        return 'linux-web';
      default:
        return 'web';
    }
  }
  // Native apps
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.linux:
      return 'linux';
    default:
      return 'unknown';
  }
}

/// Represents a leaderboard entry
class LeaderboardEntry {
  final int? id;
  final String playerName;
  final int score;
  final int wave;
  final int kills;
  final double timeAlive;
  final List<String> upgrades;
  final String? weaponUsed;
  final String? platform;
  final DateTime? createdAt;
  final int? rank;

  LeaderboardEntry({
    this.id,
    required this.playerName,
    required this.score,
    required this.wave,
    required this.kills,
    required this.timeAlive,
    required this.upgrades,
    this.weaponUsed,
    this.platform,
    this.createdAt,
    this.rank,
  });

  Map<String, dynamic> toJson() => {
        'playerName': playerName,
        'score': score,
        'wave': wave,
        'kills': kills,
        'timeAlive': timeAlive,
        'upgrades': upgrades,
        'weaponUsed': weaponUsed,
        'platform': platform ?? _getPlatformString(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as int?,
      playerName: (json['playerName'] ?? json['player_name']) as String,
      score: json['score'] as int,
      wave: json['wave'] as int,
      kills: json['kills'] as int,
      timeAlive: (json['timeAlive'] ?? json['time_alive'] as num).toDouble(),
      upgrades: ((json['upgrades'] ?? []) as List<dynamic>).map((e) => e.toString()).toList(),
      weaponUsed: (json['weaponUsed'] ?? json['weapon_used']) as String?,
      platform: (json['platform'] ?? json['platform']) as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null),
      rank: json['rank'] as int?,
    );
  }

  String get formattedTime {
    final minutes = (timeAlive / 60).floor();
    final seconds = (timeAlive % 60).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Result of submitting a score
class SubmitResult {
  final bool success;
  final LeaderboardEntry? entry;
  final String? error;

  SubmitResult({
    required this.success,
    this.entry,
    this.error,
  });
}

/// Result of fetching leaderboard
class LeaderboardResult {
  final bool success;
  final List<LeaderboardEntry> entries;
  final String? error;

  LeaderboardResult({
    required this.success,
    required this.entries,
    this.error,
  });
}

/// Service for interacting with the global leaderboard API
class LeaderboardService {
  static const String _lastPlayerNameKey = 'last_player_name';
  static const Duration _timeout = Duration(seconds: 10);

  /// Normalize base URL by removing trailing slash
  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// Get the saved player name from previous sessions
  static Future<String?> getSavedPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastPlayerNameKey);
  }

  /// Save the player name for future sessions
  static Future<void> savePlayerName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayerNameKey, name);
  }

  /// Fetch top scores from the leaderboard
  static Future<LeaderboardResult> getTopScores({int limit = 50, int offset = 0}) async {
    final baseUrl = EnvConfig.leaderboardApiUrl;
    if (baseUrl == null) {
      return LeaderboardResult(
        success: false,
        entries: [],
        error: 'Leaderboard not configured',
      );
    }

    try {
      final normalizedUrl = _normalizeUrl(baseUrl);
      final uri = Uri.parse('$normalizedUrl/scores?limit=$limit&offset=$offset');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['entries'] as List<dynamic>;
          final entries = data.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
          return LeaderboardResult(success: true, entries: entries);
        }
      }

      return LeaderboardResult(
        success: false,
        entries: [],
        error: 'Failed to fetch leaderboard',
      );
    } catch (e) {
      print('[LeaderboardService] Error fetching scores: $e');
      return LeaderboardResult(
        success: false,
        entries: [],
        error: 'Network error: $e',
      );
    }
  }

  /// Submit a score to the leaderboard
  static Future<SubmitResult> submitScore(LeaderboardEntry entry) async {
    final baseUrl = EnvConfig.leaderboardApiUrl;
    if (baseUrl == null) {
      return SubmitResult(
        success: false,
        error: 'Leaderboard not configured',
      );
    }

    try {
      final normalizedUrl = _normalizeUrl(baseUrl);
      final uri = Uri.parse('$normalizedUrl/scores');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(entry.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          final data = json['entry'] as Map<String, dynamic>;
          final submittedEntry = LeaderboardEntry.fromJson(data);

          // Save player name for next time
          await savePlayerName(entry.playerName);

          return SubmitResult(success: true, entry: submittedEntry);
        }
      }

      // Parse error message from response
      String errorMsg = 'Failed to submit score';
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = json['error'] as String? ?? errorMsg;
      } catch (_) {}

      return SubmitResult(success: false, error: errorMsg);
    } catch (e) {
      print('[LeaderboardService] Error submitting score: $e');
      return SubmitResult(
        success: false,
        error: 'Network error: $e',
      );
    }
  }

  /// Check if leaderboard API is available
  static Future<bool> checkHealth() async {
    final baseUrl = EnvConfig.leaderboardApiUrl;
    if (baseUrl == null) return false;

    try {
      final normalizedUrl = _normalizeUrl(baseUrl);
      final uri = Uri.parse('$normalizedUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('[LeaderboardService] Health check failed: $e');
      return false;
    }
  }

  /// Get predicted rank for a score
  static Future<int?> getPredictedRank(int score) async {
    final baseUrl = EnvConfig.leaderboardApiUrl;
    if (baseUrl == null) return null;

    try {
      final normalizedUrl = _normalizeUrl(baseUrl);
      final uri = Uri.parse('$normalizedUrl/rank/predict?score=$score');
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        if (json['success'] == true) {
          return json['predictedRank'] as int;
        }
      }

      return null;
    } catch (e) {
      print('[LeaderboardService] Error getting predicted rank: $e');
      return null;
    }
  }
}
