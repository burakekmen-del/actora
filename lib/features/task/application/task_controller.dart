import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/app_log.dart';
import '../domain/task.dart';

final taskControllerProvider = StateNotifierProvider<TaskController, Task?>(
  (ref) => TaskController(),
);

class TaskController extends StateNotifier<Task?> {
  TaskController() : super(null);

  void setTask(Task task) {
    AppLog.state('task.set', details: {
      'title': task.title,
      'status': task.status.name,
      'minutes': task.estimatedMinutes,
    });
    state = task;
  }

  bool startTask() {
    if (state == null) {
      AppLog.blocked('task.start', 'no_task');
      return false;
    }

    if (state!.status != TaskStatus.idle) {
      AppLog.blocked('task.start', 'invalid_status',
          details: {'status': state!.status.name});
      return false;
    }

    AppLog.tap('task.start', details: {'title': state!.title});
    state = state!.copyWith(status: TaskStatus.inProgress);
    AppLog.state('task.started', details: {'title': state!.title});
    return true;
  }

  bool completeTask() {
    if (state == null) {
      AppLog.blocked('task.complete', 'no_task');
      return false;
    }

    if (state!.status != TaskStatus.inProgress) {
      AppLog.blocked('task.complete', 'invalid_status',
          details: {'status': state!.status.name});
      return false;
    }

    AppLog.tap('task.complete', details: {'title': state!.title});
    state = state!.copyWith(status: TaskStatus.completed);
    AppLog.state('task.completed', details: {'title': state!.title});
    return true;
  }

  bool deferTask() {
    if (state == null) {
      AppLog.blocked('task.defer', 'no_task');
      return false;
    }

    final canDefer = state!.status == TaskStatus.idle ||
        state!.status == TaskStatus.inProgress;
    if (!canDefer) {
      AppLog.blocked('task.defer', 'invalid_status',
          details: {'status': state!.status.name});
      return false;
    }

    AppLog.tap('task.defer', details: {'title': state!.title});
    state = state!.copyWith(status: TaskStatus.deferred);
    AppLog.state('task.deferred', details: {'title': state!.title});
    return true;
  }

  bool cannotDoTask() {
    if (state == null) {
      AppLog.blocked('task.cannot_do', 'no_task');
      return false;
    }

    final canCannotDo = state!.status == TaskStatus.idle ||
        state!.status == TaskStatus.inProgress;
    if (!canCannotDo) {
      AppLog.blocked('task.cannot_do', 'invalid_status',
          details: {'status': state!.status.name});
      return false;
    }

    AppLog.tap('task.cannot_do', details: {'title': state!.title});
    state = state!.copyWith(status: TaskStatus.cannotDo);
    AppLog.state('task.cannot_do_applied', details: {'title': state!.title});
    return true;
  }

  void clearTask() {
    if (state == null) return;
    AppLog.state('task.cleared', details: {'title': state!.title});
    state = null;
  }
}
