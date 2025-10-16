import 'dart:async';
import 'dart:convert';

import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Cache entry for dhikr targets
/// 
/// This class represents a cached entry containing dhikr targets with their
/// calculated timestamp. It includes expiration logic to ensure cache freshness.
class DhikrTargetsCacheEntry {
  final Map<String, int> targets;
  final DateTime calculatedAt;

  DhikrTargetsCacheEntry({required this.targets, required this.calculatedAt});

  /// Check if the cache entry has expired
  /// 
  /// Returns true if the cache is older than 10 minutes, ensuring
  /// that targets are refreshed periodically to reflect user preference changes.
  bool get isExpired =>
      DateTime.now().difference(calculatedAt) > const Duration(minutes: 10);
}

/// Cache entry for tasbih statistics
/// 
/// This class represents a cached entry containing aggregated tasbih statistics
/// for a specific number of days. It includes expiration logic to balance
/// performance with data freshness.
class TasbihStatsCacheEntry {
  final Map<String, int> stats;
  final DateTime calculatedAt;
  final int days;

  TasbihStatsCacheEntry({
    required this.stats,
    required this.calculatedAt,
    required this.days,
  });

  /// Check if the cache entry has expired
  /// 
  /// Returns true if the cache is older than 5 minutes, providing a good
  /// balance between performance and data freshness for statistics.
  bool get isExpired =>
      DateTime.now().difference(calculatedAt) > const Duration(minutes: 5);
}

