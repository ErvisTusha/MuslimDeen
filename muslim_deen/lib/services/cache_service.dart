import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

class CacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();

  static const int _defaultExpirationMinutes = 60;
  static const int qiblaExpirationMinutes = 1440; // 24 hours, for Qibla direction
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
