import 'dart:async';
import 'package:hijri/hijri_calendar.dart';
import 'package:uuid/uuid.dart';

import 'package:muslim_deen/models/fasting_record.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service for managing fasting records, streaks, and Ramadan tracking
class FastingService {
  final DatabaseService _databaseService;
  final LoggerService _logger = locator<LoggerService>();
  final Uuid _uuid = const Uuid();

  // Cache for fasting records
  final Map<String, FastingRecord> _recordCache = {};
  bool _isInitialized = false;

  // Ramadan tracking
  DateTime? _ramadanStart;
  DateTime? _ramadanEnd;
  int? _currentRamadanYear;

  FastingService(this._databaseService);

  /// Initialize the fasting service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _ensureDatabaseTables();
      await _loadRamadanDates();
      _isInitialized = true;
      _logger.info('FastingService initialized successfully');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize FastingService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Ensure database tables exist
  Future<void> _ensureDatabaseTables() async {
    const createTableQuery = '''
      CREATE TABLE IF NOT EXISTS fasting_records (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        startTime TEXT,
        endTime TEXT,
        notes TEXT,
        isRamadan INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''';

    await _databaseService.executeCommand(createTableQuery);

    // Create indexes for better performance
    await _databaseService.executeCommand(
      'CREATE INDEX IF NOT EXISTS idx_fasting_date ON fasting_records(date)',
    );
    await _databaseService.executeCommand(
      'CREATE INDEX IF NOT EXISTS idx_fasting_type ON fasting_records(type)',
    );
    await _databaseService.executeCommand(
      'CREATE INDEX IF NOT EXISTS idx_fasting_status ON fasting_records(status)',
    );
  }

  /// Load Ramadan dates for the current year
  Future<void> _loadRamadanDates() async {
    final now = DateTime.now();
    final hijriNow = HijriCalendar.fromDate(now);

    // Ramadan is the 9th month of Hijri calendar
    // For now, use approximate Gregorian dates - in production this should be calculated properly
    final ramadanStart = DateTime(hijriNow.hYear + 578, 3, 1); // Approximate
    final ramadanEnd = DateTime(hijriNow.hYear + 578, 3, 30); // Approximate

    // If we're past Ramadan this year, calculate for next year
    if (now.isAfter(ramadanEnd)) {
      final nextRamadanStart = DateTime(
        hijriNow.hYear + 579,
        3,
        1,
      ); // Approximate
      final nextRamadanEnd = DateTime(
        hijriNow.hYear + 579,
        3,
        30,
      ); // Approximate
      _ramadanStart = nextRamadanStart;
      _ramadanEnd = nextRamadanEnd;
      _currentRamadanYear = hijriNow.hYear + 1;
    } else {
      _ramadanStart = ramadanStart;
      _ramadanEnd = ramadanEnd;
      _currentRamadanYear = hijriNow.hYear;
    }

    _logger.debug(
      'Ramadan dates loaded',
      data: {
        'start': _ramadanStart?.toIso8601String(),
        'end': _ramadanEnd?.toIso8601String(),
        'year': _currentRamadanYear,
      },
    );
  }

