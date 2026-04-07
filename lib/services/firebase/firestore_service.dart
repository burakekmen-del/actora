import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/domain/onboarding_models.dart';
import '../../features/task/domain/task.dart';

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final userEntitlementProvider = StreamProvider<UserEntitlement>((ref) async* {
  final service = ref.watch(firestoreServiceProvider);
  yield* service.watchUserEntitlement();
});

class FirestoreService {
  final StreamController<UserEntitlement> _entitlementController =
      StreamController<UserEntitlement>.broadcast();

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _selectedFocusKey = 'selected_focus';
  static const String _preferredDurationKey = 'preferred_duration';
  static const String _streakCountKey = 'streak_count';
  static const String _lastTaskCompletionLocalDateKey =
      'last_task_completion_local_date';
  static const String _lastTaskCompletedAtKey = 'last_task_completed_at';
  static const String _timezoneOffsetMinutesKey = 'timezone_offset_minutes';
  static const String _lastAppOpenLocalDateKey = 'last_app_open_local_date';
  static const String _lastAppOpenAtKey = 'last_app_open_at';
  static const String _fcmTokenKey = 'fcm_token';
  static const String _fcmTokenUpdatedAtKey = 'fcm_token_updated_at';
  static const String _freezeCountKey = 'freeze_count';
  static const String _consistencyModeActiveKey = 'consistency_mode_active';
  static const String _premiumExpiryDateKey = 'premium_expiry_date';
  static const String _premiumUpdatedAtKey = 'premium_updated_at';
  static const String _createdAtKey = 'created_at';
  static const String _currentTaskKey = 'current_task';
  static const String _lastTaskAssignedLocalDateKey =
      'last_task_assigned_local_date';
  static const String _weeklyCompletedCountKey = 'weekly_completed_count';
  static const String _weeklyAnchorLocalDateKey = 'weekly_anchor_local_date';
  static const String _localUserIdKey = 'local_user_id';
  static const String _pendingChallengeInviteKey = 'pending_challenge_invite';
  static const String _challengeInviteAcceptedCountKey =
      'challenge_invite_accepted_count';
  static const String _challengeInviteSentCountKey =
      'challenge_invite_sent_count';
  static const String _challengeRewardedFromSetKey = 'challenge_rewarded_from';
  static const String _todayCompletionCountKey = 'today_completion_count';
  static const String _todayCompletionCountDateKey =
      'today_completion_count_date';
  static const String _friendStreakKey = 'friend_streak';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveOnboardingAndFirstTask({
    required UserFocus focus,
    required PreferredDuration duration,
    required Task task,
  }) async {
    final prefs = await _prefs;
    final now = DateTime.now().toIso8601String();
    await prefs.setBool(_onboardingCompletedKey, true);
    await prefs.setString(_selectedFocusKey, focus.label);
    await prefs.setString(_preferredDurationKey, duration.label);
    await prefs.setInt(_streakCountKey, 0);
    await prefs.setInt(_weeklyCompletedCountKey, 0);
    await prefs.setString(_weeklyAnchorLocalDateKey, _dateKey(DateTime.now()));
    await prefs.setString(_createdAtKey, prefs.getString(_createdAtKey) ?? now);
    await _saveTaskToPrefs(task);
  }

  Stream<UserEntitlement> watchUserEntitlement() async* {
    yield await getUserEntitlement();
    yield* _entitlementController.stream;
  }

  Future<UserEntitlement> getUserEntitlement() async {
    final prefs = await _prefs;
    return UserEntitlement(
      consistencyModeActive: prefs.getBool(_consistencyModeActiveKey) ?? false,
      premiumExpiryDate: _parseDateTime(prefs.getString(_premiumExpiryDateKey)),
      freezeCount: prefs.getInt(_freezeCountKey) ?? 1,
      createdAt: _parseDateTime(prefs.getString(_createdAtKey)),
    );
  }

