import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Database operation metrics for performance monitoring
class DatabaseMetrics {
  final String operation;
  final Duration duration;
  final int rowsAffected;
  final DateTime timestamp;

  DatabaseMetrics({
    required this.operation,
    required this.duration,
    required this.rowsAffected,
    required this.timestamp,
  });
}

/// Batch operation wrapper for transaction support
class BatchOperation {
  final String table;
  final String operation; // 'insert', 'update', 'delete'
  final Map<String, dynamic> data;
  final String? where;
  final List<dynamic>? whereArgs;

  BatchOperation({
    required this.table,
    required this.operation,
    required this.data,
    this.where,
    this.whereArgs,
  });
}

/// Service to handle local SQLite database operations
class DatabaseService {
  static const String _databaseName = 'muslim_deen.db';
  static const int _databaseVersion = 4;
  static const int _maxConnections = 3;
  static const Duration _slowQueryThreshold = Duration(milliseconds: 100);

  Database? _database;
  final LoggerService _logger = locator<LoggerService>();
  
  // Connection management
  int _activeConnections = 0;
  final List<Database> _connectionPool = [];
  bool _isInitialized = false;
  
  // Performance monitoring
  final List<DatabaseMetrics> _metricsHistory = [];
  static const int _maxMetricsHistory = 100;
  Timer? _cleanupTimer;