  /// Add or update a fasting record
  Future<void> saveFastingRecord(FastingRecord record) async {
    try {
      final isRamadan = _isDateInRamadan(record.date);
      final updatedRecord = record.copyWith(isRamadan: isRamadan);

      await _databaseService.saveFastingRecord(
        updatedRecord.date.toIso8601String().split('T')[0],
        updatedRecord.type.name,
        updatedRecord.status.name,
        notes: updatedRecord.notes,
      );

      _recordCache[updatedRecord.id] = updatedRecord;

      _logger.debug(
        'Fasting record saved',
        data: {
          'id': updatedRecord.id,
          'date': updatedRecord.date.toIso8601String(),
          'status': updatedRecord.status.toString(),
        },
      );
    } catch (e, s) {
      _logger.error('Failed to save fasting record', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get fasting record for a specific date
  Future<FastingRecord?> getFastingRecord(DateTime date) async {
    final dateStr = date.toIso8601String().split('T')[0]; // Get date part only

    try {
      final result = await _databaseService.getFastingRecord(dateStr);

      if (result != null) {
        final record = FastingRecord.fromJson(result);
        _recordCache[record.id] = record;
        return record;
      }

      return null;
    } catch (e, s) {
      _logger.error(
        'Failed to get fasting record for date',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Get all fasting records within a date range
  Future<List<FastingRecord>> getFastingRecordsInRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final results = await _databaseService.getFastingRecordsInRange(
        start,
        end,
      );

      final records = <FastingRecord>[];
      for (final result in results) {
        final record = FastingRecord.fromJson(result);
        _recordCache[record.id] = record;
        records.add(record);
      }

      return records;
    } catch (e, s) {
      _logger.error(
        'Failed to get fasting records in range',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  /// Start a fast for today
  Future<FastingRecord> startFast({
    FastingType type = FastingType.voluntary,
    String? notes,
  }) async {
    final today = DateTime.now();
    final existingRecord = await getFastingRecordForDate(today);

    if (existingRecord != null) {
      // Update existing record
      final updatedRecord = existingRecord.copyWith(
        status: FastingStatus.completed,
        startTime: DateTime.now(),
        notes: notes ?? existingRecord.notes,
      );
      await saveFastingRecord(updatedRecord);
      return updatedRecord;
    } else {
      // Create new record
      final newRecord = FastingRecord(
        id: _uuid.v4(),
        date: today,
        type: type,
        status: FastingStatus.completed,
        startTime: DateTime.now(),
        notes: notes,
      );
      await saveFastingRecord(newRecord);
      return newRecord;
    }
  }

  /// End a fast (mark as completed or broken)
  Future<void> endFast({
    required String recordId,
    required bool completed,
    String? notes,
  }) async {
    final record = _recordCache[recordId] ?? await _getRecordById(recordId);
    if (record == null) return;

    final updatedRecord = record.copyWith(
      status: completed ? FastingStatus.completed : FastingStatus.broken,
      endTime: DateTime.now(),
      notes: notes ?? record.notes,
    );

    await saveFastingRecord(updatedRecord);
  }

  /// Mark a fast as completed for a specific date
  Future<void> markFastAsCompleted(DateTime date) async {
    await init();

    try {
      // Check if a record already exists for this date
      final existingRecord = await getFastingRecordForDate(date);

      if (existingRecord != null) {
        // Update existing record
        final updatedRecord = existingRecord.copyWith(
          status: FastingStatus.completed,
          endTime: DateTime.now(),
        );
        await saveFastingRecord(updatedRecord);
      } else {
        // Create new record
        final isRamadan = _isDateInRamadan(date);
        final newRecord = FastingRecord(
          id: _uuid.v4(),
          date: date,
          type: isRamadan ? FastingType.ramadan : FastingType.voluntary,
          status: FastingStatus.completed,
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          isRamadan: isRamadan,
        );
        await saveFastingRecord(newRecord);
      }

      _logger.debug(
        'Fast marked as completed',
        data: {'date': date.toIso8601String()},
      );
    } catch (e, s) {
      _logger.error(
        'Failed to mark fast as completed',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Get fasting record by ID
  Future<FastingRecord?> _getRecordById(String id) async {
    if (_recordCache.containsKey(id)) {
      return _recordCache[id];
    }

    try {
      final results =
          await _databaseService.executeQuery(
                'SELECT * FROM fasting_records WHERE id = ?',
                [id],
              )
              as List<Map<String, dynamic>>;

      if (results.isNotEmpty) {
        final record = FastingRecord.fromJson(results.first);
        _recordCache[record.id] = record;
        return record;
      }

      return null;
    } catch (e, s) {
      _logger.error(
        'Failed to get fasting record by ID',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Get fasting record for a specific date
  Future<FastingRecord?> getFastingRecordForDate(DateTime date) async {
    await init();

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final results =
          await _databaseService.executeQuery(
                'SELECT * FROM fasting_records WHERE date = ?',
                [dateStr],
              )
              as List<Map<String, dynamic>>;

      if (results.isNotEmpty) {
        final record = FastingRecord.fromJson(results.first);
        _recordCache[record.id] = record;
        return record;
      }

      return null;
    } catch (e, s) {
      _logger.error(
        'Failed to get fasting record for date',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Calculate fasting statistics
  Future<FastingStats> getFastingStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await init();

    final start =
        startDate ?? DateTime.now().subtract(const Duration(days: 365));
    final end = endDate ?? DateTime.now();

    try {
      final records = await getFastingRecordsInRange(start, end);

      final totalFasts = records.length;
      final completedFasts = records.where((r) => r.isCompleted).length;
      final ramadanFasts =
          records.where((r) => r.isRamadan && r.isCompleted).length;
      final voluntaryFasts =
          records
              .where((r) => r.type == FastingType.voluntary && r.isCompleted)
              .length;

      final completionRate = totalFasts > 0 ? completedFasts / totalFasts : 0.0;

      // Calculate streaks
      final currentStreak = _calculateCurrentStreak(records);
      final longestStreak = _calculateLongestStreak(records);

      return FastingStats(
        totalFasts: totalFasts,
        completedFasts: completedFasts,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        ramadanFasts: ramadanFasts,
        voluntaryFasts: voluntaryFasts,
        completionRate: completionRate,
      );
    } catch (e, s) {
      _logger.error(
        'Failed to calculate fasting stats',
        error: e,
        stackTrace: s,
      );
      return FastingStats.empty();
    }
  }

  /// Calculate current fasting streak
  int _calculateCurrentStreak(List<FastingRecord> records) {
    if (records.isEmpty) return 0;

    // Sort by date descending
    final sortedRecords =
        records.where((r) => r.isCompleted).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    if (sortedRecords.isEmpty) return 0;

    // Check if most recent fast was today or yesterday
    final today = DateTime.now();
    final mostRecent = sortedRecords.first.date;
    final daysSinceLastFast = today.difference(mostRecent).inDays;

    if (daysSinceLastFast > 1) return 0; // Streak broken

    int streak = 1;
    DateTime currentDate = mostRecent;

    for (int i = 1; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final daysDiff = currentDate.difference(record.date).inDays;

      if (daysDiff == 1) {
        streak++;
        currentDate = record.date;
      } else {
        break; // Gap in streak
      }
    }

    return streak;
  }

  /// Calculate longest fasting streak
  int _calculateLongestStreak(List<FastingRecord> records) {
    if (records.isEmpty) return 0;

    final completedRecords =
        records.where((r) => r.isCompleted).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    if (completedRecords.isEmpty) return 0;

    int longestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < completedRecords.length; i++) {
      final daysDiff =
          completedRecords[i].date
              .difference(completedRecords[i - 1].date)
              .inDays;

      if (daysDiff == 1) {
        currentStreak++;
        longestStreak =
            longestStreak > currentStreak ? longestStreak : currentStreak;
      } else {
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  /// Check if a date is during Ramadan
  bool _isDateInRamadan(DateTime date) {
    if (_ramadanStart == null || _ramadanEnd == null) return false;

    final dateOnly = DateTime(date.year, date.month, date.day);
    final ramadanStartOnly = DateTime(
      _ramadanStart!.year,
      _ramadanStart!.month,
      _ramadanStart!.day,
    );
    final ramadanEndOnly = DateTime(
      _ramadanEnd!.year,
      _ramadanEnd!.month,
      _ramadanEnd!.day,
    );

    return dateOnly.isAtSameMomentAs(ramadanStartOnly) ||
        dateOnly.isAtSameMomentAs(ramadanEndOnly) ||
        (dateOnly.isAfter(ramadanStartOnly) &&
            dateOnly.isBefore(ramadanEndOnly));
  }

  /// Get Ramadan countdown information
  Map<String, dynamic> getRamadanCountdown() {
    if (_ramadanStart == null) {
      return {
        'isRamadan': false,
        'daysUntilRamadan': null,
        'ramadanStart': null,
        'ramadanEnd': null,
        'currentDay': null,
        'totalDays': 30,
      };
    }

    final now = DateTime.now();
    final isCurrentlyRamadan = _isDateInRamadan(now);

    if (isCurrentlyRamadan) {
      // Calculate current day of Ramadan
      final daysIntoRamadan = now.difference(_ramadanStart!).inDays + 1;
      return {
        'isRamadan': true,
        'daysUntilRamadan': 0,
        'ramadanStart': _ramadanStart,
        'ramadanEnd': _ramadanEnd,
        'currentDay': daysIntoRamadan.clamp(1, 30),
        'totalDays': 30,
      };
    } else {
      // Calculate days until Ramadan
      final daysUntil = _ramadanStart!.difference(now).inDays + 1;
      return {
        'isRamadan': false,
        'daysUntilRamadan': daysUntil > 0 ? daysUntil : null,
        'ramadanStart': _ramadanStart,
        'ramadanEnd': _ramadanEnd,
        'currentDay': null,
        'totalDays': 30,
      };
    }
  }

  /// Get fasting records for a specific month
  Future<List<FastingRecord>> getFastingRecordsForMonth(
    int year,
    int month,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0); // Last day of month

    return getFastingRecordsInRange(startOfMonth, endOfMonth);
  }

  /// Delete a fasting record
  Future<void> deleteFastingRecord(String recordId) async {
    await init();

    try {
      await _databaseService.executeCommand(
        'DELETE FROM fasting_records WHERE id = ?',
        [recordId],
      );

      _recordCache.remove(recordId);

      _logger.debug('Fasting record deleted', data: {'id': recordId});
    } catch (e, s) {
      _logger.error('Failed to delete fasting record', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Clear all fasting records (for testing or reset)
  Future<void> clearAllRecords() async {
    await init();

    try {
      await _databaseService.executeCommand('DELETE FROM fasting_records');
      _recordCache.clear();

      _logger.info('All fasting records cleared');
    } catch (e, s) {
      _logger.error('Failed to clear fasting records', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Dispose of resources
  void dispose() {
    _recordCache.clear();
    _logger.info('FastingService disposed');
  }
}
