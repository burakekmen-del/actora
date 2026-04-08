import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/logging/app_log.dart';

final inviteTrackerProvider = Provider<InviteTrackerService>(
  (ref) => InviteTrackerService(),
);

class InviteTrackerService {
  InviteTrackerService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 8);

  static const String _baseUrl = String.fromEnvironment(
    'ACTORA_VIRAL_API_BASE_URL',
    defaultValue: 'https://invite.hatirlatbana.com',
  );

  /// Create invite + prepare for sharing
  Future<ShareableInvite> prepareShareInvite({
    required String senderId,
    required String senderLabel,
    required int streak,
    required int dayIndex,
  }) async {
    final inviteId = _generateShortInviteId();

    AppLog.action(
      'viral.prepare_share_invite',
      details: {
        'sender_id': senderId,
        'streak': streak,
      },
    );

    try {
      final response = await _postJson(
        _apiUrlFor('invites'),
        body: {
          'invite_id': inviteId,
          'sender_id': senderId,
          'sender_label': senderLabel,
          'sender_streak': streak,
          'day_index': dayIndex,
          'channel': 'share_sheet',
        },
      );

      final invite = ShareableInvite.fromJson(response);
      AppLog.action(
        'viral.share_invite_created',
        details: {'invite_id': invite.inviteId},
      );
      return invite;
    } catch (e) {
      AppLog.error(
        'viral.prepare_share_invite_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Track share action (measure which channel was used)
  Future<void> trackShareAction({
    required String inviteId,
    required String userId,
    required String channel, // 'whatsapp', 'sms', 'copy_link'
  }) async {
    AppLog.action(
      'viral.share_tracked',
      details: {
        'invite_id': inviteId,
        'channel': channel,
      },
    );

    try {
      await _postJson(
        _apiUrlFor('invites/$inviteId/track_share'),
        body: {
          'shared_by': userId,
          'channel': channel,
          'shared_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      AppLog.error(
        'viral.track_share_failed',
        e,
        StackTrace.current,
      );
      // Don't rethrow - this is non-critical
    }
  }

  /// Check if invite was accepted
  Future<bool> checkIfInviteAccepted(String inviteId) async {
    try {
      final response = await _getJson(_apiUrlFor('invites/$inviteId'));
      return response['status'] == 'accepted';
    } catch (e) {
      AppLog.error(
        'viral.check_acceptance_failed',
        e,
        StackTrace.current,
      );
      return false;
    }
  }

  /// Fetch invite details for display
  Future<ShareableInvite> fetchInviteForDisplay(String inviteId) async {
    AppLog.action('viral.fetch_invite_for_display', details: {
      'invite_id': inviteId,
    });

    try {
      final response = await _getJson(_apiUrlFor('invites/$inviteId'));
      return ShareableInvite.fromJson(response);
    } catch (e) {
      AppLog.error(
        'viral.fetch_invite_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Accept invite (user receives invite)
  Future<ShareableInvite> acceptInvite({
    required String inviteId,
    required String acceptedBy,
  }) async {
    AppLog.action(
      'viral.accept_invite',
      details: {
        'invite_id': inviteId,
        'accepted_by': acceptedBy,
      },
    );

    try {
      final response = await _postJson(
        _apiUrlFor('invites/$inviteId/accept'),
        body: {
          'accepted_by': acceptedBy,
          'accepted_label': 'accepted',
        },
      );

      final invite = ShareableInvite.fromJson(response);
      AppLog.action('viral.invite_accepted', details: {
        'invite_id': inviteId,
        'sender': invite.senderLabel,
      });
      return invite;
    } catch (e) {
      AppLog.error(
        'viral.accept_invite_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Get viral metrics
  Future<ViralMetrics> fetchMetrics() async {
    try {
      final response = await _getJson(_apiUrlFor('metrics'));
      return ViralMetrics.fromJson(response);
    } catch (e) {
      AppLog.error(
        'viral.fetch_metrics_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  // Private helpers
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(
      _requestTimeout,
      onTimeout: () => throw TimeoutException(
        'Viral API request timed out.',
      ),
    );
    return _decodeJsonResponse(response);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri, {
    required Map<String, Object?> body,
  }) async {
    final response = await _client
        .post(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Viral API request timed out.',
          ),
        );
    return _decodeJsonResponse(response);
  }

  Map<String, dynamic> _decodeJsonResponse(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body['error']?.toString() ?? 'API request failed.';
    throw StateError('$message (${response.statusCode})');
  }

  static String _generateShortInviteId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String result = '';
    final now = DateTime.now();
    for (int i = 0; i < 8; i++) {
      result += chars[(now.microsecondsSinceEpoch + i) % chars.length];
    }
    return result;
  }

  static Uri _apiUrlFor(String path) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    return Uri.parse('${base}api/$path');
  }
}

class ShareableInvite {
  const ShareableInvite({
    required this.inviteId,
    required this.inviteUrl,
    required this.shortUrl,
    required this.senderStreak,
    required this.senderLabel,
    required this.shareMessage,
  });

  final String inviteId;
  final String inviteUrl;
  final String shortUrl;
  final int senderStreak;
  final String senderLabel;
  final String shareMessage;

  String get whatsappShare => '🚀 $senderLabel seni Actora\'ya davet ediyor!\n'
      '$senderStreak gün çizgisi ile devam ediyor. Takılır mısın?\n\n'
      'İndir: ${Uri.encodeComponent(shortUrl)}';

  String get smsShare =>
      'Actora\'da $senderLabel ile birlikte! $senderStreak gün çizgisi. '
      'Senin de desen? $shortUrl #ActoraChallenge';

  String get copyLinkShare => inviteUrl;

  factory ShareableInvite.fromJson(Map<String, dynamic> json) {
    final baseUrl = 'https://invite.hatirlatbana.com';
    final inviteId = json['invite_id'] as String? ?? '';

    return ShareableInvite(
      inviteId: inviteId,
      inviteUrl: '$baseUrl/invite/$inviteId',
      shortUrl: '$baseUrl/r/$inviteId',
      senderStreak: (json['sender_streak'] as num?)?.toInt() ?? 0,
      senderLabel: json['sender_label'] as String? ?? 'Biri',
      shareMessage: 'Actora Davet: $baseUrl/r/$inviteId',
    );
  }
}

class ViralMetrics {
  const ViralMetrics({
    required this.totalSent,
    required this.totalAccepted,
    required this.viralCoefficient,
  });

  final int totalSent;
  final int totalAccepted;
  final double viralCoefficient;

  factory ViralMetrics.fromJson(Map<String, dynamic> json) {
    return ViralMetrics(
      totalSent: (json['total_sent'] as num?)?.toInt() ?? 0,
      totalAccepted: (json['total_accepted'] as num?)?.toInt() ?? 0,
      viralCoefficient: (json['viral_coefficient'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
