import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

class CacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();

  static const int _defaultExpirationMinutes = 60;
  static const int qiblaExpirationMinutes =
      1440; // 24 hours, for Qibla direction
  static const int mosquesExpirationMinutes = 720; // 12 hours, for mosque data

  CacheService(this._prefs);

  T? getCache<T>(String key) {
    try {
      if (!_prefs.containsKey('${key}_data') ||
          !_prefs.containsKey('${key}_expiration')) {
        return null;
      }

      final int expiration = _prefs.getInt('${key}_expiration') ?? 0;
      if (expiration < DateTime.now().millisecondsSinceEpoch) {
        _prefs.remove('${key}_data');
        _prefs.remove('${key}_expiration');
        return null;
      }

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

  Future<bool> setCache<T>(String key, T data, {int? expirationMinutes}) async {
    try {
      final String jsonData = jsonEncode(data);
      await _prefs.setString('${key}_data', jsonData);

      final int cacheDurationMinutes =
          expirationMinutes ?? _defaultExpirationMinutes;
      final int expirationTimestamp =
          DateTime.now()
              .add(Duration(minutes: cacheDurationMinutes))
              .millisecondsSinceEpoch;
      await _prefs.setInt('${key}_expiration', expirationTimestamp);

      _logger.info('Cache set for key: $key');
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
      if (value is String) {
        return await _prefs.setString(key, value);
      } else if (value is int) {
        return await _prefs.setInt(key, value);
      } else if (value is double) {
        return await _prefs.setDouble(key, value);
      } else if (value is bool) {
        return await _prefs.setBool(key, value);
      } else if (value is List<String>) {
        return await _prefs.setStringList(key, value);
      } else {
        // For complex types not directly supported by SharedPreferences,
        // they should be encoded to a String (e.g., JSON) before calling saveData.
        _logger.warning(
          'Unsupported type for saveData. Key: $key, Type: ${value.runtimeType}. Value must be String, int, double, bool, or List<String>.',
        );
        return false;
      }
    } catch (e, s) {
      _logger.error('Error saving data for key: $key', error: e, stackTrace: s);
      return false;
    }
  }

  dynamic getData(String key) {
    try {
      final dynamic value = _prefs.get(key);
      _logger.info('Data retrieved for key: $key');
      return value;
    } catch (e, s) {
      _logger.error('Error getting data for key: $key', error: e, stackTrace: s);
      return null;
    }
  }

  Future<bool> removeData(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) {
        _logger.info('Data removed for key: $key');
      } else {
        _logger.warning('Failed to remove data for key: $key (key might not exist)');
      }
      return success;
    } catch (e, s) {
      _logger.error('Error removing data for key: $key', error: e, stackTrace: s);
      return false;
    }
  }

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

  String generateLocationCacheKey(
    String prefix,
    double latitude,
    double longitude, {
    double radius = 0,
  }) {
    return '${prefix}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}${radius > 0 ? '_${radius.toStringAsFixed(0)}' : ''}';
  }
}
