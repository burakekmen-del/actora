import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/actora_app.dart';
import 'services/analytics/analytics_service.dart';
import 'services/firebase/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firestoreService = FirestoreService();
  final analyticsService = AnalyticsService();

  final appOpenResult = await firestoreService.trackAppOpenAndReturnIsDay2();
  if (appOpenResult.isDay2Return) {
    await analyticsService.logAppOpenDay2();
  }

  runApp(const ProviderScope(child: ActoraApp()));
}
