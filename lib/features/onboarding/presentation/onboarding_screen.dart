import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_text.dart';
import '../../dashboard/presentation/today_screen.dart';
import '../application/onboarding_controller.dart';
import '../domain/onboarding_models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isTransitioning = false;

  Future<void> _continue() async {
    if (_isTransitioning) return;
    final step = ref.read(onboardingStepProvider);

    AppLog.tap('ui.onboarding.continue', details: {'step': step});

    setState(() {
      _isTransitioning = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 180));

    if (step < 2) {
      ref.read(onboardingControllerProvider).nextStep();
    } else {
      await ref.read(onboardingControllerProvider).completeOnboarding();

      if (!mounted) return;
      if (ref.read(onboardingCompletedProvider)) {
        AppLog.action('ui.onboarding.navigate_today');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 180),
            pageBuilder: (_, __, ___) => const TodayScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isTransitioning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final step = ref.watch(onboardingStepProvider);
    final selectedFocus = ref.watch(selectedFocusProvider);
    final selectedDuration = ref.watch(preferredDurationProvider);

    final canProceed = switch (step) {
      0 => true,
      1 => true,
      _ => selectedFocus != null && selectedDuration != null,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: switch (step) {
                    0 => _MessageStep(
                        key: const ValueKey(0),
                        text: l10n.youDontNeedMotivation,
                      ),
                    1 => _MessageStep(
                        key: const ValueKey(1),
                        text: l10n.youNeedAction,
                      ),
                    _ => const _DirectSelectionStep(key: ValueKey(2)),
                  },
                ),
              ),
              if (step == 2) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Text(
                      l10n.publicCommitmentLine,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: canProceed && !_isTransitioning ? _continue : null,
                child: Text(step < 2 ? l10n.continueLabel : l10n.startLabel),
              ),
              if (step > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isTransitioning
                      ? null
                      : () {
                          AppLog.tap('ui.onboarding.back',
                              details: {'step': step});
                          ref.read(onboardingControllerProvider).previousStep();
                        },
                  child: Text(l10n.backLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageStep extends StatefulWidget {
  const _MessageStep({
    super.key,
    required this.text,
  });

  final String text;

  @override
  State<_MessageStep> createState() => _MessageStepState();
}

class _MessageStepState extends State<_MessageStep> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedText(
        text: widget.text,
        visible: _visible,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class _DirectSelectionStep extends ConsumerWidget {
  const _DirectSelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final selectedFocus = ref.watch(selectedFocusProvider);
    final selectedDuration = ref.watch(preferredDurationProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseYourAction,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          Text(l10n.focusSection, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          ...UserFocus.values.map(
            (focus) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectableTile(
                label: l10n.userFocusLabel(focus),
                selected: selectedFocus == focus,
                onTap: () {
                  ref.read(selectedFocusProvider.notifier).state = focus;
                  AppLog.state('ui.onboarding.focus_selected', details: {
                    'focus': focus.name,
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.durationSection,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          ...PreferredDuration.values.map(
            (duration) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SelectableTile(
                label: l10n.preferredDurationLabel(duration),
                selected: selectedDuration == duration,
                onTap: () {
                  ref.read(preferredDurationProvider.notifier).state = duration;
                  AppLog.state('ui.onboarding.duration_selected', details: {
                    'duration': duration.name,
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.white24,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppTheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
