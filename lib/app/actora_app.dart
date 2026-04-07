import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../core/logging/app_log.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/animated_text.dart';
import '../features/debug/presentation/debug_shell.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../services/analytics/analytics_service.dart';
import '../services/firebase/firestore_service.dart';

class ActoraApp extends ConsumerWidget {
  const ActoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(onboardingBootstrapProvider);
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    AppLog.verbose('app.build', details: {
      'onboarding_completed': onboardingCompleted,
      'bootstrap_state': bootstrap.when(
        data: (_) => 'data',
        loading: () => 'loading',
        error: (_, __) => 'error',
      ),
    });
    final target =
        onboardingCompleted ? const TodayScreen() : const OnboardingScreen();

    final home = bootstrap.when(
      data: (_) => _LaunchSequenceScreen(target: target),
      loading: () => const _BootScreen(),
      error: (_, __) => _LaunchSequenceScreen(target: target),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Actora',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('tr')],
      localeResolutionCallback: (locale, supportedLocales) {
        AppLog.verbose('app.locale_resolution', details: {
          'requested': locale?.languageCode ?? 'null',
        });
        if (locale == null) {
          return const Locale('en');
        }
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      theme: AppTheme.darkTheme,
      home: _ChallengeInviteGate(child: DebugShell(child: home)),
    );
  }
}

class _ChallengeInviteGate extends ConsumerStatefulWidget {
  const _ChallengeInviteGate({required this.child});

  final Widget child;

  @override
  ConsumerState<_ChallengeInviteGate> createState() =>
      _ChallengeInviteGateState();
}

class _ChallengeInviteGateState extends ConsumerState<_ChallengeInviteGate> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingInvite();
    });
  }

  Future<void> _checkPendingInvite() async {
    if (_handled) {
      return;
    }

    final service = ref.read(firestoreServiceProvider);
    final invite = await service.loadPendingChallengeInvite();
    if (invite == null || invite.fromUserId.isEmpty) {
      return;
    }
    _handled = true;

    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    final analytics = ref.read(analyticsServiceProvider);

    await analytics.logChallengeOpened(
      streak: invite.streak,
      fromUserId: invite.fromUserId,
      dayIndex: invite.streak,
    );

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.deepLinkChallengeTitle),
          content: Text(l10n.deepLinkChallengeBody),
          actions: [
            TextButton(
              onPressed: () async {
                await service.clearPendingChallengeInvite();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.declineChallengeLabel),
            ),
            FilledButton(
              onPressed: () async {
                await service.markChallengeInviteAccepted();
                await analytics.logChallengeAccepted(
                  streak: invite.streak,
                  fromUserId: invite.fromUserId,
                  dayIndex: invite.streak,
                );
                await analytics.logFriendJoined(
                  streak: invite.streak,
                  dayIndex: invite.streak,
                );
                await analytics.logShareToInstallConversion(
                  fromUserId: invite.fromUserId,
                  streak: invite.streak,
                  dayIndex: invite.streak,
                );
                await service.grantChallengeReferralReward(
                  fromUserId: invite.fromUserId,
                );
                await service.bindFriendStreak(friendId: invite.fromUserId);
                final snapshot = await service.getViralSnapshot();
                await analytics.logViralCoefficient(
                  value: snapshot.$3,
                  invites: snapshot.$1,
                  accepted: snapshot.$2,
                  streak: invite.streak,
                  dayIndex: invite.streak,
                );
                await service.clearPendingChallengeInvite();
                await service.resetForChallengeAcceptance();

                if (!context.mounted) {
                  return;
                }
                ref.read(onboardingCompletedProvider.notifier).state = false;
                ref.read(onboardingStepProvider.notifier).state = 0;
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder<void>(
                    transitionDuration: const Duration(milliseconds: 180),
                    pageBuilder: (_, __, ___) => const OnboardingScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                  (route) => false,
                );
              },
              child: Text(l10n.acceptChallengeLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: ColoredBox(color: Colors.black));
  }
}

class _LaunchSequenceScreen extends StatefulWidget {
  const _LaunchSequenceScreen({required this.target});

  final Widget target;

  @override
  State<_LaunchSequenceScreen> createState() => _LaunchSequenceScreenState();
}

class _LaunchSequenceScreenState extends State<_LaunchSequenceScreen> {
  bool _showStopWaiting = false;
  bool _showStart = false;

  @override
  void initState() {
    super.initState();
    AppLog.flow('launch.sequence', 'init');
    _runSequence();
  }

  Future<void> _runSequence() async {
    AppLog.flow('launch.sequence', 'step_stop_waiting_delay');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _showStopWaiting = true;
    });
    AppLog.verbose('launch.sequence.stop_waiting_visible');

    AppLog.flow('launch.sequence', 'step_start_delay');
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _showStart = true;
    });
    AppLog.verbose('launch.sequence.start_visible');

    AppLog.flow('launch.sequence', 'step_navigate_delay');
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    AppLog.action('launch.sequence.navigate_target', details: {
      'target_widget': widget.target.runtimeType.toString(),
    });
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => widget.target,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    AppLog.flow('launch.sequence', 'dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    return Scaffold(
      body: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedText(
              text: l10n.stopWaiting,
              visible: _showStopWaiting,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            AnimatedText(
              text: l10n.startSplash,
              visible: _showStart,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
