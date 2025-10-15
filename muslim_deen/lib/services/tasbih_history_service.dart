import 'dart:async';
import 'dart:convert';

import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Cache entry for dhikr targets
class DhikrTargetsCacheEntry {
  final Map<String, int> targets;
  final DateTime calculatedAt;

  DhikrTargetsCacheEntry({required this.targets, required this.calculatedAt});

  bool get isExpired =>
      DateTime.now().difference(calculatedAt) > const Duration(minutes: 10);
}

/// Cache entry for tasbih statistics
class TasbihStatsCacheEntry {
  final Map<String, int> stats;
  final DateTime calculatedAt;
  final int days;

  TasbihStatsCacheEntry({
    required this.stats,
    required this.calculatedAt,
    required this.days,
  });

  bool get isExpired =>
      DateTime.now().difference(calculatedAt) > const Duration(minutes: 5);
}

/// Service to track tasbih/dhikr counts and provide historical statistics
class TasbihHistoryService {
  static TasbihHistoryService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();
  final StorageService _storage = locator<StorageService>();

  static const int _maxHistoryDays = 90; // Keep 90 days of history

  // Caching for frequently accessed data
  DhikrTargetsCacheEntry? _dhikrTargetsCache;
  final Map<String, TasbihStatsCacheEntry> _statsCache = {};
  Timer? _cacheCleanupTimer;
  static const Duration _cacheCleanupInterval = Duration(minutes: 15);

  factory TasbihHistoryService() {
    _instance ??= TasbihHistoryService._internal();
    return _instance!;
  }

  TasbihHistoryService._internal() {
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
    // Clean dhikr targets cache
    if (_dhikrTargetsCache?.isExpired == true) {
      _dhikrTargetsCache = null;
      _logger.debug('Cleaned up expired dhikr targets cache');
    }

    // Clean stats cache
    final expiredKeys = <String>[];
    for (final entry in _statsCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _statsCache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.debug(
        'Cleaned up ${expiredKeys.length} expired stats cache entries',
      );
    }
  }

  /// Generate cache key for statistics
  String _generateStatsCacheKey(int days) {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    return 'stats_${todayKey}_$days';
  }

  /// Get cached statistics if available and not expired
  Map<String, int>? _getCachedStats(int days) {
    final cacheKey = _generateStatsCacheKey(days);
    final cachedEntry = _statsCache[cacheKey];

    if (cachedEntry != null &&
        !cachedEntry.isExpired &&
        cachedEntry.days == days) {
      _logger.debug('Retrieved tasbih stats from cache for $days days');
      return cachedEntry.stats;
    }

    return null;
  }

  /// Cache statistics calculation result
  void _cacheStats(Map<String, int> stats, int days) {
    final cacheKey = _generateStatsCacheKey(days);
    _statsCache[cacheKey] = TasbihStatsCacheEntry(
      stats: stats,
      calculatedAt: DateTime.now(),
      days: days,
    );

    _logger.debug('Cached tasbih stats for $days days');
  }

  /// Invalidate caches when tasbih data changes
  void _invalidateCaches() {
    _dhikrTargetsCache = null;
    _statsCache.clear();
    _logger.debug('Invalidated all tasbih caches');
  }

