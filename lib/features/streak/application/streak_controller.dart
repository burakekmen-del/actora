import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firestore_service.dart';

final streakProvider = StateNotifierProvider<StreakController, int>(
  (ref) => StreakController(),
);

final day4CliffPreventionReadyProvider = Provider<bool>((ref) {
  final streak = ref.watch(streakProvider);
  return streak == 3;
});

class StreakController extends StateNotifier<int> {
  StreakController() : super(0);

  void increment() {
    state = state + 1;
  }

  void setStreak(int value) {
    state = value < 0 ? 0 : value;
  }

  Future<void> hydrateFromServer({
    required FirestoreService firestoreService,
  }) async {
    final streak = await firestoreService.getStreakCount();
    setStreak(streak);
  }

  Future<DailyStreakCompletionResult> completeDailyTask({
    required FirestoreService firestoreService,
  }) async {
    final result = await firestoreService.completeDailyTaskAndUpdateStreak();
    setStreak(result.updatedStreakCount);
    return result;
  }

  void reset() {
    state = 0;
  }

  Future<MissedTaskOutcome> processMissedTask({
    required FirestoreService firestoreService,
  }) async {
    final result = await firestoreService.resolveMissedTask();

    if (result.freezeUsed) {
      return MissedTaskOutcome.freezeUsed(isPremium: result.isPremium);
    }

    if (result.streakReset) {
      reset();
      return const MissedTaskOutcome.streakReset();
    }

    return const MissedTaskOutcome.streakReset();
  }
}

class MissedTaskOutcome {
  const MissedTaskOutcome._({
    required this.type,
    this.isPremium = false,
  });

  const MissedTaskOutcome.freezeUsed({required bool isPremium})
      : this._(type: MissedTaskOutcomeType.freezeUsed, isPremium: isPremium);

  const MissedTaskOutcome.streakReset()
      : this._(type: MissedTaskOutcomeType.streakReset);

  final MissedTaskOutcomeType type;
  final bool isPremium;
}

enum MissedTaskOutcomeType {
  freezeUsed,
  streakReset,
}