  Future<int> getStreakCount() async {
    final prefs = await _prefs;
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  Future<DailyStreakCompletionResult> completeDailyTaskAndUpdateStreak() async {
    final prefs = await _prefs;
    final now = DateTime.now();
    final today = _dateKey(now);
    final currentStreak = prefs.getInt(_streakCountKey) ?? 0;
    final lastCompletion = prefs.getString(_lastTaskCompletionLocalDateKey);

    if (lastCompletion == today) {
      await prefs.setString(_lastTaskCompletedAtKey, now.toIso8601String());
      await prefs.setInt(
        _timezoneOffsetMinutesKey,
        now.timeZoneOffset.inMinutes,
      );
      await _refreshWeeklyProgress(prefs, now, increment: false);
      return DailyStreakCompletionResult(
        updatedStreakCount: currentStreak,
        incremented: false,
      );
    }

    final nextStreak = currentStreak + 1;
    await prefs.setInt(_streakCountKey, nextStreak);
    await prefs.setString(_lastTaskCompletionLocalDateKey, today);
    await prefs.setString(_lastTaskCompletedAtKey, now.toIso8601String());
    await prefs.setInt(_timezoneOffsetMinutesKey, now.timeZoneOffset.inMinutes);
    await _refreshWeeklyProgress(prefs, now, increment: true);

    return DailyStreakCompletionResult(
      updatedStreakCount: nextStreak,
      incremented: true,
    );
  }

  Future<MissedTaskResolutionResult> resolveMissedTask() async {
    final prefs = await _prefs;
    final entitlement = await getUserEntitlement();
    final currentStreak = prefs.getInt(_streakCountKey) ?? 0;

    if (entitlement.isPremium) {
      await prefs.setBool(_consistencyModeActiveKey, true);
      await prefs.setString(
        _premiumUpdatedAtKey,
        DateTime.now().toIso8601String(),
      );
      _emitEntitlement(entitlement);
      return MissedTaskResolutionResult(
        freezeUsed: true,
        isPremium: true,
        streakReset: false,
        updatedStreakCount: currentStreak,
      );
    }

    final freezeCount = prefs.getInt(_freezeCountKey) ?? 1;
    if (freezeCount > 0) {
      await prefs.setInt(_freezeCountKey, freezeCount - 1);
      await prefs.setString(
        _premiumUpdatedAtKey,
        DateTime.now().toIso8601String(),
      );
      _emitEntitlement(await getUserEntitlement());
      return MissedTaskResolutionResult(
        freezeUsed: true,
        isPremium: false,
        streakReset: false,
        updatedStreakCount: currentStreak,
      );
    }

    await prefs.setInt(_streakCountKey, 0);
    await prefs.remove(_lastTaskCompletionLocalDateKey);
    return const MissedTaskResolutionResult(
      freezeUsed: false,
      isPremium: false,
      streakReset: true,
      updatedStreakCount: 0,
    );
  }

  Future<AppOpenTrackingResult> trackAppOpenAndReturnIsDay2() async {
    final prefs = await _prefs;
    final nowLocal = DateTime.now();
    final todayKey = _dateKey(nowLocal);
    final yesterdayKey = _dateKey(nowLocal.subtract(const Duration(days: 1)));
    final previousOpenKey = prefs.getString(_lastAppOpenLocalDateKey);

    final isDay2Return = previousOpenKey == yesterdayKey;

    await prefs.setString(_lastAppOpenLocalDateKey, todayKey);
    await prefs.setString(_lastAppOpenAtKey, nowLocal.toIso8601String());
    await prefs.setInt(
      _timezoneOffsetMinutesKey,
      nowLocal.timeZoneOffset.inMinutes,
    );

    return AppOpenTrackingResult(isDay2Return: isDay2Return);
  }

  Future<void> saveFcmToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_fcmTokenKey, token);
    await prefs.setString(
      _fcmTokenUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> saveTask({required String userId, required Task task}) {
    return _saveTaskToPrefs(task);
  }

  Future<bool> hasCompletedTaskToday() async {
    final prefs = await _prefs;
    final today = _dateKey(DateTime.now());
    return prefs.getString(_lastTaskCompletionLocalDateKey) == today;
  }

  Future<bool> hasAssignedTaskToday() async {
    final prefs = await _prefs;
    final today = _dateKey(DateTime.now());
    return prefs.getString(_lastTaskAssignedLocalDateKey) == today;
  }

  Future<void> markTaskAssignedToday() async {
    final prefs = await _prefs;
    await prefs.setString(
        _lastTaskAssignedLocalDateKey, _dateKey(DateTime.now()));
  }

  Future<void> clearSavedTask() async {
    final prefs = await _prefs;
    await prefs.remove(_currentTaskKey);
  }

  Future<String> getOrCreateLocalUserId() async {
    final prefs = await _prefs;
    final existing = prefs.getString(_localUserIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final created = 'u_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(_localUserIdKey, created);
    return created;
  }

  Future<void> captureChallengeDeepLink(Uri uri) async {
    final supportedScheme = uri.scheme == 'app' || uri.scheme == 'actora';
    final isChallenge = supportedScheme &&
        uri.host == 'actora' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.first == 'challenge';
    if (!isChallenge) {
      return;
    }

    final fromUserId = uri.queryParameters['from'];
    final streak = int.tryParse(uri.queryParameters['streak'] ?? '') ?? 0;
    if (fromUserId == null || fromUserId.isEmpty) {
      return;
    }

    final invite = ChallengeInvite(
      fromUserId: fromUserId,
      streak: streak,
      receivedAt: DateTime.now(),
    );
    final prefs = await _prefs;
    await prefs.setString(
        _pendingChallengeInviteKey, jsonEncode(invite.toMap()));
  }

  Future<ChallengeInvite?> loadPendingChallengeInvite() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_pendingChallengeInviteKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ChallengeInvite.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPendingChallengeInvite() async {
    final prefs = await _prefs;
    await prefs.remove(_pendingChallengeInviteKey);
  }

  Future<void> markChallengeInviteSent() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_challengeInviteSentCountKey) ?? 0;
    await prefs.setInt(_challengeInviteSentCountKey, current + 1);
  }

