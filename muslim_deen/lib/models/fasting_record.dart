
enum FastingType {
  ramadan,      // Obligatory Ramadan fasting
  voluntary,    // Voluntary fasting (like Monday/Thursday)
  qada,         // Makeup fasting for missed Ramadan days
  kaffarah,     // Expiatory fasting
  other,        // Other types of fasting
}

/// Status of a fasting day
enum FastingStatus {
  completed,    // Successfully completed the fast
  broken,       // Fast was broken (intentionally or unintentionally)
  excused,      // Excused from fasting (travel, illness, etc.)
  notStarted,   // Day hasn't started yet
}

/// Represents a single fasting record for a specific day
class FastingRecord {
  final String id;
  final DateTime date;
  final FastingType type;
  final FastingStatus status;
  final DateTime? startTime;      // When the fast was started
  final DateTime? endTime;        // When the fast was completed/broken
  final String? notes;            // Optional notes about the fast
  final bool isRamadan;           // Whether this day is during Ramadan
  final DateTime createdAt;
  final DateTime updatedAt;

  FastingRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.status,
    this.startTime,
    this.endTime,
    this.notes,
    this.isRamadan = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create a FastingRecord from JSON (for database storage)
  factory FastingRecord.fromJson(Map<String, dynamic> json) {
    return FastingRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: FastingType.values[json['type'] as int],
      status: FastingStatus.values[json['status'] as int],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime'] as String) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      notes: json['notes'] as String?,
      isRamadan: json['isRamadan'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert FastingRecord to JSON (for database storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.index,
      'status': status.index,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'notes': notes,
      'isRamadan': isRamadan,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of this record with updated fields
  FastingRecord copyWith({
    String? id,
    DateTime? date,
    FastingType? type,
    FastingStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    bool? isRamadan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FastingRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      isRamadan: isRamadan ?? this.isRamadan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Check if the fast was completed successfully
  bool get isCompleted => status == FastingStatus.completed;

  /// Check if the fast was broken
  bool get isBroken => status == FastingStatus.broken;

  /// Check if fasting is excused for this day
  bool get isExcused => status == FastingStatus.excused;

  /// Get the duration of the fast (if completed)
  Duration? get fastDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FastingRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FastingRecord(id: $id, date: $date, type: $type, status: $status, isRamadan: $isRamadan)';
  }
}

/// Statistics for fasting tracking
class FastingStats {
  final int totalFasts;
  final int completedFasts;
  final int currentStreak;
  final int longestStreak;
  final int ramadanFasts;
  final int voluntaryFasts;
  final double completionRate;

  FastingStats({
    required this.totalFasts,
    required this.completedFasts,
    required this.currentStreak,
    required this.longestStreak,
    required this.ramadanFasts,
    required this.voluntaryFasts,
    required this.completionRate,
  });

  factory FastingStats.empty() {
    return FastingStats(
      totalFasts: 0,
      completedFasts: 0,
      currentStreak: 0,
      longestStreak: 0,
      ramadanFasts: 0,
      voluntaryFasts: 0,
      completionRate: 0.0,
    );
  }

  @override
  String toString() {
    return 'FastingStats(total: $totalFasts, completed: $completedFasts, streak: $currentStreak/$longestStreak, rate: ${(completionRate * 100).toStringAsFixed(1)}%)';
  }
}