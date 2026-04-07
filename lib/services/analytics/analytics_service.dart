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

  Future<void> logShareScreenShown() {
    return _safeLog(name: 'share_screen_shown');
  }

  Future<void> logShareClicked() {
    return _safeLog(name: 'share_clicked');
  }

  Future<void> logShareClosedWithoutShare() {
    return _safeLog(name: 'share_closed_without_share');
  }

  Future<void> logShareCopied() {
    return _safeLog(name: 'share_copied');
  }

  Future<void> logChallengeSent({
    required int streak,
    required String fromUserId,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'challenge_sent',
      parameters: {
        'streak': streak,
        'from_user_id': fromUserId,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logChallengeOpened({
    required int streak,
    required String fromUserId,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'challenge_opened',
      parameters: {
        'streak': streak,
        'from_user_id': fromUserId,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logChallengeAccepted({
    required int streak,
    required String fromUserId,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'challenge_accepted',
      parameters: {
        'streak': streak,
        'from_user_id': fromUserId,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logShareToInstallConversion({
    required String fromUserId,
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'share_to_install_conversion',
      parameters: {
        'from_user_id': fromUserId,
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logViralCoefficient({
    required double value,
    required int invites,
    required int accepted,
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'viral_coefficient',
      parameters: {
        'value_x100': (value * 100).round(),
        'invites': invites,
        'accepted': accepted,
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logLeaderboardViewed({
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'leaderboard_viewed',
      parameters: {
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logFriendLinkCreated({
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'friend_link_created',
      parameters: {
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logFriendJoined({
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'friend_joined',
      parameters: {
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logFriendStreakActive({
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'friend_streak_active',
      parameters: {
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logDailyCounterSeen({
    required int streak,
    required int dayIndex,
    String variant = 'A',
  }) {
    return _safeLog(
      name: 'daily_counter_seen',
      parameters: {
        'streak': streak,
        'day_index': dayIndex,
        'variant': variant,
      },
    );
  }

  Future<void> logDoneExperienceShown() {
    return _safeLog(name: 'done_experience_shown');
  }

  Future<void> logReturnedNextDay() {
    return _safeLog(name: 'returned_next_day');
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
