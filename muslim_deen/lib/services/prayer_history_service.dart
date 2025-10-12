import 'dart:async';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Cache entry for streak calculations
class StreakCacheEntry {
  final int streak;
  final DateTime calculatedAt;
  final String cacheKey;

  StreakCacheEntry({
    required this.streak,
    required this.calculatedAt,
    required this.cacheKey,
  });

  bool get isExpired =>
      DateTime.now().difference(calculatedAt) > const Duration(minutes: 5);
}

/// Service to track prayer completion history and provide statistics
class PrayerHistoryService {
  static PrayerHistoryService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();

  // Streak calculation caching
  final Map<String, StreakCacheEntry> _streakCache = {};
  Timer? _cacheCleanupTimer;
  static const Duration _cacheCleanupInterval = Duration(minutes: 10);

  factory PrayerHistoryService() {
    _instance ??= PrayerHistoryService._internal();
    return _instance!;
  }

  PrayerHistoryService._internal() {
    _startCacheCleanupTimer();
  }

  /// Start periodic cleanup of expired cache entries
  void _startCacheCleanupTimer() {
    _cacheCleanupTimer = Timer.periodic(_cacheCleanupInterval, (_) {
      _cleanupExpiredCache();
    });
  }

  /// Clean up expired cache entries
  void _cleanupExpiredCache() {
    final expiredKeys = <String>[];
    for (final entry in _streakCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _streakCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.debug(
        'Cleaned up ${expiredKeys.length} expired streak cache entries',
      );
    }
  }

  /// Generate cache key for streak calculation
  String _generateStreakCacheKey(int totalPrayersPerDay) {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    return 'streak_${todayKey}_$totalPrayersPerDay';
  }

  /// Get cached streak if available and not expired
  int? _getCachedStreak(int totalPrayersPerDay) {
    final cacheKey = _generateStreakCacheKey(totalPrayersPerDay);
    final cachedEntry = _streakCache[cacheKey];

    if (cachedEntry != null && !cachedEntry.isExpired) {
      _logger.debug('Retrieved streak from cache: ${cachedEntry.streak}');
      return cachedEntry.streak;
    }

    return null;
  }

  /// Cache streak calculation result
  void _cacheStreak(int streak, int totalPrayersPerDay) {
    final cacheKey = _generateStreakCacheKey(totalPrayersPerDay);
    _streakCache[cacheKey] = StreakCacheEntry(
      streak: streak,
      calculatedAt: DateTime.now(),
      cacheKey: cacheKey,
    );

    _logger.debug('Cached streak calculation: $streak');
  }

  /// Invalidate streak cache when prayer data changes
  void _invalidateStreakCache() {
    final cacheSize = _streakCache.length;
    _streakCache.clear();
    _logger.debug('Invalidated streak cache ($cacheSize entries)');
  }

  /// Dispose of resources
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    _streakCache.clear();
  }

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

        // Invalidate streak cache since prayer data changed
        _invalidateStreakCache();
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

        // Invalidate streak cache since prayer data changed
        _invalidateStreakCache();
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
      // Generate all date keys at once
      final dateKeys = <String>[];
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        dateKeys.add(_getDateKey(date));
      }

      // Fetch all prayer history in a single batch query
      final historyBatch = await _database.getPrayerHistoryBatch(dateKeys);

      // Process the batched results
      for (final dateKey in dateKeys) {
        final data = historyBatch[dateKey] ?? '';
        final completedPrayers = data.isEmpty ? <String>[] : data.split(',');

        for (final prayer in completedPrayers) {
          stats[prayer] = (stats[prayer] ?? 0) + 1;
        }
      }

      _logger.debug('Retrieved $days-day stats with batch query: $stats');
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
      // Generate all date keys at once
      final dateKeys = <String>[];
      final dateKeyToOriginalDate = <String, DateTime>{};

      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        dateKeys.add(dateKey);
        dateKeyToOriginalDate[dateKey] = date;
      }

      // Fetch all prayer history in a single batch query
      final historyBatch = await _database.getPrayerHistoryBatch(dateKeys);

      // Process the batched results
      for (final dateKey in dateKeys) {
        final data = historyBatch[dateKey] ?? '';
        final completedPrayers = data.isEmpty ? <String>[] : data.split(',');

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

  /// Get streak data (consecutive days with all prayers completed) with caching
  Future<int> getCurrentStreak({int totalPrayersPerDay = 5}) async {
    // Check cache first
    final cachedStreak = _getCachedStreak(totalPrayersPerDay);
    if (cachedStreak != null) {
      return cachedStreak;
    }

    int streak = 0;
    final now = DateTime.now();

    try {
      // Use optimized query with date range filtering instead of individual day-by-day queries
      streak = await _database.transaction((txn) async {
        // Calculate the start date for streak checking (up to 365 days back)
        final startDate = now.subtract(const Duration(days: 365));
        final startDateKey = _getDateKey(startDate);

        // Get all prayer history from the last 365 days in a single query
        final result = await txn.query(
          'prayer_history',
          where: 'date >= ? AND date <= ?',
          whereArgs: [startDateKey, _getDateKey(now)],
          orderBy: 'date DESC',
        );

        // Create a map for quick lookup
        final historyMap = <String, String>{};
        for (final row in result) {
          historyMap[row['date'] as String] =
              row['completed_prayers'] as String;
        }

        // Calculate streak by checking consecutive days
        int currentStreak = 0;
        for (int i = 0; i < 365; i++) {
          final checkDate = now.subtract(Duration(days: i));
          final dateKey = _getDateKey(checkDate);

          final completedPrayers = historyMap[dateKey] ?? '';
          final completed =
              completedPrayers.isEmpty
                  ? <String>[]
                  : completedPrayers.split(',');

          if (completed.length >= totalPrayersPerDay) {
            currentStreak++;
          } else {
            break;
          }
        }

        return currentStreak;
      });

      // Update personal record if current streak is higher
      await _updatePrayerStreakRecord(streak);

      // Cache the result
      _cacheStreak(streak, totalPrayersPerDay);

      _logger.debug('Current prayer streak with optimized query: $streak days');
    } catch (e, stackTrace) {
      _logger.error(
        'Error calculating streak',
        error: e,
        stackTrace: stackTrace,
      );
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
