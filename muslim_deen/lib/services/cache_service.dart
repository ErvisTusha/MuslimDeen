import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart'; // Removed unused import
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

class CacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();

  // Cache expiration times in minutes
  static const int _defaultExpirationMinutes = 60; // 1 hour
  static const int qiblaExpirationMinutes = 1440; // 24 hours
  static const int mosquesExpirationMinutes = 720; // 12 hours
  static const int oneDayInMinutes = 24 * 60; // 24 hours

  CacheService(this._prefs);

  /// Saves data to cache with expiration time
  Future<bool> setCache(
    String key,
    dynamic data, {
    int expirationMinutes = _defaultExpirationMinutes,
  }) async {
    try {
      final String jsonData = jsonEncode(data);
      final int timestamp =
          DateTime.now()
              .add(Duration(minutes: expirationMinutes))
              .millisecondsSinceEpoch;

      // Save the data and its expiration timestamp
      await _prefs.setString('${key}_data', jsonData);
      await _prefs.setInt('${key}_expiration', timestamp);

      _logger.info(
        'Data cached for key: $key',
        data: {'expirationMinutes': expirationMinutes},
      );
      return true;
    } catch (e, s) {
      _logger.error(
        'Failed to cache data for key: $key',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return false;
    }
  }

  /// Gets data from cache if it exists and is not expired
  T? getCache<T>(String key) {
    try {
      // Check if the cache exists
      if (!_prefs.containsKey('${key}_data') ||
          !_prefs.containsKey('${key}_expiration')) {
        return null;
      }

      // Check if the cache is expired
      final int expiration = _prefs.getInt('${key}_expiration') ?? 0;
      if (expiration < DateTime.now().millisecondsSinceEpoch) {
        // Cache expired, clean it up
        _prefs.remove('${key}_data');
        _prefs.remove('${key}_expiration');
        return null;
      }

      // Retrieve and decode the cached data
      final String jsonData = _prefs.getString('${key}_data') ?? '';
      final dynamic decodedData = jsonDecode(jsonData);

      _logger.info('Cache hit for key: $key');
      return decodedData as T;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cache for key: $key',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return null;
    }
  }

  /// Removes a specific cache entry
  Future<bool> removeCache(String key) async {
    try {
      await _prefs.remove('${key}_data');
      await _prefs.remove('${key}_expiration');
      _logger.info('Cache removed for key: $key');
      return true;
    } catch (e, s) {
      _logger.error(
        'Error removing cache for key: $key',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return false;
    }
  }

  /// Clears all cache entries
  Future<bool> clearAllCache() async {
    try {
      final Set<String> keys = _prefs.getKeys();
      for (final String key in keys) {
        if (key.endsWith('_data') || key.endsWith('_expiration')) {
          await _prefs.remove(key);
        }
      }
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

  /// Returns all unique base keys stored in the cache.
  Set<String> getAllBaseKeys() {
    final allStoredKeys = _prefs.getKeys();
    final baseKeys = <String>{};
    for (final key in allStoredKeys) {
      if (key.endsWith('_data')) {
        baseKeys.add(key.substring(0, key.length - '_data'.length));
      }
      // No need to check for '_expiration' as '_data' implies its existence
    }
    _logger.info('Retrieved all base keys from cache.', data: {'count': baseKeys.length});
    return baseKeys;
  }

  /// Generate a cache key for location-based data
  String generateLocationCacheKey(
    String prefix,
    double latitude,
    double longitude, {
    double radius = 0,
  }) {
    return '${prefix}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}${radius > 0 ? '_${radius.toStringAsFixed(0)}' : ''}';
  }
}
