/// Represents an incoming invite challenge from another user
class InviteChallenge {
  const InviteChallenge({
    required this.inviteId,
    required this.senderId,
    required this.senderLabel,
    required this.senderStreak,
    required this.senderDayIndex,
    required this.createdAt,
  });

  final String inviteId;
  final String senderId;
  final String senderLabel;
  final int senderStreak;
  final int senderDayIndex;
  final DateTime createdAt;

  /// Whether this invite is still pending (not accepted yet)
  bool get isPending => true; // Status would come from API

  /// Human-readable description of the challenge
  String get challengeDescription =>
      '$senderLabel is on a $senderStreak-day streak and invites you to join!';

  factory InviteChallenge.fromJson(Map<String, dynamic> json) {
    return InviteChallenge(
      inviteId: json['invite_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderLabel: json['sender_label'] as String? ?? 'Biri',
      senderStreak: (json['sender_streak'] as num?)?.toInt() ?? 0,
      senderDayIndex: (json['day_index'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'invite_id': inviteId,
        'sender_id': senderId,
        'sender_label': senderLabel,
        'sender_streak': senderStreak,
        'day_index': senderDayIndex,
        'created_at': createdAt.toIso8601String(),
      };

  /// Get emoji for streak level
  String getStreakEmoji() {
    if (senderStreak >= 30) return '🔥';
    if (senderStreak >= 15) return '💪';
    if (senderStreak >= 7) return '⭐';
    if (senderStreak >= 1) return '🚀';
    return '🎯';
  }
}
