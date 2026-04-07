import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/auto_test_result.dart';

class FailOverlay extends StatefulWidget {
  const FailOverlay({
    super.key,
    required this.result,
    required this.onOpen,
    required this.onDismiss,
  });

  final AutoTestResult result;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  State<FailOverlay> createState() => _FailOverlayState();
}

class _FailOverlayState extends State<FailOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 5), widget.onDismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Dismissible(
          key: const ValueKey('auto-test-fail-overlay'),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Test Failed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.result.failCount} adim basarisiz',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpen,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('OPEN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
