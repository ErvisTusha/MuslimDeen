import 'dart:async';
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to handle local SQLite database operations
class DatabaseService {
  static const String _databaseName = 'muslim_deen.db';
  static const int _databaseVersion = 1;

  Database? _database;
  final LoggerService _logger = locator<LoggerService>();

  /// Initialize the database
  Future<void> init() async {
    if (_database != null) return;

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    _logger.info('DatabaseService initialized at $path');
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

    _logger.info('Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future database migrations here
    _logger.info('Database upgraded from $oldVersion to $newVersion');
  }

  /// Get database instance
  Database _getDatabase() {
    if (_database == null) {
      throw StateError('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  /// Save app settings
  Future<void> saveSettings(String key, String value) async {
    final db = _getDatabase();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('settings', {
      'key': key,
      'value': value,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _logger.debug('Settings saved: $key');
  }

  /// Get app settings
  Future<String?> getSettings(String key) async {
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
  }

  /// Save prayer completion data
  Future<void> savePrayerHistory(String date, String completedPrayers) async {
    final db = _getDatabase();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('prayer_history', {
      'date': date,
      'completed_prayers': completedPrayers,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _logger.debug('Prayer history saved for date: $date');
  }

  /// Get prayer completion data for a specific date
  Future<String?> getPrayerHistory(String date) async {
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
  }

  /// Get all prayer history
  Future<List<Map<String, dynamic>>> getAllPrayerHistory() async {
    final db = _getDatabase();
    return await db.query('prayer_history', orderBy: 'date DESC');
  }

  /// Save tasbih count data
  Future<void> saveTasbihHistory(
    String date,
    String dhikrType,
    int count,
  ) async {
    final db = _getDatabase();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('tasbih_history', {
      'date': date,
      'dhikr_type': dhikrType,
      'count': count,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _logger.debug('Tasbih history saved: $date, $dhikrType, $count');
  }

  /// Get tasbih counts for a specific date
  Future<Map<String, int>> getTasbihHistory(String date) async {
    final db = _getDatabase();
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
  }

  /// Get all tasbih history
  Future<List<Map<String, dynamic>>> getAllTasbihHistory() async {
    final db = _getDatabase();
    return await db.query(
      'tasbih_history',
      orderBy: 'date DESC, dhikr_type ASC',
    );
  }

  /// Save user location
  Future<void> saveLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    final db = _getDatabase();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('user_location', {
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _logger.debug('Location saved: $latitude, $longitude, $locationName');
  }

  /// Get user location
  Future<Map<String, dynamic>?> getLocation() async {
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

  /// Remove data for a specific key
  Future<void> removeData(String key) async {
    final db = _getDatabase();
    await db.delete('settings', where: 'key = ?', whereArgs: [key]);
    _logger.debug('Data removed for key: $key');
  }

  /// Clean old history data (older than 90 days)
  Future<void> cleanOldHistory() async {
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
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _logger.info('Database closed');
    }
  }
}
