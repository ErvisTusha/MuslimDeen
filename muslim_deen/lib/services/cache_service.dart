import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

class CacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();

  static const int _defaultExpirationMinutes = 60; // 1 hour
  static const int qiblaExpirationMinutes = 1440; // 24 hours
  static const int mosquesExpirationMinutes = 720; // 12 hours
  // static const int oneDayInMinutes = 24 * 60; // 24 hours // Unused

  CacheService(this._prefs);

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

  Set<String> getAllBaseKeys() {
    final allStoredKeys = _prefs.getKeys();
    final baseKeys = <String>{};
    for (final key in allStoredKeys) {
      if (key.endsWith('_data')) {
        baseKeys.add(key.substring(0, key.length - '_data'.length));
      }
    }
    _logger.info(
      'Retrieved all base keys from cache.',
      data: {'count': baseKeys.length},
    );
    return baseKeys;
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
