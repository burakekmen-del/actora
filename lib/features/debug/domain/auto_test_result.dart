import 'auto_test_step.dart';

class AutoTestResult {
  const AutoTestResult({
    required this.steps,
    required this.finishedAt,
  });

  final List<AutoTestStep> steps;
  final DateTime finishedAt;

  int get totalSteps => steps.length;

  int get successCount => steps.where((step) => step.success).length;

  int get failCount => steps.where((step) => !step.success).length;

  List<AutoTestStep> get failedSteps =>
      steps.where((step) => !step.success).toList(growable: false);
}
