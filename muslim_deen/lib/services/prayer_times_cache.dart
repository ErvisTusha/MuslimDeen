import 'package:adhan_dart/adhan_dart.dart';

import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/models/app_settings.dart';

/// Specialized cache for prayer times to reduce API calls and calculations
class PrayerTimesCache {
  static const String _cacheKeyPrefix = 'prayer_times_';

  final CacheService _cacheService;
  final LoggerService _logger;

  PrayerTimesCache(this._cacheService, this._logger);

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
