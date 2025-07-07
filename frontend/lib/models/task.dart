import 'package:dimaist/utils/value_wrapper.dart';

class Task {
  final int? id;
  final String description;
  final int projectId;
  final DateTime? dueDate;
  final DateTime? dueDatetime;
  final List<String> labels;
  final int order;
  final DateTime? completedAt;
  final List<DateTime> reminders;
  final String? recurrence;

  Task({
    this.id,
    required this.description,
    required this.projectId,
    this.dueDate,
    this.dueDatetime,
    required this.labels,
    required this.order,
    this.completedAt,
    this.reminders = const [],
    this.recurrence,
  }) : assert(
         dueDate == null || dueDatetime == null,
         'Cannot have both dueDate and dueDatetime',
       );

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      description: json['description'],
      projectId: json['project_id'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      dueDatetime: json['due_datetime'] != null
          ? DateTime.parse(json['due_datetime'])
          : null,
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
      recurrence: json['recurrence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'project_id': projectId,
      'due_date': dueDate?.toIso8601String(),
      'due_datetime': dueDatetime?.toIso8601String(),
      'labels': labels,
      'order': order,
      'completed_at': completedAt?.toIso8601String(),
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'recurrence': recurrence,
    };
  }

  Task copyWith({
    int? id,
    String? description,
    int? projectId,
    ValueWrapper<DateTime?>? dueDate,
    ValueWrapper<DateTime?>? dueDatetime,
    List<String>? labels,
    int? order,
    ValueWrapper<DateTime?>? completedAt,
    List<DateTime>? reminders,
    String? recurrence,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      dueDate: dueDate != null ? dueDate.value : this.dueDate,
      dueDatetime: dueDatetime != null ? dueDatetime.value : this.dueDatetime,
      labels: labels ?? this.labels,
      order: order ?? this.order,
      completedAt: completedAt != null ? completedAt.value : this.completedAt,
      reminders: reminders ?? this.reminders,
      recurrence: recurrence ?? this.recurrence,
    );
  }
}
