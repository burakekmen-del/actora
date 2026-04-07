enum TaskStatus { idle, inProgress, completed, deferred, cannotDo }

enum TaskType { hydration, breathing, cleanup, planning, focus }

TaskStatus _taskStatusFromString(String? value) {
  return TaskStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => TaskStatus.idle,
  );
}

TaskType _taskTypeFromString(String? value) {
  return TaskType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => TaskType.focus,
  );
}

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.type,
    required this.estimatedMinutes,
    required this.isFirstTask,
  });

  final String id;
  final String title;
  final TaskStatus status;
  final DateTime createdAt;
  final TaskType type;
  final int estimatedMinutes;
  final bool isFirstTask;

  Task copyWith({
    String? id,
    String? title,
    TaskStatus? status,
    DateTime? createdAt,
    TaskType? type,
    int? estimatedMinutes,
    bool? isFirstTask,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isFirstTask: isFirstTask ?? this.isFirstTask,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'type': type.name,
      'estimatedMinutes': estimatedMinutes,
      'isFirstTask': isFirstTask,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    final createdAt = createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now();

    return Task(
      id: (map['id'] as String?) ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: (map['title'] as String?) ?? 'Task',
      status: _taskStatusFromString(map['status'] as String?),
      createdAt: createdAt,
      type: _taskTypeFromString(map['type'] as String?),
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 5,
      isFirstTask: map['isFirstTask'] == true,
    );
  }
}
