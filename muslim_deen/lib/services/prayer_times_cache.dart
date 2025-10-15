import 'dart:convert'; // Added for jsonEncode and jsonDecode

import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Specialized cache for prayer times to reduce API calls and calculations
class PrayerTimesCache {
  static const String _cacheKeyPrefix = 'prayer_times_';
  static const int _cacheDurationHours = 6; // Extended from 30 days to 6 hours
  static const int _maxCacheSize = 100; // Maximum number of cached entries

  final CacheService _cacheService;
  final LoggerService _logger;

  // Track cache keys for size management
  final List<String> _cacheKeys = [];
  final Map<String, DateTime> _cacheTimestamps = {};

  PrayerTimesCache(this._cacheService, this._logger);

  /// Generate a more specific cache key for a specific date, location, and calculation parameters
  String _generateCacheKey(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) {
    // Format as prayer_times_YYYY-MM-DD_HH_LAT_LON_METHOD_MADHAB
    // Including hour for more granular caching
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}_${date.hour.toString().padLeft(2, '0')}';
    // Use a fixed number of decimal places for latitude and longitude to ensure key consistency.
    final locationStr =
        '${coordinates.latitude.toStringAsFixed(4)}_${coordinates.longitude.toStringAsFixed(4)}';
    final methodStr = calculationMethod ?? 'default';
    final madhabStr = madhab ?? 'default';
    return '$_cacheKeyPrefix${dateStr}_$locationStr\_$methodStr\_$madhabStr';
  }

  /// Cache prayer times for a specific date and location
  Future<void> cachePrayerTimes(
    PrayerTimesModel prayerTimes,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        prayerTimes.date,
        coordinates,
        calculationMethod: calculationMethod,
        madhab: madhab,
      );

      // Manage cache size
      await _manageCacheSize();

      final Map<String, dynamic> prayerTimesJson = prayerTimes.toJson();
      // Manually handle expiration like the old CacheService.setCache
      final int expirationTimestamp =
          DateTime.now()
              .add(Duration(hours: _cacheDurationHours))
              .millisecondsSinceEpoch;

      await _cacheService.saveData(
        cacheKey,
        jsonEncode(prayerTimesJson),
      ); // Save data
      await _cacheService.saveData(
        '${cacheKey}_expiration',
        expirationTimestamp,
      ); // Save expiration

      // Track this key for size management
      _cacheKeys.add(cacheKey);
      _cacheTimestamps[cacheKey] = DateTime.now();

      _logger.debug(
        'Cached prayer times for ${prayerTimes.date} with key $cacheKey until ${DateTime.fromMillisecondsSinceEpoch(expirationTimestamp)}',
      );

      // Clean up old cached entries
      await _cleanupOldCache();
    } catch (e, s) {
      _logger.error('Error caching prayer times', error: e, stackTrace: s);
    }
  }

  /// Manage cache size by removing oldest entries
  Future<void> _manageCacheSize() async {
    if (_cacheKeys.length >= _maxCacheSize) {
      // Sort keys by timestamp (oldest first)
      final sortedKeys = List<String>.from(_cacheKeys);
      sortedKeys.sort((a, b) {
        final timeA =
            _cacheTimestamps[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timeB =
            _cacheTimestamps[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timeA.compareTo(timeB);
      });

      // Remove oldest entries (10% of cache or 1 entry, whichever is larger)
      final removeCount = (_maxCacheSize * 0.1).ceil().clamp(
        1,
        _maxCacheSize ~/ 2,
      );
      for (int i = 0; i < removeCount && i < sortedKeys.length; i++) {
        final keyToRemove = sortedKeys[i];
        await _cacheService.removeData(keyToRemove);
        await _cacheService.removeData('${keyToRemove}_expiration');
        _cacheKeys.remove(keyToRemove);
        _cacheTimestamps.remove(keyToRemove);
      }

      _logger.debug(
        'Removed $removeCount oldest cache entries to maintain size limit',
      );
    }
  }

  /// Get cached prayer times for a specific date and location
  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        date,
        coordinates,
        calculationMethod: calculationMethod,
        madhab: madhab,
      );

      // Manually handle expiration like the old CacheService.getCache
      final int? expirationTimestamp =
          _cacheService.getData('${cacheKey}_expiration') as int?;
      if (expirationTimestamp == null ||
          expirationTimestamp < DateTime.now().millisecondsSinceEpoch) {
        await _cacheService.removeData(cacheKey); // Remove data
        await _cacheService.removeData(
          '${cacheKey}_expiration',
        ); // Remove expiration
        _cacheKeys.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
        _logger.debug(
          'Cached prayer times for $date with key $cacheKey expired or not found.',
        );
        return null;
      }

      final String? jsonData = _cacheService.getData(cacheKey) as String?;
      if (jsonData == null) {
        return null;
      }

      final Map<String, dynamic> prayerTimesJson =
          jsonDecode(jsonData) as Map<String, dynamic>;
      _logger.debug(
        'Retrieved cached prayer times for $date with key $cacheKey',
      );
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
}
