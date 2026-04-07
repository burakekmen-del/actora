import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.name,
    required this.streak,
    this.isCurrentUser = false,
  });

  final String name;
  final int streak;
  final bool isCurrentUser;
}

class LeaderboardSnapshot {
  const LeaderboardSnapshot({
    required this.entries,
    required this.userRank,
    required this.topStreak,
  });

  final List<LeaderboardEntry> entries;
  final int userRank;
  final int topStreak;
}

final leaderboardServiceProvider = Provider<LeaderboardService>(
  (ref) => const LeaderboardService(),
);

class LeaderboardService {
  const LeaderboardService();

  static const List<String> _names = <String>[
    'Alex',
    'Maya',
    'Eren',
    'Lina',
    'Noah',
    'Ayla',
    'Arda',
    'Iris',
    'Mert',
    'Sena',
    'Nora',
    'Kaan',
    'Rina',
    'Deniz',
    'Milo',
    'Sofia',
    'Atlas',
    'Lara',
    'Ece',
    'Leo',
  ];

  LeaderboardSnapshot buildForStreak({
    required int userStreak,
    required int daySeed,
  }) {
    final seed = daySeed.abs() + 17;
    final fake = <LeaderboardEntry>[];

    for (var i = 0; i < 20; i++) {
      final score = 3 + ((seed * (i + 11)) % 19);
      fake.add(LeaderboardEntry(name: _names[i], streak: score));
    }

    fake.sort((a, b) => b.streak.compareTo(a.streak));

    final adjustedUserStreak = userStreak < 1 ? 1 : userStreak;
    var inserted = false;
    final withUser = <LeaderboardEntry>[];

    for (var i = 0; i < fake.length; i++) {
      if (!inserted && adjustedUserStreak >= fake[i].streak) {
        withUser.add(
          LeaderboardEntry(
            name: 'You',
            streak: adjustedUserStreak,
            isCurrentUser: true,
          ),
        );
        inserted = true;
      }
      if (withUser.length < 20) {
        withUser.add(fake[i]);
      }
    }

    if (!inserted && withUser.length < 20) {
      withUser.add(
        LeaderboardEntry(
          name: 'You',
          streak: adjustedUserStreak,
          isCurrentUser: true,
        ),
      );
    }

    if (withUser.length > 20) {
      withUser.removeRange(20, withUser.length);
    }

    final rank = withUser.indexWhere((e) => e.isCurrentUser) + 1;
    return LeaderboardSnapshot(
      entries: withUser,
      userRank: rank <= 0 ? 20 : rank,
      topStreak: withUser.isEmpty ? adjustedUserStreak : withUser.first.streak,
    );
  }
}
