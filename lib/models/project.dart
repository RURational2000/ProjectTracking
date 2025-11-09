class Project {
  final int? id;
  final String name;
  final int totalMinutes; // Accumulated time in minutes
  final DateTime createdAt;
  final DateTime? lastActiveAt;

  Project({
    this.id,
    required this.name,
    this.totalMinutes = 0,
    DateTime? createdAt,
    this.lastActiveAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalMinutes': totalMinutes,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalMinutes: map['totalMinutes'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastActiveAt: map['lastActiveAt'] != null 
          ? DateTime.parse(map['lastActiveAt'] as String)
          : null,
    );
  }

  Project copyWith({
    int? id,
    String? name,
    int? totalMinutes,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
