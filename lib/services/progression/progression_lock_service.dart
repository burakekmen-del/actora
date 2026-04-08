import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logging/app_log.dart';
import 'friend_competition_service.dart';

/// 🔒 PROGRESSION LOCK SERVICE
///
/// Core logic for enforcing the "soft lock" system:
/// - User cannot advance Day N without at least 1 accepted invite
/// - Tracks progression status
/// - Handles unlock triggers
/// - Manages loss aversion state

class ProgressionLockService {
  final String userId;
  final FriendCompetitionService competitionService;

  ProgressionLockService({
    required this.userId,
    required this.competitionService,
  });

  /// ========================================
  /// CHECK: Can user progress to next day?
  /// ========================================
  /// Returns:
  /// - true: User can proceed (has 1+ accept)
  /// - false: User is LOCKED (no accepts)
  Future<bool> canProgressToNextDay(int targetDay) async {
    try {
      // Get all active competitions (invites that were ACCEPTED)
      final competitions = await competitionService.getActiveCompetitions();

      // Need at least 1 competition to progress
      final isUnlocked = competitions.isNotEmpty;

      AppLog.info(
        'Progression check for Day $targetDay: ${isUnlocked ? 'UNLOCKED' : 'LOCKED'}',
        category: 'progression_lock',
        extraData: {
          'competitions_count': competitions.length,
          'target_day': targetDay,
        },
      );

      return isUnlocked;
    } catch (e) {
      AppLog.error(
        'Error checking progression unlock',
        error: e,
        category: 'progression_lock',
      );
      // Fail-safe: allow progression on service error
      return true;
    }
  }

  /// ========================================
  /// TRIGGER: Loss aversion check
  /// ========================================
  /// Returns true if we should show loss aversion screen
  /// (User is behind on streak compared to their best competitor)
  Future<bool> shouldShowLossAversion({
    required int currentDay,
    required int currentStreak,
  }) async {
    try {
      // Get top competitor
      final topCompetitor = await competitionService.getTopCompetitor();

      if (topCompetitor == null) {
        // No competitors yet
        return false;
      }

      // Calculate if user is significantly behind
      final daysBehind = topCompetitor.friendDay - currentDay;
      final streakBehind = topCompetitor.friendStreak - currentStreak;

      // Show loss aversion if:
      // 1. Friend is 2+ days ahead, AND
      // 2. Current user streak is at least 3 days (sunk cost)
      final shouldShow = daysBehind >= 2 && currentStreak >= 3;

      if (shouldShow) {
        AppLog.info(
          'Loss aversion triggered: User behind by $daysBehind days',
          category: 'loss_aversion',
          extraData: {
            'days_behind': daysBehind,
            'streak_behind': streakBehind,
            'competitor': topCompetitor.friendName,
          },
        );
      }

      return shouldShow;
    } catch (e) {
      AppLog.error(
        'Error checking loss aversion',
        error: e,
        category: 'loss_aversion',
      );
      return false;
    }
  }

  /// ========================================
  /// GET: Current progression status
  /// ========================================
  Future<ProgressionStatus> getProgressionStatus({
    required int currentDay,
    required int currentStreak,
  }) async {
    try {
      final canProgress = await canProgressToNextDay(currentDay + 1);
      final shouldShowLossAversion = await shouldShowLossAversion(
        currentDay: currentDay,
        currentStreak: currentStreak,
      );
      final topCompetitor = await competitionService.getTopCompetitor();
      final allCompetitions = await competitionService.getActiveCompetitions();

      return ProgressionStatus(
        canProgressToNextDay: canProgress,
        shouldShowLossAversion: shouldShowLossAversion,
        topCompetitor: topCompetitor,
        totalCompetitors: allCompetitions.length,
        competitionList: allCompetitions,
      );
    } catch (e) {
      AppLog.error(
        'Error getting progression status',
        error: e,
        category: 'progression_lock',
      );
      // Fail-safe: return permissive status
      return ProgressionStatus(
        canProgressToNextDay: true,
        shouldShowLossAversion: false,
        topCompetitor: null,
        totalCompetitors: 0,
        competitionList: [],
      );
    }
  }

