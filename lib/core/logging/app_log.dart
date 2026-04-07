import 'package:flutter/foundation.dart';

class AppLog {
  static const bool _verboseEnabled = kDebugMode
      ? bool.fromEnvironment('ACTORA_VERBOSE_LOGS', defaultValue: true)
      : false;

  static bool get isVerboseEnabled => _verboseEnabled;

  static void tap(String action, {Map<String, Object?> details = const {}}) {
    _write('tap', action, details: details);
  }

  static void action(String action, {Map<String, Object?> details = const {}}) {
    _write('action', action, details: details);
  }

  static void blocked(String action, String reason,
      {Map<String, Object?> details = const {}}) {
    _write('blocked', action, reason: reason, details: details);
  }

  static void state(String action, {Map<String, Object?> details = const {}}) {
    _write('state', action, details: details);
  }

  static void verbose(String action,
      {Map<String, Object?> details = const {}}) {
    if (!isVerboseEnabled) return;
    _write('trace', action, details: details);
  }

  static void flow(
    String action,
    String phase, {
    Map<String, Object?> details = const {},
  }) {
    if (!isVerboseEnabled) return;
    _write('flow', action, reason: phase, details: details);
  }

  static void error(String action, Object error, StackTrace stackTrace,
      {Map<String, Object?> details = const {}}) {
    if (!kDebugMode) return;
    debugPrint(
      '[APP][error][$action] $error | details=$details\n$stackTrace',
    );
  }

  static void _write(
    String kind,
    String action, {
    String? reason,
    Map<String, Object?> details = const {},
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer('[APP][$kind][$action]');
    if (reason != null) {
      buffer.write(' reason=$reason');
    }
    if (details.isNotEmpty) {
      buffer.write(' details=$details');
    }
    debugPrint(buffer.toString());
  }
}
