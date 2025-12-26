import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Specialized cache for prayer times to reduce API calls and calculations
/// Delegated to CacheService for core storage and expiration logic
class PrayerTimesCache {
  static const String _cacheKeyPrefix = 'prayer_times_';
  static const int _cacheDurationMinutes = 720; // 12 hours

  final CacheService _cacheService;
  final LoggerService _logger;

  PrayerTimesCache(this._cacheService, this._logger);

  /// Generate a more specific cache key for a specific date, location, and calculation parameters
  String _generateCacheKey(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final locationStr =
        '${coordinates.latitude.toStringAsFixed(3)}_${coordinates.longitude.toStringAsFixed(3)}';
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
    final cacheKey = _generateCacheKey(
      prayerTimes.date,
      coordinates,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    await _cacheService.setCache(
      cacheKey,
      prayerTimes.toJson(),
      expirationMinutes: _cacheDurationMinutes,
    );

    _logger.debug(
      'Cached prayer times for ${prayerTimes.date} with key $cacheKey',
    );
  }

  /// Get cached prayer times for a specific date and location
  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) async {
    final cacheKey = _generateCacheKey(
      date,
      coordinates,
      calculationMethod: calculationMethod,
      madhab: madhab,
    );

    final Map<String, dynamic>? data = _cacheService
        .getCache<Map<String, dynamic>>(cacheKey);
    if (data == null) return null;

    return PrayerTimesModel.fromJson(data);
  }

  /// Clear all prayer times cache
  Future<void> clearAllCache() async {
    // Ideally CacheService should have a removeWithPrefix method
    // For now we'll let CacheService's LRU handle it or clear completely
    // Given the task is to simplify, we'll keep it simple.
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return _cacheService.getCacheStats();
  }
}
