import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_log.dart';

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => AnalyticsService(),
);

class AnalyticsService {
  AnalyticsService();

  Future<void> logAppOpenDay2() {
    return _safeLog(name: 'app_open_day_2');
  }

  Future<void> logTaskStarted() {
    return _safeLog(name: 'task_started');
  }

  Future<void> logTaskCompleted() {
    return _safeLog(name: 'task_completed');
  }

  Future<void> logTaskDeferred() {
    return _safeLog(name: 'task_deferred');
  }

  Future<void> logCannotDo() {
    return _safeLog(name: 'cannot_do');
  }

  Future<void> logTaskCannotDo() {
    return _safeLog(name: 'task_cannot_do');
  }

  Future<void> logShareOpened() {
    return _safeLog(name: 'share_opened');
  }

  Future<void> logShareClicked() {
    return _safeLog(name: 'share_clicked');
  }

  Future<void> logStreakDay3() {
    return _safeLog(name: 'streak_day_3');
  }

  Future<void> logStreakDay7() {
    return _safeLog(name: 'streak_day_7');
  }

  Future<void> logFreezeUsed({required bool isPremium}) {
    return _safeLog(
      name: 'freeze_used',
      parameters: {'is_premium': isPremium},
    );
  }

  Future<void> logPurchaseStarted({required String productId}) {
    return _safeLog(
      name: 'purchase_started',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseCompleted({required String productId}) {
    return _safeLog(
      name: 'purchase_completed',
      parameters: {'product_id': productId},
    );
  }

  Future<void> _safeLog({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      AppLog.action('analytics.$name', details: parameters ?? const {});
    }
  }
}
