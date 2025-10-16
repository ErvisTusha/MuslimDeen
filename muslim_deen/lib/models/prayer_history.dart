/// Prayer History Data Models
/// Comprehensive prayer tracking models for analytics and history

/// Individual prayer record representing a single prayer performance
/// 
/// This model captures detailed information about a specific prayer instance,
/// including completion status, timing, quality metrics, and user-provided notes.
/// It serves as the foundational data unit for prayer tracking and analytics.
/// 
/// Design principles:
/// - Immutable data structure for audit trail integrity
/// - Comprehensive tracking for meaningful analytics
/// - Flexible metadata storage for extensibility
/// - Unique identification for data integrity
/// 
/// Key responsibilities:
/// - Record prayer performance with timing details
/// - Store quality assessments and user feedback
/// - Maintain metadata for advanced analytics
/// - Support serialization for persistent storage
/// 
/// Usage patterns:
/// - Created when users mark prayers as completed
/// - Used by analytics services for trend analysis
/// - Referenced by streak calculation algorithms
/// - Displayed in history views with detailed information
class PrayerRecord {
  /// Unique identifier for this prayer record
  /// Generated using timestamp to ensure uniqueness
  /// Used for database primary key and reference handling
  final String id;
  
  /// Name of the prayer (e.g., 'Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha')
  /// Should match standard prayer naming conventions
  /// Used for grouping and filtering records
  final String prayerName;
  
  /// Timestamp when this prayer was performed or recorded
  /// Used for chronological ordering and time-based analysis
  /// Should be in UTC for consistent timezone handling
  final DateTime timestamp;
  
  /// Whether the prayer was completed
  /// True indicates the user marked the prayer as performed
  /// False indicates missed or intentionally skipped prayer
  final bool completed;
  
  /// Whether the prayer was performed on time
  /// True indicates prayer was performed within the valid time window
  /// False indicates prayer was performed late (qada)
  final bool onTime;
  
  /// Duration of the prayer performance
  /// Measured from start to end of prayer ritual
  /// Used for analyzing prayer duration patterns
  final Duration duration;
  
  /// Quality score for the prayer performance (1-10)
  /// Self-assessment by the user of prayer quality and focus
  /// 1 = poor quality, 10 = excellent quality
  final int quality;
  
  /// Optional user notes about the prayer
  /// Free-form text for personal reflections or reminders
  /// Can include distractions, special circumstances, etc.
  final String? notes;
  
  /// Additional metadata for extensibility
  /// Key-value pairs for storing additional information
  /// Used for custom fields, experimental features, etc.
  final Map<String, dynamic> metadata;

  /// Creates a new PrayerRecord with complete performance information
  /// 
  /// Parameters:
  /// - [id]: Unique identifier (required)
  /// - [prayerName]: Name of the prayer (required)
  /// - [timestamp]: When prayer was performed (required)
  /// - [completed]: Whether prayer was completed (required)
  /// - [onTime]: Whether prayer was on time (required)
  /// - [duration]: Prayer duration (required)
  /// - [quality]: Quality score 1-10 (required)
  /// - [notes]: Optional user notes (optional)
  /// - [metadata]: Additional key-value data (optional)
  const PrayerRecord({
    required this.id,
    required this.prayerName,
    required this.timestamp,
    required this.completed,
    required this.onTime,
    required this.duration,
    required this.quality,
    this.notes,
    this.metadata = const {},
  });

  /// Creates a new PrayerRecord with auto-generated ID
  /// 
  /// Convenience factory for creating records without manual ID generation.
  /// Automatically generates a unique ID based on current timestamp.
  /// 
  /// Parameters:
  /// - [prayerName]: Name of the prayer (required)
  /// - [timestamp]: When prayer was performed (defaults to now)
  /// - [completed]: Whether prayer was completed (defaults to false)
  /// - [onTime]: Whether prayer was on time (defaults to false)
  /// - [duration]: Prayer duration (defaults to zero)
  /// - [quality]: Quality score 1-10 (defaults to 5)
  /// - [notes]: Optional user notes (optional)
  /// 
  /// Returns: New PrayerRecord with generated ID
  factory PrayerRecord.create({
    required String prayerName,
    required DateTime timestamp,
    bool completed = false,
    bool onTime = false,
    Duration duration = Duration.zero,
    int quality = 5,
    String? notes,
  }) {
    return PrayerRecord(
      id: 'prayer_${DateTime.now().millisecondsSinceEpoch}',
      prayerName: prayerName,
      timestamp: timestamp,
      completed: completed,
      onTime: onTime,
      duration: duration,
      quality: quality,
      notes: notes,
    );
  }
}

