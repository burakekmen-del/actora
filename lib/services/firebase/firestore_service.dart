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