  Future<void> markChallengeInviteAccepted() async {
    final prefs = await _prefs;
    final current = prefs.getInt(_challengeInviteAcceptedCountKey) ?? 0;
    await prefs.setInt(_challengeInviteAcceptedCountKey, current + 1);
  }

  Future<int> getTodayCompletionCount() async {
    final prefs = await _prefs;
    final today = _dateKey(DateTime.now());
    final storedDate = prefs.getString(_todayCompletionCountDateKey);

    if (storedDate != today) {
      final base = _simulatedDailyBase(today);
      await prefs.setString(_todayCompletionCountDateKey, today);
      await prefs.setInt(_todayCompletionCountKey, base);
      return base;
    }

    final current = prefs.getInt(_todayCompletionCountKey);
    if (current != null) {
      return current;
    }

    final base = _simulatedDailyBase(today);
    await prefs.setInt(_todayCompletionCountKey, base);
    return base;
  }

  Future<int> incrementTodayCompletionCount() async {
    final prefs = await _prefs;
    final current = await getTodayCompletionCount();
    final next = current + 1;
    await prefs.setInt(_todayCompletionCountKey, next);
    await prefs.setString(
        _todayCompletionCountDateKey, _dateKey(DateTime.now()));
    return next;
  }

  Future<void> bindFriendStreak({required String friendId}) async {
    if (friendId.isEmpty) {
      return;
    }
    final prefs = await _prefs;
    final friend = FriendStreakState(
      friendId: friendId,
      friendName: _friendName(friendId),
      sharedStreakDays: 0,
      isActive: true,
      linkedAt: DateTime.now(),
      lastSyncedDate: _dateKey(DateTime.now()),
    );
    await prefs.setString(_friendStreakKey, jsonEncode(friend.toMap()));
  }