/// Analytics container for prayer performance data
/// 
/// This model aggregates prayer records into meaningful statistics and insights.
/// It provides calculated metrics for understanding prayer patterns, consistency,
/// and areas for improvement. The analytics can be filtered by date ranges
/// and prayer types for targeted analysis.
/// 
/// Design principles:
/// - Immutable snapshot of analytics at calculation time
/// - Comprehensive statistical coverage
/// - Efficient calculation from raw records
/// - Extensible for future metric additions
/// 
/// Key responsibilities:
/// - Calculate completion and punctuality rates
/// - Compute average prayer quality scores
/// - Determine time-based performance trends
/// - Support date-range filtered analytics
/// 
/// Usage patterns:
/// - Generated on-demand for dashboard displays
/// - Used for progress tracking and goal setting
/// - Supports historical trend analysis
/// - Basis for personalized recommendations
class PrayerAnalytics {
  /// Collection of prayer records used for analytics
  /// Sorted chronologically for time-based analysis
  final List<PrayerRecord> records;
  
  /// Start date of the analytics period
  /// Null indicates using earliest record date
  final DateTime? startDate;
  
  /// End date of the analytics period
  /// Null indicates using latest record date
  final DateTime? endDate;
  
  /// Calculated statistical metrics
  /// Key-value pairs of metric names and values
  /// Includes rates, averages, and other computed values
  final Map<String, double> statistics;

  /// Creates a new PrayerAnalytics with calculated statistics
  /// 
  /// Parameters:
  /// - [records]: Prayer records to analyze (required)
  /// - [startDate]: Period start date (optional)
  /// - [endDate]: Period end date (optional)
  /// - [statistics]: Pre-calculated statistics (required)
  const PrayerAnalytics({
    required this.records,
    this.startDate,
    this.endDate,
    required this.statistics,
  });

  /// Calculates PrayerAnalytics from a collection of prayer records
  /// 
  /// Factory method that processes raw prayer records into meaningful
  /// analytics with comprehensive statistics. Handles empty record sets
  /// and automatic date range determination.
  /// 
  /// Parameters:
  /// - [records]: Collection of prayer records to analyze
  /// 
  /// Returns: PrayerAnalytics with calculated statistics
  /// 
  /// Calculated statistics:
  /// - completion_rate: Percentage of prayers completed
  /// - punctuality_rate: Percentage of prayers on time
  /// - average_quality: Mean quality score (1-10)
  /// - average_duration: Mean prayer duration in milliseconds
  factory PrayerAnalytics.fromRecords(List<PrayerRecord> records) {
    if (records.isEmpty) {
      return PrayerAnalytics(
        records: [],
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        statistics: {},
      );
    }

    final sortedRecords = List<PrayerRecord>.from(records);
    sortedRecords.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final startDate = sortedRecords.first.timestamp;
    final endDate = sortedRecords.last.timestamp;

    // Calculate statistics
    final completedCount = sortedRecords.where((r) => r.completed).length;
    final onTimeCount = sortedRecords.where((r) => r.onTime).length;
    final totalDuration = sortedRecords.fold<Duration>(
      Duration.zero,
      (sum, r) => sum + r.duration,
    );

    final statistics = <String, double>{
      'completion_rate':
          sortedRecords.isNotEmpty
              ? completedCount / sortedRecords.length
              : 0.0,
      'punctuality_rate':
          sortedRecords.isNotEmpty ? onTimeCount / sortedRecords.length : 0.0,
      'average_quality':
          sortedRecords.isNotEmpty
              ? sortedRecords.map((r) => r.quality).reduce((a, b) => a + b) /
                  sortedRecords.length
              : 0.0,
      'average_duration':
          sortedRecords.isNotEmpty
              ? totalDuration.inMilliseconds.toDouble() / sortedRecords.length
              : 0.0,
    };

    return PrayerAnalytics(
      records: sortedRecords,
      startDate: startDate,
      endDate: endDate,
      statistics: statistics,
    );
  }
}

/// Prayer streak tracking and analysis model
/// 
/// This model tracks consecutive prayer performance streaks, which are
/// important motivational metrics in Islamic practice. It calculates current
/// and longest streaks for specific prayer types or overall prayer performance.
/// 
/// Design principles:
/// - Immutable snapshot of streak data at calculation time
/// - Support for both current and historical streak analysis
/// - Flexible prayer type filtering
/// - Active/inactive status tracking
/// 
/// Key responsibilities:
/// - Calculate current consecutive prayer streaks
/// - Track longest historical streaks
/// - Determine streak activity status
/// - Provide streak start dates for celebration
/// 
/// Usage patterns:
/// - Generated daily to update streak displays
/// - Used for achievement systems and milestones
/// - Supports streak recovery and maintenance features
/// - Basis for motivational notifications
class PrayerStreak {
  /// Current consecutive prayer streak count
  /// Number of consecutive days with completed prayers
  /// Resets to 0 when a day is missed
  final int currentStreak;
  
