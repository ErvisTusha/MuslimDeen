import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';

/// Service responsible for calculating and providing prayer times.
///
/// It handles different calculation methods, madhabs, and user-specific offsets.
/// It also caches the latest calculated prayer times and provides information
/// about the current and next prayer.
class PrayerService {
  final LocationService _locationService;
  final PrayerTimesCache _prayerTimesCache;
  adhan.PrayerTimes? _currentPrayerTimes;
  DateTime? _lastCalculationTime;
  adhan.CalculationParameters? _lastParamsUsed;
  DateTime? _lastCalculationDate;
  bool _isInitialized = false;
  final LoggerService _logger = locator<LoggerService>();
  String? _lastCalculationMethodString;
  AppSettings? _lastAppSettingsUsed;

  // Performance optimization: Cache calculation parameters
  final Map<String, adhan.CalculationParameters> _paramCache = {};

  // Performance optimization: Cache position for short periods
  Position? _cachedPosition;
  DateTime? _positionCacheTime;
  static const Duration _positionCacheDuration = Duration(minutes: 5);

  PrayerService(this._locationService, this._prayerTimesCache);

  Future<void> init() async {
    if (_isInitialized) return;
    await _locationService.init();
    _isInitialized = true;
    _logger.info('PrayerService initialized');
  }

  /// Creates CalculationParameters based on the provided settings with caching.
  /// Falls back to defaults if settings are null or invalid.
  adhan.CalculationParameters _getCalculationParams(AppSettings? settings) {
    final calculationMethod =
        settings?.calculationMethod ?? 'MuslimWorldLeague';
    final madhab = settings?.madhab ?? 'hanafi';
    final cacheKey = '$calculationMethod-$madhab';

    if (_paramCache.containsKey(cacheKey)) {
      return _paramCache[cacheKey]!;
    }

    adhan.CalculationParameters params;

    switch (calculationMethod) {
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
      case 'Turkey':
        _logger.warning(
          "Warning: 'Turkey' calculation method selected, but not directly supported by adhan_dart. Falling back to MuslimWorldLeague.",
        );
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
        break;
      default:
        _logger.warning(
          "Unsupported calculation method '$calculationMethod', using MuslimWorldLeague.",
        );
        params =
            adhan.CalculationMethod.muslimWorldLeague()
                as adhan.CalculationParameters;
    }

    params.madhab =
        (madhab.toLowerCase() == 'hanafi')
            ? adhan.Madhab.hanafi
            : adhan.Madhab.shafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.twilightAngle;

    _paramCache[cacheKey] = params;

    return params;
  }

  /// Calculates prayer times for a specific date and position,
  /// performs the calculation, updates service state, caches the result, and returns the prayer times.
  Future<adhan.PrayerTimes> _calculateAndPersistPrayerTimes(
    DateTime date,
    Position position,
    AppSettings effectiveSettings,
    adhan.CalculationParameters currentParams,
  ) async {
    final DateTime dateForCalculation = date.toUtc();
    final adhan.Coordinates coordinates = adhan.Coordinates(
      position.latitude,
      position.longitude,
    );

    final newAdhanPrayerTimes = adhan.PrayerTimes(
      coordinates: coordinates,
      date: dateForCalculation,
      calculationParameters: currentParams,
    );

    _currentPrayerTimes = newAdhanPrayerTimes;
    _lastCalculationTime = DateTime.now();
    _lastParamsUsed = currentParams;
    _lastCalculationDate = dateForCalculation;
    _lastCalculationMethodString = effectiveSettings.calculationMethod;
    _lastAppSettingsUsed = effectiveSettings;

    _logger.debug(
      'Prayer times calculated (cache miss or direct calc) and service state updated',
      data: {
        'date': dateForCalculation.toIso8601String(),
        'lat': position.latitude,
        'lon': position.longitude,
        'method': effectiveSettings.calculationMethod,
        'madhab': effectiveSettings.madhab,
        'fajr': newAdhanPrayerTimes.fajr?.toIso8601String(),
      },
    );

    final prayerTimesModelToCache = PrayerTimesModel.fromAdhanPrayerTimes(
      newAdhanPrayerTimes,
      date,
    );
    await _prayerTimesCache.cachePrayerTimes(
      prayerTimesModelToCache,
      coordinates,
    );
    _logger.info('Prayer times for $date cached.');

    return newAdhanPrayerTimes;
  }

