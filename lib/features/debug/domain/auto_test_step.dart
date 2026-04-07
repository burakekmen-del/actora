class AutoTestStep {
  const AutoTestStep({
    required this.name,
    required this.success,
    required this.duration,
    this.error,
  });

  final String name;
  final bool success;
  final Duration duration;
  final String? error;

  String get category {
    if (name.startsWith('identity_') || name.startsWith('weekly_progress_')) {
      return 'Identity';
    }

    if (name.startsWith('task_evolution_')) {
      return 'Evolution';
    }

    if (name.contains('cannot_do') ||
        name.contains('missed_day') ||
        name.contains('freeze')) {
      return 'Guard';
    }

    return 'Core';
  }
}
