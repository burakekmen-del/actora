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
      home: DebugShell(child: home),
    );
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
