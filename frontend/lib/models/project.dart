class Project {
  final int? id;
  final String name;
  final int order;
  final bool isInbox;
  final String color;

  Project({
    this.id,
    required this.name,
    required this.order,
    this.isInbox = false,
    required this.color,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      name: json['name'],
      order: json['order'],
      isInbox: json['is_inbox'] ?? false,
      color: json['color'] ?? 'grey',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'is_inbox': isInbox,
      'color': color,
    };
  }

  Project copyWith({
    int? id,
    String? name,
    int? order,
    bool? isInbox,
    String? color,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isInbox: isInbox ?? this.isInbox,
      color: color ?? this.color,
    );
  }
}
