import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/logging/app_log.dart';
import '../../features/share/domain/friend_competition.dart';

final friendCompetitionProvider = Provider<FriendCompetitionService>(
  (ref) => FriendCompetitionService(),
);

/// 🔥 FRIEND COMPETITION SERVICE
///
/// Handles all competitive tracking via HTTP API calls
/// - Create competition when invite accepted
/// - Sync friend streaks daily
/// - Track comparative metrics
/// - Trigger retention notifications
class FriendCompetitionService {
  FriendCompetitionService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _requestTimeout = Duration(seconds: 8);

  static const String _baseUrl = String.fromEnvironment(
    'ACTORA_VIRAL_API_BASE_URL',
    defaultValue: 'https://invite.hatirlatbana.com',
  );

  String _apiUrlFor(String path) => '$_baseUrl/api/v1/$path';

  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      final response =
          await _client.get(Uri.parse(url)).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLog.error(
        'viral.api_get_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postJson(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(body),
          )
          .timeout(_requestTimeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'API error ${response.statusCode}: ${response.body}',
        );
      }

      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      AppLog.error(
        'viral.api_post_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Create a new competition when invite is accepted
  Future<FriendCompetition> createCompetition({
    required String userId,
    required String friendId,
    required String friendName,
    required int userCurrentStreak,
    required int friendCurrentStreak,
  }) async {
    try {
      final response = await _postJson(
        _apiUrlFor('competitions/create'),
        body: {
          'user_id': userId,
          'friend_id': friendId,
          'friend_name': friendName,
          'user_streak': userCurrentStreak,
          'friend_streak': friendCurrentStreak,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      final competition = FriendCompetition(
        competitionId: response['competition_id'] as String? ?? '',
        userId: userId,
        friendId: friendId,
        friendName: friendName,
        userStreak: userCurrentStreak,
        friendStreak: friendCurrentStreak,
        userJoinedAt: DateTime.now(),
        friendJoinedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
        status: 'active',
      );

      AppLog.action('viral.competition_created', details: {
        'user_id': userId,
        'friend_id': friendId,
        'friend_name': friendName,
      });

      return competition;
    } catch (e) {
      AppLog.error(
        'viral.competition_creation_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Get all active competitions for user
  Future<FriendComparisonList> getActiveCompetitions(String userId) async {
    try {
      final response = await _getJson(
        _apiUrlFor('users/$userId/competitions/active'),
      );

      final competitionsData = response['competitions'] as List? ?? [];
      final competitions = competitionsData
          .cast<Map<String, dynamic>>()
          .map((data) => FriendCompetition.fromFirestore(data))
          .toList();

      return FriendComparisonList(
        userId: userId,
        competitions: competitions,
        lastUpdatedAt: DateTime.now(),
      );
    } catch (e) {
      AppLog.error(
        'viral.fetch_competitions_failed',
        e,
        StackTrace.current,
      );
      return FriendComparisonList(
        userId: userId,
        competitions: [],
        lastUpdatedAt: DateTime.now(),
      );
    }
  }

  /// Update user streak in a competition
  Future<void> updateCompetitionStreak({
    required String userId,
    required String competitionId,
    required int newUserStreak,
  }) async {
    try {
      await _postJson(
        _apiUrlFor('competitions/$competitionId/update_streak'),
        body: {
          'user_id': userId,
          'new_streak': newUserStreak,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );

      AppLog.action('viral.competition_streak_updated', details: {
        'competition_id': competitionId,
        'user_id': userId,
        'new_streak': newUserStreak,
      });
    } catch (e) {
      AppLog.error(
        'viral.competition_streak_update_failed',
        e,
        StackTrace.current,
      );
      rethrow;
    }
  }

  /// Sync friend's current streak
  Future<void> syncFriendStreak({
    required String userId,
    required String friendId,
    required int friendNewStreak,
  }) async {
    try {
      await _postJson(
        _apiUrlFor('competitions/sync_friend_streak'),
        body: {
          'user_id': userId,
          'friend_id': friendId,
          'friend_new_streak': friendNewStreak,
          'synced_at': DateTime.now().toIso8601String(),
        },
      );

      AppLog.action('viral.friend_streak_synced', details: {
        'user_id': userId,
        'friend_id': friendId,
        'friend_new_streak': friendNewStreak,
      });
    } catch (e) {
      AppLog.error(
        'viral.friend_streak_sync_failed',
        e,
        StackTrace.current,
      );
      // Non-critical, don't rethrow
    }
  }

  /// Get top competitor (friend most ahead)
  Future<FriendCompetition?> getTopCompetitor(String userId) async {
    try {
      final competitions = await getActiveCompetitions(userId);
      return competitions.topCompetitor;
    } catch (e) {
      AppLog.error(
        'viral.top_competitor_failed',
        e,
        StackTrace.current,
      );
      return null;
    }
  }

  /// Get statistics for competitive dashboard
  Future<Map<String, dynamic>> getCompetitionStats(String userId) async {
    try {
      return await _getJson(
        _apiUrlFor('users/$userId/competitions/stats'),
      );
    } catch (e) {
      AppLog.error(
        'viral.competition_stats_failed',
        e,
        StackTrace.current,
      );
      return {
        'totalCompetitions': 0,
        'activeCompetitions': 0,
        'completedCompetitions': 0,
      };
    }
  }

  /// Generate competitive notification
  Future<String?> generateCompetitiveNotification(String userId) async {
    try {
      final topCompetitor = await getTopCompetitor(userId);
      if (topCompetitor == null || !topCompetitor.friendIsAhead) {
        return null;
      }

      final gap = topCompetitor.friendStreak - topCompetitor.userStreak;
      return '⚡ ${topCompetitor.friendName} is $gap days ahead. Catch them!';
    } catch (e) {
      AppLog.error(
        'viral.notification_generation_failed',
        e,
        StackTrace.current,
      );
      return null;
    }
  }
}
