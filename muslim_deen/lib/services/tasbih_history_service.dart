import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Service to track tasbih/dhikr counts and provide historical statistics
class TasbihHistoryService {
  static TasbihHistoryService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final DatabaseService _database = locator<DatabaseService>();

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

  /// Get tasbih session history (recent sessions with timestamps)
  Future<List<Map<String, dynamic>>> getTasbihSessions(int limit) async {
    final sessions = <Map<String, dynamic>>[];

    try {
      // This would require storing session data separately
      // For now, return empty list as sessions aren't tracked yet
      _logger.debug('Tasbih sessions not yet implemented');
    } catch (e) {
      _logger.error('Error getting tasbih sessions', error: e);
    }

    return sessions;
  }

  /// Generate a date key in format YYYY-MM-DD
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
