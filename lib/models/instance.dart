class Instance {
  final int? id;
  final int projectId;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes; // Calculated duration

  Instance({
    this.id,
    required this.projectId,
    DateTime? startTime,
    this.endTime,
    this.durationMinutes = 0,
  }) : startTime = startTime ?? DateTime.now();

  bool get isActive => endTime == null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
    };
  }

  factory Instance.fromMap(Map<String, dynamic> map) {
    return Instance(
      id: map['id'] as int?,
      projectId: map['projectId'] as int,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      durationMinutes: map['durationMinutes'] as int? ?? 0,
    );
  }

  Instance copyWith({
    int? id,
    int? projectId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
  }) {
    return Instance(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
