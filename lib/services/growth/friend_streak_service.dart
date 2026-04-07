import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firestore_service.dart';

final friendStreakServiceProvider = Provider<FriendStreakService>(
  (ref) => FriendStreakService(ref.read(firestoreServiceProvider)),
);

class FriendStreakService {
  FriendStreakService(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<FriendStreakState?> getActiveFriendStreak() {
    return _firestoreService.loadFriendStreakState();
  }

  Future<void> bindFromChallenge({required String friendId}) {
    return _firestoreService.bindFriendStreak(friendId: friendId);
  }

  Future<FriendStreakState?> markDailyCompletion({required int streak}) {
    return _firestoreService.updateFriendStreakAfterUserCompletion(
        streak: streak);
  }
}
