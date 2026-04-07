import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_text.dart';
import '../../../core/widgets/impact_overlay.dart';
import '../../dashboard/application/execution_day_gate.dart';
import '../../debug/application/auto_test_runner.dart';
import '../../debug/application/debug_controller.dart';
import '../../debug/domain/auto_test_result.dart';
import '../../debug/domain/auto_test_step.dart';
import '../../onboarding/domain/onboarding_models.dart';
import '../../../services/analytics/analytics_service.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../../services/growth/friend_streak_service.dart';
import '../../../services/growth/leaderboard_service.dart';
import '../../streak/application/streak_controller.dart';
import '../../task/application/first_task_factory.dart';
import '../../task/application/task_controller.dart';
import '../../task/domain/task.dart';
import '../../share/presentation/share_screen.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _streakPulseController;
  int _previousStreak = 0;

  Timer? _returnNudgeTimer;
  bool _returnNudgeShown = false;

  Timer? _focusTimer;
  int _focusSeconds = 0;
  int _focusTargetSeconds = 0;
  bool _showFocusOverlay = false;

  bool _showDonePrimary = false;
  bool _showDoneSecondary = false;
  bool _completeLock = false;
  bool _runningFullTest = false;
  int _weeklyCompleted = 0;
  int _todayCompletionCount = 0;
  int _leaderboardRank = 0;
  int _leaderboardTopStreak = 0;
  String? _friendStreakLine;
  bool _socialEventsLogged = false;
  bool _justCompletedNow = false;
  static const int _weeklyGoal = 7;
  ExecutionDayState _executionDayState = ExecutionDayState.noTaskToday;
  String? _doneIdentityMessage;
  String? _doneCuriosityMessage;

  List<_GroupBucket> _groupSteps(List<AutoTestStep> steps) {
    const order = <String>['Core', 'Identity', 'Evolution', 'Guard'];
    final buckets = <String, List<AutoTestStep>>{};
    for (final step in steps) {
      buckets.putIfAbsent(step.category, () => <AutoTestStep>[]).add(step);
    }

    final grouped = <_GroupBucket>[];
    for (final key in order) {
      final items = buckets[key];
      if (items != null && items.isNotEmpty) {
        grouped.add(_GroupBucket(name: key, steps: items));
      }
    }
    grouped.sort((left, right) {
      final leftFailRate = left.failCount / left.steps.length;
      final rightFailRate = right.failCount / right.steps.length;
      final failRateCompare = rightFailRate.compareTo(leftFailRate);
      if (failRateCompare != 0) {
        return failRateCompare;
      }

      final failCountCompare = right.failCount.compareTo(left.failCount);
      if (failCountCompare != 0) {
        return failCountCompare;
      }

      return left.name.compareTo(right.name);
    });
    return grouped;
  }

  Widget _buildGroupedTestResults(AutoTestResult result) {
    final groups = _groupSteps(result.steps);
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final success = group.successCount;
        final fail = group.failCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.name} • $success/${group.steps.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (fail > 0)
                Text(
                  'Fail: $fail',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
              const SizedBox(height: 4),
              ...group.steps.map((step) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    step.success ? Icons.check_circle : Icons.cancel,
                    color: step.success ? Colors.green : Colors.red,
                  ),
                  title: Text(step.name),
                  subtitle: step.error == null
                      ? Text('${step.duration.inMilliseconds} ms')
                      : Text(step.error!),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    AppLog.flow('today.screen', 'init_state');
    _streakPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _startReturnNudgeTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      AppLog.flow('today.screen.bootstrap', 'start');
      await _resolveExecutionDayGate();
      AppLog.flow('today.screen.bootstrap', 'completed');
    });
  }

  @override
  void dispose() {
    AppLog.flow('today.screen', 'dispose');
    _returnNudgeTimer?.cancel();
    _focusTimer?.cancel();
    _streakPulseController.dispose();
    super.dispose();
  }

  void _startReturnNudgeTimer() {
    _returnNudgeTimer?.cancel();
    _returnNudgeTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || _returnNudgeShown) return;

      final task = ref.read(taskControllerProvider);
      final hasStarted = task?.status == TaskStatus.inProgress ||
          task?.status == TaskStatus.completed;
      if (hasStarted) return;

      _returnNudgeShown = true;
      AppLog.action('ui.today.return_nudge_shown');
      showDialog<void>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.ofLocale(
            Localizations.localeOf(context),
          );
          return AlertDialog(
            content: Text(l10n.youCameBackFinishIt),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.continueShort),
              ),
            ],
          );
        },
      );
    });
  }

  bool _isSameLocalDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  Future<void> _resolveExecutionDayGate() async {
    final service = ref.read(firestoreServiceProvider);
    final taskController = ref.read(taskControllerProvider.notifier);
    _justCompletedNow = false;

    await ref
        .read(streakProvider.notifier)
        .hydrateFromServer(firestoreService: service);
    await _refreshWeeklyProgress();
    await _refreshSocialLayer();

    final savedTask = await service.loadSavedTask();
    final completedToday = await service.hasCompletedTaskToday();
    final assignedToday = await service.hasAssignedTaskToday();

    AppLog.verbose('today.gate.snapshot', details: {
      'saved_task': savedTask != null,
      'saved_status': savedTask?.status.name,
      'completed_today': completedToday,
      'assigned_today': assignedToday,
    });

    if (!mounted) {
      return;
    }

    if (savedTask != null &&
        savedTask.status == TaskStatus.inProgress &&
        !_isSameLocalDay(savedTask.createdAt, DateTime.now())) {
      await _handleStaleInProgressTask(savedTask);
      return;
    }

    if (completedToday) {
      taskController.clearTask();
      setState(() {
        _executionDayState = ExecutionDayState.completedToday;
      });
      return;
    }

    if (savedTask != null) {
      taskController.setTask(savedTask);
      setState(() {
        _executionDayState = ExecutionDayState.activeTask;
      });
      return;
    }

    if (!assignedToday) {
      await _generateDailyTask();
      return;
    }

    setState(() {
      _executionDayState = ExecutionDayState.noTaskToday;
    });
  }

  Future<void> _refreshSocialLayer() async {
    final service = ref.read(firestoreServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final streak = ref.read(streakProvider);
    final daySeed = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final leaderboard = ref
        .read(leaderboardServiceProvider)
        .buildForStreak(userStreak: streak, daySeed: daySeed);
    final friendState =
        await ref.read(friendStreakServiceProvider).getActiveFriendStreak();
    final todayCount = await service.getTodayCompletionCount();

    if (!mounted) {
      return;
    }

    setState(() {
      _todayCompletionCount = todayCount;
      _leaderboardRank = leaderboard.userRank;
      _leaderboardTopStreak = leaderboard.topStreak;
      _friendStreakLine = friendState == null
          ? null
          : AppLocalizations.ofLocale(Localizations.localeOf(context))
              .friendStreakLabel(
              friendName: friendState.friendName,
              day: friendState.sharedStreakDays,
            );
    });

    if (_socialEventsLogged) {
      return;
    }

    await analytics.logDailyCounterSeen(
      streak: streak,
      dayIndex: daySeed,
    );
    await analytics.logLeaderboardViewed(
      streak: streak,
      dayIndex: daySeed,
    );
    _socialEventsLogged = true;
  }

  Future<void> _generateDailyTask() async {
    final service = ref.read(firestoreServiceProvider);
    final localeCode = Localizations.localeOf(context).languageCode;
    final focus = await service.loadSelectedFocus() ?? UserFocus.focus;
    final duration =
        await service.loadPreferredDuration() ?? PreferredDuration.twoMin;
    final streakDay = ref.read(streakProvider) + 1;

    final task = FirstTaskFactory.create(
      focus: focus,
      preferredDuration: duration,
      languageCode: localeCode,
      streakDay: streakDay,
    );

    await service.saveTask(userId: 'local', task: task);
    ref.read(taskControllerProvider.notifier).setTask(task);

    if (!mounted) {
      return;
    }
    setState(() {
      _executionDayState = ExecutionDayState.activeTask;
    });
    AppLog.action('today.gate.daily_task_generated', details: {
      'title': task.title,
      'streak_day': streakDay,
    });
  }

  Future<void> _handleStaleInProgressTask(Task staleTask) async {
    final taskController = ref.read(taskControllerProvider.notifier);
    final streakController = ref.read(streakProvider.notifier);
    final service = ref.read(firestoreServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final previousStreak = ref.read(streakProvider);

    AppLog.action('today.gate.stale_task_detected', details: {
      'title': staleTask.title,
      'created_at': staleTask.createdAt.toIso8601String(),
      'previous_streak': previousStreak,
    });

    final outcome = await streakController.processMissedTask(
      firestoreService: service,
    );
    await service.clearSavedTask();
    taskController.clearTask();

    if (outcome.type == MissedTaskOutcomeType.freezeUsed) {
      await analytics.logFreezeUsed(isPremium: outcome.isPremium);
      if (!mounted) {
        return;
      }
      setState(() {
        _executionDayState = ExecutionDayState.noTaskToday;
      });
      return;
    }

    if (mounted && previousStreak > 0) {
      final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.lossHeadline),
            content: Text(l10n.lossBody(previousStreak)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.continueLabel),
              ),
            ],
          );
        },
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _executionDayState = ExecutionDayState.missedToday;
    });
  }

  Future<void> _handleStart() async {
    AppLog.flow('today.start', 'begin');
    final taskController = ref.read(taskControllerProvider.notifier);
    final analytics = ref.read(analyticsServiceProvider);
    final task = ref.read(taskControllerProvider);

    HapticFeedback.selectionClick();
    AppLog.tap('ui.today.start', details: {'has_task': task != null});
    final started = taskController.startTask();
    if (!started) {
      AppLog.blocked('ui.today.start', 'invalid_transition');
      return;
    }
    await _persistCurrentTask();
    await analytics.logTaskStarted();

    _focusTimer?.cancel();
    _focusTargetSeconds = (task?.estimatedMinutes ?? 0) * 60;
    setState(() {
      _focusSeconds = 0;
      _showFocusOverlay = true;
      _executionDayState = ExecutionDayState.activeTask;
    });
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_showFocusOverlay) {
        timer.cancel();
        return;
      }
      setState(() {
        _focusSeconds += 1;
      });

      final taskState = ref.read(taskControllerProvider);
      final isInProgress = taskState?.status == TaskStatus.inProgress;
      if (_focusTargetSeconds > 0 &&
          _focusSeconds >= _focusTargetSeconds &&
          isInProgress) {
        AppLog.action(
          'ui.today.focus_target_reached',
          details: {
            'target_seconds': _focusTargetSeconds,
            'elapsed_seconds': _focusSeconds,
          },
        );
        timer.cancel();
        unawaited(_handleComplete());
      }
    });
    AppLog.flow('today.start', 'completed', details: {
      'focus_target_seconds': _focusTargetSeconds,
    });
  }

  Future<void> _handleComplete() async {
    AppLog.flow('today.complete', 'begin');
    if (_completeLock) return;
    _completeLock = true;
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final wasFirstTask = ref.read(taskControllerProvider)?.isFirstTask ?? false;
    AppLog.tap(
      'ui.today.complete',
      details: {'task_status': ref.read(taskControllerProvider)?.status.name},
    );

    final taskController = ref.read(taskControllerProvider.notifier);
    final streakController = ref.read(streakProvider.notifier);
    final analytics = ref.read(analyticsServiceProvider);

    HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 160));

    DailyStreakCompletionResult? streakResult;
    final completed = taskController.completeTask();
    if (completed) {
      await _clearSavedTask();
      taskController.clearTask();
      streakResult = await streakController.completeDailyTask(
        firestoreService: ref.read(firestoreServiceProvider),
      );
      final service = ref.read(firestoreServiceProvider);
      _todayCompletionCount = await service.incrementTodayCompletionCount();
      final friendState =
          await ref.read(friendStreakServiceProvider).markDailyCompletion(
                streak: streakResult.updatedStreakCount,
              );
      await _refreshWeeklyProgress();
      _doneIdentityMessage = l10n.dynamicMessage(
        streakResult.updatedStreakCount,
      );
      _doneCuriosityMessage = l10n.pressurePercentByStreak(
        streakResult.updatedStreakCount,
      );
      await analytics.logTaskCompleted();
      if (friendState != null) {
        await analytics.logFriendStreakActive(
          streak: streakResult.updatedStreakCount,
          dayIndex: streakResult.updatedStreakCount,
        );
      }
      if (streakResult.updatedStreakCount == 3) {
        await analytics.logStreakDay3();
      }
      if (streakResult.updatedStreakCount == 7) {
        await analytics.logStreakDay7();
      }
      _justCompletedNow = true;
    } else {
      AppLog.blocked('ui.today.complete', 'no_task_loaded');
    }

    _focusTimer?.cancel();
    if (mounted) {
      setState(() {
        _showFocusOverlay = false;
        _showDonePrimary = true;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _showDoneSecondary = true;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted && completed && wasFirstTask) {
      await _showHookMoment();
    }

    if (mounted && completed) {
      final int updatedStreak =
          streakResult?.updatedStreakCount ?? (ref.read(streakProvider) ?? 0);
      AppLog.verbose('today.complete.post_sequence', details: {
        'updated_streak': updatedStreak,
      });
      await _showMandatoryDoneExperience(streak: updatedStreak);
      if (!mounted) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));
      await _openShareAfterDone(streak: updatedStreak);
      if (mounted) {
        setState(() {
          _executionDayState = ExecutionDayState.completedToday;
        });
      }
    }

    if (mounted) {
      setState(() {
        _showDonePrimary = false;
        _showDoneSecondary = false;
        _doneIdentityMessage = null;
        _doneCuriosityMessage = null;
      });
    }

    _completeLock = false;
    AppLog.flow('today.complete', 'completed', details: {
      'completed': completed,
    });
  }

  Future<void> _handleCannotDo() async {
    AppLog.flow('today.cannot_do', 'begin');
    final taskController = ref.read(taskControllerProvider.notifier);
    final streakController = ref.read(streakProvider.notifier);
    final firestoreService = ref.read(firestoreServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final previousStreak = ref.read(streakProvider);

    AppLog.tap(
      'ui.today.cannot_do',
      details: {'task_present': ref.read(taskControllerProvider) != null},
    );

    _focusTimer?.cancel();
    if (mounted) {
      setState(() {
        _showFocusOverlay = false;
      });
    }

    final cannotDoApplied = taskController.cannotDoTask();
    if (!cannotDoApplied) {
      AppLog.blocked('ui.today.cannot_do', 'invalid_transition');
      return;
    }

    await analytics.logCannotDo();
    await analytics.logTaskCannotDo();
    await _clearSavedTask();
    taskController.clearTask();

    final outcome = await streakController.processMissedTask(
      firestoreService: firestoreService,
    );

    if (outcome.type == MissedTaskOutcomeType.freezeUsed) {
      AppLog.verbose('today.cannot_do.freeze_used', details: {
        'is_premium': outcome.isPremium,
      });
      await analytics.logFreezeUsed(isPremium: outcome.isPremium);
      if (mounted) {
        setState(() {
          _executionDayState = ExecutionDayState.noTaskToday;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.streakSavedDontWasteIt)));
      }
      return;
    }

    if (!mounted) {
      return;
    }

    if (outcome.type == MissedTaskOutcomeType.streakReset &&
        previousStreak > 0) {
      AppLog.verbose('today.cannot_do.loss_dialog_shown', details: {
        'previous_streak': previousStreak,
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.lossHeadline),
            content: Text(l10n.lossBody(previousStreak)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.continueLabel),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        return;
      }
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.streakReset)));
    if (mounted) {
      setState(() {
        _executionDayState = ExecutionDayState.missedToday;
      });
    }
    AppLog.flow('today.cannot_do', 'completed', details: {
      'outcome': outcome.type.name,
    });
  }

  Future<void> _persistCurrentTask() async {
    final task = ref.read(taskControllerProvider);
    if (task == null) return;

    await ref
        .read(firestoreServiceProvider)
        .saveTask(userId: 'local', task: task);
    AppLog.action(
      'ui.today.task_persisted',
      details: {'title': task.title, 'status': task.status.name},
    );
  }

  Future<void> _clearSavedTask() async {
    await ref.read(firestoreServiceProvider).clearSavedTask();
    AppLog.action('ui.today.task_cleared');
  }

  Future<void> _refreshWeeklyProgress() async {
    final progress = await ref
        .read(firestoreServiceProvider)
        .getWeeklyProgress(weeklyGoal: _weeklyGoal);
    if (!mounted) return;
    setState(() {
      _weeklyCompleted = progress.completed;
    });
  }

  Future<void> _openShareAfterDone({required int streak}) async {
    AppLog.flow('today.share_after_done', 'open', details: {'streak': streak});
    if (!_justCompletedNow) {
      AppLog.blocked('today.share_after_done', 'not_just_completed');
      return;
    }
    if (!mounted) {
      return;
    }
    await ref.read(analyticsServiceProvider).logShareOpened();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ShareScreen(streak: streak),
      ),
    );
    _justCompletedNow = false;
  }

  Future<void> _showMandatoryDoneExperience({required int streak}) async {
    AppLog.flow('today.done_experience', 'open', details: {'streak': streak});
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    await ref.read(analyticsServiceProvider).logDoneExperienceShown();
    if (!mounted) {
      return;
    }
    final stage = ValueNotifier<int>(0);
    final firstReveal = Timer(const Duration(milliseconds: 500), () {
      stage.value = 1;
    });
    final secondReveal = Timer(const Duration(milliseconds: 1300), () {
      stage.value = 2;
      HapticFeedback.heavyImpact();
    });
    final closeTimer = Timer(const Duration(milliseconds: 2700), () {
      if (!mounted) {
        return;
      }
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) {
        nav.pop();
      }
    });
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'done_experience',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.done,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<int>(
                          valueListenable: stage,
                          builder: (context, value, _) {
                            return Column(
                              children: [
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: value >= 1 ? 1 : 0,
                                  child: Text(
                                    l10n.doneMomentLineTwo,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 180),
                                  opacity: value >= 2 ? 1 : 0,
                                  child: Text(
                                    l10n.doneMomentLineThree,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.white54),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
    firstReveal.cancel();
    secondReveal.cancel();
    closeTimer.cancel();
    stage.dispose();
    AppLog.flow('today.done_experience', 'closed', details: {'streak': streak});
  }

  Future<void> _showHookMoment() async {
    AppLog.flow('today.hook_moment', 'open');
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.hookMomentStepOne,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.hookMomentStepTwo,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.continueLabel),
            ),
          ],
        );
      },
    );
    AppLog.flow('today.hook_moment', 'closed');
  }

  Future<void> _runFullTestFromToday() async {
    AppLog.flow('today.auto_test', 'begin');
    if (!kDebugMode || _runningFullTest) {
      return;
    }

    setState(() {
      _runningFullTest = true;
    });

    try {
      AppLog.tap('ui.today.debug_test_button');
      final result = await ref.read(autoTestRunnerProvider).runFullTest();
      ref.read(debugControllerProvider.notifier).setLastTestResult(result);

      if (!mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surfaceAlt,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AUTO TEST RESULT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Total: ${result.totalSteps}'),
                  Text('Success: ${result.successCount}'),
                  Text('Failed: ${result.failCount}'),
                  const SizedBox(height: 10),
                  Expanded(child: _buildGroupedTestResults(result)),
                ],
              ),
            ),
          );
        },
      );
      AppLog.flow('today.auto_test', 'completed', details: {
        'total': result.totalSteps,
        'success': result.successCount,
        'failed': result.failCount,
      });
    } finally {
      if (mounted) {
        setState(() {
          _runningFullTest = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final streak = ref.watch(streakProvider);
    final task = ref.watch(taskControllerProvider);
    final gateState = _executionDayState;

    if (streak != _previousStreak) {
      final shouldPulse =
          (_previousStreak == 0 && streak == 1) || streak > _previousStreak;
      if (shouldPulse) {
        _streakPulseController
          ..reset()
          ..forward();
      }
      _previousStreak = streak;
    }

    final canComplete = task?.status == TaskStatus.inProgress;
    final displayFocusSeconds = _focusTargetSeconds > 0
        ? (_focusTargetSeconds - _focusSeconds)
            .clamp(0, _focusTargetSeconds)
            .toInt()
        : _focusSeconds;
    final overlayLabel = task?.title ?? '';

    return Scaffold(
      body: SafeArea(
        child: ImpactOverlay(
          visible: _showFocusOverlay,
          seconds: displayFocusSeconds,
          label: overlayLabel,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StreakBar(
                  streak: streak,
                  pulse: _streakPulseController,
                  freezeBadgeLabel: l10n.streakRiskLabel,
                  identityLevel: l10n.identityLevelLabel(streak),
                  socialPressureLine:
                      l10n.socialPressureCounter(_todayCompletionCount),
                  weeklyProgressLabel: l10n.weeklyProgressLabel(
                    _weeklyCompleted,
                    _weeklyGoal,
                  ),
                  weeklyProgressValue: _weeklyCompleted / _weeklyGoal,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.leaderboardRankLabel(
                      _leaderboardRank <= 0 ? 12 : _leaderboardRank),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.leaderboardTopStreakLabel(
                    _leaderboardTopStreak <= 0 ? streak : _leaderboardTopStreak,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white54),
                ),
                if (_friendStreakLine != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _friendStreakLine!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                ],
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed:
                          _runningFullTest ? null : _runFullTestFromToday,
                      child: Text(
                        _runningFullTest ? 'TEST RUNNING...' : 'TEST',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  flex: 7,
                  child: _TaskCard(
                    task: task,
                    gateState: gateState,
                    collapsing: _showDonePrimary,
                    l10n: l10n,
                    streak: streak,
                  ),
                ),
                const SizedBox(height: 12),
                _DoneSequence(
                  showPrimary: _showDonePrimary,
                  showSecondary: _showDoneSecondary,
                  l10n: l10n,
                  streak: streak,
                  identityMessage: _doneIdentityMessage,
                  curiosityMessage: _doneCuriosityMessage,
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: task != null &&
                                    gateState == ExecutionDayState.activeTask
                                ? [
                                    _PressScale(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          AppLog.tap(
                                            'ui.today.primary_button',
                                            details: {
                                              'label': canComplete
                                                  ? 'done'
                                                  : 'start',
                                              'task_present': true,
                                              'task_status': task.status.name,
                                            },
                                          );
                                          if (canComplete) {
                                            await _handleComplete();
                                          } else {
                                            await _handleStart();
                                          }
                                        },
                                        child: Text(
                                          canComplete
                                              ? l10n.done
                                              : l10n.startLabel,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _PressScale(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          AppLog.tap(
                                            'ui.today.defer',
                                            details: {
                                              'task_present': true,
                                              'task_status': task.status.name,
                                            },
                                          );
                                          final taskController = ref.read(
                                            taskControllerProvider.notifier,
                                          );
                                          final deferred =
                                              taskController.deferTask();
                                          if (!deferred) {
                                            AppLog.blocked(
                                              'ui.today.defer',
                                              'invalid_transition',
                                            );
                                            return;
                                          }
                                          unawaited(ref
                                              .read(analyticsServiceProvider)
                                              .logTaskDeferred());
                                          taskController.clearTask();
                                          unawaited(_clearSavedTask());
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(l10n.deferredToast),
                                            ),
                                          );
                                          _focusTimer?.cancel();
                                          if (mounted) {
                                            setState(() {
                                              _showFocusOverlay = false;
                                              _executionDayState =
                                                  ExecutionDayState.noTaskToday;
                                            });
                                          }
                                        },
                                        child: Text(l10n.laterLabel),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () {
                                        AppLog.tap(
                                          'ui.today.skip_or_cant_do',
                                          details: {
                                            'task_present': true,
                                            'task_status': task.status.name,
                                          },
                                        );
                                        _handleCannotDo();
                                      },
                                      child: Text(l10n.cantDoLabel),
                                    ),
                                  ]
                                : [
                                    _PressScale(
                                      child: OutlinedButton(
                                        onPressed: () {},
                                        child: Text(
                                          gateState ==
                                                  ExecutionDayState
                                                      .completedToday
                                              ? '⏳ ${l10n.continueTomorrowLabel}'
                                              : '⏳ ${l10n.comeBackTomorrow}',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (gateState ==
                                        ExecutionDayState.completedToday)
                                      TextButton(
                                        onPressed: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  ShareScreen(streak: streak),
                                            ),
                                          );
                                        },
                                        child: Text('🚀 ${l10n.shareLabel}'),
                                      ),
                                  ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupBucket {
  const _GroupBucket({required this.name, required this.steps});

  final String name;
  final List<AutoTestStep> steps;

  int get successCount => steps.where((step) => step.success).length;

  int get failCount => steps.length - successCount;
}

class _StreakBar extends StatelessWidget {
  const _StreakBar({
    required this.streak,
    required this.pulse,
    required this.freezeBadgeLabel,
    required this.identityLevel,
    required this.socialPressureLine,
    required this.weeklyProgressLabel,
    required this.weeklyProgressValue,
  });

  final int streak;
  final Animation<double> pulse;
  final String freezeBadgeLabel;
  final String identityLevel;
  final String socialPressureLine;
  final String weeklyProgressLabel;
  final double weeklyProgressValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final scale = 1 + (0.04 * pulse.value);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  '🔥 $streak',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$identityLevel • ${l10n.streakMood(streak)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weeklyProgressLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        socialPressureLine,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: weeklyProgressValue.clamp(0, 1),
                          minHeight: 5,
                          backgroundColor: Colors.white10,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    freezeBadgeLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.gateState,
    required this.collapsing,
    required this.l10n,
    required this.streak,
  });

  final Task? task;
  final ExecutionDayState gateState;
  final bool collapsing;
  final AppLocalizations l10n;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 220),
      scale: collapsing ? 0.92 : 1,
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white10),
        ),
        child: task == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gateState == ExecutionDayState.missedToday
                          ? l10n.lossHeadline
                          : l10n.doneIdlePrimary(streak),
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      gateState == ExecutionDayState.missedToday
                          ? l10n.lossBody(streak)
                          : l10n.doneIdleSecondary(streak),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task!.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.minutesLabel(task!.estimatedMinutes),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.unfinishedPressurePrimary,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.unfinishedPressureSecondary,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DoneSequence extends StatelessWidget {
  const _DoneSequence({
    required this.showPrimary,
    required this.showSecondary,
    required this.l10n,
    required this.streak,
    this.identityMessage,
    this.curiosityMessage,
  });

  final bool showPrimary;
  final bool showSecondary;
  final AppLocalizations l10n;
  final int streak;
  final String? identityMessage;
  final String? curiosityMessage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedText(
            text: l10n.done,
            visible: showPrimary,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          AnimatedText(
            text: identityMessage ?? l10n.dynamicMessage(streak),
            visible: showSecondary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          AnimatedText(
            text: curiosityMessage ?? l10n.returnPressureByStreak(streak),
            visible: showSecondary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});

  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!_pressed) {
          HapticFeedback.selectionClick();
          setState(() {
            _pressed = true;
          });
        }
      },
      onPointerUp: (_) {
        if (_pressed) {
          setState(() {
            _pressed = false;
          });
        }
      },
      onPointerCancel: (_) {
        if (_pressed) {
          setState(() {
            _pressed = false;
          });
        }
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.96 : 1,
        child: widget.child,
      ),
    );
  }
}
