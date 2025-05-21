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

      // Convert to JSON for storage - This is handled by CacheService now
      final Map<String, dynamic> prayerTimesJson = {
        'fajr': prayerTimes.fajr?.toIso8601String(),
        'sunrise': prayerTimes.sunrise?.toIso8601String(),
        'dhuhr': prayerTimes.dhuhr?.toIso8601String(),
        'asr': prayerTimes.asr?.toIso8601String(),
        'maghrib': prayerTimes.maghrib?.toIso8601String(),
        'isha': prayerTimes.isha?.toIso8601String(),
        'date': prayerTimes.date.toIso8601String(),
        'hijriDay': prayerTimes.hijriDay,
        'hijriMonth': prayerTimes.hijriMonth,
        'hijriYear': prayerTimes.hijriYear,
        'hijriMonthName': prayerTimes.hijriMonthName,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      // Use CacheService's setCache method with appropriate expiration
      await _cacheService.setCache(
        cacheKey,
        prayerTimesJson,
        expirationMinutes: _cacheDurationDays * 24 * 60,
      );
      _logger.debug('Cached prayer times for ${prayerTimes.date}');

      // Clean up old cached entries
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
      // Use CacheService's getCache method
      final cachedData = _cacheService.getCache<Map<String, dynamic>>(cacheKey);

      if (cachedData == null) {
        return null;
      }

      final Map<String, dynamic> prayerTimesJson = cachedData;

      // Helper to safely parse DateTime?
      DateTime? safeParseDateTime(String? dateString) {
        return dateString == null ? null : DateTime.tryParse(dateString);
      }

      return PrayerTimesModel(
        fajr: safeParseDateTime(prayerTimesJson['fajr'] as String?),
        sunrise: safeParseDateTime(prayerTimesJson['sunrise'] as String?),
        dhuhr: safeParseDateTime(prayerTimesJson['dhuhr'] as String?),
        asr: safeParseDateTime(prayerTimesJson['asr'] as String?),
        maghrib: safeParseDateTime(prayerTimesJson['maghrib'] as String?),
        isha: safeParseDateTime(prayerTimesJson['isha'] as String?),
        date: DateTime.parse(prayerTimesJson['date'] as String),
        hijriDay: prayerTimesJson['hijriDay'] as int,
        hijriMonth: prayerTimesJson['hijriMonth'] as int,
        hijriYear: prayerTimesJson['hijriYear'] as int,
        hijriMonthName: prayerTimesJson['hijriMonthName'] as String,
      );
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
      // Access SharedPreferences keys directly via CacheService's internal _prefs object or a new getter in CacheService
      // For now, assuming CacheService might expose a way to get all its keys or we adapt.
      // This part needs CacheService to expose its SharedPreferences instance or a method to get all keys.
      // Let's assume _cacheService._prefs.getKeys() is accessible for this refactoring step.
      // If not, CacheService needs modification or this logic needs to be re-thought.
      // For the purpose of this refactor, we will proceed with a placeholder for how keys are fetched.
      // In a real scenario, CacheService would need a `getAllKeys()` method or similar.
      // Since CacheService uses `_prefs.getKeys()`, we can't directly call it here without modifying CacheService.
      // However, `CacheService.clearAllCache()` iterates keys, so a similar internal mechanism exists.
      // For now, this method will be less effective if it can't list keys starting with _cacheKeyPrefix.
      // A better approach would be for CacheService to manage its own expirations more proactively
      // or provide a method to remove keys by prefix and check their specific expiration metadata.

      // The current CacheService.getCache() already handles expiration for individual keys upon access.
      // A dedicated cleanup for PrayerTimesCache might be redundant if CacheService handles global expiry well.
      // However, if we want to be proactive for this specific type of cache:

      _logger.info('Starting cleanup of old prayer times cache entries.');
      // This is a simplified placeholder. A robust solution requires CacheService to provide a way to iterate its keys
      // or for PrayerTimesCache to maintain its own list of managed keys.
      // Given CacheService.removeCache(key) exists, we can try to remove keys if we knew them.
      // One strategy: iterate known date ranges. This is inefficient.
      // Best: CacheService.removeKeysByPrefix(prefix) or CacheService.getKeysByPrefix(prefix)

      // For now, we will rely on CacheService.getCache() to clear expired entries on access.
      // A more aggressive cleanup would require changes to CacheService.
      // Consider removing this method or enhancing CacheService.
      // For this iteration, let's log that cleanup is deferred to CacheService's on-access expiry.
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

  /// Prefetch prayer times for the next several days
  Future<void> prefetchPrayerTimes(
    Future<PrayerTimesModel> Function(DateTime) getPrayerTimes,
    Coordinates coordinates, {
    int daysToFetch = 7,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < daysToFetch; i++) {
      final date = today.add(Duration(days: i));

      final cached = await getCachedPrayerTimes(date, coordinates);
      if (cached == null) {
        try {
          _logger.debug('Prefetching prayer times for $date');
          final prayerTimes = await getPrayerTimes(date);
          await cachePrayerTimes(prayerTimes, coordinates);
        } catch (e, s) {
          _logger.error(
            'Error prefetching prayer times for $date',
            error: e,
            stackTrace: s,
          );
        }
      }
    }
  }
}
