import 'dart:convert'; // Keep for PrayerTimesModel.fromJson if it expects Map<String, dynamic> from jsonDecode

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
      final expirationMinutes = const Duration(days: _cacheDurationDays).inMinutes;

      // Call the new _cacheService.setCache method
      await _cacheService.setCache<Map<String, dynamic>>(
        cacheKey,
        prayerTimes.toJson(), // prayerTimes.toJson() returns Map<String, dynamic>
        expirationMinutes: expirationMinutes,
      );

      _logger.debug(
        'Cached prayer times for ${prayerTimes.date} with key $cacheKey, using CacheService.setCache. Expires in $expirationMinutes minutes.',
      );

      // Clean up old cached entries (can remain a no-op or rely on getCache's expiry)
      await _cleanupOldCache();
    } catch (e, s) {
      _logger.error('Error caching prayer times using CacheService.setCache', error: e, stackTrace: s);
    }
  }

  /// Get cached prayer times for a specific date and location
  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates,
  ) async {
    try {
      final cacheKey = _generateCacheKey(date, coordinates);

      // Call the _cacheService.getCache method
      final Map<String, dynamic>? prayerTimesJson =
          _cacheService.getCache<Map<String, dynamic>>(cacheKey);

      if (prayerTimesJson == null) {
        _logger.debug('Cache miss for prayer times with key $cacheKey using CacheService.getCache.');
        return null;
      }
      
      _logger.debug('Retrieved cached prayer times for $date with key $cacheKey using CacheService.getCache');
      return PrayerTimesModel.fromJson(prayerTimesJson);
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached prayer times using CacheService.getCache',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Clean up old cached entries
  Future<void> _cleanupOldCache() async {
    try {
      _logger.info('Starting cleanup of old prayer times cache entries (currently a no-op).');
      // The CacheService.getCache() method now handles expiration for individual keys upon access.
      // A more aggressive or proactive cleanup would require CacheService to expose methods
      // for iterating or removing keys based on patterns or metadata, which is beyond this subtask.
      _logger.debug(
        'PrayerTimesCache._cleanupOldCache: Relies on CacheService.getCache to expire items on access.',
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
