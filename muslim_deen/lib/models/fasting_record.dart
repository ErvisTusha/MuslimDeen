/// Fasting tracking data models for Ramadan and other fasts
/// 
/// This file defines comprehensive models for tracking various types of Islamic
/// fasting, including obligatory Ramadan fasts, voluntary fasts, and makeup
/// fasts. The models support detailed tracking, analytics, and historical analysis.

/// Enumeration of fasting types recognized in Islamic practice
/// 
/// Defines different categories of fasting based on Islamic jurisprudence.
/// Each type has different rules, requirements, and spiritual significance.
enum FastingType {
  /// Obligatory fasting during the month of Ramadan
  /// One of the Five Pillars of Islam, required for all adult Muslims
  ramadan,
  
  /// Voluntary fasting outside of Ramadan
  /// Includes sunnah fasts like Mondays and Thursdays
  voluntary,
  
  /// Makeup fasting for missed Ramadan days
  /// Required when Ramadan fasts are missed due to valid reasons
  qada,
  
  /// Expiatory fasting for violations or omissions
  /// Prescribed as compensation for certain Islamic violations
  kaffarah,
  
  /// Other types of fasting not covered by above categories
  /// Custom or special fasting occasions
  other,
}

/// Status of a fasting day for tracking purposes
/// 
/// Defines the different states a fasting day can be in, allowing
/// for comprehensive tracking and analytics of fasting patterns.
enum FastingStatus {
  /// Successfully completed the fast
  /// Indicates the person maintained the fast from dawn to sunset
  completed,
  
  /// Fast was broken intentionally or accidentally
  /// Indicates the fast was not maintained for the full day
  broken,
  
  /// Excused from fasting due to valid Islamic reasons
  /// Includes illness, travel, menstruation, etc.
  excused,
  
  /// Day hasn't started yet or status is unknown
  /// Used for future dates or undetermined status
  notStarted,
}

/// Represents a single fasting record for a specific day
/// 
/// This model captures comprehensive information about a fasting day,
/// including timing, status, type, and user-provided notes. It supports
/// both individual tracking and aggregate analytics for fasting patterns.
/// 
/// Design principles:
/// - Immutable data structure for audit trail integrity
/// - Comprehensive tracking for meaningful analytics
/// - Support for all Islamic fasting types
/// - Flexible metadata storage for extensibility
/// 
/// Key responsibilities:
/// - Record fasting performance with timing details
/// - Store fasting type and status information
/// - Maintain metadata for advanced analytics
/// - Support serialization for persistent storage
/// 
/// Usage patterns:
/// - Created when users mark fasting status for a day
/// - Used by analytics services for pattern analysis
/// - Referenced by streak calculation algorithms
/// - Displayed in history views with detailed information
class FastingRecord {
  /// Unique identifier for this fasting record
  /// Used for database primary key and reference handling
  /// Generated using timestamp and random components for uniqueness
  final String id;
  
  /// Calendar date for which this fasting record applies
  /// Represents the specific day of fasting (Gregorian calendar)
  /// Used for chronological ordering and date-based filtering
  final DateTime date;
  
  /// Type of fasting for this record
  /// Determines the rules, requirements, and spiritual significance
  /// Must match one of the predefined FastingType values
  final FastingType type;
  
  /// Current status of the fasting day
  /// Indicates whether the fast was completed, broken, or excused
  /// Can be updated as the day progresses
  final FastingStatus status;
  
  /// Timestamp when the fast was started
  /// Typically represents the pre-dawn meal time (suhoor)
  /// Null indicates no start time was recorded
  final DateTime? startTime;
  
  /// Timestamp when the fast was completed or broken
  /// Represents sunset time or when the fast was terminated early
  /// Null indicates no end time was recorded or fast is ongoing
  final DateTime? endTime;
  
  /// Optional user notes about the fast
  /// Free-form text for personal reflections, challenges, or special circumstances
  /// Can include health issues, spiritual experiences, or difficulties faced
  final String? notes;
  
  /// Whether this day falls during Ramadan
  /// Special flag for Ramadan days which have different spiritual significance
  /// Used for Ramadan-specific analytics and features
  final bool isRamadan;
  
  /// Timestamp when this record was created
  /// Used for audit trail and data integrity tracking
  /// Automatically set to current time when record is created
  final DateTime createdAt;
  
  /// Timestamp when this record was last updated
  /// Used for tracking changes and maintaining data freshness
  /// Automatically updated when record fields change
  final DateTime updatedAt;

  /// Creates a new FastingRecord with complete fasting information
  /// 
  /// Parameters:
  /// - [id]: Unique identifier (required)
  /// - [date]: Calendar date for the fast (required)
  /// - [type]: Type of fasting (required)
  /// - [status]: Current fasting status (required)
  /// - [startTime]: When fast was started (optional)
  /// - [endTime]: When fast ended or was broken (optional)
  /// - [notes]: User notes about the fast (optional)
  /// - [isRamadan]: Whether this is a Ramadan fast (defaults to false)
  /// - [createdAt]: Record creation time (optional, defaults to now)
  /// - [updatedAt]: Record last update time (optional, defaults to now)
  /// 
  /// Notes:
  /// - createdAt and updatedAt default to current time if not provided
  /// - isRamadan should be explicitly set for Ramadan days
  /// - startTime and endTime can be null for incomplete tracking
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

