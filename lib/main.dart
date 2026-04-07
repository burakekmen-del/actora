import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/actora_app.dart';
import 'core/logging/app_log.dart';
import 'services/analytics/analytics_service.dart';
import 'services/firebase/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLog.action('runtime.main_started', details: {
    'verbose_logs': AppLog.isVerboseEnabled,
  });

  final firestoreService = FirestoreService();
  final analyticsService = AnalyticsService();

  AppLog.flow('runtime.bootstrap', 'begin');

  final appOpenResult = await firestoreService.trackAppOpenAndReturnIsDay2();
  AppLog.verbose('runtime.bootstrap.app_open_checked', details: {
    'is_day2_return': appOpenResult.isDay2Return,
  });
  if (appOpenResult.isDay2Return) {
    await analyticsService.logAppOpenDay2();
  }

  AppLog.flow('runtime.bootstrap', 'completed');
  AppLog.action('runtime.run_app');

  runApp(const ProviderScope(child: ActoraApp()));
}
