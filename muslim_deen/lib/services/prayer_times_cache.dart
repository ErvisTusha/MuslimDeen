import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/extensions/cache_service_extension.dart';

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

      // Convert to JSON for storage
      final Map<String, dynamic> prayerTimesJson = {
        'fajr': prayerTimes.fajr?.toIso8601String(),
        'sunrise': prayerTimes.sunrise?.toIso8601String(),
        'dhuhr': prayerTimes.dhuhr?.toIso8601String(),
        'asr': prayerTimes.asr?.toIso8601String(),
        'maghrib': prayerTimes.maghrib?.toIso8601String(),
        'isha': prayerTimes.isha?.toIso8601String(),
        'date': prayerTimes.date.toIso8601String(), // Date is not nullable
        'hijriDay': prayerTimes.hijriDay,
        'hijriMonth': prayerTimes.hijriMonth,
        'hijriYear': prayerTimes.hijriYear,
        'hijriMonthName': prayerTimes.hijriMonthName,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await _cacheService.saveData(cacheKey, jsonEncode(prayerTimesJson));
      _logger.debug('Cached prayer times for ${prayerTimes.date}');

      // Clean up old cached entries
      _cleanupOldCache();
    } catch (e) {
      _logger.error('Error caching prayer times', error: e);
    }
  }

  /// Get cached prayer times for a specific date and location
  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates,
  ) async {
    try {
      final cacheKey = _generateCacheKey(date, coordinates);
      final cachedData = _cacheService.getData(cacheKey) as String?;

      if (cachedData == null) {
        return null;
      }

      final Map<String, dynamic> prayerTimesJson = jsonDecode(cachedData);

      // Helper to safely parse DateTime?
      DateTime? safeParseDateTime(String? dateString) {
        return dateString == null ? null : DateTime.parse(dateString);
      }

      return PrayerTimesModel(
        fajr: safeParseDateTime(prayerTimesJson['fajr'] as String?),
        sunrise: safeParseDateTime(prayerTimesJson['sunrise'] as String?),
        dhuhr: safeParseDateTime(prayerTimesJson['dhuhr'] as String?),
        asr: safeParseDateTime(prayerTimesJson['asr'] as String?),
        maghrib: safeParseDateTime(prayerTimesJson['maghrib'] as String?),
        isha: safeParseDateTime(prayerTimesJson['isha'] as String?),
        date: DateTime.parse(prayerTimesJson['date'] as String), // Date is not nullable
        hijriDay: prayerTimesJson['hijriDay'] as int,
        hijriMonth: prayerTimesJson['hijriMonth'] as int,
        hijriYear: prayerTimesJson['hijriYear'],
        hijriMonthName: prayerTimesJson['hijriMonthName'],
      );
    } catch (e) {
      _logger.error('Error retrieving cached prayer times', error: e);
      return null;
    }
  }

  /// Clean up old cached entries
  Future<void> _cleanupOldCache() async {
    try {
      final allKeys = _cacheService.getAllKeys().where(
        (key) => key.startsWith(_cacheKeyPrefix),
      );

      final now = DateTime.now();
      final cutoffDate = DateTime(
        now.year,
        now.month,
        now.day - _cacheDurationDays,
      );

      for (final key in allKeys) {
        // Extract date from key (format: prayer_times_YYYY-MM-DD_LAT_LON)
        final parts = key.split('_');
        if (parts.length >= 3) {
          try {
            final dateStr = parts[2];
            final date = DateTime.parse(dateStr);

            if (date.isBefore(cutoffDate)) {
              await _cacheService.removeData(key);
              _logger.debug('Removed old cached prayer times for $dateStr');
            }
          } catch (e) {
            // Skip this key if it doesn't match our expected format
            continue;
          }
        }
      }
    } catch (e) {
      _logger.error('Error cleaning up prayer times cache', error: e);
    }
  }

  /// Prefetch prayer times for the next several days
  Future<void> prefetchPrayerTimes(
    Future<PrayerTimesModel> Function(DateTime) getPrayerTimes,
    Coordinates coordinates, {
    int daysToFetch = 7,
  }) async {
    // Start with today
    final now = DateTime.now();

    for (int i = 0; i < daysToFetch; i++) {
      final date = DateTime(now.year, now.month, now.day + i);

      // Check if already cached
      final cached = await getCachedPrayerTimes(date, coordinates);
      if (cached == null) {
        try {
          final prayerTimes = await getPrayerTimes(date);
          await cachePrayerTimes(prayerTimes, coordinates);
        } catch (e) {
          _logger.error('Error prefetching prayer times', error: e);
        }
      }
    }
  }
}
