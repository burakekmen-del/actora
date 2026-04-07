import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../task/application/task_controller.dart';
import '../../task/domain/task.dart';

final todayTaskProvider = Provider<Task?>((ref) {
  return ref.watch(taskControllerProvider);
});
