import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auto_test_result.dart';

@immutable
class DebugState {
  const DebugState({
    this.isDebugPanelOpen = false,
    this.lastTestResult,
    this.showFailOverlay = false,
  });

  final bool isDebugPanelOpen;
  final AutoTestResult? lastTestResult;
  final bool showFailOverlay;

  DebugState copyWith({
    bool? isDebugPanelOpen,
    AutoTestResult? lastTestResult,
    bool? showFailOverlay,
    bool clearResult = false,
  }) {
    return DebugState(
      isDebugPanelOpen: isDebugPanelOpen ?? this.isDebugPanelOpen,
      lastTestResult:
          clearResult ? null : (lastTestResult ?? this.lastTestResult),
      showFailOverlay: showFailOverlay ?? this.showFailOverlay,
    );
  }
}

class DebugController extends StateNotifier<DebugState> {
  DebugController() : super(const DebugState());

  void setDebugPanelOpen(bool isOpen) {
    state = state.copyWith(isDebugPanelOpen: isOpen);
  }

  void setLastTestResult(AutoTestResult result) {
    state = state.copyWith(
      lastTestResult: result,
      showFailOverlay: result.failCount > 0,
    );
  }

  void dismissFailOverlay() {
    state = state.copyWith(showFailOverlay: false);
  }
}

final debugControllerProvider =
    StateNotifierProvider<DebugController, DebugState>(
  (ref) => DebugController(),
);
