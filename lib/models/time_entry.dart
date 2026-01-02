class TimeEntry {
  final int? id;
  final int taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final String date; // Format: YYYY-MM-DD
  final String? description;

  TimeEntry({
    this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.date,
    this.description,
  });

  // Convert TimeEntry to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'date': date,
      'description': description,
    };
  }

  // Create TimeEntry from Map
  factory TimeEntry.fromMap(Map<String, dynamic> map) {
    return TimeEntry(
      id: map['id'],
      taskId: map['task_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      date: map['date'],
      description: map['description'],
    );
  }

  // Calculate duration
  Duration getDuration() {
    if (endTime == null) {
      // If still running, calculate from start to now
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  // Check if entry is currently running
  bool get isRunning => endTime == null;

  TimeEntry copyWith({
    int? id,
    int? taskId,
    DateTime? startTime,
    DateTime? endTime,
    String? date,
    String? description,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }
}
