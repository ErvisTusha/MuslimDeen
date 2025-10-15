import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:adhan_dart/adhan_dart.dart' show Coordinates;

class CacheService {
  static const String _prayerTimesCacheKey = 'prayer_times_cache';
  static const String _cacheTimestampKey = 'prayer_times_cache_timestamp';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

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
