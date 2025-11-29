import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

/// Service for managing app version and detecting updates
class VersionService {
  static const String _lastSeenVersionKey = 'last_seen_version';
  static const String _firstLaunchKey = 'first_launch';

  final SharedPreferences _prefs;
  late final String _currentVersion;

  VersionService(this._prefs);

  /// Initialize the version service and load current version from pubspec.yaml
  static Future<VersionService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = VersionService(prefs);
    await service._loadCurrentVersion();
    return service;
  }

  /// Load current version from pubspec.yaml
  Future<void> _loadCurrentVersion() async {
    try {
      final pubspecString = await rootBundle.loadString('pubspec.yaml');
      final pubspec = loadYaml(pubspecString);
      _currentVersion = pubspec['version'] as String? ?? '0.1.0';
    } catch (e) {
      print('[VersionService] Error loading version from pubspec.yaml: $e');
      _currentVersion = '0.1.0'; // Fallback version
    }
  }

  /// Get the current app version
  String getCurrentVersion() => _currentVersion;

  /// Get the last version the user saw
  String? getLastSeenVersion() {
    return _prefs.getString(_lastSeenVersionKey);
  }

  /// Mark the current version as seen by the user
  Future<void> markCurrentVersionAsSeen() async {
    await _prefs.setString(_lastSeenVersionKey, _currentVersion);
  }

  /// Check if this is the first launch ever
  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  /// Mark that the app has been launched before
  Future<void> markAsLaunched() async {
    await _prefs.setBool(_firstLaunchKey, false);
  }

  /// Check if the app has been updated since last launch
  bool hasNewVersion() {
    final lastSeen = getLastSeenVersion();

    // First launch - no update to show
    if (lastSeen == null) {
      return false;
    }

    // Compare versions
    return lastSeen != _currentVersion;
  }

  /// Get a user-friendly description of the update
  String getUpdateDescription() {
    final lastSeen = getLastSeenVersion();
    if (lastSeen == null) {
      return 'Welcome to Space Shooter!';
    }

    return 'Updated from v$lastSeen to v$_currentVersion';
  }
}