  /// Creates a FastingRecord from JSON data
  /// 
  /// Factory method for deserializing stored fasting records from
  /// databases or network sources. Handles enum conversions and
  /// date parsing with appropriate error handling.
  /// 
  /// Parameters:
  /// - [json]: Map containing serialized fasting record data
  /// 
  /// Returns: New FastingRecord with restored data
  /// 
  /// Error handling:
  /// - Assumes valid JSON structure (should be validated before use)
  /// - Invalid dates may cause DateTime parsing errors
  /// - Invalid enum values may cause range errors
  factory FastingRecord.fromJson(Map<String, dynamic> json) {
    return FastingRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      type: FastingType.values[json['type'] as int],
      status: FastingStatus.values[json['status'] as int],
      startTime:
          json['startTime'] != null
              ? DateTime.parse(json['startTime'] as String)
              : null,
      endTime:
          json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : null,
      notes: json['notes'] as String?,
      isRamadan: json['isRamadan'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serializes this FastingRecord to JSON for storage
  /// 
  /// Converts the fasting record to a format suitable for persistent
  /// storage in databases, SharedPreferences, or network transmission.
  /// 
  /// Serialization details:
  /// - Enums are converted to their index values
  /// - DateTime objects are converted to ISO8601 strings
  /// - Null values are handled appropriately
  /// - All fields are preserved for complete reconstruction
  /// 
  /// Returns: Map<String, dynamic> containing all record data
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

  /// Creates a copy of this record with updated fields
  /// 
  /// Implements the immutable update pattern for safe modifications.
  /// Only the provided parameters are updated; all others retain
  /// their original values. Automatically updates the updatedAt timestamp.
  /// 
  /// Parameters:
  /// - [id]: New unique identifier (optional)
  /// - [date]: New date (optional)
  /// - [type]: New fasting type (optional)
  /// - [status]: New fasting status (optional)
  /// - [startTime]: New start time (optional)
  /// - [endTime]: New end time (optional)
  /// - [notes]: New notes (optional)
  /// - [isRamadan]: New Ramadan flag (optional)
  /// - [createdAt]: New creation time (optional)
  /// - [updatedAt]: New update time (optional, defaults to now)
  /// 
  /// Returns: New FastingRecord with updated values
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

  // ==================== COMPUTED PROPERTIES ====================
  
  /// Checks if the fast was completed successfully
  /// 
  /// Convenience property for checking completion status
  /// without exposing the status enum directly.
  /// 
  /// Returns: true if status is completed, false otherwise
  bool get isCompleted => status == FastingStatus.completed;
  
  /// Checks if the fast was broken
  /// 
  /// Convenience property for checking if the fast was broken
  /// without exposing the status enum directly.
  /// 
  /// Returns: true if status is broken, false otherwise
  bool get isBroken => status == FastingStatus.broken;
  
  /// Checks if fasting is excused for this day
  /// 
  /// Convenience property for checking if fasting was excused
  /// without exposing the status enum directly.
  /// 
  /// Returns: true if status is excused, false otherwise
  bool get isExcused => status == FastingStatus.excused;
  
  /// Gets the duration of the fast
  /// 
  /// Calculates the total duration between start and end time
  /// if both are available. Returns null if either time is missing.
  /// 
  /// Returns: Duration of fast, or null if timing incomplete
  Duration? get fastDuration {
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  // ==================== UTILITY METHODS ====================
  
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

/// Statistics for fasting tracking and analytics
/// 
/// This model aggregates fasting data into meaningful statistics
/// for tracking progress, identifying patterns, and setting goals.
/// It provides comprehensive metrics for different fasting types.
/// 
/// Design principles:
/// - Immutable snapshot of statistics at calculation time
/// - Comprehensive metric coverage for fasting analysis
/// - Support for different fasting types and periods
/// - Efficient calculation from raw records
/// 
/// Usage patterns:
/// - Generated on-demand for dashboard displays
/// - Used for progress tracking and goal setting
/// - Supports historical trend analysis
/// - Basis for personalized recommendations
class FastingStats {
  /// Total number of fasting days tracked
  /// Includes all fasting types and statuses
  final int totalFasts;
  
  /// Number of successfully completed fasts
  /// Only includes fasts with completed status
  final int completedFasts;
  
  /// Current consecutive fasting streak
  /// Number of consecutive days with completed fasts
  final int currentStreak;
  
  /// Longest fasting streak achieved
  /// Maximum consecutive days with completed fasts
  final int longestStreak;
  
  /// Number of Ramadan fasts
  /// Only includes fasts during Ramadan
  final int ramadanFasts;
  
  /// Number of voluntary fasts
  /// Only includes voluntary fasting types
  final int voluntaryFasts;
  
  /// Overall completion rate (0.0 to 1.0)
  /// Ratio of completed fasts to total fasts attempted
  final double completionRate;

  /// Creates a new FastingStats with complete statistics
  /// 
  /// Parameters:
  /// - [totalFasts]: Total fasting days (required)
  /// - [completedFasts]: Completed fasts (required)
  /// - [currentStreak]: Current streak (required)
  /// - [longestStreak]: Longest streak (required)
  /// - [ramadanFasts]: Ramadan fasts (required)
  /// - [voluntaryFasts]: Voluntary fasts (required)
  /// - [completionRate]: Completion percentage (required)
  const FastingStats({
    required this.totalFasts,
    required this.completedFasts,
    required this.currentStreak,
    required this.longestStreak,
    required this.ramadanFasts,
    required this.voluntaryFasts,
    required this.completionRate,
  });

  /// Creates empty FastingStats with zero values
  /// 
  /// Factory method for creating default empty statistics
  /// when no fasting data is available.
  /// 
  /// Returns: FastingStats with all zero values
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