  /// Longest streak achieved historically
  /// Maximum consecutive days with completed prayers
  /// Used for personal records and goal setting
  final int longestStreak;
  
  /// Date when the current streak started
  /// Used for calculating streak duration and celebrations
  /// Updates when streak restarts after breaking
  final DateTime startDate;
  
  /// Type of prayer for this streak calculation
  /// Can be specific prayer type or overall prayer performance
  final PrayerType prayerType;
  
  /// Prayer records contributing to this streak
  /// Historical records used for streak calculation and validation
  final List<PrayerRecord> records;
  
  /// Whether this streak is currently active
  /// False indicates streak has been broken
  /// True indicates streak is ongoing
  final bool isActive;

  /// Creates a new PrayerStreak with complete streak information
  /// 
  /// Parameters:
  /// - [currentStreak]: Current streak count (required)
  /// - [longestStreak]: Longest historical streak (required)
  /// - [startDate]: When current streak started (required)
  /// - [prayerType]: Type of prayer for streak (required)
  /// - [records]: Contributing prayer records (required)
  /// - [isActive]: Whether streak is active (required)
  const PrayerStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.startDate,
    required this.prayerType,
    required this.records,
    required this.isActive,
  });

  /// Calculates PrayerStreak from prayer records
  /// 
  /// Factory method that analyzes prayer records to determine streak
  /// information. Supports filtering by prayer type and can create
  /// empty streaks for prayer types with no records.
  /// 
  /// Parameters:
  /// - [records]: Prayer records to analyze (required)
  /// - [prayerType]: Type of prayer for streak calculation (required)
  /// - [active]: Whether streak should be marked active (defaults to true)
  /// 
  /// Returns: PrayerStreak with calculated streak information
  factory PrayerStreak.calculate({
    required List<PrayerRecord> records,
    required PrayerType prayerType,
    bool active = true,
  }) {
    if (records.isEmpty) {
      return PrayerStreak.empty(prayerType);
    }

    // Filter records for specific prayer type
    final prayerRecords =
        records
            .where(
              (r) => r.prayerName.toLowerCase().contains(
                prayerType.name.toLowerCase(),
              ),
            )
            .toList();

    // Calculate current streak
    int currentStreak = 0;
    DateTime? streakStart;

    for (int i = prayerRecords.length - 1; i >= 0; i--) {
      final record = prayerRecords[i];
      if (record.completed) {
        currentStreak++;
        streakStart = record.timestamp;
      } else {
        break;
      }
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 0;

    for (final record in prayerRecords) {
      if (record.completed) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    return PrayerStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      startDate: streakStart ?? DateTime.now(),
      prayerType: prayerType,
      records: prayerRecords,
      isActive: active,
    );
  }

  /// Creates an empty PrayerStreak for a prayer type
  /// 
  /// Factory method for creating a default empty streak when no
  /// prayer records exist for a specific prayer type.
  /// 
  /// Parameters:
  /// - [prayerType]: Type of prayer for empty streak (required)
  /// 
  /// Returns: Empty PrayerStreak with zero values
  factory PrayerStreak.empty(PrayerType prayerType) {
    return PrayerStreak(
      currentStreak: 0,
      longestStreak: 0,
      startDate: DateTime.now(),
      prayerType: prayerType,
      records: [],
      isActive: false,
    );
  }
}

/// Prayer trend analysis model
/// 
/// This model tracks performance trends over different time periods,
/// helping users understand their prayer patterns and identify areas
/// for improvement. Trends can be positive, negative, or stable.
/// 
/// Design principles:
/// - Configurable time period analysis
/// - Quantitative trend measurement
/// - Confidence scoring for trend reliability
/// - Comprehensive record tracking
/// 
/// Usage patterns:
/// - Generated weekly or monthly for trend reports
/// - Used for predictive analytics and recommendations
/// - Supports goal setting and progress tracking
class PrayerTrend {
  /// Time period for trend analysis
  /// Examples: 'daily', 'weekly', 'monthly'
  final String period;
  
  /// Numerical trend value (-1.0 to 1.0)
  /// Positive values indicate improving performance
  /// Negative values indicate declining performance
  /// Near zero indicates stable performance
  final double trendValue;
  
  /// Qualitative trend direction
  /// Categorical representation of trend for UI display
  final String trendDirection;
  
  /// Confidence score for trend reliability (0.0 to 1.0)
  /// Higher values indicate more reliable trend calculations
  /// Based on data volume and consistency
  final double confidence;
  
