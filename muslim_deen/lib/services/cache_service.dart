import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/cache_metrics_service.dart';

class CacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();
  CacheMetricsService? _metricsService;

  static const int _defaultExpirationMinutes = 60;
  static const int qiblaExpirationMinutes =
      1440; // 24 hours, for Qibla direction
  static const int mosquesExpirationMinutes = 720; // 12 hours, for mosque data

  // Advanced cache management
  static const int _maxCacheSize = 1000; // Maximum number of cache entries
  static const int _compressionThreshold =
      1024; // Compress data larger than 1KB
  static const String _cacheIndexKey = 'cache_index';
  static const String _cacheStatsKey = 'cache_stats';

  // LRU cache management
  final Map<String, DateTime> _accessTimes = {};
  final Map<String, int> _accessCounts = {};
  Timer? _cleanupTimer;

  CacheService(this._prefs) {
    _initializeAdvancedCache();
    _startPeriodicCleanup();
  }

  /// Initialize advanced cache features
  void _initializeAdvancedCache() {
    try {
      _loadCacheIndex();
      _logger.info('Advanced cache features initialized');
    } catch (e, s) {
      _logger.error(
        'Error initializing advanced cache',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Set metrics service for performance tracking
  void setMetricsService(CacheMetricsService metricsService) {
    _metricsService = metricsService;
    _logger.debug('Cache metrics service attached');
  }

  /// Load cache index from storage
  void _loadCacheIndex() {
    try {
      final indexJson = _prefs.getString(_cacheIndexKey);
      if (indexJson != null) {
        final index = jsonDecode(indexJson) as Map<String, dynamic>;
        final accessTimesJson = index['accessTimes'] as Map<String, dynamic>?;
        final accessCountsJson = index['accessCounts'] as Map<String, dynamic>?;

        if (accessTimesJson != null) {
          for (final entry in accessTimesJson.entries) {
            _accessTimes[entry.key] = DateTime.parse(entry.value as String);
          }
        }

        if (accessCountsJson != null) {
          for (final entry in accessCountsJson.entries) {
            _accessCounts[entry.key] = entry.value as int;
          }
        }
      }
      _logger.debug(
        'Cache index loaded',
        data: {'entries': _accessTimes.length},
      );
    } catch (e, s) {
      _logger.error('Error loading cache index', error: e, stackTrace: s);
    }
  }

  /// Save cache index to storage
  Future<void> _saveCacheIndex() async {
    try {
      final index = {
        'accessTimes': _accessTimes.map(
          (k, v) => MapEntry(k, v.toIso8601String()),
        ),
        'accessCounts': _accessCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      await _prefs.setString(_cacheIndexKey, jsonEncode(index));
    } catch (e, s) {
      _logger.error('Error saving cache index', error: e, stackTrace: s);
    }
  }

  /// Start periodic cleanup timer
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 1), (_) {
      _performPeriodicCleanup();
    });
  }

  /// Perform periodic cleanup of expired and old cache entries
  Future<void> _performPeriodicCleanup() async {
    try {
      await _cleanupExpiredEntries();
      await _enforceMaxCacheSize();
      await _saveCacheIndex();
      _logger.debug('Periodic cache cleanup completed');
    } catch (e, s) {
      _logger.error('Error during periodic cleanup', error: e, stackTrace: s);
    }
  }

  /// Clean up expired cache entries
  Future<void> _cleanupExpiredEntries() async {
    try {
      final keys = _prefs.getKeys();
      int cleanedCount = 0;

      for (final key in keys) {
        if (key.endsWith('_expiration')) {
          final dataKey = key.replaceAll('_expiration', '_data');
          final expiration = _prefs.getInt(key) ?? 0;

          if (expiration < DateTime.now().millisecondsSinceEpoch) {
            await _prefs.remove(dataKey);
            await _prefs.remove(key);
            _accessTimes.remove(dataKey);
            _accessCounts.remove(dataKey);
            cleanedCount++;
          }
        }
      }

      if (cleanedCount > 0) {
        _logger.info(
          'Cleaned up expired cache entries',
          data: {'count': cleanedCount},
        );
      }
    } catch (e, s) {
      _logger.error(
        'Error cleaning up expired entries',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Enforce maximum cache size using LRU eviction
  Future<void> _enforceMaxCacheSize() async {
    try {
      if (_accessTimes.length <= _maxCacheSize) return;

      // Sort by last access time (oldest first)
      final sortedEntries =
          _accessTimes.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));

      // Remove oldest entries
      final removeCount =
          _accessTimes.length -
          _maxCacheSize +
          100; // Remove extra to avoid frequent cleanup
      int removedCount = 0;

      for (int i = 0; i < removeCount && i < sortedEntries.length; i++) {
        final key = sortedEntries[i].key;
        await _prefs.remove(key);
        await _prefs.remove('${key}_expiration');
        await _prefs.remove('${key}_compressed');
        _accessTimes.remove(key);
        _accessCounts.remove(key);
        removedCount++;
      }

      if (removedCount > 0) {
        _logger.info(
          'Enforced cache size limit',
          data: {'removed': removedCount},
        );
      }
    } catch (e, s) {
      _logger.error('Error enforcing cache size', error: e, stackTrace: s);
    }
  }

  /// Update access tracking for LRU
  void _updateAccessTracking(String key) {
    _accessTimes[key] = DateTime.now();
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
  }

  /// Compress data if it's large enough
  Future<String> _compressData(String data) async {
    try {
      if (data.length < _compressionThreshold) {
        return data;
      }

      final bytes = utf8.encode(data);
      final compressedBytes = gzip.encode(bytes);
      final compressedData = base64.encode(compressedBytes);

      _logger.debug(
        'Data compressed',
        data: {
          'originalSize': data.length,
          'compressedSize': compressedData.length,
          'ratio':
              (compressedData.length / data.length * 100).toStringAsFixed(1) +
              '%',
        },
      );

      return compressedData;
    } catch (e, s) {
      _logger.error('Error compressing data', error: e, stackTrace: s);
      return data; // Return original data on compression error
    }
  }

  /// Synchronous decompress data for use in getCache
  String _decompressDataSync(String data, String key) {
    try {
      final compressedBytes = base64.decode(data);
      final decompressedBytes = gzip.decode(compressedBytes);
      final decompressedData = utf8.decode(decompressedBytes);

      _logger.debug(
        'Data decompressed synchronously',
        data: {
          'compressedSize': data.length,
          'decompressedSize': decompressedData.length,
        },
      );

      return decompressedData;
    } catch (e, s) {
      _logger.error(
        'Error decompressing data synchronously',
        error: e,
        stackTrace: s,
      );
      return data; // Return original data on decompression error
    }
  }

  /// Generate optimized cache key with hash
  String _generateOptimizedKey(String key) {
    // Use SHA256 hash for long keys to reduce storage overhead
    if (key.length > 100) {
      final bytes = utf8.encode(key);
      final digest = sha256.convert(bytes);
      return '${key.substring(0, 50)}_${digest.toString().substring(0, 16)}';
    }
    return key;
  }

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    _saveCacheIndex();
    _logger.info('CacheService disposed');
  }

  T? getCache<T>(String key) {
    try {
      final optimizedKey = _generateOptimizedKey(key);
      final dataKey = '${optimizedKey}_data';

      if (!_prefs.containsKey(dataKey) ||
          !_prefs.containsKey('${optimizedKey}_expiration')) {
        _metricsService?.recordMiss(key, 'get');
        return null;
      }

      final int expiration = _prefs.getInt('${optimizedKey}_expiration') ?? 0;
      if (expiration < DateTime.now().millisecondsSinceEpoch) {
        _prefs.remove(dataKey);
        _prefs.remove('${optimizedKey}_expiration');
        _prefs.remove('${optimizedKey}_compressed');
        _accessTimes.remove(dataKey);
        _accessCounts.remove(dataKey);
        _metricsService?.recordMiss(key, 'get');
        return null;
      }

      final String jsonData = _prefs.getString(dataKey) ?? '';
      final isCompressed =
          _prefs.getBool('${optimizedKey}_compressed') ?? false;
      final decompressedData =
          isCompressed ? _decompressDataSync(jsonData, dataKey) : jsonData;
      final dynamic decodedData = jsonDecode(decompressedData);

      _updateAccessTracking(dataKey);
      _metricsService?.recordHit(key, 'get');
      _logger.info('Cache hit for key: $key');
      return decodedData as T;
    } catch (e, s) {
      _metricsService?.recordMiss(key, 'get');
      _logger.error(
        'Error retrieving cache for key: $key',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return null;
    }
  }

  Future<bool> setCache<T>(String key, T data, {int? expirationMinutes}) async {
    try {
      final optimizedKey = _generateOptimizedKey(key);
      final dataKey = '${optimizedKey}_data';
      final String jsonData = jsonEncode(data);

      // Compress data if it's large enough
      final compressedData = await _compressData(jsonData);
      final isCompressed = compressedData != jsonData;

      await _prefs.setString(dataKey, compressedData);

      if (isCompressed) {
        await _prefs.setBool('${optimizedKey}_compressed', true);
      }

      final int cacheDurationMinutes =
          expirationMinutes ?? _defaultExpirationMinutes;
      final int expirationTimestamp =
          DateTime.now()
              .add(Duration(minutes: cacheDurationMinutes))
              .millisecondsSinceEpoch;
      await _prefs.setInt('${optimizedKey}_expiration', expirationTimestamp);

      _updateAccessTracking(dataKey);
      _metricsService?.recordCacheSize(_accessTimes.length);
      _logger.info(
        'Cache set for key: $key',
        data: {'compressed': isCompressed, 'size': compressedData.length},
      );
      return true;
    } catch (e, s) {
      _logger.error(
        'Error setting cache for key: $key',
        error: e,
        stackTrace: s,
        data: {'data_type': T.toString()},
      );
      return false;
    }
  }

  Future<bool> saveData(String key, dynamic value) async {
    try {
      final success = await _saveValueByType(_prefs, key, value);
      if (success) {
        _logger.info('Data saved for key: $key');
      }
      return success;
    } catch (e, s) {
      _logger.error('Error saving data for key: $key', error: e, stackTrace: s);
      return false;
    }
  }

  /// Helper method to save different value types to SharedPreferences
  Future<bool> _saveValueByType(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    if (value is String) {
      return await prefs.setString(key, value);
    } else if (value is int) {
      return await prefs.setInt(key, value);
    } else if (value is double) {
      return await prefs.setDouble(key, value);
    } else if (value is bool) {
      return await prefs.setBool(key, value);
    } else if (value is List<String>) {
      return await prefs.setStringList(key, value);
    } else {
      // For complex types not directly supported by SharedPreferences,
      // they should be encoded to a String (e.g., JSON) before calling saveData.
      _logger.warning(
        'Unsupported type for saveData. Key: $key, Type: ${value.runtimeType}. Value must be String, int, double, bool, or List<String>.',
      );
      return false;
    }
  }

  dynamic getData(String key) {
    try {
      final dynamic value = _prefs.get(key);
      _logger.info('Data retrieved for key: $key');
      return value;
    } catch (e, s) {
      _logger.error(
        'Error getting data for key: $key',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<bool> removeData(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) {
        _logger.info('Data removed for key: $key');
      } else {
        _logger.warning(
          'Failed to remove data for key: $key (key might not exist)',
        );
      }
      return success;
    } catch (e, s) {
      _logger.error(
        'Error removing data for key: $key',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<bool> clearAllCache() async {
    try {
      final Set<String> keys = _prefs.getKeys();
      for (final String key in keys) {
        if (key.endsWith('_data') ||
            key.endsWith('_expiration') ||
            key.endsWith('_compressed')) {
          await _prefs.remove(key);
        }
      }

      // Clear in-memory tracking
      _accessTimes.clear();
      _accessCounts.clear();

      await _prefs.remove(_cacheIndexKey);
      await _prefs.remove(_cacheStatsKey);

      _metricsService?.recordCacheSize(0);
      _logger.info('All cache cleared');
      return true;
    } catch (e, s) {
      _logger.error(
        'Error clearing all cache',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return false;
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final stats = {
      'totalEntries': _accessTimes.length,
      'averageAccessCount':
          _accessCounts.isEmpty
              ? 0.0
              : _accessCounts.values.reduce((a, b) => a + b) /
                  _accessCounts.length,
      'mostAccessedKeys': _getMostAccessedKeys(5),
      'leastAccessedKeys': _getLeastAccessedKeys(5),
      'oldestEntries': _getOldestEntries(5),
      'newestEntries': _getNewestEntries(5),
    };

    return stats;
  }

  /// Get most accessed keys
  List<String> _getMostAccessedKeys(int count) {
    final sortedEntries =
        _accessCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(count).map((e) => e.key).toList();
  }

  /// Get least accessed keys
  List<String> _getLeastAccessedKeys(int count) {
    final sortedEntries =
        _accessCounts.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return sortedEntries.take(count).map((e) => e.key).toList();
  }

  /// Get oldest entries
  List<String> _getOldestEntries(int count) {
    final sortedEntries =
        _accessTimes.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
    return sortedEntries.take(count).map((e) => e.key).toList();
  }

  /// Get newest entries
  List<String> _getNewestEntries(int count) {
    final sortedEntries =
        _accessTimes.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(count).map((e) => e.key).toList();
  }

  /// Force cleanup of expired entries
  Future<void> forceCleanup() async {
    await _performPeriodicCleanup();
  }

  String generateLocationCacheKey(
    String prefix,
    double latitude,
    double longitude, {
    double radius = 0,
  }) {
    return '${prefix}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}${radius > 0 ? '_${radius.toStringAsFixed(0)}' : ''}';
  }
}
