import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_localizations.dart';
import '../core/logging/app_log.dart' as app_log;
import '../core/theme/app_theme.dart';
import '../core/widgets/animated_text.dart';
import '../features/debug/presentation/debug_shell.dart';
import '../features/dashboard/presentation/today_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../services/analytics/analytics_service.dart';
import '../services/firebase/firestore_service.dart';
import '../services/viral/invite_backend_service.dart';

class ActoraApp extends ConsumerWidget {
  const ActoraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(onboardingBootstrapProvider);
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);
    app_log.AppLog.verbose('app.build', details: {
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
        app_log.AppLog.verbose('app.locale_resolution', details: {
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
    if (invite == null) {
      return;
    }

    ChallengeInvite resolvedInvite = invite;
    if (invite.fromUserId.isEmpty && invite.inviteId.isNotEmpty) {
      try {
        final backend = ref.read(inviteBackendServiceProvider);
        final record = await backend.fetchInvite(invite.inviteId);
        resolvedInvite = ChallengeInvite(
          inviteId: record.inviteId,
          fromUserId: record.senderId,
          streak: record.senderStreak,
          receivedAt: invite.receivedAt,
        );
      } catch (error, stackTrace) {
        app_log.AppLog.error('invite.resolve.failed', error, stackTrace);
      }
    }

    if (resolvedInvite.fromUserId.isEmpty && resolvedInvite.inviteId.isEmpty) {
      return;
    }
    _handled = true;

    if (!mounted) {
      return;
    }
    final analytics = ref.read(analyticsServiceProvider);

    await analytics.logChallengeOpened(
      streak: resolvedInvite.streak,
      fromUserId: resolvedInvite.fromUserId,
      dayIndex: resolvedInvite.streak,
    );

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) =>
            _ChallengeAcceptScreen(invite: resolvedInvite),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111317), Color(0xFF050608)],
          ),
        ),
        child: Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x55000000),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeAcceptScreen extends ConsumerStatefulWidget {
  const _ChallengeAcceptScreen({required this.invite});

  final ChallengeInvite invite;

  @override
  ConsumerState<_ChallengeAcceptScreen> createState() =>
      _ChallengeAcceptScreenState();
}

class _ChallengeAcceptScreenState
    extends ConsumerState<_ChallengeAcceptScreen> {
  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.ofLocale(Localizations.localeOf(context));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.deepLinkChallengeTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.deepLinkChallengeBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              _InviteSummary(invite: widget.invite),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isAccepting
                    ? null
                    : () async {
                        setState(() {
                          _isAccepting = true;
                        });
                        final service = ref.read(firestoreServiceProvider);
                        final backend = ref.read(inviteBackendServiceProvider);
                        final analytics = ref.read(analyticsServiceProvider);
                        final userId = await service.getOrCreateLocalUserId();

                        try {
                          if (widget.invite.inviteId.isNotEmpty) {
                            await backend.acceptInvite(
                              inviteId: widget.invite.inviteId,
                              acceptedBy: userId,
                            );
                          }
                          await service.markChallengeInviteAccepted();
                          await analytics.logChallengeAccepted(
                            streak: widget.invite.streak,
                            fromUserId: widget.invite.fromUserId,
                            dayIndex: widget.invite.streak,
                          );
                          await analytics.logFriendJoined(
                            streak: widget.invite.streak,
                            dayIndex: widget.invite.streak,
                          );
                          await analytics.logShareToInstallConversion(
                            fromUserId: widget.invite.fromUserId,
                            streak: widget.invite.streak,
                            dayIndex: widget.invite.streak,
                          );
                          try {
                            final snapshot = await backend.fetchMetrics();
                            await analytics.logViralCoefficient(
                              value: snapshot.viralCoefficient,
                              invites: snapshot.totalSent,
                              accepted: snapshot.totalAccepted,
                              streak: widget.invite.streak,
                              dayIndex: widget.invite.streak,
                            );
                          } catch (error) {
                            app_log.AppLog.blocked(
                              'invite.accept.metrics_failed',
                              error.toString(),
                            );
                          }
                          await service.grantChallengeReferralReward(
                            fromUserId: widget.invite.fromUserId,
                          );
                          await service.bindFriendStreak(
                            friendId: widget.invite.fromUserId,
                          );
                          await service.clearPendingChallengeInvite();
                          await service.resetForChallengeAcceptance();
                          ref.read(onboardingCompletedProvider.notifier).state =
                              false;
                          ref.read(onboardingStepProvider.notifier).state = 0;
                        } catch (error, stackTrace) {
                          app_log.AppLog.error(
                            'invite.accept.failed',
                            error,
                            stackTrace,
                          );
                        }

                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder<void>(
                            transitionDuration:
                                const Duration(milliseconds: 180),
                            pageBuilder: (_, __, ___) =>
                                const OnboardingScreen(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                          (route) => false,
                        );
                      },
                child: Text(l10n.acceptChallengeLabel),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isAccepting
                    ? null
                    : () async {
                        await ref
                            .read(firestoreServiceProvider)
                            .clearPendingChallengeInvite();
                        if (!mounted) {
                          return;
                        }
                        Navigator.of(this.context).pop();
                      },
                child: Text(l10n.declineChallengeLabel),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteSummary extends StatelessWidget {
  const _InviteSummary({required this.invite});

  final ChallengeInvite invite;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Invite ID',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              invite.inviteId.isEmpty ? 'pending' : invite.inviteId,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Streak: ${invite.streak}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ),
      ),
    );
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
    app_log.AppLog.flow('launch.sequence', 'init');
    _runSequence();
  }

  Future<void> _runSequence() async {
    app_log.AppLog.flow('launch.sequence', 'step_stop_waiting_delay');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _showStopWaiting = true;
    });
    app_log.AppLog.verbose('launch.sequence.stop_waiting_visible');

    app_log.AppLog.flow('launch.sequence', 'step_start_delay');
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _showStart = true;
    });
    app_log.AppLog.verbose('launch.sequence.start_visible');

    app_log.AppLog.flow('launch.sequence', 'step_navigate_delay');
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    app_log.AppLog.action('launch.sequence.navigate_target', details: {
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
    app_log.AppLog.flow('launch.sequence', 'dispose');
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
