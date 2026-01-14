class Project {
  final int? id;
  final String name;
  final int totalMinutes; // Accumulated time in minutes
  final DateTime createdAt;
  final DateTime? lastActiveAt;
  final String status; // 'active', 'completed', 'on_hold', 'reset', 'canceled'
  final bool isArchived;
  final DateTime? completedAt;
  final String? description;
  final int? parentProjectId;

  Project({
    this.id,
    required this.name,
    this.totalMinutes = 0,
    DateTime? createdAt,
    this.lastActiveAt,
    this.status = 'active',
    this.isArchived = false,
    this.completedAt,
    this.description,
    this.parentProjectId,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalMinutes': totalMinutes,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'status': status,
      'isArchived': isArchived,
      'completedAt': completedAt?.toIso8601String(),
      'description': description,
      'parentProjectId': parentProjectId,
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
      status: map['status'] as String? ?? 'active',
      isArchived: map['isArchived'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      description: map['description'] as String?,
      parentProjectId: map['parentProjectId'] as int?,
    );
  }

  Project copyWith({
    int? id,
    String? name,
    int? totalMinutes,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? status,
    bool? isArchived,
    DateTime? completedAt,
    String? description,
    int? parentProjectId,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      status: status ?? this.status,
      isArchived: isArchived ?? this.isArchived,
      completedAt: completedAt ?? this.completedAt,
      description: description ?? this.description,
      parentProjectId: parentProjectId ?? this.parentProjectId,
    );
  }
}
