import 'package:frontend/utils/value_wrapper.dart';

class Task {
  final int? id;
  final String description;
  final int projectId;
  final DateTime? dueDate;
  final List<String> labels;
  final int order;
  final DateTime? completedAt;

  Task({
    this.id,
    required this.description,
    required this.projectId,
    this.dueDate,
    required this.labels,
    required this.order,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      description: json['description'],
      projectId: json['project_id'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      labels: List<String>.from(json['labels'] ?? []),
      order: json['order'],
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'project_id': projectId,
      'due_date': dueDate?.toIso8601String(),
      'labels': labels,
      'order': order,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  Task copyWith({
    int? id,
    String? description,
    int? projectId,
    ValueWrapper<DateTime?>? dueDate,
    List<String>? labels,
    int? order,
    ValueWrapper<DateTime?>? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      dueDate: dueDate != null ? dueDate.value : this.dueDate,
      labels: labels ?? this.labels,
      order: order ?? this.order,
      completedAt: completedAt != null ? completedAt.value : this.completedAt,
    );
  }
}