  /// Prayer records used for trend calculation
  /// Historical records that form the basis of trend analysis
  final List<PrayerRecord> relevantRecords;

  /// Creates a new PrayerTrend with complete trend information
  /// 
  /// Parameters:
  /// - [period]: Time period for analysis (required)
  /// - [trendValue]: Numerical trend value (required)
  /// - [trendDirection]: Qualitative trend direction (required)
  /// - [confidence]: Reliability confidence score (required)
  /// - [relevantRecords]: Records used for calculation (required)
  const PrayerTrend({
    required this.period,
    required this.trendValue,
    required this.trendDirection,
    required this.confidence,
    required this.relevantRecords,
  });
}

/// Enumeration of prayer types
/// 
/// Defines the five daily prayers with display names and
/// Arabic representations for localization support.
enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  const PrayerType();

  /// Gets the English display name for this prayer type
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  /// Gets the Arabic display name for this prayer type
  String get arabicName {
    switch (this) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
    }
  }
}

/// Prayer insight model for personalized recommendations
/// 
/// This model represents actionable insights derived from prayer
/// performance data. Insights help users improve their prayer
/// habits through personalized recommendations and observations.
/// 
/// Usage patterns:
/// - Generated by AI/ML algorithms from user data
/// - Displayed in dashboard and recommendation feeds
/// - Used for goal setting and progress tracking
class PrayerInsight {
  /// Category or type of insight
  /// Examples: 'consistency', 'timing', 'quality'
  final String type;
  
  /// Insight message explaining the observation
  /// User-friendly description of the pattern or issue
  final String message;
  
  /// Recommended action to address the insight
  /// Specific, actionable advice for improvement
  final String recommendation;
  
  /// Priority level for addressing this insight
  /// Examples: 'low', 'medium', 'high', 'urgent'
  final String priority;
  
  /// When this insight was generated
  /// Used for filtering recent insights
  final DateTime timestamp;

  /// Creates a new PrayerInsight with complete information
  /// 
  /// Parameters:
  /// - [type]: Insight category (required)
  /// - [message]: Insight description (required)
  /// - [recommendation]: Actionable advice (required)
  /// - [priority]: Priority level (required)
  /// - [timestamp]: Generation time (required)
  const PrayerInsight({
    required this.type,
    required this.message,
    required this.recommendation,
    required this.priority,
    required this.timestamp,
  });
}

/// Prayer recommendation model for personalized guidance
/// 
/// This model represents specific recommendations to help users
/// improve their prayer performance based on their historical
/// data and patterns.
class PrayerRecommendation {
  /// Category of recommendation
  /// Examples: 'timing', 'consistency', 'quality', 'environment'
  final String category;
  
  /// Brief title for the recommendation
  /// Displayed in lists and notifications
  final String title;
  
  /// Detailed description of the recommendation
  /// Explains the what, why, and how of the recommendation
  final String description;
  
  /// Specific actions to implement the recommendation
  /// Step-by-step guidance for execution
  final List<String> actions;
  
  /// Expected timeframe for seeing results
  /// Examples: '1 week', '1 month', 'immediate'
  final String timeframe;
  
  /// Expected benefit from implementing the recommendation
  /// Describes the positive impact on prayer performance
  final String expectedBenefit;
  
  /// Confidence score for recommendation effectiveness
  /// Higher values indicate more proven recommendations
  final double confidence;

  /// Creates a new PrayerRecommendation with complete information
  /// 
  /// Parameters:
  /// - [category]: Recommendation category (required)
  /// - [title]: Brief title (required)
  /// - [description]: Detailed description (required)
  /// - [actions]: Action steps (required)
  /// - [timeframe]: Expected timeframe (required)
  /// - [expectedBenefit]: Expected outcome (required)
  /// - [confidence]: Effectiveness confidence (required)
  const PrayerRecommendation({
    required this.category,
    required this.title,
    required this.description,
    required this.actions,
    required this.timeframe,
    required this.expectedBenefit,
    required this.confidence,
  });
}

/// Exception class for prayer analytics errors
/// 
/// Custom exception for handling errors in prayer analytics
/// calculations, data processing, and insight generation.
class PrayerAnalyticsException implements Exception {
  /// Error message describing the analytics issue
  final String message;
  
  /// Optional stack trace for debugging
  final String? stackTrace;

  /// Creates a new PrayerAnalyticsException
  /// 
  /// Parameters:
  /// - [message]: Error description (required)
  /// - [stackTrace]: Debug information (optional)
  const PrayerAnalyticsException(this.message, this.stackTrace);

  @override
  String toString() => 'PrayerAnalyticsException: $message';
}