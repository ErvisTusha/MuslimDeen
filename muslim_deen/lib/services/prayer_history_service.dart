import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Service to track prayer completion history and provide statistics
class PrayerHistoryService {
  static PrayerHistoryService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();

  factory PrayerHistoryService() {
    _instance ??= PrayerHistoryService._internal();
    return _instance!;
  }

  PrayerHistoryService._internal();

  /// Mark a prayer as completed for today
  Future<void> markPrayerCompleted(String prayerName) async {
    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      // Get existing prayers for today
      final todayData = await _database.getPrayerHistory(dateKey) ?? '';
      final completedPrayers =
          todayData.isEmpty ? <String>[] : todayData.split(',');

      // Add prayer if not already marked
      if (!completedPrayers.contains(prayerName)) {
        completedPrayers.add(prayerName);
        await _database.savePrayerHistory(dateKey, completedPrayers.join(','));
        _logger.info('Prayer marked as completed: $prayerName on $dateKey');
      }

      // Clean old history
      await _cleanOldHistory();
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to mark prayer as completed',
        error: e,
        stackTrace: stackTrace,
        data: {'prayer': prayerName},
      );
    }
  }

  /// Unmark a prayer for today
  Future<void> unmarkPrayerCompleted(String prayerName) async {
    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      final todayData = await _database.getPrayerHistory(dateKey) ?? '';
      final completedPrayers =
          todayData.isEmpty ? <String>[] : todayData.split(',');

      if (completedPrayers.contains(prayerName)) {
        completedPrayers.remove(prayerName);
        if (completedPrayers.isEmpty) {
          // For database, we can't easily delete by date, so save empty string
          await _database.savePrayerHistory(dateKey, '');
        } else {
          await _database.savePrayerHistory(
            dateKey,
            completedPrayers.join(','),
          );
        }
        _logger.info('Prayer unmarked: $prayerName on $dateKey');
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to unmark prayer',
        error: e,
        stackTrace: stackTrace,
        data: {'prayer': prayerName},
      );
    }
  }

  /// Check if a prayer is completed for a specific date
  Future<bool> isPrayerCompleted(String prayerName, DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final data = await _database.getPrayerHistory(dateKey) ?? '';
      final completedPrayers = data.isEmpty ? <String>[] : data.split(',');
      return completedPrayers.contains(prayerName);
    } catch (e) {
      _logger.warning('Error checking prayer completion', error: e);
      return false;
    }
  }

  /// Check if a prayer is completed today
  Future<bool> isPrayerCompletedToday(String prayerName) async {
    return isPrayerCompleted(prayerName, DateTime.now());
  }

  /// Get prayers completed on a specific date
  Future<List<String>> getCompletedPrayers(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      final data = await _database.getPrayerHistory(dateKey) ?? '';
      return data.isEmpty ? [] : data.split(',');
    } catch (e) {
      _logger.warning('Error getting completed prayers', error: e);
      return [];
    }
  }

  /// Get prayers completed today
  Future<List<String>> getCompletedPrayersToday() async {
    return getCompletedPrayers(DateTime.now());
  }

  /// Get weekly statistics (last 7 days)
  Future<Map<String, int>> getWeeklyStats() async {
    return _getStatsForDays(7);
  }

  /// Get monthly statistics (last 30 days)
  Future<Map<String, int>> getMonthlyStats() async {
    return _getStatsForDays(30);
  }

  /// Get statistics for a specific number of days
  Future<Map<String, int>> _getStatsForDays(int days) async {
    final stats = <String, int>{};
    final now = DateTime.now();

    try {
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final completedPrayers = await getCompletedPrayers(date);

        for (final prayer in completedPrayers) {
          stats[prayer] = (stats[prayer] ?? 0) + 1;
        }
      }
      _logger.debug('Retrieved $days-day stats: $stats');
    } catch (e, stackTrace) {
      _logger.error(
        'Error calculating prayer statistics',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return stats;
  }

  /// Get completion rate for last N days
  Future<double> getCompletionRate({
    int days = 7,
    int totalPrayersPerDay = 5,
  }) async {
    try {
      final stats = await _getStatsForDays(days);
      final totalCompleted = stats.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      final totalExpected = days * totalPrayersPerDay;
      return totalExpected > 0 ? totalCompleted / totalExpected : 0.0;
    } catch (e) {
      _logger.warning('Error calculating completion rate', error: e);
      return 0.0;
    }
  }

  /// Get daily completion data for visualization
  Future<Map<String, Map<String, bool>>> getDailyCompletionGrid(
    int days,
  ) async {
    final grid = <String, Map<String, bool>>{};
    final now = DateTime.now();
    const prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

    try {
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final completedPrayers = await getCompletedPrayers(date);

        grid[dateKey] = {
          for (var prayer in prayers) prayer: completedPrayers.contains(prayer),
        };
      }
    } catch (e) {
      _logger.error('Error getting daily completion grid', error: e);
    }

    return grid;
  }

  /// Generate a date key in format YYYY-MM-DD
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clean history older than _maxHistoryDays
  Future<void> _cleanOldHistory() async {
    try {
      await _database.cleanOldHistory();
      _logger.debug('Old prayer history cleaned from database');
    } catch (e) {
      _logger.warning('Error cleaning old prayer history', error: e);
    }
  }

  /// Get streak data (consecutive days with all prayers completed)
  Future<int> getCurrentStreak({int totalPrayersPerDay = 5}) async {
    int streak = 0;
    final now = DateTime.now();

    try {
      for (int i = 0; i < 365; i++) {
        // Max 1 year streak
        final date = now.subtract(Duration(days: i));
        final completed = await getCompletedPrayers(date);

        if (completed.length >= totalPrayersPerDay) {
          streak++;
        } else {
          break;
        }
      }

      // Update personal record if current streak is higher
      await _updatePrayerStreakRecord(streak);

      _logger.debug('Current prayer streak: $streak days');
    } catch (e) {
      _logger.warning('Error calculating streak', error: e);
    }

    return streak;
  }

  /// Get personal record for prayer streak
  Future<int> getPrayerStreakRecord() async {
    try {
      final record = await _database.getSettings('prayer_streak_record');
      return record != null ? int.parse(record) : 0;
    } catch (e) {
      _logger.warning('Error getting prayer streak record', error: e);
      return 0;
    }
  }

  /// Update personal record for prayer streak if current streak is higher
  Future<void> _updatePrayerStreakRecord(int currentStreak) async {
    try {
      final currentRecord = await getPrayerStreakRecord();
      if (currentStreak > currentRecord) {
        await _database.saveSettings(
          'prayer_streak_record',
          currentStreak.toString(),
        );
        _logger.info('New prayer streak record: $currentStreak days');
      }
    } catch (e) {
      _logger.warning('Error updating prayer streak record', error: e);
    }
  }

  /// Get personal record for prayer streak
  Future<int> getBestStreak() async {
    return getPrayerStreakRecord();
  }
}
