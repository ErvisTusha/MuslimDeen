import 'dart:async';
import 'dart:math';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Represents prayer performance data for a specific period
class PrayerPerformanceData {
  final DateTime date;
  final int completedPrayers;
  final int totalPrayers;
  final double completionRate;
  final List<String> completedPrayerNames;

  // Performance insights fields
  final String? mostConsistentPrayer;
  final String? leastConsistentPrayer;
  final String? bestPerformingDay;
  final String? improvementArea;

  PrayerPerformanceData({
    required this.date,
    required this.completedPrayers,
    required this.totalPrayers,
    required this.completionRate,
    required this.completedPrayerNames,
    this.mostConsistentPrayer,
    this.leastConsistentPrayer,
    this.bestPerformingDay,
    this.improvementArea,
  });
}

/// Represents trend analysis data
class PrayerTrendData {
  final double averageCompletionRate;
  final double trendSlope; // Positive = improving, negative = declining
  final TrendDirection trendDirection;
  final int bestDay;
  final int worstDay;
  final double averagePrayersPerDay;
  final int bestDayCount;
  final Map<String, double> prayerTypeRates; // Completion rate per prayer type
  final List<PrayerPerformanceData> dataPoints;

  PrayerTrendData({
    required this.averageCompletionRate,
    required this.trendSlope,
    required this.trendDirection,
    required this.bestDay,
    required this.worstDay,
    required this.averagePrayersPerDay,
    required this.bestDayCount,
    required this.prayerTypeRates,
    required this.dataPoints,
  });
}

/// Trend direction enum
enum TrendDirection { improving, declining, stable }

/// Advanced analytics service for prayer performance insights and trend analysis.
///
/// This singleton service provides sophisticated analysis of prayer completion
/// data, offering insights into user behavior patterns, performance trends,
/// and improvement recommendations. It implements statistical algorithms
/// including linear regression for trend analysis and comprehensive performance
/// metrics.
///
/// ## Key Features
/// - Performance trend analysis with linear regression
/// - Consistency scoring based on multiple factors
/// - Prayer-specific completion rate analysis
/// - Best/worst performing day identification
/// - Personalized improvement recommendations
/// - Monthly distribution analysis
///
/// ## Analytics Capabilities
/// - Trend direction detection (improving/declining/stable)
/// - Consistency scoring (0-100 scale)
/// - Performance insights generation
/// - Statistical modeling of prayer patterns
///
/// ## Data Models
/// - [PrayerPerformanceData]: Individual day performance metrics
/// - [PrayerTrendData]: Aggregate trend analysis results
/// - [TrendDirection]: Enum for trend classification
///
/// ## Dependencies
/// - [DatabaseService]: Source of prayer completion data
/// - [LoggerService]: Operations and error logging
///
/// ## Singleton Pattern
/// Ensures consistent analytics calculations across the app and prevents
/// duplicate computation resources.
class PrayerAnalyticsService {
  static PrayerAnalyticsService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();

  static const int _totalPrayersPerDay = 5; // fajr, dhuhr, asr, maghrib, isha

  factory PrayerAnalyticsService() {
    _instance ??= PrayerAnalyticsService._internal();
    return _instance!;
  }

  PrayerAnalyticsService._internal();

  /// Retrieves prayer performance data for a specified date range.
  ///
  /// This method processes raw prayer completion data into structured
  /// performance metrics that can be used for visualization and analysis.
  /// It handles missing data gracefully and provides completion rates.
  ///
  /// Parameters:
  /// - [startDate]: Start date for the analysis period
  /// - [endDate]: End date for the analysis period
  ///
  /// Returns: List of [PrayerPerformanceData] objects, one for each day
  ///
  /// Data Processing:
  /// - Converts completion lists to completion rates
  /// - Handles missing days with zero completion
  /// - Normalizes completion rates to 0.0-1.0 range
  ///
  /// Performance: Iterates through each day in the range
  ///
  /// Error Handling: Returns empty list on errors and logs the issue
  Future<List<PrayerPerformanceData>> getPerformanceData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final data = <PrayerPerformanceData>[];

      for (
        DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dateStr = date.toIso8601String().split('T')[0];
        final completedPrayers = await _database.getPrayerHistory(dateStr);

        if (completedPrayers != null) {
          final prayerList = completedPrayers.split(',');
          final completionRate = prayerList.length / _totalPrayersPerDay;

          data.add(
            PrayerPerformanceData(
              date: date,
              completedPrayers: prayerList.length,
              totalPrayers: _totalPrayersPerDay,
              completionRate: completionRate.clamp(0.0, 1.0),
              completedPrayerNames: prayerList,
            ),
          );
        } else {
          data.add(
            PrayerPerformanceData(
              date: date,
              completedPrayers: 0,
              totalPrayers: _totalPrayersPerDay,
              completionRate: 0.0,
              completedPrayerNames: [],
            ),
          );
        }
      }

