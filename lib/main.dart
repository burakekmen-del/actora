import 'dart:async';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/actora_app.dart';
import 'app/deep_link_providers.dart';
import 'core/logging/app_log.dart';
import 'features/share/domain/invite_challenge.dart';
import 'services/analytics/analytics_service.dart';
import 'services/firebase/firestore_service.dart';
import 'services/viral/invite_tracker_service.dart';

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      AppLog.error(
        'runtime.flutter_error',
        details.exception,
        details.stack ?? StackTrace.current,
      );
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
      AppLog.error('runtime.platform_dispatcher', error, stackTrace);
      return true;
    };

    AppLog.action('runtime.main_started', details: {
      'verbose_logs': AppLog.isVerboseEnabled,
    });

    final firestoreService = FirestoreService();
    final analyticsService = AnalyticsService();
    final appLinks = AppLinks();
    final inviteTracker = InviteTrackerService();

    AppLog.flow('runtime.bootstrap', 'begin');

    final appOpenResult = await firestoreService.trackAppOpenAndReturnIsDay2();
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri, inviteTracker);
    }
    appLinks.uriLinkStream.listen((uri) async {
      await _handleDeepLink(uri, inviteTracker);
    }, onError: (Object error, StackTrace stackTrace) {
      AppLog.error('runtime.bootstrap.deep_link_stream', error, stackTrace);
    });

    AppLog.verbose('runtime.bootstrap.app_open_checked', details: {
      'is_day2_return': appOpenResult.isDay2Return,
    });
    if (appOpenResult.isDay2Return) {
      await analyticsService.logAppOpenDay2();
      await analyticsService.logReturnedNextDay();
    }

    AppLog.flow('runtime.bootstrap', 'completed');
    AppLog.action('runtime.run_app');

    runApp(const ProviderScope(child: ActoraApp()));
  }, (Object error, StackTrace stackTrace) {
    AppLog.error('runtime.zone_uncaught', error, stackTrace);
  });
}

/// Handle deep link and fetch invite details
Future<void> _handleDeepLink(
  Uri uri,
  InviteTrackerService trackerService,
) async {
  try {
    // Extract invite ID from URI
    final inviteId = uri.queryParameters['ref'];
    if (inviteId == null || inviteId.isEmpty) {
      AppLog.verbose('runtime.deep_link_no_invite_id', details: {
        'uri': uri.toString(),
      });
      return;
    }

    AppLog.action('runtime.deep_link_received', details: {
      'invite_id': inviteId,
    });

    // Fetch invite details
    final invite = await trackerService.fetchInviteForDisplay(inviteId);

    // Create challenge model
    final challenge = InviteChallenge(
      inviteId: invite.inviteId,
      senderId: invite.senderLabel, // Note: API doesn't return sender_id
      senderLabel: invite.senderLabel,
      senderStreak: invite.senderStreak,
      senderDayIndex: 1, // TODO: Get from API
      createdAt: DateTime.now(),
    );

    // Store in global state (will trigger modal on home screen)
    // Note: This is a race condition workaround - we'll improve with ProviderContainer
    AppLog.action('runtime.deep_link_invite_fetched', details: {
      'invite_id': inviteId,
      'sender': invite.senderLabel,
    });

    // For now, log that we got it. The modal will be triggered by home screen
    // checking the URI stream in real-time
  } catch (e) {
    AppLog.error(
      'runtime.deep_link_fetch_failed',
      e,
      StackTrace.current,
    );
  }
}