  /// ========================================
  /// ACTION: Record progression unlock
  /// ========================================
  /// Called when user successfully invites someone and moves to next day
  Future<void> recordProgressionUnlock({
    required int dayNumber,
    required String competitionId,
  }) async {
    try {
      AppLog.info(
        'Recorded progression unlock at Day $dayNumber',
        category: 'progression_lock',
        extraData: {
          'day': dayNumber,
          'competition_id': competitionId,
        },
      );

      // Could track this for analytics/retention
      // Example: analytics.logEvent('progression_unlocked', {'day': dayNumber})
    } catch (e) {
      AppLog.error(
        'Error recording progression unlock',
        error: e,
        category: 'progression_lock',
      );
    }
  }

  /// ========================================
  /// ACTION: Record progression skip/quit
  /// ========================================
  Future<void> recordProgressionQuit({
    required int dayNumber,
    required int streak,
  }) async {
    try {
      AppLog.warning(
        'User quit at Day $dayNumber (streak: $streak)',
        category: 'progression_lock',
        extraData: {
          'day': dayNumber,
          'streak': streak,
        },
      );

      // Track for cohort analysis
      // Example: Identify users at risk of churn
    } catch (e) {
      AppLog.error(
        'Error recording progression quit',
        error: e,
        category: 'progression_lock',
      );
    }
  }

  /// ========================================
  /// STREAK SYNC: When user completes day, update ALL competitions
  /// ========================================
  /// This is called after user completes task
  /// It notifies all friends that user advanced
  Future<void> syncStreakWithAllCompetitors({
    required int newStreak,
    required int dayNumber,
  }) async {
    try {
      final competitions = await competitionService.getActiveCompetitions();

      AppLog.info(
        'Syncing streak with ${competitions.length} competitors',
        category: 'progression_lock',
        extraData: {
          'new_streak': newStreak,
          'day_number': dayNumber,
        },
      );

      // Update each competition with new streak
      for (final competition in competitions) {
        try {
          await competitionService.updateCompetitionStreak(
            competitionId: competition.competitionId,
            newStreak: newStreak,
          );

          // Generate notification for friend seeing user advance
          await competitionService.generateCompetitiveNotification(
            competitionId: competition.competitionId,
            type: 'user_progressed',
            friendName: competition.friendName,
            currentStreak: newStreak,
          );
        } catch (e) {
          AppLog.error(
            'Error syncing with competitor ${competition.friendName}',
            error: e,
            category: 'progression_lock',
          );
          // Don't fail the whole operation, continue with others
        }
      }
    } catch (e) {
      AppLog.error(
        'Error syncing streak with all competitors',
        error: e,
        category: 'progression_lock',
      );
    }
  }
}

/// 📊 DATA CLASS: Progression status snapshot
class ProgressionStatus {
  final bool canProgressToNextDay;
  final bool shouldShowLossAversion;
  final Map<String, dynamic>? topCompetitor;
  final int totalCompetitors;
  final List<Map<String, dynamic>> competitionList;

  ProgressionStatus({
    required this.canProgressToNextDay,
    required this.shouldShowLossAversion,
    required this.topCompetitor,
    required this.totalCompetitors,
    required this.competitionList,
  });

  /// Friendly status message
  String get statusMessage {
    if (!canProgressToNextDay) {
      return 'Invite 1 friend to unlock next day';
    }
    if (shouldShowLossAversion && topCompetitor != null) {
      final friendName = topCompetitor!['friendName'] ?? 'Friend';
      return '$friendName is ahead - catch up today!';
    }
    return 'Ready to progress';
  }

  /// For debugging
  @override
  String toString() => 'ProgressionStatus(canProgress: $canProgressToNextDay, '
      'lossAversion: $shouldShowLossAversion, competitors: $totalCompetitors)';
}

/// 🔌 RIVERPOD PROVIDER
///
/// Usage:
/// ```
/// final progressionLockProvider = FutureProvider((ref) async {
///   final competitionService = ref.watch(friendCompetitionProvider);
///   await competitionService.initializeUserId('user123');
///   return ProgressionLockService(
///     userId: 'user123',
///     competitionService: competitionService,
///   );
/// });
/// ```
