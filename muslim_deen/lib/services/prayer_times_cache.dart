import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Specialized cache for prayer times to reduce API calls and calculations
class PrayerTimesCache {
  static const String _cacheKeyPrefix = 'prayer_times_';
  static const int _cacheDurationDays = 30; // Cache prayer times for 30 days

  final CacheService _cacheService;
  final LoggerService _logger;

  PrayerTimesCache(this._cacheService, this._logger);

  /// Generate a cache key for a specific date and location
  String _generateCacheKey(DateTime date, Coordinates coordinates) {
    // Format as prayer_times_YYYY-MM-DD_LAT_LON
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    // Use a fixed number of decimal places for latitude and longitude to ensure key consistency.
    final locationStr =
        '${coordinates.latitude.toStringAsFixed(4)}_${coordinates.longitude.toStringAsFixed(4)}';
    return '$_cacheKeyPrefix${dateStr}_$locationStr';
  }

  /// Cache prayer times for a specific date and location
  Future<void> cachePrayerTimes(
    PrayerTimesModel prayerTimes,
    Coordinates coordinates,
  ) async {
    try {
      final cacheKey = _generateCacheKey(prayerTimes.date, coordinates);
      final Map<String, dynamic> prayerTimesJson = prayerTimes.toJson();
      final int expirationTimestamp = DateTime.now().add(Duration(days: _cacheDurationDays)).millisecondsSinceEpoch;
      
      await _cacheService.saveData(cacheKey, jsonEncode(prayerTimesJson));
      await _cacheService.saveData('${cacheKey}_expiration', expirationTimestamp);

      _logger.debug('Cached prayer times for ${prayerTimes.date} with key $cacheKey until ${DateTime.fromMillisecondsSinceEpoch(expirationTimestamp)}');

      await _cleanupOldCache();
    } catch (e, s) {
      _logger.error('Error caching prayer times', error: e, stackTrace: s);
    }
  }

  /// Get cached prayer times for a specific date and location
  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates,
  ) async {
    try {
      final cacheKey = _generateCacheKey(date, coordinates);
      
      final int? expirationTimestamp = _cacheService.getData('${cacheKey}_expiration') as int?;
      if (expirationTimestamp == null || expirationTimestamp < DateTime.now().millisecondsSinceEpoch) {
        await _cacheService.removeData(cacheKey);
        await _cacheService.removeData('${cacheKey}_expiration');
        _logger.debug('Cached prayer times for $date with key $cacheKey expired or not found.');
        return null;
      }

      final String? jsonData = _cacheService.getData(cacheKey) as String?;
      if (jsonData == null) {
        return null;
      }
      
      final Map<String, dynamic> prayerTimesJson = jsonDecode(jsonData) as Map<String, dynamic>;
      _logger.debug('Retrieved cached prayer times for $date with key $cacheKey');
      return PrayerTimesModel.fromJson(prayerTimesJson);
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached prayer times',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Clean up old cached entries
  Future<void> _cleanupOldCache() async {
    try {
      _logger.info('Starting cleanup of old prayer times cache entries.');
      _logger.debug(
        'PrayerTimesCache._cleanupOldCache: Relies on CacheService to expire items on access.',
      );
    } catch (e, s) {
      _logger.error(
        'Error during prayer times cache cleanup attempt',
        error: e,
        stackTrace: s,
      );
    }
  }

}