  /// Helper method to get the effective position with caching, handling errors and fallback.
  Future<Position> _getEffectivePosition(String operationContext) async {
    if (_cachedPosition != null &&
        _positionCacheTime != null &&
        DateTime.now().difference(_positionCacheTime!) <
            _positionCacheDuration) {
      return _cachedPosition!;
    }

    try {
      final position = await _locationService.getLocation();

      _cachedPosition = position;
      _positionCacheTime = DateTime.now();

      return position;
    } catch (e) {
      _logger.error(
        'Error getting location for $operationContext, using fallback.',
        error: e,
      );
      return _getFallbackPosition();
    }
  }

  /// Gets user location based on their preference (manual or device)
  /// and calculates prayer times for the given date using provided settings.
  /// This method now incorporates caching.
  Future<adhan.PrayerTimes> calculatePrayerTimesForDate(
    DateTime date,
    AppSettings? settings,
  ) async {
    if (!_isInitialized) await init();
    final effectiveSettings = settings ?? AppSettings.defaults;
    final position = await _getEffectivePosition(
      'prayer time calculation for date ${date.toIso8601String()}',
    );
    final coordinates = adhan.Coordinates(
      position.latitude,
      position.longitude,
    );

    if (_canReuseCurrentCalculation(date, effectiveSettings, coordinates)) {
      _logger.debug('Reusing current prayer time calculation');
      return _currentPrayerTimes!;
    }

    final cachedTimes = await _prayerTimesCache.getCachedPrayerTimes(
      date,
      coordinates,
    );

    if (cachedTimes != null) {
      final currentParams = _getCalculationParams(effectiveSettings);
      final adhanPrayerTimes = adhan.PrayerTimes(
        coordinates: coordinates,
        date: date.toUtc(),
        calculationParameters: currentParams,
      );

      _currentPrayerTimes = adhanPrayerTimes;
      _lastCalculationTime = DateTime.now();
      _lastParamsUsed = currentParams;
      _lastCalculationDate = date.toUtc();
      _lastCalculationMethodString = effectiveSettings.calculationMethod;
      _lastAppSettingsUsed = effectiveSettings;

      _logger.debug('Prayer times loaded from cache and service state updated');
      return adhanPrayerTimes;
    }

    final currentParams = _getCalculationParams(effectiveSettings);
    return await _calculateAndPersistPrayerTimes(
      date,
      position,
      effectiveSettings,
      currentParams,
    );
  }

  /// Check if current calculation can be reused to avoid redundant computations
  bool _canReuseCurrentCalculation(
    DateTime date,
    AppSettings settings,
    adhan.Coordinates coordinates,
  ) {
    if (_currentPrayerTimes == null || _lastCalculationDate == null) {
      return false;
    }

    final dateUtc = date.toUtc();
    final isSameDate =
        _lastCalculationDate!.year == dateUtc.year &&
        _lastCalculationDate!.month == dateUtc.month &&
        _lastCalculationDate!.day == dateUtc.day;

    final settingsMadhab = settings.madhab.toLowerCase();
    final lastMadhab = _lastParamsUsed?.madhab;
    final isSameMadhab = (settingsMadhab == 'hanafi' && lastMadhab == adhan.Madhab.hanafi) ||
                         (settingsMadhab == 'shafi' && lastMadhab == adhan.Madhab.shafi) ||
                         (settingsMadhab != 'hanafi' && settingsMadhab != 'shafi' && lastMadhab == adhan.Madhab.shafi);
    
    final isSameSettings =
        _lastCalculationMethodString == settings.calculationMethod && isSameMadhab;

    const positionTolerance = 0.001; // About 100m
    final isSameLocation =
        (_currentPrayerTimes!.coordinates.latitude - coordinates.latitude)
                .abs() <
            positionTolerance &&
        (_currentPrayerTimes!.coordinates.longitude - coordinates.longitude)
                .abs() <
            positionTolerance;

    return isSameDate && isSameSettings && isSameLocation;
  }

