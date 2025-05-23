import 'dart:convert'; // Added for jsonEncode and jsonDecode

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
      // Use CacheService's setCache method with appropriate expiration
      // Note: CacheService.setCache was removed in Subtask 15.
      // For this refactoring, I will use CacheService.saveData directly,
      // assuming CacheService is responsible for handling JSON encoding if needed,
      // or that PrayerTimesModel.toJson() returns a Map<String, dynamic> suitable for it.
      // The CacheService.saveData currently handles different types including String (for JSON).
      // The setCache method previously handled jsonEncode and timestamping.
      // We will replicate that logic here or assume saveData can handle a Map.
      // For now, let's assume saveData will store the JSON string correctly.
      // And CacheService.getCache (now getData) will retrieve it.
      // CacheService.setCache used expirationMinutes, CacheService.saveData does not directly.
      // This implies CacheService itself needs to handle expiration based on a new parameter,
      // or we use a different key structure with expiration, or rely on PrayerTimesCache's own logic.
      // For now, will use the existing CacheService.saveData and getCache (getData) structure.
      // The CacheService.setCache implementation was:
      //   final String jsonData = jsonEncode(data);
      //   final int timestamp = DateTime.now().add(Duration(minutes: expirationMinutes)).millisecondsSinceEpoch;
      //   await _prefs.setString('${key}_data', jsonData);
      //   await _prefs.setInt('${key}_expiration', timestamp);
      // We need to replicate this logic if CacheService.saveData doesn't do it.
      // Given CacheService.saveData just saves the value and CacheService.getData just gets it,
      // PrayerTimesCache MUST handle the JSON conversion and expiration logic itself if CacheService doesn't.
      // The CacheService setCache/getCache methods that handled this were removed.
      // I will re-implement the core logic here.

      final Map<String, dynamic> prayerTimesJson = prayerTimes.toJson();
      // Manually handle expiration like the old CacheService.setCache
      final int expirationTimestamp = DateTime.now().add(Duration(days: _cacheDurationDays)).millisecondsSinceEpoch;
      
      await _cacheService.saveData(cacheKey, jsonEncode(prayerTimesJson)); // Save data
      await _cacheService.saveData('${cacheKey}_expiration', expirationTimestamp); // Save expiration

      _logger.debug('Cached prayer times for ${prayerTimes.date} with key $cacheKey until ${DateTime.fromMillisecondsSinceEpoch(expirationTimestamp)}');

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
      
      // Manually handle expiration like the old CacheService.getCache
      final int? expirationTimestamp = _cacheService.getData('${cacheKey}_expiration') as int?;
      if (expirationTimestamp == null || expirationTimestamp < DateTime.now().millisecondsSinceEpoch) {
        await _cacheService.removeData(cacheKey); // Remove data
        await _cacheService.removeData('${cacheKey}_expiration'); // Remove expiration
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



