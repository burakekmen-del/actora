import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auto_test_runner.dart';
import '../application/debug_controller.dart';
import '../domain/auto_test_result.dart';
import '../domain/auto_test_step.dart';

class DebugPanelScreen extends ConsumerStatefulWidget {
  const DebugPanelScreen({super.key});

  @override
  ConsumerState<DebugPanelScreen> createState() => _DebugPanelScreenState();
}

class _DebugPanelScreenState extends ConsumerState<DebugPanelScreen> {
  bool _running = false;

  List<_GroupBucket> _groupSteps(List<AutoTestStep> steps) {
    const order = <String>['Core', 'Identity', 'Evolution', 'Guard'];
    final buckets = <String, List<AutoTestStep>>{};
    for (final step in steps) {
      buckets.putIfAbsent(step.category, () => <AutoTestStep>[]).add(step);
    }

    final grouped = <_GroupBucket>[];
    for (final key in order) {
      final items = buckets[key];
      if (items != null && items.isNotEmpty) {
        grouped.add(_GroupBucket(name: key, steps: items));
      }
    }
    grouped.sort((left, right) {
      final leftFailRate = left.failCount / left.steps.length;
      final rightFailRate = right.failCount / right.steps.length;
      final failRateCompare = rightFailRate.compareTo(leftFailRate);
      if (failRateCompare != 0) {
        return failRateCompare;
      }

      final failCountCompare = right.failCount.compareTo(left.failCount);
      if (failCountCompare != 0) {
        return failCountCompare;
      }

      return left.name.compareTo(right.name);
    });
    return grouped;
  }

  Widget _buildGroupedResults(AutoTestResult result) {
    final groups = _groupSteps(result.steps);
    return ListView.builder(
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final success = group.successCount;
        final fail = group.failCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${group.name} • $success/${group.steps.length}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (fail > 0)
                Text(
                  'Fail: $fail',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
              const SizedBox(height: 4),
              ...group.steps.map((step) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    step.success ? Icons.check_circle : Icons.cancel,
                    color: step.success ? Colors.green : Colors.red,
                  ),
                  title: Text(step.name),
                  subtitle: step.error == null
                      ? Text('${step.duration.inMilliseconds} ms')
                      : Text(step.error!),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _runTests() async {
    if (_running || !kDebugMode) return;
    setState(() {
      _running = true;
    });

    try {
      final runner = ref.read(autoTestRunnerProvider);
      final result = await runner.runFullTest();
      ref.read(debugControllerProvider.notifier).setLastTestResult(result);
    } finally {
      if (mounted) {
        setState(() {
          _running = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final debugState = ref.watch(debugControllerProvider);
    final result = debugState.lastTestResult;

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Panel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _running ? null : _runTests,
              child: Text(_running ? 'Running...' : 'Run Full Test'),
            ),
            const SizedBox(height: 16),
            if (!kDebugMode)
              const Text('Debug mode kapali oldugu icin bu ekran pasif.'),
            if (result != null) ...[
              Text(
                'AUTO TEST RESULT',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text('Total: ${result.totalSteps}'),
              Text('Success: ${result.successCount}'),
              Text('Failed: ${result.failCount}'),
              const SizedBox(height: 12),
              Expanded(child: _buildGroupedResults(result)),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupBucket {
  const _GroupBucket({required this.name, required this.steps});

  final String name;
  final List<AutoTestStep> steps;

  int get successCount => steps.where((step) => step.success).length;

  int get failCount => steps.length - successCount;
}
