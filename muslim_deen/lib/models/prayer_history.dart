/// Prayer History Data Models
/// Comprehensive prayer tracking models for analytics and history

class PrayerRecord {
  final String id;
  final String prayerName;
  final DateTime timestamp;
  final bool completed;
  final bool onTime;
  final Duration duration;
  final int quality; // 1-10 quality score
  final String? notes;
  final Map<String, dynamic> metadata;

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

class PrayerAnalytics {
  final List<PrayerRecord> records;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, double> statistics;

  const PrayerAnalytics({
    required this.records,
    this.startDate,
    this.endDate,
    required this.statistics,
  });

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

class PrayerStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime startDate;
  final PrayerType prayerType;
  final List<PrayerRecord> records;
  final bool isActive;

  const PrayerStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.startDate,
    required this.prayerType,
    required this.records,
    required this.isActive,
  });

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

class PrayerTrend {
  final String period; // 'daily', 'weekly', 'monthly'
  final double trendValue; // -1.0 to 1.0
  final String trendDirection; // 'increasing', 'decreasing', 'stable'
  final double confidence;
  final List<PrayerRecord> relevantRecords;

  const PrayerTrend({
    required this.period,
    required this.trendValue,
    required this.trendDirection,
    required this.confidence,
    required this.relevantRecords,
  });
}

enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  const PrayerType();

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

class PrayerInsight {
  final String type;
  final String message;
  final String recommendation;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime timestamp;

  const PrayerInsight({
    required this.type,
    required this.message,
    required this.recommendation,
    required this.priority,
    required this.timestamp,
  });
}

class PrayerRecommendation {
  final String category;
  final String title;
  final String description;
  final List<String> actions;
  final String timeframe;
  final String expectedBenefit;
  final double confidence;

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

// Exception classes
class PrayerAnalyticsException implements Exception {
  final String message;
  final String? stackTrace;

  const PrayerAnalyticsException(this.message, this.stackTrace);

  @override
  String toString() => 'PrayerAnalyticsException: $message';
}
