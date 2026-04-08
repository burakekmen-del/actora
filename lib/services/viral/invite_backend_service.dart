import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final inviteBackendServiceProvider = Provider<InviteBackendService>(
  (ref) => InviteBackendService(),
);

class InviteBackendService {
  InviteBackendService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 8);

  static const String _baseUrl = String.fromEnvironment(
    'ACTORA_VIRAL_API_BASE_URL',
    defaultValue: 'https://invite.hatirlatbana.com',
  );

  static String generateInviteId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();
    return [
      hex.sublist(0, 4).join(),
      hex.sublist(4, 6).join(),
      hex.sublist(6, 8).join(),
      hex.sublist(8, 10).join(),
      hex.sublist(10, 16).join(),
    ].join('-');
  }

  bool get isConfigured => _baseUrl.isNotEmpty;

  Uri get _apiRoot {
    final normalizedBase = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    return Uri.parse(normalizedBase).resolve('api/');
  }

  String buildInviteUrl(String inviteId) {
    return Uri.parse(_baseUrl).resolve('/invite/$inviteId').toString();
  }

  Future<InviteRecord> createInvite({
    required String inviteId,
    required String senderId,
    required int streak,
    required int dayIndex,
    required String senderLabel,
    String channel = 'share_sheet',
    String variant = 'A',
  }) async {
    final response = await _postJson(
      _apiRoot.resolve('invites'),
      body: <String, Object?>{
        'invite_id': inviteId,
        'sender_id': senderId,
        'sender_label': senderLabel,
        'sender_streak': streak,
        'day_index': dayIndex,
        'channel': channel,
        'variant': variant,
      },
    );
    return InviteRecord.fromJson(response);
  }

  Future<InviteRecord> fetchInvite(String inviteId) async {
    final response = await _getJson(_apiRoot.resolve('invites/$inviteId'));
    return InviteRecord.fromJson(response);
  }

  Future<InviteRecord> acceptInvite({
    required String inviteId,
    required String acceptedBy,
    String acceptedLabel = 'accepted',
  }) async {
    final response = await _postJson(
      _apiRoot.resolve('invites/$inviteId/accept'),
      body: <String, Object?>{
        'accepted_by': acceptedBy,
        'accepted_label': acceptedLabel,
      },
    );
    return InviteRecord.fromJson(response);
  }

  Future<ViralMetricsSnapshot> fetchMetrics() async {
    final response = await _getJson(_apiRoot.resolve('metrics'));
    return ViralMetricsSnapshot.fromJson(response);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(
      _requestTimeout,
      onTimeout: () => throw TimeoutException(
        'Invite backend request timed out. Check emulator host/LAN setup.',
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
            'Accept': 'application/json'
          },
          body: jsonEncode(body),
        )
        .timeout(
          _requestTimeout,
          onTimeout: () => throw TimeoutException(
            'Invite backend request timed out. Check emulator host/LAN setup.',
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

    final message =
        body['error']?.toString() ?? 'Invite backend request failed.';
    throw StateError('$message (${response.statusCode})');
  }
}

class InviteRecord {
  const InviteRecord({
    required this.inviteId,
    required this.senderId,
    required this.senderLabel,
    required this.senderStreak,
    required this.dayIndex,
    required this.status,
    required this.createdAt,
    required this.inviteUrl,
    this.acceptedBy,
    this.acceptedAt,
  });

  final String inviteId;
  final String senderId;
  final String senderLabel;
  final int senderStreak;
  final int dayIndex;
  final String status;
  final DateTime createdAt;
  final String inviteUrl;
  final String? acceptedBy;
  final DateTime? acceptedAt;

  factory InviteRecord.fromJson(Map<String, dynamic> json) {
    return InviteRecord(
      inviteId: (json['invite_id'] as String?) ?? '',
      senderId: (json['sender_id'] as String?) ?? '',
      senderLabel: (json['sender_label'] as String?) ?? 'Bir arkadaşın',
      senderStreak: (json['sender_streak'] as num?)?.toInt() ?? 0,
      dayIndex: (json['day_index'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      inviteUrl: (json['invite_url'] as String?) ?? '',
      acceptedBy: json['accepted_by'] as String?,
      acceptedAt: DateTime.tryParse(json['accepted_at']?.toString() ?? ''),
    );
  }
}

class ViralMetricsSnapshot {
  const ViralMetricsSnapshot({
    required this.totalSent,
    required this.totalAccepted,
    required this.viralCoefficient,
    required this.updatedAt,
  });

  final int totalSent;
  final int totalAccepted;
  final double viralCoefficient;
  final DateTime? updatedAt;

  factory ViralMetricsSnapshot.fromJson(Map<String, dynamic> json) {
    return ViralMetricsSnapshot(
      totalSent: (json['total_sent'] as num?)?.toInt() ?? 0,
      totalAccepted: (json['total_accepted'] as num?)?.toInt() ?? 0,
      viralCoefficient: (json['viral_coefficient'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}
