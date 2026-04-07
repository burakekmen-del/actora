import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/logging/app_log.dart';
import '../../../features/onboarding/domain/onboarding_models.dart';
import '../../../features/streak/application/streak_controller.dart';
import '../../../features/task/application/first_task_factory.dart';
import '../../../features/task/application/task_controller.dart';
import '../../../features/task/domain/task.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/firebase/firestore_service.dart';
import '../domain/auto_test_result.dart';
import '../domain/auto_test_step.dart';

final autoTestRunnerProvider = Provider<AutoTestRunner>((ref) {
  return AutoTestRunner(ref);
});

class AutoTestRunner {
  AutoTestRunner(this._ref);

  final Ref _ref;

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _selectedFocusKey = 'selected_focus';
  static const String _preferredDurationKey = 'preferred_duration';
  static const String _streakCountKey = 'streak_count';
  static const String _lastTaskCompletionLocalDateKey =
      'last_task_completion_local_date';
  static const String _currentTaskKey = 'current_task';
  static const String _freezeCountKey = 'freeze_count';
  static const String _consistencyModeActiveKey = 'consistency_mode_active';

  Future<AutoTestResult> runFullTest() async {
    if (!kDebugMode) {
      return AutoTestResult(steps: const [], finishedAt: DateTime.now());
    }

    final firestoreService = _ref.read(firestoreServiceProvider);
    final analyticsService = _ref.read(analyticsServiceProvider);
    final taskController = TaskController();
    final streakController = StreakController();

    final prefs = await SharedPreferences.getInstance();
    final snapshot = _snapshotPrefs(prefs);
    final steps = <AutoTestStep>[];
    Task? activeTask;

    Future<void> runStep(String name, Future<void> Function() action) async {
      final startedAt = DateTime.now();
      try {
        await action();
        final duration = DateTime.now().difference(startedAt);
        steps.add(AutoTestStep(name: name, success: true, duration: duration));
        AppLog.action(
          'auto_test_step',
          details: {
            'step': name,
            'result': 'success',
            'ms': duration.inMilliseconds,
          },
        );
      } catch (error, stackTrace) {
        final duration = DateTime.now().difference(startedAt);
        steps.add(
          AutoTestStep(
            name: name,
            success: false,
            duration: duration,
            error: error.toString(),
          ),
        );
        AppLog.error(
          'auto_test_error',
          error,
          stackTrace,
          details: {
            'step': name,
            'result': 'fail',
            'ms': duration.inMilliseconds,
          },
        );
      }
    }

    try {
      await runStep('onboarding_reset', () async {
        await _clearOnboardingAndTaskPrefs(prefs);
        await prefs.setInt(_streakCountKey, 0);
        await prefs.setString(
          _lastTaskCompletionLocalDateKey,
          _dateKey(DateTime.now().subtract(const Duration(days: 1))),
        );
      });

      await runStep('onboarding_started', () async {
        AppLog.action('onboarding_started');
      });

      const selectedFocus = UserFocus.discipline;
      const selectedDuration = PreferredDuration.twoMin;

      await runStep('onboarding_focus_selected', () async {
        AppLog.action('onboarding_step', details: {'step': 'focus'});
        await prefs.setString(_selectedFocusKey, selectedFocus.label);
      });

      await runStep('onboarding_duration_selected', () async {
        AppLog.action('onboarding_step', details: {'step': 'duration'});
        await prefs.setString(_preferredDurationKey, selectedDuration.label);
      });

      late Task firstTask;
      await runStep('onboarding_completed', () async {
        firstTask = FirstTaskFactory.create(
          focus: selectedFocus,
          preferredDuration: selectedDuration,
          languageCode: 'tr',
        );

        await firestoreService.saveOnboardingAndFirstTask(
          focus: selectedFocus,
          duration: selectedDuration,
          task: firstTask,
        );

        final completed = await firestoreService.getOnboardingCompleted();
        _expect(completed, 'Onboarding complete flag false döndü');
        AppLog.action('onboarding_completed');
      });

      await runStep('weekly_progress_initial', () async {
        final progress = await firestoreService.getWeeklyProgress();
        _expect(
          progress.completed == 0,
          'Haftalık progress başlangıçta 0 olmalı',
        );
        _expect(progress.goal == 7, 'Haftalık goal 7 olmalı');
      });

      await runStep('task_create', () async {
        final saved = await firestoreService.loadSavedTask();
        _expect(saved != null, 'İlk task oluşturulamadı');
        activeTask = saved;
        taskController.setTask(saved!);
      });

      await runStep('task_start', () async {
        final started = taskController.startTask();
        _expect(started, 'Task start başarısız');

        activeTask = activeTask?.copyWith(status: TaskStatus.inProgress);
        _expect(activeTask != null, 'Start sonrası aktif task null olamaz');
        await firestoreService.saveTask(userId: 'local', task: activeTask!);
        await analyticsService.logTaskStarted();
      });

      await runStep('task_complete', () async {
        final completed = taskController.completeTask();
        _expect(completed, 'Task complete başarısız');
        await firestoreService.clearSavedTask();
        taskController.clearTask();

        final streakResult = await streakController.completeDailyTask(
          firestoreService: firestoreService,
        );
        _expect(streakResult.incremented, 'Streak incremented=true olmalı');
        _expect(streakResult.updatedStreakCount == 1, 'Streak 1 olmalı');
        await analyticsService.logTaskCompleted();
      });

      await runStep('task_verify_streak_incremented', () async {
        final streak = await firestoreService.getStreakCount();
        _expect(streak >= 1, 'Complete sonrası streak >= 1 olmalı');
      });

      await runStep('weekly_progress_after_complete', () async {
        final progress = await firestoreService.getWeeklyProgress();
        _expect(
          progress.completed == 1,
          'Complete sonrası haftalık progress 1 olmalı',
        );
      });

      await runStep('identity_levels_thresholds', () async {
        final l10n = AppLocalizations('tr');
        _expect(l10n.identityLevelLabel(1) == 'Started', 'Day1 Started olmalı');
        _expect(
          l10n.identityLevelLabel(3) == 'Building',
          'Day3 Building olmalı',
        );
        _expect(
          l10n.identityLevelLabel(7) == 'Locked in',
          'Day7 Locked in olmalı',
        );
        _expect(
          l10n.identityLevelLabel(14) == 'Unstoppable',
          'Day14 Unstoppable olmalı',
        );
      });

      await runStep('identity_done_messages_present', () async {
        final l10n = AppLocalizations('tr');
        _expect(
          l10n.identityDoneMessage(1) == 'Başladın.',
          'Day1 kimlik mesajı uyuşmuyor',
        );
        _expect(
          l10n.identityDoneMessage(3) == 'Çoğu kişi burada bırakır.',
          'Day3 kimlik mesajı uyuşmuyor',
        );
        _expect(
          l10n.identityDoneMessage(7) == 'Artık bırakan biri değilsin.',
          'Day7 kimlik mesajı uyuşmuyor',
        );
        _expect(
          l10n.identityDoneMessage(14) == 'Artık geri dönüş yok.',
          'Day14 kimlik mesajı uyuşmuyor',
        );
      });

      await runStep('hook_moment_copy_present', () async {
        final l10n = AppLocalizations('tr');
        _expect(
          l10n.hookMomentStepOne == 'Buraya kadar geldin.',
          'Hook step one copy uyuşmuyor',
        );
        _expect(
          l10n.hookMomentStepTwo == 'Şimdi bırakırsan, diğerleri gibisin.',
          'Hook step two copy uyuşmuyor',
        );
      });

      await runStep('public_commitment_copy_present', () async {
        final l10n = AppLocalizations('tr');
        _expect(
          l10n.publicCommitmentLine == 'Bunu 7 gün yapıyorum.',
          'Public commitment copy uyuşmuyor',
        );
      });

      await runStep('curiosity_loop_copy_present', () async {
        final l10n = AppLocalizations('tr');
        _expect(
          l10n.returnPressureMessage == 'Yarın yapmazsan sıfırlanır.',
          'Return pressure copy uyuşmuyor',
        );
        _expect(
          l10n.dynamicMessage(1) == 'İyi başlangıç.',
          'Dynamic day1 copy uyuşmuyor',
        );
        _expect(
          l10n.dynamicMessage(3) == 'Sen bırakan biri değilsin.',
          'Dynamic day3 copy uyuşmuyor',
        );
        _expect(
          l10n.dynamicMessage(6) == 'Sen bırakan biri değilsin.',
          'Dynamic day6 copy uyuşmuyor',
        );
        _expect(
          l10n.dynamicMessage(10) == 'Artık geri dönüş yok.',
          'Dynamic day10 copy uyuşmuyor',
        );
        _expect(
          l10n.socialPressureMessage(1) == 'Çoğu kişi burada bırakır.',
          'Social pressure first stage copy uyuşmuyor',
        );
        _expect(
          l10n.socialPressureMessage(3) == 'Çoğu kişi 3. günde bırakır.',
          'Social pressure day3 copy uyuşmuyor',
        );
      });

      await runStep('loss_copy_present', () async {
        final l10n = AppLocalizations('tr');
        _expect(l10n.lossHeadline == 'Seri bozuldu.', 'Loss headline uyumsuz');
        _expect(
          l10n.lossBody(3) == '3 gün. Gitti.',
          'Loss body uyumsuz',
        );
      });

      await runStep('task_evolution_day10', () async {
        final evolved = FirstTaskFactory.create(
          focus: UserFocus.focus,
          preferredDuration: PreferredDuration.twoMin,
          languageCode: 'tr',
          streakDay: 10,
        );
        _expect(
          evolved.estimatedMinutes >= 3,
          'Day10 görev süresi en az 3 dk olmalı',
        );
      });

      await runStep('task_evolution_day20_followup', () async {
        final evolved = FirstTaskFactory.create(
          focus: UserFocus.focus,
          preferredDuration: PreferredDuration.twoMin,
          languageCode: 'tr',
          streakDay: 20,
        );
        _expect(
          evolved.estimatedMinutes >= 5,
          'Day20 görev süresi en az 5 dk olmalı',
        );

        final followUp = FirstTaskFactory.create(
          focus: UserFocus.focus,
          preferredDuration: PreferredDuration.fiveMin,
          languageCode: 'tr',
          streakDay: 20,
          followUp: true,
        );
        _expect(followUp.estimatedMinutes == 2, 'Follow-up görev 2 dk olmalı');
        _expect(!followUp.isFirstTask, 'Follow-up görev firstTask olmamalı');
      });

      await runStep('task_deferred_flow', () async {
        final task = _buildTask(title: 'Defer QA');
        taskController.setTask(task);
        final deferred = taskController.deferTask();
        _expect(deferred, 'Task defer başarısız');

        await firestoreService.clearSavedTask();
        taskController.clearTask();

        final restored = await firestoreService.loadSavedTask();
        _expect(restored == null, 'Deferred task restore edilmemeli');
      });

      await runStep('task_cannot_do_flow', () async {
        final task = _buildTask(title: 'CannotDo QA');
        taskController.setTask(task);
        final cannotDoApplied = taskController.cannotDoTask();
        _expect(cannotDoApplied, 'Task cannotDo başarısız');

        await firestoreService.clearSavedTask();
        taskController.clearTask();

        final outcome = await streakController.processMissedTask(
          firestoreService: firestoreService,
        );
        _expect(
          outcome.type == MissedTaskOutcomeType.freezeUsed ||
              outcome.type == MissedTaskOutcomeType.streakReset,
          'Freeze veya reset outcome bekleniyordu',
        );
      });

      await runStep('streak_same_day_double_complete', () async {
        await prefs.setInt(_streakCountKey, 1);
        await prefs.setString(
          _lastTaskCompletionLocalDateKey,
          _dateKey(DateTime.now()),
        );

        final first = await firestoreService.completeDailyTaskAndUpdateStreak();
        final second =
            await firestoreService.completeDailyTaskAndUpdateStreak();

        _expect(!first.incremented, 'Aynı gün first incremented false olmalı');
        _expect(
          !second.incremented,
          'Aynı gün second incremented false olmalı',
        );
        _expect(second.updatedStreakCount == 1, 'Aynı gün streak değişmemeli');
      });

      await runStep('streak_next_day_increment', () async {
        await prefs.setInt(_streakCountKey, 1);
        await prefs.setString(
          _lastTaskCompletionLocalDateKey,
          _dateKey(DateTime.now().subtract(const Duration(days: 1))),
        );

        final result =
            await firestoreService.completeDailyTaskAndUpdateStreak();
        _expect(result.incremented, 'Next day increment true olmalı');
        _expect(result.updatedStreakCount == 2, 'Next day streak 2 olmalı');
      });

      await runStep('streak_missed_day_reset', () async {
        await prefs.setBool(_consistencyModeActiveKey, false);
        await prefs.setInt(_freezeCountKey, 0);
        await prefs.setInt(_streakCountKey, 3);
        await prefs.setString(
          _lastTaskCompletionLocalDateKey,
          _dateKey(DateTime.now().subtract(const Duration(days: 2))),
        );

        final missedResult = await firestoreService.resolveMissedTask();
        _expect(
          missedResult.streakReset,
          'Missed day streak reset bekleniyordu',
        );
        final streak = await firestoreService.getStreakCount();
        _expect(streak == 0, 'Reset sonrası streak 0 olmalı');
      });

      await runStep('persistence_restore_idle', () async {
        final idleTask = _buildTask(title: 'Idle Restore QA');
        await firestoreService.saveTask(userId: 'local', task: idleTask);
        final restored = await firestoreService.loadSavedTask();
        _expect(restored != null, 'Idle task restore edilmeli');
      });

      await runStep('persistence_no_restore_completed', () async {
        final completedTask = _buildTask(
          title: 'Completed Restore QA',
          status: TaskStatus.completed,
        );
        await firestoreService.saveTask(userId: 'local', task: completedTask);
        final restored = await firestoreService.loadSavedTask();
        _expect(restored == null, 'Completed task restore edilmemeli');
      });

      await runStep('onboarding_persistence_reopen', () async {
        await prefs.setBool(_onboardingCompletedKey, true);
        final onboardingCompleted =
            await firestoreService.getOnboardingCompleted();
        _expect(onboardingCompleted, 'Onboarding persistence bozuk');
      });

      await runStep('error_null_task_complete', () async {
        taskController.clearTask();
        final completed = taskController.completeTask();
        _expect(!completed, 'Null task complete false olmalı');
      });

      await runStep('error_duplicate_tap_start', () async {
        taskController.setTask(_buildTask(title: 'Duplicate Start QA'));
        final firstStart = taskController.startTask();
        final secondStart = taskController.startTask();
        _expect(firstStart, 'İlk start true olmalı');
        _expect(!secondStart, 'İkinci start false olmalı');
      });

      await runStep('error_invalid_saved_task', () async {
        await prefs.setString(_currentTaskKey, '{invalid_json');
        final restored = await firestoreService.loadSavedTask();
        _expect(restored == null, 'Invalid saved task restore edilmemeli');
      });
    } finally {
      await _restorePrefs(prefs, snapshot);
    }

    final result = AutoTestResult(
      steps: List<AutoTestStep>.unmodifiable(steps),
      finishedAt: DateTime.now(),
    );

    if (result.failCount > 0) {
      AppLog.error(
        'auto_test_failed',
        StateError('Auto test failed'),
        StackTrace.current,
        details: {
          'failedCount': result.failCount,
          'failedSteps': result.failedSteps.map((step) => step.name).join(','),
        },
      );
    }

    AppLog.action(
      'auto_test_result',
      details: {
        'total': result.totalSteps,
        'success': result.successCount,
        'failed': result.failCount,
      },
    );

    return result;
  }

  Map<String, Object?> _snapshotPrefs(SharedPreferences prefs) {
    final snapshot = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      snapshot[key] = prefs.get(key);
    }
    return snapshot;
  }

  Future<void> _restorePrefs(
    SharedPreferences prefs,
    Map<String, Object?> snapshot,
  ) async {
    await prefs.clear();
    for (final entry in snapshot.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
    }
  }

  Future<void> _clearOnboardingAndTaskPrefs(SharedPreferences prefs) async {
    await prefs.remove(_onboardingCompletedKey);
    await prefs.remove(_selectedFocusKey);
    await prefs.remove(_preferredDurationKey);
    await prefs.remove(_currentTaskKey);
  }

  static Task _buildTask({
    required String title,
    TaskStatus status = TaskStatus.idle,
  }) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      status: status,
      createdAt: DateTime.now(),
      type: TaskType.focus,
      estimatedMinutes: 2,
      isFirstTask: false,
    );
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _expect(bool condition, String message) {
    if (!condition) {
      throw StateError(message);
    }
  }
}