  /// Dispose of resources
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    _invalidateCaches();
  }

  /// Record a tasbih count for today with batch operations
  Future<void> recordTasbihCount(String dhikrType, int count) async {
    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      // Use transaction for atomic update
      await _database.transaction((txn) async {
        // Get existing counts for today
        final todayData = await _database.getTasbihHistory(dateKey, txn: txn);
        todayData[dhikrType] = (todayData[dhikrType] ?? 0) + count;

        // Batch update all dhikr types for today
        final batchData = <String, Map<String, int>>{dateKey: todayData};

        await _database.batchInsertTasbihHistory(batchData, txn: txn);
      });

      // Invalidate caches since tasbih data changed
      _invalidateCaches();

      _logger.info('Recorded $count $dhikrType tasbihs on $dateKey');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to record tasbih count',
        error: e,
        stackTrace: stackTrace,
        data: {'dhikr': dhikrType, 'count': count},
      );
    }
  }

  /// Record multiple tasbih counts in a single batch operation
  Future<void> recordTasbihCountsBatch(Map<String, int> counts) async {
    if (counts.isEmpty) return;

    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      // Use transaction for atomic update
      await _database.transaction((txn) async {
        // Get existing counts for today
        final todayData = await _database.getTasbihHistory(dateKey, txn: txn);

        // Update counts
        for (final entry in counts.entries) {
          todayData[entry.key] = (todayData[entry.key] ?? 0) + entry.value;
        }

        // Batch update all dhikr types for today
        final batchData = <String, Map<String, int>>{dateKey: todayData};

        await _database.batchInsertTasbihHistory(batchData, txn: txn);
      });

      // Invalidate caches since tasbih data changed
      _invalidateCaches();

      _logger.info('Batch recorded ${counts.length} tasbih types on $dateKey');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to record tasbih counts batch',
        error: e,
        stackTrace: stackTrace,
        data: {'counts': counts},
      );
    }
  }

  /// Get tasbih counts for a specific date
  Future<Map<String, int>> getTasbihCounts(DateTime date) async {
    try {
      final dateKey = _getDateKey(date);
      return await _database.getTasbihHistory(dateKey);
    } catch (e) {
      _logger.warning('Error getting tasbih counts for date', error: e);
      return {};
    }
  }

  /// Get tasbih counts for today
  Future<Map<String, int>> getTodayTasbihCounts() async {
    return getTasbihCounts(DateTime.now());
  }

  /// Get total tasbih counts for the last N days with caching
  Future<Map<String, int>> getTasbihStatsForDays(int days) async {
    // Check cache first
    final cachedStats = _getCachedStats(days);
    if (cachedStats != null) {
      return cachedStats;
    }

    var stats = <String, int>{};
    final now = DateTime.now();

    try {
      // Use optimized query with date range filtering
      stats = await _database.transaction((txn) async {
        final startDate = now.subtract(Duration(days: days - 1));
        final startDateKey = _getDateKey(startDate);
        final endDateKey = _getDateKey(now);

        // Get all tasbih history for the date range in a single query
        final result = await txn.query(
          'tasbih_history',
          where: 'date >= ? AND date <= ?',
          whereArgs: [startDateKey, endDateKey],
          orderBy: 'date DESC',
        );

        final aggregatedStats = <String, int>{};
        for (final row in result) {
          final dhikrType = row['dhikr_type'] as String;
          final count = row['count'] as int;
          aggregatedStats[dhikrType] =
              (aggregatedStats[dhikrType] ?? 0) + count;
        }

        return aggregatedStats;
      });

      // Cache the result
      _cacheStats(stats, days);

      _logger.debug(
        'Retrieved $days-day tasbih stats with optimized query: $stats',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Error calculating tasbih statistics',
        error: e,
        stackTrace: stackTrace,
      );
    }

    return stats;
  }

  /// Get weekly tasbih statistics
  Future<Map<String, int>> getWeeklyTasbihStats() async {
    return getTasbihStatsForDays(7);
  }

  /// Get monthly tasbih statistics
  Future<Map<String, int>> getMonthlyTasbihStats() async {
    return getTasbihStatsForDays(30);
  }

  /// Get daily tasbih data for visualization (last N days)
  Future<Map<String, Map<String, int>>> getDailyTasbihGrid(int days) async {
    final grid = <String, Map<String, int>>{};
    final now = DateTime.now();

    try {
      // Generate all date keys at once
      final dateKeys = <String>[];
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        dateKeys.add(_getDateKey(date));
      }

      // Fetch all tasbih history in a single batch query
      final historyBatch = await _database.getTasbihHistoryBatch(dateKeys);

      // Process the batched results
      for (final dateKey in dateKeys) {
        grid[dateKey] = historyBatch[dateKey] ?? {};
      }
    } catch (e) {
      _logger.error('Error getting daily tasbih grid', error: e);
    }

    return grid;
  }

  /// Get total tasbih count for a specific dhikr type across all time
  Future<int> getTotalTasbihCount(String dhikrType) async {
    try {
      int total = 0;
      final now = DateTime.now();

      // Generate all date keys at once
      final dateKeys = <String>[];
      for (int i = 0; i < _maxHistoryDays; i++) {
        final date = now.subtract(Duration(days: i));
        dateKeys.add(_getDateKey(date));
      }

      // Fetch all tasbih history in a single batch query
      final historyBatch = await _database.getTasbihHistoryBatch(dateKeys);

      // Process the batched results
      for (final dateKey in dateKeys) {
        final counts = historyBatch[dateKey] ?? {};
        total += counts[dhikrType] ?? 0;
      }

      return total;
    } catch (e) {
      _logger.warning('Error getting total tasbih count', error: e);
      return 0;
    }
  }

  /// Get current tasbih streak (consecutive days with all dhikr targets completed)
  /// Get streak data (consecutive days with all dhikr targets completed)
  Future<int> getCurrentTasbihStreak({Map<String, int>? customTargets}) async {
    final targets = customTargets ?? AppConstants.defaultDhikrTargets;
    int streak = 0;
    final now = DateTime.now();

    try {
      // Generate all date keys at once (up to 365 days)
      final dateKeys = <String>[];
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        dateKeys.add(_getDateKey(date));
      }

      // Fetch all tasbih history in a single batch query
      final historyBatch = await _database.getTasbihHistoryBatch(dateKeys);

      // Process the batched results in order
      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);

        final counts = historyBatch[dateKey] ?? {};

        // Check if all dhikr targets are met
        bool allTargetsMet = true;
        for (final entry in targets.entries) {
          final dhikrType = entry.key;
          final target = entry.value;
          final actual = counts[dhikrType] ?? 0;
          if (actual < target) {
            allTargetsMet = false;
            break;
          }
        }

        if (allTargetsMet) {
          streak++;
        } else {
          break;
        }
      }

      // Update personal record if current streak is higher
      await _updateTasbihStreakRecord(streak);

      _logger.debug('Current tasbih streak with batch query: $streak days');
    } catch (e) {
      _logger.warning('Error calculating tasbih streak', error: e);
    }

    return streak;
  }

  /// Generate a date key in format YYYY-MM-DD
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get best tasbih streak (personal record)
  Future<int> getBestTasbihStreak() async {
    return getTasbihStreakRecord();
  }

  /// Get personal record for tasbih streak
  Future<int> getTasbihStreakRecord() async {
    try {
      final record = await _database.getSettings('tasbih_streak_record');
      return record != null ? int.parse(record) : 0;
    } catch (e) {
      _logger.warning('Error getting tasbih streak record', error: e);
      return 0;
    }
  }

  /// Update personal record for tasbih streak if current streak is higher
  Future<void> _updateTasbihStreakRecord(int currentStreak) async {
    try {
      final currentRecord = await getTasbihStreakRecord();
      if (currentStreak > currentRecord) {
        await _database.saveSettings(
          'tasbih_streak_record',
          currentStreak.toString(),
        );
        _logger.info('New tasbih streak record: $currentStreak days');
      }
    } catch (e) {
      _logger.warning('Error updating tasbih streak record', error: e);
    }
  }

  /// Get the current effective dhikr targets with caching
  Future<Map<String, int>> getCurrentDhikrTargets() async {
    // Check cache first
    if (_dhikrTargetsCache != null && !_dhikrTargetsCache!.isExpired) {
      _logger.debug('Retrieved dhikr targets from cache');
      return _dhikrTargetsCache!.targets;
    }

    try {
      final targets = <String, int>{};

      // Check if custom targets are enabled
      final isCustomTarget =
          _storage.getData('is_custom_target') as bool? ?? false;

      if (isCustomTarget) {
        // Load custom targets
        final customTargetsJson =
            _storage.getData('custom_dhikr_targets') as String?;
        if (customTargetsJson != null) {
          final customTargets =
              json.decode(customTargetsJson) as Map<String, dynamic>;
          for (final entry in customTargets.entries) {
            targets[entry.key] = entry.value as int;
          }
        }
      }

      // For any missing targets, use stored target or defaults
      for (final dhikrType in AppConstants.dhikrOrder) {
        if (!targets.containsKey(dhikrType)) {
          final storedTarget = _storage.getData('tasbih_target') as int?;
          targets[dhikrType] =
              (storedTarget != null && storedTarget > 0)
                  ? storedTarget
                  : AppConstants.defaultDhikrTargets[dhikrType]!;
        }
      }

      // Cache the result
      _dhikrTargetsCache = DhikrTargetsCacheEntry(
        targets: targets,
        calculatedAt: DateTime.now(),
      );

      _logger.debug('Current dhikr targets: $targets');
      return targets;
    } catch (e) {
      _logger.warning(
        'Error getting current dhikr targets, using defaults',
        error: e,
      );
      return AppConstants.defaultDhikrTargets;
    }
  }

  /// Invalidate dhikr targets cache (call when settings change)
  void invalidateDhikrTargetsCache() {
    _dhikrTargetsCache = null;
    _logger.debug('Invalidated dhikr targets cache');
  }
}
