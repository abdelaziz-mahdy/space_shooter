import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for the app
/// Loads variables from .env file (local) or environment (CI/CD)
class EnvConfig {
  static bool _initialized = false;

  /// Initialize environment configuration
  /// Should be called in main() before runApp()
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      print('[EnvConfig] Loaded .env file');
    } catch (e) {
      // .env file might not exist in CI/CD builds
      // Variables will come from system environment
      print('[EnvConfig] No .env file found, using system environment');
    }

    _initialized = true;
  }

  /// Get the leaderboard API URL
  /// Returns null if not configured (offline mode)
  static String? get leaderboardApiUrl {
    final url = dotenv.env['LEADERBOARD_API_URL'];
    if (url == null || url.isEmpty) {
      print('[EnvConfig] LEADERBOARD_API_URL not configured');
      return null;
    }
    return url;
  }

  /// Check if leaderboard is configured
  static bool get isLeaderboardEnabled => leaderboardApiUrl != null;
}