  /// Gets user location based on their preference (manual or device)
  /// and calculates today's prayer times using provided settings.
  /// Updates the service's current prayer times state.
  Future<adhan.PrayerTimes> calculatePrayerTimesForToday(
    AppSettings? settings,
  ) async {
    return calculatePrayerTimesForDate(DateTime.now(), settings);
  }

  /// Provides a fallback position (Mecca) when location services fail or are unavailable.
  /// This ensures that prayer time calculations can still proceed with a default location.
  Position _getFallbackPosition() {
    _logger.warning('Using fallback position (Mecca) for prayer calculations.');
    return Position(
      latitude: 21.4225,
      longitude: 39.8262,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Determines the current prayer based on the current time and cached prayer times.
  /// Returns the standardized prayer name ('fajr', 'dhuhr', etc.) or 'none'.
  /// Throws an exception if times haven't been calculated yet.
  String getCurrentPrayer() {
    if (_currentPrayerTimes == null) {
      _logger.warning('Attempted to get current prayer before calculation.');
      return adhan.Prayer.none;
    }
    return _currentPrayerTimes!.currentPrayer(date: DateTime.now()) as String;
  }

  /// Determines the next prayer based on the current time and cached prayer times.
  /// Returns the standardized prayer name ('fajr', 'dhuhr', etc.).
  /// Handles wrapping around from Isha to Fajr.
  /// Throws an exception if times haven't been calculated yet.
  String getNextPrayer() {
    if (_currentPrayerTimes == null) {
      _logger.warning('Attempted to get next prayer before calculation.');
      return adhan.Prayer.none;
    }
    return _currentPrayerTimes!.nextPrayer(date: DateTime.now()) as String;
  }

  /// Calculates the time of the next prayer.
  /// Returns the DateTime of the next prayer, or null if calculation fails.
  /// Handles the transition from Isha to the next day's Fajr.
  /// Throws an exception if initial calculation hasn't happened.
  Future<DateTime?> getNextPrayerTime() async {
    if (_currentPrayerTimes == null) {
      _logger.warning('Attempted to get next prayer time before calculation.');
      return null;
    }
    final String nextPrayerName = getNextPrayer();
    final String currentPrayerName = getCurrentPrayer();

    if (nextPrayerName == adhan.Prayer.none) {
      if (currentPrayerName == adhan.Prayer.isha) {
        _logger.debug(
          "Current prayer is Isha, next prayer is Fajr tomorrow. Attempting to calculate next day's Fajr.",
        );
        if (_lastAppSettingsUsed != null) {
          return await _getNextDayFajr(_lastAppSettingsUsed!);
        } else {
          _logger.warning(
            "Cannot calculate next day's Fajr for getNextPrayerTime because _lastAppSettingsUsed is null.",
          );
          return null;
        }
      } else {
        _logger.warning(
          "getNextPrayerTime: nextPrayer is 'none', but current prayer is not 'isha'. Current: $currentPrayerName",
        );
        return null;
      }
    }
    return _currentPrayerTimes!.timeForPrayer(nextPrayerName);
  }

  Future<void> recalculatePrayerTimesIfNeeded(AppSettings settings) async {
    if (!_isInitialized) await init();

    final currentSettingsParams = _getCalculationParams(settings);
    final String currentMethodNameString = settings.calculationMethod;
    final nowUtc = DateTime.now().toUtc();

    final bool dateChanged =
        _lastCalculationDate == null ||
        _lastCalculationDate!.year != nowUtc.year ||
        _lastCalculationDate!.month != nowUtc.month ||
        _lastCalculationDate!.day != nowUtc.day;

    final bool needsRecalculation =
        _currentPrayerTimes == null ||
        _lastCalculationTime == null ||
        DateTime.now().difference(_lastCalculationTime!) >
            const Duration(hours: 1) ||
        _lastParamsUsed?.madhab != currentSettingsParams.madhab ||
        _lastCalculationMethodString != currentMethodNameString ||
        dateChanged;

    if (needsRecalculation) {
      String reason;
      if (_currentPrayerTimes == null) {
        reason = 'initial_calc';
      } else if (_lastCalculationTime == null) {
        reason = 'no_last_calc_time';
      } else if (DateTime.now().difference(_lastCalculationTime!) >
          const Duration(hours: 1)) {
        reason = 'time_elapsed';
      } else if (_lastParamsUsed?.madhab != currentSettingsParams.madhab) {
        reason = 'madhab_changed';
      } else if (_lastCalculationMethodString != currentMethodNameString) {
        reason = 'method_name_changed';
      } else if (dateChanged) {
        reason = 'date_changed';
      } else {
        reason = 'unknown_recalculation_trigger';
        _logger.warning(
          'Prayer times recalculation triggered, but specific reason not identified by simplified logic.',
          data: {
            'needsRecalculation': needsRecalculation,
            'dateChanged': dateChanged,
            'lastCalcTimeNull': _lastCalculationTime == null,
            'timeDiffHours':
                _lastCalculationTime != null
                    ? DateTime.now().difference(_lastCalculationTime!).inHours
                    : null,
            'madhabChanged':
                _lastParamsUsed?.madhab != currentSettingsParams.madhab,
            'methodChanged':
                _lastCalculationMethodString != currentMethodNameString,
          },
        );
      }

      _logger.info(
        'Recalculating prayer times due to settings/time change',
        data: {'reason': reason},
      );
      try {
        await calculatePrayerTimesForToday(settings);
      } catch (e) {
        _logger.error(
          "Error during scheduled recalculation of prayer times",
          error: e,
          data: {'settingsJson': settings.toJson()},
        );
      }
    }
  }

  Future<DateTime?> _getNextDayFajr(AppSettings settings) async {
    if (!_isInitialized) await init();
    final position = await _getEffectivePosition('next day Fajr calculation');

    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final params = _getCalculationParams(settings);
      final tomorrowPrayerTimes = adhan.PrayerTimes(
        date: tomorrow,
        coordinates: adhan.Coordinates(position.latitude, position.longitude),
        calculationParameters: params,
      );
      _logger.debug(
        "Calculated next day's Fajr",
        data: {'fajrTime': tomorrowPrayerTimes.fajr?.toIso8601String()},
      );
      return tomorrowPrayerTimes.fajr;
    } catch (e) {
      _logger.error(
        "Error calculating next day's Fajr",
        error: e,
        data: {'settingsJson': settings.toJson()},
      );
      return null;
    }
  }

  DateTime? getOffsettedPrayerTime(
    String prayerName,
    adhan.PrayerTimes rawPrayerTimes,
    AppSettings settings,
  ) {
    DateTime? rawTime;
    int offsetMinutes = 0;

    switch (prayerName.toLowerCase()) {
      case 'fajr':
        rawTime = rawPrayerTimes.fajr;
        offsetMinutes = settings.fajrOffset;
        break;
      case 'sunrise':
        rawTime = rawPrayerTimes.sunrise;
        offsetMinutes = settings.sunriseOffset;
        break;
      case 'dhuhr':
        rawTime = rawPrayerTimes.dhuhr;
        offsetMinutes = settings.dhuhrOffset;
        break;
      case 'asr':
        rawTime = rawPrayerTimes.asr;
        offsetMinutes = settings.asrOffset;
        break;
      case 'maghrib':
        rawTime = rawPrayerTimes.maghrib;
        offsetMinutes = settings.maghribOffset;
        break;
      case 'isha':
        rawTime = rawPrayerTimes.isha;
        offsetMinutes = settings.ishaOffset;
        break;
      default:
        _logger.warning(
          'getOffsettedPrayerTime called with unknown prayer name: $prayerName',
        );
        return null;
    }

    if (rawTime == null) {
      return null;
    }
    return rawTime.add(Duration(minutes: offsetMinutes));
  }
}