  /// Initialize the database with connection management
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Use default sqflite factory for Android/iOS
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _databaseName);

      _logger.info('Initializing database at path: $path');

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) {
          _logger.info('Database opened successfully');
        },
      );

      _isInitialized = true;
      _activeConnections = 1;

      // Start cleanup timer for old metrics
      _startCleanupTimer();

      _logger.info('DatabaseService initialized at $path with connection management');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to initialize database',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Start periodic cleanup of old metrics
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _cleanupOldMetrics();
    });
  }

  /// Clean up old metrics to prevent memory leaks
  void _cleanupOldMetrics() {
    if (_metricsHistory.length > _maxMetricsHistory) {
      _metricsHistory.removeRange(0, _metricsHistory.length - _maxMetricsHistory);
      _logger.debug('Cleaned up old database metrics');
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE prayer_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        completed_prayers TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(date)
      )
    ''');

    await db.execute('''
      CREATE TABLE tasbih_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        dhikr_type TEXT NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        UNIQUE(date, dhikr_type)
      )
    ''');

    await db.execute('''
      CREATE TABLE user_location (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        location_name TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fasting_records (
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
    ''');

    // Add indexes for better performance
    await db.execute('CREATE INDEX idx_prayer_history_date ON prayer_history(date)');
    await db.execute('CREATE INDEX idx_tasbih_history_date ON tasbih_history(date)');
    await db.execute('CREATE INDEX idx_fasting_records_date ON fasting_records(date)');
    await db.execute('CREATE INDEX idx_settings_key ON settings(key)');

    _logger.info('Database tables and indexes created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add indexes for better performance
      await db.execute('CREATE INDEX idx_prayer_history_date ON prayer_history(date)');
      await db.execute('CREATE INDEX idx_tasbih_history_date ON tasbih_history(date)');
      await db.execute('CREATE INDEX idx_settings_key ON settings(key)');
      _logger.info('Database indexes added in version 2');
    }
    if (oldVersion < 3) {
      // Add fasting_records table
      await db.execute('''
        CREATE TABLE fasting_records (
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
      ''');
      await db.execute('CREATE INDEX idx_fasting_records_date ON fasting_records(date)');
      _logger.info('Fasting records table added in version 3');
    }
    if (oldVersion < 4) {
      // Check if fasting_records table exists and has the wrong schema
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='fasting_records'");
      if (tables.isNotEmpty) {
        // Check the schema of the existing table
        final schema = await db.rawQuery("PRAGMA table_info(fasting_records)");
        final hasWrongSchema = schema.any((col) => col['name'] == 'fasting_type' || col['name'] == 'created_at');

        if (hasWrongSchema) {
          // Drop and recreate with correct schema (data will be lost, but this fixes the schema issue)
          await db.execute('DROP TABLE fasting_records');
          await db.execute('''
            CREATE TABLE fasting_records (
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
          ''');
          _logger.info('Fasting records table recreated with correct schema in version 4');
        } else {
          _logger.info('Fasting records table already has correct schema');
        }
      }
      await db.execute('CREATE INDEX IF NOT EXISTS idx_fasting_records_date ON fasting_records(date)');
    }
    _logger.info('Database upgraded from $oldVersion to $newVersion');
  }

  /// Get database instance with connection management
  Database _getDatabase() {
    if (!_isInitialized || _database == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  /// Execute a database operation with performance tracking
  Future<T> _executeWithTracking<T>(
    String operation,
    Future<T> Function() databaseOperation,
  ) async {
    final stopwatch = Stopwatch()..start();
    int rowsAffected = 0;
    
    try {
      final result = await databaseOperation();
      stopwatch.stop();
      
      // Track metrics
      if (result is int) {
        rowsAffected = result;
      } else if (result is List && result.isNotEmpty) {
        rowsAffected = result.length;
      }
      
      _recordMetrics(operation, stopwatch.elapsed, rowsAffected);
      
      // Log slow queries
      if (stopwatch.elapsed > _slowQueryThreshold) {
        _logger.warning(
          'Slow database query detected',
          data: {
            'operation': operation,
            'duration': '${stopwatch.elapsed.inMilliseconds}ms',
            'rowsAffected': rowsAffected,
          },
        );
      }
      
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.error(
        'Database operation failed: $operation',
        error: e,
        stackTrace: stackTrace,
        data: {
          'duration': '${stopwatch.elapsed.inMilliseconds}ms',
        },
      );
      rethrow;
    }
  }

  /// Record database performance metrics
  void _recordMetrics(String operation, Duration duration, int rowsAffected) {
    final metrics = DatabaseMetrics(
      operation: operation,
      duration: duration,
      rowsAffected: rowsAffected,
      timestamp: DateTime.now(),
    );
    
    _metricsHistory.add(metrics);
    
    _logger.debug(
      'Database operation completed',
      data: {
        'operation': operation,
        'duration': '${duration.inMilliseconds}ms',
        'rowsAffected': rowsAffected,
      },
    );
  }

  /// Execute multiple operations in a transaction
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return _executeWithTracking('transaction', () async {
      final db = _getDatabase();
      return await db.transaction(action);
    });
  }

  /// Execute batch operations
  Future<List<dynamic>> batch(List<BatchOperation> operations) async {
    return _executeWithTracking('batch', () async {
      final db = _getDatabase();
      final batch = db.batch();
      
      for (final op in operations) {
        switch (op.operation.toLowerCase()) {
          case 'insert':
            batch.insert(op.table, op.data);
            break;
          case 'update':
            batch.update(op.table, op.data, where: op.where, whereArgs: op.whereArgs);
            break;
          case 'delete':
            batch.delete(op.table, where: op.where, whereArgs: op.whereArgs);
            break;
          default:
            throw ArgumentError('Unknown batch operation: ${op.operation}');
        }
      }
      
      return await batch.commit();
    });
  }

  /// Batch insert prayer history for multiple dates
  Future<void> batchInsertPrayerHistory(Map<String, String> prayerData) async {
    if (prayerData.isEmpty) return;
    
    final operations = prayerData.entries.map((entry) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return BatchOperation(
        table: 'prayer_history',
        operation: 'insert',
        data: {
          'date': entry.key,
          'completed_prayers': entry.value,
          'created_at': now,
          'updated_at': now,
        },
      );
    }).toList();
    
    await transaction((txn) async {
      for (final op in operations) {
        await txn.insert(
          'prayer_history',
          op.data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
    
    _logger.info('Batch inserted ${prayerData.length} prayer history records');
  }

  /// Batch insert tasbih history for multiple dates and types
  Future<void> batchInsertTasbihHistory(
    Map<String, Map<String, int>> tasbihData, {
    Transaction? txn,
  }) async {
    if (tasbihData.isEmpty) return;
    
    final operations = <BatchOperation>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    for (final dateEntry in tasbihData.entries) {
      final date = dateEntry.key;
      for (final tasbihEntry in dateEntry.value.entries) {
        operations.add(BatchOperation(
          table: 'tasbih_history',
          operation: 'insert',
          data: {
            'date': date,
            'dhikr_type': tasbihEntry.key,
            'count': tasbihEntry.value,
            'created_at': now,
            'updated_at': now,
          },
        ));
      }
    }
    
    if (txn != null) {
      // Use provided transaction
      for (final op in operations) {
        await txn.insert(
          'tasbih_history',
          op.data,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } else {
      // Start new transaction
      await transaction((txn) async {
        for (final op in operations) {
          await txn.insert(
            'tasbih_history',
            op.data,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
    
    _logger.info('Batch inserted ${operations.length} tasbih history records');
  }

  /// Insert or update fasting record
  Future<void> saveFastingRecord(String date, String fastingType, String status, {String? notes}) async {
    await _executeWithTracking('saveFastingRecord', () async {
      final db = _getDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('fasting_records', {
        'date': date,
        'fasting_type': fastingType,
        'status': status,
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    _logger.debug('Fasting record saved for date: $date');
  }

  /// Get fasting record for a specific date
  Future<Map<String, dynamic>?> getFastingRecord(String date) async {
    return await _executeWithTracking('getFastingRecord', () async {
      final db = _getDatabase();
      final result = await db.query(
        'fasting_records',
        where: 'date = ?',
        whereArgs: [date],
        limit: 1,
      );

      return result.isNotEmpty ? result.first : null;
    });
  }

  /// Get all fasting records within a date range
  Future<List<Map<String, dynamic>>> getFastingRecordsInRange(DateTime startDate, DateTime endDate) async {
    return await _executeWithTracking('getFastingRecordsInRange', () async {
      final db = _getDatabase();
      final result = await db.query(
        'fasting_records',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDate.toIso8601String().split('T')[0], endDate.toIso8601String().split('T')[0]],
        orderBy: 'date ASC',
      );

      return result;
    });
  }

  /// Get fasting statistics
  Future<Map<String, dynamic>> getFastingStatistics() async {
    return await _executeWithTracking('getFastingStatistics', () async {
      final db = _getDatabase();
      final result = await db.rawQuery('''
        SELECT 
          COUNT(*) as total_days,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_days,
          SUM(CASE WHEN status = 'broken' THEN 1 ELSE 0 END) as broken_days,
          SUM(CASE WHEN fasting_type = 'ramadan' THEN 1 ELSE 0 END) as ramadan_days
        FROM fasting_records
      ''');

      return result.isNotEmpty ? result.first : {};
    });
  }

  /// Execute raw SQL query with performance tracking
  Future<dynamic> executeQuery(String sql, [List<dynamic>? arguments]) async {
    return await _executeWithTracking('executeQuery', () async {
      final db = _getDatabase();
      return await db.rawQuery(sql, arguments);
    });
  }

  /// Execute raw SQL command with performance tracking
  Future<void> executeCommand(String sql, [List<dynamic>? arguments]) async {
    await _executeWithTracking('executeCommand', () async {
      final db = _getDatabase();
      return await db.execute(sql, arguments);
    });
  }

  /// Get average query time for the last N operations
  Duration getAverageQueryTime({int lastN = 10}) {
    if (_metricsHistory.isEmpty) return Duration.zero;
    
    final recentMetrics = _metricsHistory.length > lastN
        ? _metricsHistory.sublist(_metricsHistory.length - lastN)
        : _metricsHistory;
    
    final totalMs = recentMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ recentMetrics.length);
  }

  /// Check if database connection is healthy
  bool get isHealthy => _isInitialized && _database != null && _database!.isOpen;

  /// Get connection status
  Map<String, dynamic> getConnectionStatus() {
    return {
      'initialized': _isInitialized,
      'activeConnections': _activeConnections,
      'maxConnections': _maxConnections,
      'healthy': isHealthy,
      'path': _database?.path,
    };
  }

  /// Save app settings with performance tracking
  Future<void> saveSettings(String key, String value) async {
    await _executeWithTracking('saveSettings', () async {
      final db = _getDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('settings', {
        'key': key,
        'value': value,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    _logger.debug('Settings saved: $key');
  }

  /// Get app settings with performance tracking
  Future<String?> getSettings(String key) async {
    return await _executeWithTracking('getSettings', () async {
      final db = _getDatabase();
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['value'] as String;
      }
      return null;
    });
  }

  /// Save prayer completion data with performance tracking
  Future<void> savePrayerHistory(String date, String completedPrayers) async {
    await _executeWithTracking('savePrayerHistory', () async {
      final db = _getDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('prayer_history', {
        'date': date,
        'completed_prayers': completedPrayers,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    _logger.debug('Prayer history saved for date: $date');
  }

  /// Get prayer completion data for a specific date with performance tracking
  Future<String?> getPrayerHistory(String date) async {
    return await _executeWithTracking('getPrayerHistory', () async {
      final db = _getDatabase();
      final result = await db.query(
        'prayer_history',
        where: 'date = ?',
        whereArgs: [date],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first['completed_prayers'] as String;
      }
      return null;
    });
  }

  /// Get prayer history for multiple dates in a single query with performance tracking
  Future<Map<String, String>> getPrayerHistoryBatch(List<String> dates) async {
    return await _executeWithTracking('getPrayerHistoryBatch', () async {
      final db = _getDatabase();
      if (dates.isEmpty) return {};
      
      // Create placeholders for the IN clause
      final placeholders = List.filled(dates.length, '?').join(',');
      final result = await db.query(
        'prayer_history',
        where: 'date IN ($placeholders)',
        whereArgs: dates,
      );

      final history = <String, String>{};
      for (final row in result) {
        history[row['date'] as String] = row['completed_prayers'] as String;
      }
      
      return history;
    });
  }

  /// Get all prayer history with performance tracking
  Future<List<Map<String, dynamic>>> getAllPrayerHistory() async {
    return await _executeWithTracking('getAllPrayerHistory', () async {
      final db = _getDatabase();
      return await db.query('prayer_history', orderBy: 'date DESC');
    });
  }

  /// Save tasbih count data with performance tracking
  Future<void> saveTasbihHistory(
    String date,
    String dhikrType,
    int count,
  ) async {
    await _executeWithTracking('saveTasbihHistory', () async {
      final db = _getDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('tasbih_history', {
        'date': date,
        'dhikr_type': dhikrType,
        'count': count,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    _logger.debug('Tasbih history saved: $date, $dhikrType, $count');
  }

  /// Get tasbih counts for a specific date with performance tracking
  Future<Map<String, int>> getTasbihHistory(String date, {Transaction? txn}) async {
    return await _executeWithTracking('getTasbihHistory', () async {
      final db = txn ?? _getDatabase();
      final result = await db.query(
        'tasbih_history',
        where: 'date = ?',
        whereArgs: [date],
      );

      final counts = <String, int>{};
      for (final row in result) {
        counts[row['dhikr_type'] as String] = row['count'] as int;
      }

      return counts;
    });
  }

  /// Get tasbih history for multiple dates in a single query with performance tracking
  Future<Map<String, Map<String, int>>> getTasbihHistoryBatch(List<String> dates) async {
    return await _executeWithTracking('getTasbihHistoryBatch', () async {
      final db = _getDatabase();
      if (dates.isEmpty) return {};
      
      // Create placeholders for the IN clause
      final placeholders = List.filled(dates.length, '?').join(',');
      final result = await db.query(
        'tasbih_history',
        where: 'date IN ($placeholders)',
        whereArgs: dates,
      );

      final history = <String, Map<String, int>>{};
      for (final row in result) {
        final date = row['date'] as String;
        final dhikrType = row['dhikr_type'] as String;
        final count = row['count'] as int;
        
        if (!history.containsKey(date)) {
          history[date] = {};
        }
        history[date]![dhikrType] = count;
      }
      
      return history;
    });
  }

  /// Get all tasbih history with performance tracking
  Future<List<Map<String, dynamic>>> getAllTasbihHistory() async {
    return await _executeWithTracking('getAllTasbihHistory', () async {
      final db = _getDatabase();
      return await db.query(
        'tasbih_history',
        orderBy: 'date DESC, dhikr_type ASC',
      );
    });
  }

  /// Save user location with performance tracking
  Future<void> saveLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    await _executeWithTracking('saveLocation', () async {
      final db = _getDatabase();
      final now = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('user_location', {
        'latitude': latitude,
        'longitude': longitude,
        'location_name': locationName,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });

    _logger.debug('Location saved: $latitude, $longitude, $locationName');
  }

  /// Get user location with performance tracking
  Future<Map<String, dynamic>?> getLocation() async {
    return await _executeWithTracking('getLocation', () async {
      final db = _getDatabase();
      final result = await db.query(
        'user_location',
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    });
  }

  /// Generic method to save data (for backward compatibility)
  Future<void> saveData(String key, dynamic value) async {
    if (value is String) {
      await saveSettings(key, value);
    } else if (value is Map<String, dynamic>) {
      await saveSettings(key, jsonEncode(value));
    } else {
      // For other types, convert to string
      await saveSettings(key, value.toString());
    }
  }

  /// Generic method to get data (for backward compatibility)
  Future<dynamic> getData(String key) async {
    final result = await getSettings(key);
    if (result != null) {
      // Try to parse as JSON first
      try {
        return jsonDecode(result);
      } catch (_) {
        // If not JSON, return as string
        return result;
      }
    }
    return null;
  }

  /// Remove data for a specific key with performance tracking
  Future<void> removeData(String key) async {
    await _executeWithTracking('removeData', () async {
      final db = _getDatabase();
      return await db.delete('settings', where: 'key = ?', whereArgs: [key]);
    });
    _logger.debug('Data removed for key: $key');
  }

  /// Clean old history data (older than 90 days) with performance tracking
  Future<void> cleanOldHistory() async {
    await _executeWithTracking('cleanOldHistory', () async {
      final db = _getDatabase();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 90));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      final prayerDeleted = await db.delete(
        'prayer_history',
        where: 'created_at < ?',
        whereArgs: [cutoffTimestamp],
      );

      final tasbihDeleted = await db.delete(
        'tasbih_history',
        where: 'created_at < ?',
        whereArgs: [cutoffTimestamp],
      );

      _logger.info(
        'Cleaned old history data: $prayerDeleted prayer records, $tasbihDeleted tasbih records',
      );
      
      return prayerDeleted + tasbihDeleted;
    });
  }

  /// Close database with proper cleanup
  Future<void> close() async {
    try {
      // Cancel cleanup timer
      _cleanupTimer?.cancel();
      _cleanupTimer = null;
      
      // Close all connections
      if (_database != null) {
        await _database!.close();
        _database = null;
        _activeConnections = 0;
        _isInitialized = false;
        
        _logger.info('Database closed with connection management cleanup');
      }
      
      // Clear connection pool
      _connectionPool.clear();
    } catch (e, stackTrace) {
      _logger.error(
        'Error closing database',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
