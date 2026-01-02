class Task {
  final int? id;
  final String name;
  final String shortName;
  final String color;
  final bool isActive;
  final int orderIndex;

  Task({
    this.id,
    required this.name,
    String? shortName,
    required this.color,
    this.isActive = true,
    this.orderIndex = 0,
  }) : shortName = shortName ?? (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase());

  // Convert Task to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'short_name': shortName,
      'color': color,
      'is_active': isActive ? 1 : 0,
      'order_index': orderIndex,
    };
  }

  // Create Task from Map
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      shortName: map['short_name'],
      color: map['color'],
      isActive: map['is_active'] == 1,
      orderIndex: map['order_index'] ?? 0,
    );
  }

  Task copyWith({
    int? id,
    String? name,
    String? shortName,
    String? color,
    bool? isActive,
    int? orderIndex,
  }) {
    return Task(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
