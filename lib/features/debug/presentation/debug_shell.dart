import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/debug_controller.dart';
import '../services/shake_service.dart';
import 'debug_panel_screen.dart';
import 'fail_overlay.dart';

class DebugShell extends ConsumerStatefulWidget {
  const DebugShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DebugShell> createState() => _DebugShellState();
}

class _DebugShellState extends ConsumerState<DebugShell> {
  ShakeService? _shakeService;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _shakeService = ShakeService(onShake: _openDebugPanel);
      _shakeService?.start();
    }
  }

  @override
  void dispose() {
    _shakeService?.stop();
    super.dispose();
  }

  void _openDebugPanel() {
    if (!mounted || !kDebugMode) return;
    final debugState = ref.read(debugControllerProvider);
    if (debugState.isDebugPanelOpen) return;

    ref.read(debugControllerProvider.notifier).setDebugPanelOpen(true);
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => const DebugPanelScreen(),
      ),
    )
        .whenComplete(() {
      if (mounted) {
        ref.read(debugControllerProvider.notifier).setDebugPanelOpen(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return widget.child;
    }

    final debugState = ref.watch(debugControllerProvider);
    final shouldShowOverlay =
        debugState.showFailOverlay && debugState.lastTestResult != null;

    return Stack(
      children: [
        widget.child,
        if (shouldShowOverlay)
          FailOverlay(
            result: debugState.lastTestResult!,
            onDismiss: () {
              ref.read(debugControllerProvider.notifier).dismissFailOverlay();
            },
            onOpen: () {
              ref.read(debugControllerProvider.notifier).dismissFailOverlay();
              _openDebugPanel();
            },
          ),
      ],
    );
  }
}
