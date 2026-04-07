import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/firebase/firestore_service.dart';
import '../domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.read(firestoreServiceProvider)),
);

class TaskRepository {
  TaskRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Future<void> saveTask({
    required String userId,
    required Task task,
  }) {
    return _firestoreService.saveTask(userId: userId, task: task);
  }
}
