enum ExecutionDayState {
  noTaskToday,
  activeTask,
  completedToday,
  missedToday,
}

class ExecutionDaySnapshot {
  const ExecutionDaySnapshot({
    required this.state,
    this.previousStreak,
  });

  final ExecutionDayState state;
  final int? previousStreak;
}
