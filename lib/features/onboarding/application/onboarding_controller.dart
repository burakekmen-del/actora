import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../../../services/firebase/firestore_service.dart';
import '../../task/application/first_task_factory.dart';
import '../../task/application/task_controller.dart';
import '../domain/onboarding_models.dart';

final onboardingStepProvider = StateProvider<int>((ref) => 0);
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);
final selectedFocusProvider = StateProvider<UserFocus?>((ref) => null);
final preferredDurationProvider = StateProvider<PreferredDuration?>(
  (ref) => null,
);

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});

final onboardingBootstrapProvider = FutureProvider<void>((ref) async {
  final service = ref.read(firestoreServiceProvider);
  final completed = await service.getOnboardingCompleted();

  ref.read(onboardingCompletedProvider.notifier).state = completed;

  if (!completed) {
    return;
  }

  final savedFocus = await service.loadSelectedFocus();
  final savedDuration = await service.loadPreferredDuration();

  if (savedFocus != null) {
    ref.read(selectedFocusProvider.notifier).state = savedFocus;
  }
  if (savedDuration != null) {
    ref.read(preferredDurationProvider.notifier).state = savedDuration;
  }
});

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;
  bool _isCompleting = false;

  void nextStep() {
    final step = _ref.read(onboardingStepProvider);
    if (step < 2) {
      AppLog.tap(
        'onboarding.next_step',
        details: {'from': step, 'to': step + 1},
      );
      _ref.read(onboardingStepProvider.notifier).state = step + 1;
    } else {
      AppLog.blocked(
        'onboarding.next_step',
        'already_at_final_step',
        details: {'step': step},
      );
    }
  }

  void previousStep() {
    final step = _ref.read(onboardingStepProvider);
    if (step > 0) {
      AppLog.tap(
        'onboarding.previous_step',
        details: {'from': step, 'to': step - 1},
      );
      _ref.read(onboardingStepProvider.notifier).state = step - 1;
    } else {
      AppLog.blocked(
        'onboarding.previous_step',
        'already_at_first_step',
        details: {'step': step},
      );
    }
  }

  Future<void> completeOnboarding() async {
    if (_isCompleting) {
      AppLog.blocked('onboarding.complete', 'already_completing');
      return;
    }

    if (_ref.read(onboardingCompletedProvider)) {
      AppLog.blocked('onboarding.complete', 'already_completed');
      return;
    }

    _isCompleting = true;
    try {
      final focus = _ref.read(selectedFocusProvider);
      final duration = _ref.read(preferredDurationProvider);
      if (focus == null || duration == null) {
        AppLog.blocked(
          'onboarding.complete',
          'missing_selection',
          details: {'focus': focus?.name, 'duration': duration?.name},
        );
        return;
      }

      AppLog.action(
        'onboarding.complete',
        details: {'focus': focus.name, 'duration': duration.name},
      );

      final firstTask = FirstTaskFactory.create(
        focus: focus,
        preferredDuration: duration,
        languageCode:
            WidgetsBinding.instance.platformDispatcher.locale.languageCode,
      );

      _ref.read(taskControllerProvider.notifier).setTask(firstTask);
      _ref.read(onboardingCompletedProvider.notifier).state = true;

      AppLog.state(
        'onboarding.completed',
        details: {
          'focus': focus.name,
          'duration': duration.name,
          'task': firstTask.title,
        },
      );

      await _ref
          .read(firestoreServiceProvider)
          .saveOnboardingAndFirstTask(
            focus: focus,
            duration: duration,
            task: firstTask,
          );
      AppLog.action('onboarding.persisted');
    } finally {
      _isCompleting = false;
    }
  }
}
