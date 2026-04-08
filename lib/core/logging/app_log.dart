import 'package:flutter/foundation.dart';

enum _LogLevel { error, warn, info, debug, trace }

class AppLog {
  static const String _levelFromEnv = String.fromEnvironment(
    'ACTORA_LOG_LEVEL',
    defaultValue: '',
  );

  static const bool _forceVerbose = bool.fromEnvironment(
    'ACTORA_VERBOSE_LOGS',
    defaultValue: false,
  );

  static final _LogLevel _currentLevel = _resolveLevel();
  static int _sequence = 0;

  static bool get isVerboseEnabled => _shouldLog(_LogLevel.trace);

  static void tap(String action, {Map<String, Object?> details = const {}}) {
    _write(_LogLevel.info, 'tap', action, details: details);
  }

  static void action(String action, {Map<String, Object?> details = const {}}) {
    _write(_LogLevel.info, 'action', action, details: details);
  }

  static void blocked(String action, String reason,
      {Map<String, Object?> details = const {}}) {
    _write(
      _LogLevel.warn,
      'blocked',
      action,
      reason: reason,
      details: details,
    );
  }

  static void state(String action, {Map<String, Object?> details = const {}}) {
    _write(_LogLevel.debug, 'state', action, details: details);
  }

  static void verbose(String action,
      {Map<String, Object?> details = const {}}) {
    _write(_LogLevel.trace, 'trace', action, details: details);
  }

  static void flow(
    String action,
    String phase, {
    Map<String, Object?> details = const {},
  }) {
    _write(_LogLevel.debug, 'flow', action, reason: phase, details: details);
  }

  static void error(String action, Object error, StackTrace stackTrace,
      {Map<String, Object?> details = const {}}) {
    if (!_shouldLog(_LogLevel.error)) return;

    final context = <String, Object?>{
      'error': error.toString(),
      ...details,
    };
    _write(_LogLevel.error, 'error', action, details: context);

    if (_shouldLog(_LogLevel.debug)) {
      debugPrint(stackTrace.toString());
    }
  }

  static void _write(
    _LogLevel level,
    String kind,
    String action, {
    String? reason,
    Map<String, Object?> details = const {},
  }) {
    if (!_shouldLog(level)) return;

    _sequence += 1;
    final timestamp = DateTime.now().toIso8601String();
    final levelLabel = level.name.toUpperCase();
    final buffer = StringBuffer(
      '[$timestamp][APP][$levelLabel][$kind][$action][#$_sequence]',
    );
    if (reason != null) {
      buffer.write(' reason=$reason');
    }
    if (details.isNotEmpty) {
      buffer.write(' details=$details');
    }
    debugPrint(buffer.toString());
  }

  static _LogLevel _resolveLevel() {
    if (_forceVerbose) {
      return _LogLevel.trace;
    }

    if (_levelFromEnv.isNotEmpty) {
      final parsed = _parseLevel(_levelFromEnv);
      if (parsed != null) return parsed;
    }

    return kDebugMode ? _LogLevel.debug : _LogLevel.error;
  }

  static _LogLevel? _parseLevel(String value) {
    switch (value.toLowerCase()) {
      case 'error':
        return _LogLevel.error;
      case 'warn':
      case 'warning':
        return _LogLevel.warn;
      case 'info':
        return _LogLevel.info;
      case 'debug':
        return _LogLevel.debug;
      case 'trace':
      case 'verbose':
        return _LogLevel.trace;
      default:
        return null;
    }
  }

  static bool _shouldLog(_LogLevel level) => level.index <= _currentLevel.index;
}
