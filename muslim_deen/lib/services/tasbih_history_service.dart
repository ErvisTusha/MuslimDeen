import 'dart:convert';

import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Service to track tasbih/dhikr counts and provide historical statistics
class TasbihHistoryService {
  static TasbihHistoryService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();
  final StorageService _storage = locator<StorageService>();

  static const int _maxHistoryDays = 90; // Keep 90 days of history

  factory TasbihHistoryService() {
    _instance ??= TasbihHistoryService._internal();
    return _instance!;
  }

  TasbihHistoryService._internal();

  /// Record a tasbih count for today
  Future<void> recordTasbihCount(String dhikrType, int count) async {
    try {
      final now = DateTime.now();
      final dateKey = _getDateKey(now);

      // Get existing counts for today
      final todayData = await _database.getTasbihHistory(dateKey);
      todayData[dhikrType] = (todayData[dhikrType] ?? 0) + count;

      // Save each dhikr type separately
      for (final entry in todayData.entries) {
        await _database.saveTasbihHistory(dateKey, entry.key, entry.value);
      }

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

  /// Get total tasbih counts for the last N days
  Future<Map<String, int>> getTasbihStatsForDays(int days) async {
    final stats = <String, int>{};
    final now = DateTime.now();

    try {
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dailyCounts = await getTasbihCounts(date);

        dailyCounts.forEach((dhikr, count) {
          stats[dhikr] = (stats[dhikr] ?? 0) + count;
        });
      }
      _logger.debug('Retrieved $days-day tasbih stats: $stats');
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
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = _getDateKey(date);
        final counts = await getTasbihCounts(date);

        grid[dateKey] = counts;
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

      // Check last 90 days
      for (int i = 0; i < _maxHistoryDays; i++) {
        final date = now.subtract(Duration(days: i));
        final counts = await getTasbihCounts(date);
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
      for (int i = 0; i < 365; i++) {
        // Max 1 year streak
        final date = now.subtract(Duration(days: i));
        final counts = await getTasbihCounts(date);

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

      _logger.debug('Current tasbih streak: $streak days');
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

  /// Get the current effective dhikr targets (matching TesbihView logic)
  Future<Map<String, int>> getCurrentDhikrTargets() async {
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
}
