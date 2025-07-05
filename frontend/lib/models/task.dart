import 'package:frontend/utils/value_wrapper.dart';

class Task {
  final int? id;
  final String description;
  final int projectId;
  final DateTime? dueDatetime;
  final List<String> labels;
  final int order;
  final DateTime? completedAt;
  final List<DateTime> reminders;

  Task({
    this.id,
    required this.description,
    required this.projectId,
    this.dueDatetime,
    required this.labels,
    required this.order,
    this.completedAt,
    this.reminders = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      description: json['description'],
      projectId: json['project_id'],
      dueDatetime: json['due_datetime'] != null
          ? DateTime.parse(json['due_datetime'])
          : (json['due_date'] != null
              ? DateTime.parse(json['due_date'])
              : null),
      labels: List<String>.from(json['labels'] ?? []),
      order: json['order'],
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      reminders:
          (json['reminders'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'description': description,
      'project_id': projectId,
      'labels': labels,
      'order': order,
      'completed_at': completedAt?.toIso8601String(),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
    };

    if (dueDatetime != null) {
      if (dueDatetime!.hour == 0 &&
          dueDatetime!.minute == 0 &&
          dueDatetime!.second == 0 &&
          dueDatetime!.millisecond == 0 &&
          dueDatetime!.microsecond == 0) {
        data['due_date'] =
            "${dueDatetime!.year.toString().padLeft(4, '0')}-${dueDatetime!.month.toString().padLeft(2, '0')}-${dueDatetime!.day.toString().padLeft(2, '0')}";
      } else {
        data['due_datetime'] = dueDatetime!.toIso8601String();
      }
    }

    return data;
  }

  Task copyWith({
    int? id,
    String? description,
    int? projectId,
    ValueWrapper<DateTime?>? dueDatetime,
    List<String>? labels,
    int? order,
    ValueWrapper<DateTime?>? completedAt,
    List<DateTime>? reminders,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      dueDatetime: dueDatetime != null ? dueDatetime.value : this.dueDatetime,
      labels: labels ?? this.labels,
      order: order ?? this.order,
      completedAt: completedAt != null ? completedAt.value : this.completedAt,
      reminders: reminders ?? this.reminders,
    );
  }
}

