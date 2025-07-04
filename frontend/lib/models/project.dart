class Project {
  final int? id;
  final String name;
  final String color;
  final int order;

  Project({
    this.id,
    required this.name,
    required this.color,
    required this.order,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      color: json['color'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'order': order,
    };
  }
}