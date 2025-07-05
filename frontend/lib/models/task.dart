class Task {
  final int? id;
  final String description;
  final int projectId;
  final DateTime? dueDate;
  final List<String> labels;
  final int order;

  Task({
    this.id,
    required this.description,
    required this.projectId,
    this.dueDate,
    required this.labels,
    required this.order,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      description: json['description'],
      projectId: json['project_id'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      labels: List<String>.from(json['labels'] ?? []),
      order: json['order'],
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
    };
  }
}