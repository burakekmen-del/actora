/// 🔥 FRIEND COMPETITION SYSTEM
///
/// Powers:
/// - Streak comparison display
/// - Competitive notifications
/// - Viral loop retention
/// - Multi-player experience
///
/// Key insight: Users don't want to fall behind FRIENDS specifically
/// (not random strangers). Personal competition = addiction.

class FriendCompetition {
  /// Unique identifier for this friend relationship
  final String competitionId;

  /// User ID of the person viewing
  final String userId;

  /// User ID of the competing friend
  final String friendId;

  /// Friend's display name
  final String friendName;

  /// Friend's current streak
  final int friendStreak;

  /// User's current streak
  final int userStreak;

  /// Day the friend joined (for calculation)
  final DateTime friendJoinedAt;

  /// Day the user joined
  final DateTime userJoinedAt;

  /// Last sync time (when streaks were updated)
  final DateTime lastSyncAt;

  /// Status of friendship: 'active', 'completed', 'dormant'
  final String status;

  /// Total days user has been ahead (cumulative)
  final int daysAhead;

  /// Total days friend has been ahead (cumulative)
  final int daysAheadFriend;

  const FriendCompetition({
    required this.competitionId,
    required this.userId,
    required this.friendId,
    required this.friendName,
    required this.friendStreak,
    required this.userStreak,
    required this.friendJoinedAt,
    required this.userJoinedAt,
    required this.lastSyncAt,
    this.status = 'active',
    this.daysAhead = 0,
    this.daysAheadFriend = 0,
  });

  /// Returns the streak difference (negative = user is behind)
  int get streakDifference => userStreak - friendStreak;

  /// Returns true if friend is ahead
  bool get friendIsAhead => friendStreak > userStreak;

  /// Returns true if user is ahead
  bool get userIsAhead => userStreak > friendStreak;

  /// Returns true if equal streaks
  bool get isEqual => userStreak == friendStreak;

  /// Get competitive status message
  String get competitiveStatus {
    final diff = streakDifference.abs();
    if (isEqual) return 'Tied 🤝';
    if (userIsAhead) return 'Leading by $diff 👑';
    return 'Down by $diff 🎯';
  }

  /// Get motivation message based on competitive state
  String get motivationMessage {
    if (friendIsAhead) {
      return 'Time to catch up with $friendName';
    } else if (userIsAhead) {
      return 'Can you stay ahead of $friendName?';
    } else {
      return 'Who\'s going to break the tie?';
    }
  }

  /// Convert to Firestore JSON
  Map<String, dynamic> toFirestore() {
    return {
      'competitionId': competitionId,
      'userId': userId,
      'friendId': friendId,
      'friendName': friendName,
      'friendStreak': friendStreak,
      'userStreak': userStreak,
      'friendJoinedAt': friendJoinedAt,
      'userJoinedAt': userJoinedAt,
      'lastSyncAt': lastSyncAt,
      'status': status,
      'daysAhead': daysAhead,
      'daysAheadFriend': daysAheadFriend,
    };
  }

  /// Create from Firestore JSON
  factory FriendCompetition.fromFirestore(Map<String, dynamic> data) {
    return FriendCompetition(
      competitionId: data['competitionId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      friendId: data['friendId'] as String? ?? '',
      friendName: data['friendName'] as String? ?? '',
      friendStreak: data['friendStreak'] as int? ?? 0,
      userStreak: data['userStreak'] as int? ?? 0,
      friendJoinedAt:
          (data['friendJoinedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      userJoinedAt:
          (data['userJoinedAt'] as dynamic)?.toDate() ?? DateTime.now(),
      lastSyncAt: (data['lastSyncAt'] as dynamic)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'active',
      daysAhead: data['daysAhead'] as int? ?? 0,
      daysAheadFriend: data['daysAheadFriend'] as int? ?? 0,
    );
  }

  /// Copy with updates
  FriendCompetition copyWith({
    String? competitionId,
    String? userId,
    String? friendId,
    String? friendName,
    int? friendStreak,
    int? userStreak,
    DateTime? friendJoinedAt,
    DateTime? userJoinedAt,
    DateTime? lastSyncAt,
    String? status,
    int? daysAhead,
    int? daysAheadFriend,
  }) {
    return FriendCompetition(
      competitionId: competitionId ?? this.competitionId,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendStreak: friendStreak ?? this.friendStreak,
      userStreak: userStreak ?? this.userStreak,
      friendJoinedAt: friendJoinedAt ?? this.friendJoinedAt,
      userJoinedAt: userJoinedAt ?? this.userJoinedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      status: status ?? this.status,
      daysAhead: daysAhead ?? this.daysAhead,
      daysAheadFriend: daysAheadFriend ?? this.daysAheadFriend,
    );
  }
}

/// 🎯 FRIEND COMPARISON LIST - Shows all active competitions
class FriendComparisonList {
  final String userId;
  final List<FriendCompetition> competitions;
  final DateTime lastUpdatedAt;

  const FriendComparisonList({
    required this.userId,
    required this.competitions,
    required this.lastUpdatedAt,
  });

  /// Get friend who is MOST ahead (top competitor)
  FriendCompetition? get topCompetitor {
    if (competitions.isEmpty) return null;
    return competitions.reduce((a, b) =>
        (b.friendStreak - b.userStreak) > (a.friendStreak - a.userStreak)
            ? b
            : a);
  }

  /// Get total number of friends ahead
  int get friendsAhead => competitions.where((c) => c.friendIsAhead).length;

  /// Get total number of friends behind
  int get friendsBehind => competitions.where((c) => c.userIsAhead).length;

  /// Get average of all friend streaks (for benchmarking)
  double get averageFriendStreak {
    if (competitions.isEmpty) return 0;
    return competitions.fold<int>(
          0,
          (sum, competition) => sum + competition.friendStreak,
        ) /
        competitions.length;
  }

  /// Get all friends ahead, sorted by how far ahead
  List<FriendCompetition> get friendsAheadSorted {
    final ahead = competitions.where((c) => c.friendIsAhead).toList();
    ahead.sort((a, b) => (b.friendStreak - b.userStreak)
        .compareTo(a.friendStreak - a.userStreak));
    return ahead;
  }
}
