import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:adhan_dart/adhan_dart.dart' show Coordinates;

/// Legacy prayer times cache service for backward compatibility.
///
/// This service provides basic caching functionality for prayer times
/// using SharedPreferences. It's maintained for backward compatibility
/// but newer implementations should use the enhanced caching services.
///
/// ## Key Features
/// - Simple prayer times caching with daily validity
/// - Settings-based cache key generation
/// - Basic cache invalidation
///
/// ## Cache Strategy
/// - Daily cache validity (expires at midnight)
/// - Settings-based cache keys for different configurations
/// - Timestamp-based expiration checking
///
/// ## Limitations
/// - No support for multiple locations
/// - No cache size management
/// - No performance metrics
/// - Limited to single day caching
///
/// ## Dependencies
/// - [SharedPreferences]: Persistent cache storage
/// - [Adhan]: Prayer time calculation library
///
/// ## Migration Note
/// Consider migrating to [PrayerTimesCache] and [LocationCacheManager]
/// for enhanced functionality and performance.
class CacheService {
  static const String _prayerTimesCacheKey = 'prayer_times_cache';
  static const String _cacheTimestampKey = 'prayer_times_cache_timestamp';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Caches prayer times for the current day with timestamp tracking.
  ///
  /// This method stores prayer times in SharedPreferences with a
  /// timestamp for expiration checking. It serializes all prayer
  /// times to ISO 8601 strings for reliable storage.
  ///
  /// Parameters:
  /// - [prayerTimes]: Prayer times object to cache
  ///
  /// ## Storage Format
  /// - JSON object with prayer time strings
  /// - Timestamp for cache validity checking
  /// - Current date for daily expiration
  ///
  /// ## Cached Prayers
  /// - fajr: Morning prayer time
  /// - sunrise: Sunrise time
  /// - dhuhr: Noon prayer time
  /// - asr: Afternoon prayer time
  /// - maghrib: Evening prayer time
  /// - isha: Night prayer time
  ///
  /// Note: Cache expires at midnight (24-hour validity)
  Future<void> cachePrayerTimes(adhan.PrayerTimes prayerTimes) async {
    final prayerTimesMap = {
      'fajr': prayerTimes.fajr?.toIso8601String(),
      'sunrise': prayerTimes.sunrise?.toIso8601String(),
      'dhuhr': prayerTimes.dhuhr?.toIso8601String(),
      'asr': prayerTimes.asr?.toIso8601String(),
      'maghrib': prayerTimes.maghrib?.toIso8601String(),
      'isha': prayerTimes.isha?.toIso8601String(),
    };
    await _prefs.setString(_prayerTimesCacheKey, json.encode(prayerTimesMap));
    await _prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Retrieves cached prayer times if still valid for the current day.
  ///
  /// This method checks cache validity before returning cached prayer
  /// times. It ensures cache consistency by checking both timestamp
  /// and date validity.
  ///
  /// Parameters:
  /// - [settings]: App settings for parameter reconstruction
  /// - [coordinates]: Location coordinates for prayer times
  ///
  /// Returns:
  /// - [PrayerTimes] if cache is valid
  /// - null if cache is expired, invalid, or missing
  ///
  /// ## Validation Process
  /// 1. Check if cached data exists
  /// 2. Verify cache timestamp is not null
  /// 3. Ensure cache is from current day (within 24 hours)
  /// 4. Reconstruct PrayerTimes object with current parameters
  ///
  /// ## Cache Reconstruction
  /// - Uses current date for prayer times
  /// - Applies settings-based calculation parameters
  /// - Uses provided coordinates for location
  ///
  /// Performance: Fast lookup with minimal overhead
  Future<adhan.PrayerTimes?> getCachedPrayerTimes(
    AppSettings settings,
    Coordinates coordinates,
  ) async {
    final cachedPrayerTimes = _prefs.getString(_prayerTimesCacheKey);
    final cacheTimestamp = _prefs.getInt(_cacheTimestampKey);

    if (cachedPrayerTimes != null && cacheTimestamp != null) {
      final now = DateTime.now();
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(cacheTimestamp);
      if (now.difference(cacheDate).inDays == 0) {
        final params = _getCalculationParams(settings);
        return adhan.PrayerTimes(
          date: now,
          coordinates: coordinates,
          calculationParameters: params,
        );
      }
    }
    return null;
  }

  adhan.CalculationParameters _getCalculationParams(AppSettings settings) {
    adhan.CalculationParameters params;

    switch (settings.calculationMethod) {
      case 'MuslimWorldLeague':
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
        break;
      case 'NorthAmerica':
        params =
            adhan.CalculationMethod.northAmerica()
                as adhan.CalculationParameters;
        break;
      case 'Egyptian':
        params =
            adhan.CalculationMethod.egyptian() as adhan.CalculationParameters;
        break;
      case 'UmmAlQura':
        params =
            adhan.CalculationMethod.ummAlQura() as adhan.CalculationParameters;
        break;
      case 'Karachi':
        params =
            adhan.CalculationMethod.karachi() as adhan.CalculationParameters;
        break;
      case 'Tehran':
        params =
            adhan.CalculationMethod.tehran() as adhan.CalculationParameters;
        break;
      case 'Dubai':
        params = adhan.CalculationMethod.dubai() as adhan.CalculationParameters;
        break;
      case 'MoonsightingCommittee':
        params =
            adhan.CalculationMethod.moonsightingCommittee()
                as adhan.CalculationParameters;
        break;
      case 'Kuwait':
        params =
            adhan.CalculationMethod.kuwait() as adhan.CalculationParameters;
        break;
      case 'Qatar':
        params = adhan.CalculationMethod.qatar() as adhan.CalculationParameters;
        break;
      case 'Singapore':
        params =
            adhan.CalculationMethod.singapore() as adhan.CalculationParameters;
        break;
      default:
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
    }

    params.madhab =
        (settings.madhab.toLowerCase() == 'hanafi')
            ? adhan.Madhab.hanafi
            : adhan.Madhab.shafi;

    return params;
  }

  Future<void> invalidateCache() async {
    await _prefs.remove(_prayerTimesCacheKey);
    await _prefs.remove(_cacheTimestampKey);
  }
}
