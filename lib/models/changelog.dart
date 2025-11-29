import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Changelog entry model
class ChangelogEntry {
  final String version;
  final String title;
  final String date;
  final List<ChangelogSection> sections;

  const ChangelogEntry({
    required this.version,
    required this.title,
    required this.date,
    required this.sections,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['version'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      sections: (json['sections'] as List)
          .map((s) => ChangelogSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'title': title,
      'date': date,
      'sections': sections.map((s) => s.toJson()).toList(),
    };
  }
}

/// Section of changes (e.g., New Features, Bug Fixes, Balance Changes)
class ChangelogSection {
  final String title;
  final String? emoji;
  final List<String> items;

  const ChangelogSection({
    required this.title,
    this.emoji,
    required this.items,
  });

  factory ChangelogSection.fromJson(Map<String, dynamic> json) {
    return ChangelogSection(
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      items: (json['items'] as List).map((i) => i as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'emoji': emoji,
      'items': items,
    };
  }
}

/// Changelog repository - loads changelogs from assets/changelog.json
class ChangelogRepository {
  static List<ChangelogEntry>? _cachedChangelogs;

  /// Load all changelogs from assets/changelog.json
  static Future<List<ChangelogEntry>> loadChangelogs() async {
    if (_cachedChangelogs != null) {
      return _cachedChangelogs!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/changelog.json');
      final List<dynamic> jsonList = json.decode(jsonString);

      _cachedChangelogs = jsonList
          .map((json) => ChangelogEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      return _cachedChangelogs!;
    } catch (e) {
      print('[ChangelogRepository] Error loading changelogs: $e');
      return [];
    }
  }

  /// Get changelog for a specific version
  static Future<ChangelogEntry?> getChangelog(String version) async {
    final changelogs = await loadChangelogs();
    try {
      return changelogs.firstWhere((entry) => entry.version == version);
    } catch (e) {
      return null;
    }
  }

  /// Get all changelogs newer than a specific version
  static Future<List<ChangelogEntry>> getChangelogsSince(
      String lastSeenVersion) async {
    final changelogs = await loadChangelogs();

    final lastSeenIndex = changelogs.indexWhere(
      (entry) => entry.version == lastSeenVersion,
    );

    if (lastSeenIndex == -1) {
      // User hasn't seen any version, show the latest only
      return changelogs.isNotEmpty ? [changelogs.first] : [];
    }

    // Return all versions after the last seen one (newer versions are first in list)
    return changelogs.sublist(0, lastSeenIndex);
  }

  /// Get the latest changelog
  static Future<ChangelogEntry?> getLatestChangelog() async {
    final changelogs = await loadChangelogs();
    return changelogs.isNotEmpty ? changelogs.first : null;
  }

  /// Compare version strings (simple major.minor.patch comparison)
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;

      if (p1 != p2) {
        return p1.compareTo(p2);
      }
    }

    return 0;
  }
}
