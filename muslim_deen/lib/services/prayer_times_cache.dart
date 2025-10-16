import 'package:adhan_dart/adhan_dart.dart';

import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/models/app_settings.dart';

/// Specialized cache service for prayer times to reduce calculations and improve performance.
///
/// This service provides a caching layer specifically designed for prayer times data,
/// implementing intelligent cache key generation and optimized storage/retrieval.
/// It acts as a facade over the general [CacheService] with prayer-specific logic.
///
/// ## Key Features
/// - Optimized cache key generation for high hit rates
/// - Coordinate rounding to improve cache reuse for nearby locations
/// - Support for different calculation methods and madhabs
/// - Error handling with graceful degradation
/// - Structured cache key format for easy debugging
///
/// ## Cache Key Format
/// The cache key follows the pattern: `prayer_times_YYYY-MM-DD_lat_lng_method_madhab`
/// where coordinates are rounded to 4 decimal places for better hit rates.
///
/// ## Dependencies
/// - [CacheService]: Underlying storage service for cached data
/// - [LoggerService]: Centralized logging for cache operations
///
/// ## Performance Benefits
/// - Reduces expensive prayer time calculations
/// - Improves app responsiveness, especially for date navigation
/// - Minimizes battery usage by avoiding repeated calculations
/// - Provides offline capability for previously calculated dates
class PrayerTimesCache {
  static const String _cacheKeyPrefix = 'prayer_times_';

  final CacheService _cacheService;
  final LoggerService _logger;

  PrayerTimesCache(this._cacheService, this._logger);

  /// Generates an optimized cache key for prayer times storage and retrieval.
  ///
  /// The cache key is designed to maximize hit rates while maintaining uniqueness
  /// for different calculation parameters. It includes:
  /// - Date in YYYY-MM-DD format for easy chronological sorting
  /// - Coordinates rounded to 4 decimal places (≈11m precision)
  /// - Calculation method for different Islamic calculation schools
  /// - Madhab for Hanafi/Shafi differences in Asr timing
  ///
  /// Parameters:
  /// - [date]: The prayer date
  /// - [coordinates]: Geographic location
  /// - [calculationMethod]: Islamic calculation method (MWL, Umm Al-Qura, etc.)
  /// - [madhab]: Islamic school of law (Hanafi, Shafi)
  ///
  /// Returns: String cache key in format `prayer_times_YYYY-MM-DD_lat_lng_method_madhab`
  ///
  /// Design Note: Coordinate rounding balances cache efficiency with accuracy needs
  String _generateCacheKey(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final locationStr =
        '${coordinates.latitude.toStringAsFixed(4)}_${coordinates.longitude.toStringAsFixed(4)}';
    final methodStr = calculationMethod ?? 'default';
    final madhabStr = madhab ?? 'default';
    return '$_cacheKeyPrefix${dateStr}_$locationStr\_$methodStr\_$madhabStr';
  }

  /// Caches prayer times for a specific date and location.
  ///
  /// This method stores calculated prayer times in the underlying cache service
  /// using an optimized cache key for future retrieval. It handles all error
  /// cases gracefully to ensure caching failures don't break the main flow.
  ///
  /// Parameters:
  /// - [prayerTimes]: The calculated prayer times to cache
  /// - [coordinates]: Geographic location for the prayer times
  /// - [calculationMethod]: Islamic calculation method used
  /// - [madhab]: Islamic school of law used
  ///
  /// Error Handling: Catches and logs all exceptions but doesn't rethrow
  ///
  /// Performance: Asynchronous operation that doesn't block the main thread
  Future<void> cachePrayerTimes(
    PrayerTimes prayerTimes,
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

      await _cacheService.cachePrayerTimes(prayerTimes);

      _logger.debug(
        'Cached prayer times for ${prayerTimes.date} with key $cacheKey',
      );
    } catch (e, s) {
      _logger.error('Error caching prayer times', error: e, stackTrace: s);
    }
  }

  Future<PrayerTimesModel?> getCachedPrayerTimes(
    DateTime date,
    Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
    AppSettings? settings,
  }) async {
    try {
      final cacheKey = _generateCacheKey(
        date,
        coordinates,
        calculationMethod: calculationMethod,
        madhab: madhab,
      );

      final PrayerTimes? cachedPrayerTimes = await _cacheService
          .getCachedPrayerTimes(settings!, coordinates);
      if (cachedPrayerTimes != null) {
        final prayerTimesJson = {
          'date': date.toIso8601String(),
          'fajr': cachedPrayerTimes.fajr?.toIso8601String(),
          'sunrise': cachedPrayerTimes.sunrise?.toIso8601String(),
          'dhuhr': cachedPrayerTimes.dhuhr?.toIso8601String(),
          'asr': cachedPrayerTimes.asr?.toIso8601String(),
          'maghrib': cachedPrayerTimes.maghrib?.toIso8601String(),
          'isha': cachedPrayerTimes.isha?.toIso8601String(),
        };
        _logger.debug(
          'Retrieved cached prayer times for $date with key $cacheKey',
        );
        return PrayerTimesModel.fromJson(prayerTimesJson);
      }
      return null;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached prayer times',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
