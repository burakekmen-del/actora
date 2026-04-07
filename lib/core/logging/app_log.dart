import 'package:flutter/foundation.dart';

class AppLog {
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
