import 'package:flutter/foundation.dart';

/// Centralized logging utility for the game
/// Automatically disables logs in release builds for better performance
class GameLogger {
  /// Log a general message
  /// Only prints in debug mode
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      print('$prefix$message');
    }
  }

  /// Log a debug message with DEBUG tag
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[DEBUG] ';
      print('$prefix$message');
    }
  }

  /// Log an info message with INFO tag
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[INFO] ';
      print('$prefix$message');
    }
  }

  /// Log a warning message with WARNING tag
  /// Prints in both debug and release mode as warnings are important
  static void warning(String message, {String? tag}) {
    final prefix = tag != null ? '[$tag] ' : '[WARNING] ';
    if (kDebugMode) {
      print('$prefix$message');
    }
  }

  /// Log an error message with ERROR tag
  /// Always prints in both debug and release mode
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final prefix = tag != null ? '[$tag] ' : '[ERROR] ';
    print('$prefix$message');
    if (error != null) {
      print('Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      print('Stack trace:\n$stackTrace');
    }
  }

  /// Log game events (wave complete, level up, etc.)
  static void event(String event, {String? tag, Map<String, dynamic>? data}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[EVENT] ';
      final dataStr = data != null ? ' - ${data.toString()}' : '';
      print('$prefix$event$dataStr');
    }
  }

  /// Log performance metrics
  static void performance(String metric, {String? tag, dynamic value}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '[PERF] ';
      final valueStr = value != null ? ': $value' : '';
      print('$prefix$metric$valueStr');
    }
  }
}