      return data;
    } catch (e, s) {
      _logger.error('Error getting performance data', error: e, stackTrace: s);
      return [];
    }
  }

  /// Analyze prayer trends over a period
  Future<PrayerTrendData> analyzeTrends({int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final performanceData = await getPerformanceData(
        startDate: startDate,
        endDate: endDate,
      );

      if (performanceData.isEmpty) {
        return PrayerTrendData(
          averageCompletionRate: 0.0,
          trendSlope: 0.0,
          trendDirection: TrendDirection.stable,
          bestDay: 0,
          worstDay: 0,
          averagePrayersPerDay: 0.0,
          bestDayCount: 0,
          prayerTypeRates: {},
          dataPoints: [],
        );
      }

      // Calculate average completion rate
      final avgRate =
          performanceData.map((d) => d.completionRate).reduce((a, b) => a + b) /
          performanceData.length;

      // Calculate trend slope using linear regression
      final trendSlope = _calculateTrendSlope(performanceData);

      // Determine trend direction
      final trendDirection =
          trendSlope > 0.001
              ? TrendDirection.improving
              : trendSlope < -0.001
              ? TrendDirection.declining
              : TrendDirection.stable;

      // Find best and worst days
      final completionCounts =
          performanceData.map((d) => d.completedPrayers).toList();
      final bestDay = completionCounts.reduce(max);
      final worstDay = completionCounts.reduce(min);
      final averagePrayersPerDay =
          completionCounts.reduce((a, b) => a + b) / completionCounts.length;

      // Calculate prayer type completion rates
      final prayerTypeRates = await _calculatePrayerTypeRates(
        startDate,
        endDate,
      );

      return PrayerTrendData(
        averageCompletionRate: avgRate,
        trendSlope: trendSlope,
        trendDirection: trendDirection,
        bestDay: bestDay,
        worstDay: worstDay,
        averagePrayersPerDay: averagePrayersPerDay,
        bestDayCount: bestDay,
        prayerTypeRates: prayerTypeRates,
        dataPoints: performanceData,
      );
    } catch (e, s) {
      _logger.error('Error analyzing trends', error: e, stackTrace: s);
      return PrayerTrendData(
        averageCompletionRate: 0.0,
        trendSlope: 0.0,
        trendDirection: TrendDirection.stable,
        bestDay: 0,
        worstDay: 0,
        averagePrayersPerDay: 0.0,
        bestDayCount: 0,
        prayerTypeRates: {},
        dataPoints: [],
      );
    }
  }

  /// Get prayer consistency score (0-100)
  Future<int> getConsistencyScore({int days = 30}) async {
    try {
      final trends = await analyzeTrends(days: days);
      final avgRate = trends.averageCompletionRate;

      // Base score from average completion rate
      int score = (avgRate * 60).round(); // 0-60 points

      // Bonus for positive trend
      if (trends.trendSlope > 0.001) {
        score += 20; // Up to 20 points for improvement
      } else if (trends.trendSlope < -0.001) {
        score = max(0, score - 10); // Penalty for decline
      }

      // Bonus for high completion days
      final highCompletionDays =
          trends.dataPoints.where((d) => d.completionRate >= 0.8).length;
      final highCompletionRatio = highCompletionDays / trends.dataPoints.length;
      score += (highCompletionRatio * 20).round(); // Up to 20 points

      return min(100, max(0, score));
    } catch (e, s) {
      _logger.error(
        'Error calculating consistency score',
        error: e,
        stackTrace: s,
      );
      return 0;
    }
  }

  /// Get prayer performance insights as structured data
  Future<PrayerPerformanceData> getPerformanceInsights({int days = 30}) async {
    try {
      final trends = await analyzeTrends(days: days);

      // Find most and least consistent prayers
      final sortedPrayers =
          trends.prayerTypeRates.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

      final mostConsistent =
          sortedPrayers.isNotEmpty ? sortedPrayers.first.key : 'N/A';
      final leastConsistent =
          sortedPrayers.isNotEmpty ? sortedPrayers.last.key : 'N/A';

      // Find best performing day of week
      final dayPerformance = <int, List<double>>{};
      for (final data in trends.dataPoints) {
        final dayOfWeek = data.date.weekday;
        dayPerformance
            .putIfAbsent(dayOfWeek, () => [])
            .add(data.completionRate);
      }

      String bestDay = 'N/A';
      double bestAvg = 0.0;
      dayPerformance.forEach((day, rates) {
        final avg = rates.reduce((a, b) => a + b) / rates.length;
        if (avg > bestAvg) {
          bestAvg = avg;
          bestDay = _getDayName(day);
        }
      });

      // Determine improvement area
      String improvementArea = 'N/A';
      if (trends.averageCompletionRate < 0.6) {
        improvementArea = 'Overall consistency - try setting daily reminders';
      } else if (leastConsistent != 'N/A') {
        improvementArea =
            '$leastConsistent prayer - focus on maintaining this prayer';
      } else if (trends.trendDirection == TrendDirection.declining) {
        improvementArea =
            'Maintaining momentum - your recent trend is declining';
      } else {
        improvementArea = 'Excellent performance! Keep up the great work.';
      }

      return PrayerPerformanceData(
        date: DateTime.now(), // Not used for insights
        completedPrayers: 0, // Not used for insights
        totalPrayers: 0, // Not used for insights
        completionRate: 0.0, // Not used for insights
        completedPrayerNames: [], // Not used for insights
        mostConsistentPrayer: _capitalizeFirst(mostConsistent),
        leastConsistentPrayer: _capitalizeFirst(leastConsistent),
        bestPerformingDay: bestDay,
        improvementArea: improvementArea,
      );
    } catch (e, s) {
      _logger.error(
        'Error getting performance insights',
        error: e,
        stackTrace: s,
      );
      return PrayerPerformanceData(
        date: DateTime.now(),
        completedPrayers: 0,
        totalPrayers: 0,
        completionRate: 0.0,
        completedPrayerNames: [],
        mostConsistentPrayer: 'N/A',
        leastConsistentPrayer: 'N/A',
        bestPerformingDay: 'N/A',
        improvementArea: 'Unable to generate insights',
      );
    }
  }

  /// Get monthly prayer distribution
  Future<Map<String, int>> getMonthlyDistribution(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0); // Last day of month

      final performanceData = await getPerformanceData(
        startDate: startDate,
        endDate: endDate,
      );

      final distribution = <String, int>{};
      for (final data in performanceData) {
        final dayKey = data.date.day.toString();
        distribution[dayKey] = data.completedPrayers;
      }

      return distribution;
    } catch (e, s) {
      _logger.error(
        'Error getting monthly distribution',
        error: e,
        stackTrace: s,
      );
      return {};
    }
  }

  /// Calculate trend slope using simple linear regression
  double _calculateTrendSlope(List<PrayerPerformanceData> data) {
    if (data.length < 2) return 0.0;

    final n = data.length;
    final sumX = data
        .asMap()
        .entries
        .map((e) => e.key.toDouble())
        .reduce((a, b) => a + b);
    final sumY = data.map((d) => d.completionRate).reduce((a, b) => a + b);
    final sumXY = data
        .asMap()
        .entries
        .map((e) => e.key * data[e.key].completionRate)
        .reduce((a, b) => a + b);
    final sumXX = data
        .asMap()
        .entries
        .map((e) => e.key * e.key.toDouble())
        .reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope.isNaN ? 0.0 : slope;
  }

  /// Calculate completion rates for each prayer type
  Future<Map<String, double>> _calculatePrayerTypeRates(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final prayerCounts = <String, int>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
      final prayerTotals = <String, int>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };

      for (
        DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dateStr = date.toIso8601String().split('T')[0];
        final completedPrayers = await _database.getPrayerHistory(dateStr);

        if (completedPrayers != null) {
          final prayerList = completedPrayers.split(',');
          for (final prayer in prayerList) {
            if (prayerCounts.containsKey(prayer)) {
              prayerCounts[prayer] = prayerCounts[prayer]! + 1;
            }
          }
        }

        // Increment totals for each prayer
        prayerTotals.forEach((prayer, count) {
          prayerTotals[prayer] = count + 1;
        });
      }

      // Calculate rates
      final rates = <String, double>{};
      prayerCounts.forEach((prayer, count) {
        final total = prayerTotals[prayer] ?? 1;
        rates[prayer] = count / total;
      });

      return rates;
    } catch (e, s) {
      _logger.error(
        'Error calculating prayer type rates',
        error: e,
        stackTrace: s,
      );
      return {};
    }
  }

  String _getDayName(int dayOfWeek) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dayOfWeek - 1];
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
