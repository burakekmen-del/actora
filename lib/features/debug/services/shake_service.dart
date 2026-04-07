import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  ShakeService({required this.onShake});

  final VoidCallback onShake;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastHitAt;
  DateTime? _lastTriggerAt;
  int _hitCount = 0;
  bool _disabled = false;

  static const double _shakeThresholdG = 2.4;
  static const Duration _window = Duration(milliseconds: 800);
  static const Duration _cooldown = Duration(seconds: 2);

  void start() {
    if (!kDebugMode || _disabled || _subscription != null) return;
    try {
      _subscription = accelerometerEventStream().listen(
        _onEvent,
        onError: _onStreamError,
        cancelOnError: true,
      );
    } on MissingPluginException {
      _disable('missing_plugin_on_start');
    } catch (_) {
      _disable('stream_start_failed');
    }
  }

  void stop() {
    final subscription = _subscription;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
    _subscription = null;
    _hitCount = 0;
    _lastHitAt = null;
  }

  void _onStreamError(Object error, [StackTrace? stackTrace]) {
    if (error is MissingPluginException ||
        error.toString().contains('MissingPluginException')) {
      _disable('missing_plugin_on_listen');
      return;
    }

    if (kDebugMode) {
      debugPrint(
          '[APP][blocked][debug.shake] reason=stream_error details={error: $error}');
    }
  }

  void _disable(String reason) {
    _disabled = true;
    stop();
    if (kDebugMode) {
      debugPrint('[APP][blocked][debug.shake] reason=$reason');
    }
  }

  void _onEvent(AccelerometerEvent event) {
    final gX = event.x / 9.80665;
    final gY = event.y / 9.80665;
    final gZ = event.z / 9.80665;
    final gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

    if (gForce < _shakeThresholdG) {
      return;
    }

    final now = DateTime.now();
    if (_lastHitAt == null || now.difference(_lastHitAt!) > _window) {
      _hitCount = 1;
      _lastHitAt = now;
      return;
    }

    _hitCount += 1;
    _lastHitAt = now;

    final inCooldown =
        _lastTriggerAt != null && now.difference(_lastTriggerAt!) < _cooldown;
    if (_hitCount >= 2 && !inCooldown) {
      _lastTriggerAt = now;
      _hitCount = 0;
      onShake();
    }
  }
}