/// Service to track tasbih/dhikr counts and provide historical statistics
/// 
/// This service provides comprehensive functionality for tracking, storing, and
/// analyzing tasbih (dhikr) counts over time. It implements sophisticated caching
/// strategies to optimize performance while maintaining data accuracy.
/// 
/// Features:
/// - Record individual and batch tasbih counts with transaction safety
/// - Calculate statistics for various time periods (daily, weekly, monthly)
/// - Track streaks and personal records
/// - Manage custom dhikr targets
/// - Optimize database queries with batch operations
/// - Implement multi-level caching for frequently accessed data
/// 
/// Usage:
/// ```dart
/// final service = TasbihHistoryService();
/// await service.recordTasbihCount('SubhanAllah', 33);
/// final weeklyStats = await service.getWeeklyTasbihStats();
/// ```
/// 
/// Design Patterns:
/// - Singleton: Ensures consistent cache management across the app
/// - Repository: Abstracts database operations for tasbih data
/// - Cache-Aside: Implements caching with explicit invalidation
/// - Command Pattern: Encapsulates database operations in transactions
/// 
/// Performance Considerations:
/// - Uses database transactions for atomicity and performance
/// - Implements multi-level caching with TTL-based expiration
/// - Optimizes queries with batch operations and date range filtering
/// - Limits history to 90 days to prevent database bloat
/// - Uses periodic cache cleanup to prevent memory leaks
/// 
/// Threading:
/// - All database operations are asynchronous and non-blocking
/// - Cache cleanup runs on a separate timer
/// - Safe for concurrent access through database transactions
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

  /// Singleton factory constructor
  /// 
  /// Ensures only one instance exists to maintain cache consistency
  /// and prevent resource conflicts.
  factory TasbihHistoryService() {
    _instance ??= TasbihHistoryService._internal();
    return _instance!;
  }

  /// Internal constructor for singleton pattern
  /// 
  /// Initializes the cache cleanup timer to automatically remove
  /// expired entries and prevent memory leaks.
  TasbihHistoryService._internal() {
    _startCacheCleanupTimer();
  }

  /// Start periodic cleanup of expired cache entries
  /// 
  /// Sets up a timer that runs every 15 minutes to clean up expired
  /// cache entries, preventing memory leaks and ensuring cache freshness.
  void _startCacheCleanupTimer() {
    _cacheCleanupTimer = Timer.periodic(_cacheCleanupInterval, (_) {
      _cleanupExpiredCache();
    });
  }

  /// Clean up expired cache entries
  /// 
  /// Iterates through all cache entries and removes those that have
  /// expired based on their TTL. This ensures memory efficiency while
  /// maintaining frequently used data in cache.
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
  /// 
  /// Creates a unique cache key based on the current date and the
  /// number of days for which statistics are calculated.
  /// 
  /// Parameters:
  /// - [days]: The number of days for the statistics calculation
  /// 
  /// Returns:
  /// - A unique string key for caching the statistics
  String _generateStatsCacheKey(int days) {
    final today = DateTime.now();
    final todayKey = _getDateKey(today);
    return 'stats_${todayKey}_$days';
  }

  /// Get cached statistics if available and not expired
  /// 
  /// Checks the cache for existing statistics that match the requested
  /// number of days and haven't expired. This significantly improves
  /// performance for repeated statistics queries.
  /// 
  /// Parameters:
  /// - [days]: The number of days for the statistics
  /// 
  /// Returns:
  /// - Cached statistics if available and valid, null otherwise
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
  /// 
  /// Stores the calculated statistics in cache with a timestamp for
  /// future retrieval. This improves performance for repeated queries.
  /// 
  /// Parameters:
  /// - [stats]: The calculated statistics to cache
  /// - [days]: The number of days the statistics cover
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
  /// 
  /// Clears all caches when tasbih data is modified to ensure
  /// data consistency. This is called after any write operation.
  void _invalidateCaches() {
    _dhikrTargetsCache = null;
    _statsCache.clear();
    _logger.debug('Invalidated all tasbih caches');
  }

  /// Dispose of resources
  /// 
  /// Cleans up resources when the service is no longer needed.
  /// Cancels the cache cleanup timer and clears all caches.
  void dispose() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
    _invalidateCaches();
  }

  /// Record a tasbih count for today with batch operations
  /// 
  /// Records a single tasbih count for the current date using a database
  /// transaction to ensure atomicity. The operation updates existing counts
  /// or creates new entries as needed.
  /// 
  /// Parameters:
  /// - [dhikrType]: The type of dhikr (e.g., 'SubhanAllah')
  /// - [count]: The number of counts to add
  /// 
  /// Algorithm:
  /// 1. Gets existing counts for today
  /// 2. Adds the new count to the existing total
  /// 3. Uses batch insert for efficient database operation
  /// 4. Invalidates caches to ensure consistency
  /// 
  /// Error Handling:
  /// - Logs errors without throwing exceptions
  /// - Includes context data for debugging
  /// 
  /// Performance:
  /// - Uses database transactions for atomicity
  /// - Batch operations minimize database round trips
  /// - Cache invalidation ensures data consistency
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
  /// 
  /// Efficiently records multiple dhikr types in a single transaction.
  /// This is optimal for batch operations like importing data or
  /// recording multiple dhikrs at once.
  /// 
  /// Parameters:
  /// - [counts]: Map of dhikr types to their counts
  /// 
  /// Algorithm:
  /// 1. Validates input (returns early if empty)
  /// 2. Gets existing counts for today
  /// 3. Updates all counts in a single transaction
  /// 4. Uses batch insert for efficiency
  /// 5. Invalidates caches
  /// 
  /// Performance:
  /// - Single transaction for all updates
  /// - Batch insert minimizes database operations
  /// - Early return for empty input
  /// 
  /// Error Handling:
  /// - Graceful error handling with detailed logging
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
  /// 
  /// Retrieves the tasbih counts for a specific date from the database.
  /// This is a direct database query with caching for frequently accessed dates.
  /// 
  /// Parameters:
  /// - [date]: The date to retrieve counts for
  /// 
  /// Returns:
  /// - Map of dhikr types to their counts for the specified date
  /// 
  /// Error Handling:
  /// - Returns empty map on error to prevent app crashes
  /// - Logs warnings for debugging
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
  /// 
  /// Convenience method to get today's tasbih counts.
  /// 
  /// Returns:
  /// - Map of dhikr types to their counts for today
  Future<Map<String, int>> getTodayTasbihCounts() async {
    return getTasbihCounts(DateTime.now());
  }

  /// Get total tasbih counts for the last N days with caching
  /// 
  /// Calculates aggregated statistics for the specified number of days.
  /// Uses caching to improve performance for repeated queries.
  /// 
  /// Parameters:
  /// - [days]: The number of days to include in the calculation
  /// 
  /// Algorithm:
  /// 1. Checks cache first for existing results
  /// 2. If not cached, performs optimized database query
  /// 3. Uses date range filtering for efficiency
  /// 4. Aggregates results in a single pass
  /// 5. Caches the result for future use
  /// 
  /// Performance:
  /// - Multi-level caching with TTL
  /// - Optimized query with date range filtering
  /// - Single database query with aggregation
  /// 
  /// Returns:
  /// - Map of dhikr types to their total counts over the period
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
  /// 
  /// Convenience method to get statistics for the last 7 days.
  /// 
  /// Returns:
  /// - Map of dhikr types to their total counts over the last week
  Future<Map<String, int>> getWeeklyTasbihStats() async {
    return getTasbihStatsForDays(7);
  }

  /// Get monthly tasbih statistics
  /// 
  /// Convenience method to get statistics for the last 30 days.
  /// 
  /// Returns:
  /// - Map of dhikr types to their total counts over the last month
  Future<Map<String, int>> getMonthlyTasbihStats() async {
    return getTasbihStatsForDays(30);
  }

  /// Get daily tasbih data for visualization (last N days)
  /// 
  /// Retrieves daily tasbih data for visualization purposes, such as
  /// creating charts or heat maps. Uses batch queries for efficiency.
  /// 
  /// Parameters:
  /// - [days]: The number of days to retrieve data for
  /// 
  /// Algorithm:
  /// 1. Generates all date keys for the requested period
  /// 2. Performs a single batch query to get all data
  /// 3. Organizes results into a daily grid structure
  /// 
  /// Performance:
  /// - Single batch query instead of multiple individual queries
  /// - Efficient date key generation
  /// 
  /// Returns:
  /// - Map of date keys to their respective dhikr counts
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
  /// 
  /// Calculates the total count for a specific dhikr type across all
  /// stored history (up to 90 days). Uses batch queries for efficiency.
  /// 
  /// Parameters:
  /// - [dhikrType]: The dhikr type to calculate the total for
  /// 
  /// Algorithm:
  /// 1. Generates all date keys for the history period
  /// 2. Performs a single batch query
  /// 3. Aggregates counts for the specific dhikr type
  /// 
  /// Performance:
  /// - Single batch query instead of iterative queries
  /// - Bounded by _maxHistoryDays to prevent excessive queries
  /// 
  /// Returns:
  /// - Total count for the specified dhikr type
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
  /// 
  /// Calculates the current streak of consecutive days where all dhikr
  /// targets were met. This is a key gamification feature to encourage
  /// consistent dhikr practice.
  /// 
  /// Parameters:
  /// - [customTargets]: Optional custom targets to use instead of defaults
  /// 
  /// Algorithm:
  /// 1. Gets targets (custom or default)
  /// 2. Checks each day backwards from today
  /// 3. Verifies all targets are met for each day
  /// 4. Stops at first day with incomplete targets
  /// 5. Updates personal record if current streak is higher
  /// 
  /// Performance:
  /// - Batch query to get all data at once
  /// - Early termination when streak breaks
  /// - Limited to 365 days for performance
  /// 
  /// Returns:
  /// - Current streak in days
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
  /// 
  /// Creates a standardized date key for database storage and caching.
  /// This format ensures chronological sorting and easy querying.
  /// 
  /// Parameters:
  /// - [date]: The date to convert to a key
  /// 
  /// Returns:
  /// - Date key in YYYY-MM-DD format
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get best tasbih streak (personal record)
  /// 
  /// Convenience method to get the user's best streak record.
  /// 
  /// Returns:
  /// - Personal best streak in days
  Future<int> getBestTasbihStreak() async {
    return getTasbihStreakRecord();
  }

  /// Get personal record for tasbih streak
  /// 
  /// Retrieves the stored personal record for longest streak.
  /// 
  /// Returns:
  /// - Personal record in days, 0 if none exists
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
  /// 
  /// Updates the stored personal record if the current streak exceeds it.
  /// This method is called automatically when calculating the current streak.
  /// 
  /// Parameters:
  /// - [currentStreak]: The current streak to potentially save as a record
  /// 
  /// Algorithm:
  /// 1. Gets existing record
  /// 2. Compares with current streak
  /// 3. Updates if current is higher
  /// 4. Logs the new record
  /// 
  /// Error Handling:
  /// - Graceful handling of storage errors
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
  /// 
  /// Retrieves the current dhikr targets, taking into account user preferences
  /// for custom targets. Uses caching to improve performance for repeated access.
  /// 
  /// Algorithm:
  /// 1. Checks cache first
  /// 2. Determines if custom targets are enabled
  /// 3. Loads custom targets if enabled
  /// 4. Falls back to stored targets or defaults for missing types
  /// 5. Caches the result
  /// 
  /// Performance:
  /// - Multi-level caching with 10-minute TTL
  /// - Efficient JSON parsing for custom targets
  /// - Graceful fallback to defaults
  /// 
  /// Returns:
  /// - Map of dhikr types to their target counts
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
  /// 
  /// Explicitly invalidates the dhikr targets cache. This should be called
  /// whenever user settings related to dhikr targets are changed.
  /// 
  /// Usage:
  /// Call this method when users modify their dhikr target settings
  /// to ensure the new targets take effect immediately.
  void invalidateDhikrTargetsCache() {
    _dhikrTargetsCache = null;
    _logger.debug('Invalidated dhikr targets cache');
  }
}