  Future<FriendStreakState?> loadFriendStreakState() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_friendStreakKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final friend = FriendStreakState.fromMap(map);
      if (!friend.isActive) {
        return null;
      }
      return friend;
    } catch (_) {
      return null;
    }
  }

  Future<FriendStreakState?> updateFriendStreakAfterUserCompletion({
    required int streak,
  }) async {
    final friend = await loadFriendStreakState();
    if (friend == null) {
      return null;
    }

    final today = _dateKey(DateTime.now());
    if (friend.lastSyncedDate == today) {
      return friend;
    }

    final bothCompleted =
        ((today.hashCode + friend.friendId.hashCode + streak) % 100) < 68;
    final next = friend.copyWith(
      sharedStreakDays:
          bothCompleted ? friend.sharedStreakDays + 1 : friend.sharedStreakDays,
      lastSyncedDate: today,
    );

    final prefs = await _prefs;
    await prefs.setString(_friendStreakKey, jsonEncode(next.toMap()));
    return next;
  }

  Future<void> grantChallengeReferralReward(
      {required String fromUserId}) async {
    final prefs = await _prefs;
    final rewardedSet =
        prefs.getStringList(_challengeRewardedFromSetKey) ?? const <String>[];
    if (rewardedSet.contains(fromUserId)) {
      return;
    }

    final freezeCount = prefs.getInt(_freezeCountKey) ?? 0;
    await prefs.setInt(_freezeCountKey, freezeCount + 1);
    await prefs.setStringList(
      _challengeRewardedFromSetKey,
      <String>[...rewardedSet, fromUserId],
    );
    _emitEntitlement(await getUserEntitlement());
  }

  Future<(int sent, int accepted, double coefficient)>
      getViralSnapshot() async {
    final prefs = await _prefs;
    final sent = prefs.getInt(_challengeInviteSentCountKey) ?? 0;
    final accepted = prefs.getInt(_challengeInviteAcceptedCountKey) ?? 0;
    final coefficient = sent == 0 ? 0.0 : accepted / sent;
    return (sent, accepted, coefficient);
  }

  Future<void> resetForChallengeAcceptance() async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingCompletedKey, false);
    await prefs.remove(_selectedFocusKey);
    await prefs.remove(_preferredDurationKey);
    await prefs.remove(_currentTaskKey);
    await prefs.remove(_lastTaskAssignedLocalDateKey);
    await prefs.remove(_lastTaskCompletionLocalDateKey);
    await prefs.setInt(_streakCountKey, 0);
    await prefs.setInt(_weeklyCompletedCountKey, 0);
    await prefs.setString(_weeklyAnchorLocalDateKey, _dateKey(DateTime.now()));
  }

  Future<WeeklyProgress> getWeeklyProgress({int weeklyGoal = 7}) async {
    final prefs = await _prefs;
    final now = DateTime.now();
    await _refreshWeeklyProgress(prefs, now, increment: false);
    final completed = prefs.getInt(_weeklyCompletedCountKey) ?? 0;
    return WeeklyProgress(
      completed: completed.clamp(0, weeklyGoal),
      goal: weeklyGoal,
    );
  }

  Future<bool> getOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<UserFocus?> loadSelectedFocus() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_selectedFocusKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    for (final focus in UserFocus.values) {
      if (focus.label == raw) {
        return focus;
      }
    }

    return null;
  }

  Future<PreferredDuration?> loadPreferredDuration() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_preferredDurationKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    for (final duration in PreferredDuration.values) {
      if (duration.label == raw) {
        return duration;
      }
    }

    return null;
  }

  Future<void> setConsistencyModeActive(bool active) async {
    final prefs = await _prefs;
    await prefs.setBool(_consistencyModeActiveKey, active);
    await prefs.setString(
      _premiumUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
    _emitEntitlement(await getUserEntitlement());
  }

  Future<Task?> loadSavedTask() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_currentTaskKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final task = Task.fromMap(map);
      final isLoadable = task.status == TaskStatus.idle ||
          task.status == TaskStatus.inProgress;
      if (!isLoadable) {
        await clearSavedTask();
        return null;
      }
      return task;
    } catch (_) {
      return null;
    }
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _refreshWeeklyProgress(
    SharedPreferences prefs,
    DateTime now, {
    required bool increment,
  }) async {
    final today = _dateKey(now);
    final anchorRaw = prefs.getString(_weeklyAnchorLocalDateKey);
    final anchor = _parseDateKey(anchorRaw);

    var completed = prefs.getInt(_weeklyCompletedCountKey) ?? 0;
    if (anchor == null || now.difference(anchor).inDays >= 7) {
      completed = 0;
      await prefs.setString(_weeklyAnchorLocalDateKey, today);
    }

    if (increment) {
      completed += 1;
    }

    await prefs.setInt(_weeklyCompletedCountKey, completed.clamp(0, 7));
  }

  DateTime? _parseDateKey(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final parts = raw.split('-');
    if (parts.length != 3) {
      return null;
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  Future<void> _saveTaskToPrefs(Task task) async {
    final prefs = await _prefs;
    await prefs.setString(_currentTaskKey, jsonEncode(task.toMap()));
    await prefs.setString(
        _lastTaskAssignedLocalDateKey, _dateKey(DateTime.now()));
  }

  int _simulatedDailyBase(String dateKey) {
    final hash = dateKey.hashCode.abs();
    return 1180 + (hash % 140);
  }

  String _friendName(String friendId) {
    const names = <String>[
      'Alex',
      'Maya',
      'Noah',
      'Lina',
      'Eren',
      'Iris',
      'Mert',
      'Sena',
    ];
    return names[friendId.hashCode.abs() % names.length];
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  void _emitEntitlement(UserEntitlement entitlement) {
    if (!_entitlementController.isClosed) {
      _entitlementController.add(entitlement);
    }
  }
}

class AppOpenTrackingResult {
  const AppOpenTrackingResult({required this.isDay2Return});

  final bool isDay2Return;
}

class DailyStreakCompletionResult {
  const DailyStreakCompletionResult({
    required this.updatedStreakCount,
    required this.incremented,
  });

  final int updatedStreakCount;
  final bool incremented;
}

class MissedTaskResolutionResult {
  const MissedTaskResolutionResult({
    required this.freezeUsed,
    required this.isPremium,
    required this.streakReset,
    required this.updatedStreakCount,
    this.message,
  });

  final bool freezeUsed;
  final bool isPremium;
  final bool streakReset;
  final int updatedStreakCount;
  final String? message;

  factory MissedTaskResolutionResult.fromMap(dynamic map) {
    if (map is! Map) {
      return const MissedTaskResolutionResult(
        freezeUsed: false,
        isPremium: false,
        streakReset: false,
        updatedStreakCount: 0,
        message: 'Invalid missed task response',
      );
    }

    return MissedTaskResolutionResult(
      freezeUsed: map['freezeUsed'] == true,
      isPremium: map['isPremium'] == true,
      streakReset: map['streakReset'] == true,
      updatedStreakCount: (map['updatedStreakCount'] as num?)?.toInt() ?? 0,
      message: map['message'] as String?,
    );
  }
}

class WeeklyProgress {
  const WeeklyProgress({
    required this.completed,
    required this.goal,
  });

  final int completed;
  final int goal;
}

class ChallengeInvite {
  const ChallengeInvite({
    required this.fromUserId,
    required this.streak,
    required this.receivedAt,
  });

  final String fromUserId;
  final int streak;
  final DateTime receivedAt;

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'streak': streak,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  factory ChallengeInvite.fromMap(Map<String, dynamic> map) {
    return ChallengeInvite(
      fromUserId: (map['fromUserId'] as String?) ?? '',
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      receivedAt: DateTime.tryParse(map['receivedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class FriendStreakState {
  const FriendStreakState({
    required this.friendId,
    required this.friendName,
    required this.sharedStreakDays,
    required this.isActive,
    required this.linkedAt,
    required this.lastSyncedDate,
  });

  final String friendId;
  final String friendName;
  final int sharedStreakDays;
  final bool isActive;
  final DateTime linkedAt;
  final String lastSyncedDate;

  FriendStreakState copyWith({
    String? friendId,
    String? friendName,
    int? sharedStreakDays,
    bool? isActive,
    DateTime? linkedAt,
    String? lastSyncedDate,
  }) {
    return FriendStreakState(
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      sharedStreakDays: sharedStreakDays ?? this.sharedStreakDays,
      isActive: isActive ?? this.isActive,
      linkedAt: linkedAt ?? this.linkedAt,
      lastSyncedDate: lastSyncedDate ?? this.lastSyncedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friendId': friendId,
      'friendName': friendName,
      'sharedStreakDays': sharedStreakDays,
      'isActive': isActive,
      'linkedAt': linkedAt.toIso8601String(),
      'lastSyncedDate': lastSyncedDate,
    };
  }

  factory FriendStreakState.fromMap(Map<String, dynamic> map) {
    return FriendStreakState(
      friendId: (map['friendId'] as String?) ?? '',
      friendName: (map['friendName'] as String?) ?? 'Friend',
      sharedStreakDays: (map['sharedStreakDays'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] != false,
      linkedAt: DateTime.tryParse(map['linkedAt']?.toString() ?? '') ??
          DateTime.now(),
      lastSyncedDate:
          (map['lastSyncedDate'] as String?) ?? '${DateTime.now().year}-01-01',
    );
  }
}

class UserEntitlement {
  const UserEntitlement({
    required this.consistencyModeActive,
    required this.premiumExpiryDate,
    required this.freezeCount,
    required this.createdAt,
  });

  final bool consistencyModeActive;
  final DateTime? premiumExpiryDate;
  final int freezeCount;
  final DateTime? createdAt;

  bool get isPremium {
    if (consistencyModeActive) return true;
    if (premiumExpiryDate == null) return false;
    return premiumExpiryDate!.isAfter(DateTime.now());
  }

  bool get canUseFreeFreeze {
    if (isPremium) return false;
    if (freezeCount <= 0) return false;
    if (createdAt == null) return true;
    final accountAge = DateTime.now().difference(createdAt!);
    return accountAge <= const Duration(days: 7);
  }

  String get freezeBadgeLabel {
    if (isPremium) return 'Unlimited Freeze';
    final safeCount = freezeCount < 0 ? 0 : freezeCount;
    return '$safeCount Freeze left';
  }

  factory UserEntitlement.fromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return const UserEntitlement(
        consistencyModeActive: false,
        premiumExpiryDate: null,
        freezeCount: 1,
        createdAt: null,
      );
    }

    final createdAtRaw = data['createdAt'];
    final premiumExpiryRaw = data['premiumExpiryDate'];
    final createdAt = createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.tryParse(createdAtRaw?.toString() ?? '');
    final premiumExpiryDate = premiumExpiryRaw is DateTime
        ? premiumExpiryRaw
        : DateTime.tryParse(premiumExpiryRaw?.toString() ?? '');

    return UserEntitlement(
      consistencyModeActive:
          data['consistencyModeActive'] == true || data['isPremium'] == true,
      premiumExpiryDate: premiumExpiryDate,
      freezeCount: (data['freezeCount'] as num?)?.toInt() ?? 1,
      createdAt: createdAt,
    );
  }
}
