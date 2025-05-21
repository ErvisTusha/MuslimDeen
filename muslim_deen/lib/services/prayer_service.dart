import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/services/location_service.dart';
import '../models/app_settings.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';

/// Service responsible for calculating and providing prayer times.
///
/// It handles different calculation methods, madhabs, and user-specific offsets.
/// It also caches the latest calculated prayer times and provides information
/// about the current and next prayer.
class PrayerService {
  /// Resets the service state, clearing cached prayer times and calculation data
  void reset() {
    _currentPrayerTimes = null;
    _lastCalculationTime = null;
    _lastParamsUsed = null;
    _lastCalculationDate = null;
    _lastCalculationMethodString = null;
    _lastAppSettingsUsed = null;
    _isInitialized = false;
    _logger.debug('PrayerService state reset');
  }

  final LocationService _locationService;
  adhan.PrayerTimes? _currentPrayerTimes;
  DateTime? _lastCalculationTime;
  adhan.CalculationParameters? _lastParamsUsed;
  DateTime? _lastCalculationDate;
  bool _isInitialized = false;
  final LoggerService _logger = locator<LoggerService>();
  String? _lastCalculationMethodString;
  AppSettings? _lastAppSettingsUsed;

  PrayerService(this._locationService);

  Future<void> init() async {
    if (_isInitialized) return;
    await _locationService.init();
    _isInitialized = true;
    _logger.info('PrayerService initialized');
  }

  /// Gets default calculation parameters (MuslimWorldLeague, Hanafi).
  adhan.CalculationParameters getDefaultParams() {
    final adhan.CalculationParameters params =
        adhan.CalculationMethod.muslimWorldLeague()
            as adhan.CalculationParameters;
    params.madhab = adhan.Madhab.hanafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.twilightAngle;
    return params;
  }

  /// Creates CalculationParameters based on the provided settings.
  /// Falls back to defaults if settings are null or invalid.
  adhan.CalculationParameters _getCalculationParams(AppSettings? settings) {
    adhan.CalculationParameters params;
    final calculationMethod =
        settings?.calculationMethod ?? 'MuslimWorldLeague';
    final madhab = settings?.madhab ?? 'hanafi';

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
    return params;
  }

  /// Calculates prayer times for a specific date and position,
  /// updates the service's current prayer times state, and returns the calculated times.
  Future<adhan.PrayerTimes> calculatePrayerTimes(
    DateTime date,
    Position position,
    AppSettings? settings,
  ) async {
    final effectiveSettings = settings ?? AppSettings.defaults;
    final params = _getCalculationParams(effectiveSettings);
    final DateTime dateForCalculation = date.toUtc();

    _currentPrayerTimes = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(position.latitude, position.longitude),
      date: dateForCalculation,
      calculationParameters: params,
    );

    _lastCalculationTime = DateTime.now();
    _lastParamsUsed = params;
    _lastCalculationDate = dateForCalculation;
    _lastCalculationMethodString = effectiveSettings.calculationMethod;
    _lastAppSettingsUsed = effectiveSettings;

    _logger.debug(
      'Prayer times calculated and service state updated',
      data: {
        'date': dateForCalculation.toIso8601String(),
        'lat': position.latitude,
        'lon': position.longitude,
        'method': effectiveSettings.calculationMethod,
        'madhab': effectiveSettings.madhab,
        'fajr': _currentPrayerTimes!.fajr?.toIso8601String(),
      },
    );

    return _currentPrayerTimes!;
  }

  /// Calculates today's prayer times for the given position using provided settings.
  /// Updates the service's current prayer times state.
  Future<adhan.PrayerTimes> calculateTodayPrayerTimes(
    Position position,
    AppSettings? settings,
  ) async {
    return calculatePrayerTimes(DateTime.now(), position, settings);
  }

  /// Helper method to get the effective position, handling errors and fallback.
  Future<Position> _getEffectivePosition(String operationContext) async {
    try {
      return await _locationService.getLocation();
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
  /// This method does NOT update the service's main state (_currentPrayerTimes etc.).
  Future<adhan.PrayerTimes> calculatePrayerTimesForDate(
    DateTime date,
    AppSettings? settings,
  ) async {
    if (!_isInitialized) await init();
    final effectiveSettings = settings ?? AppSettings.defaults;
    final position = await _getEffectivePosition('prayer time calculation for date ${date.toIso8601String()}');

    final params = _getCalculationParams(effectiveSettings);
    final prayerTimes = adhan.PrayerTimes(
      date: date,
      coordinates: adhan.Coordinates(position.latitude, position.longitude),
      calculationParameters: params,
    );
    _logger.debug(
      'Prayer times calculated for date',
      data: {
        'date': date.toIso8601String(),
        'lat': position.latitude,
        'lon': position.longitude,
        'method': effectiveSettings.calculationMethod,
        'madhab': effectiveSettings.madhab,
        'fajr': prayerTimes.fajr?.toIso8601String(),
      },
    );
    return prayerTimes;
  }

  /// Gets user location based on their preference (manual or device)
  /// and calculates today's prayer times using provided settings.
  /// Updates the service's current prayer times state.
  Future<adhan.PrayerTimes> calculatePrayerTimesForToday(
    AppSettings? settings,
  ) async {
    if (!_isInitialized) await init();
    final effectiveSettings = settings ?? AppSettings.defaults;
    final position = await _getEffectivePosition('prayer time calculation for today');

    await calculatePrayerTimes(DateTime.now(), position, effectiveSettings);

    _logger.info(
      'Successfully calculated and updated prayer times for today via main pathway.',
      data: {
        'lat': position.latitude,
        'lon': position.longitude,
        'method': effectiveSettings.calculationMethod,
        'madhab': effectiveSettings.madhab,
        'fajr': _currentPrayerTimes!.fajr?.toIso8601String(),
      },
    );
    return _currentPrayerTimes!;
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

  /// Returns the most recently calculated PrayerTimes object.
  /// Throws an exception if times haven't been calculated yet.
  adhan.PrayerTimes getPrayerTimes() {
    if (_currentPrayerTimes == null) {
      _logger.warning('getPrayerTimes called before calculation, returning default/fallback.');
      throw Exception('Prayer times have not been calculated yet.');
    }
    return _currentPrayerTimes!;
  }

  /// Gets the specific time for a given prayer from the cached prayer times.
  /// Applies any user-defined offsets.
  /// [prayer] should be one of 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'.
  /// Returns null if the prayer name is invalid.
  /// Throws an exception if times haven't been calculated yet.
  DateTime? getPrayerTime(String prayer) {
    if (_currentPrayerTimes == null) {
      _logger.warning('getPrayerTime called before calculation for $prayer, returning null.');
      throw Exception('Prayer times have not been calculated yet.');
    }

    DateTime? rawTime;
    int offsetMinutes = 0;

    final AppSettings? currentSettings = _lastAppSettingsUsed;

    if (currentSettings == null) {
      _logger.warning(
        'Last AppSettings not available for applying offsets. Returning raw time for $prayer.',
      );
    }

    switch (prayer) {
      case 'fajr': // Reverted from adhan.Prayer.fajr
        rawTime = _currentPrayerTimes!.fajr;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.fajrOffset;
        }
        break;
      case 'sunrise': // Reverted from adhan.Prayer.sunrise
        rawTime = _currentPrayerTimes!.sunrise;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.sunriseOffset;
        }
        break;
      case 'dhuhr': // Reverted from adhan.Prayer.dhuhr
        rawTime = _currentPrayerTimes!.dhuhr;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.dhuhrOffset;
        }
        break;
      case 'asr': // Reverted from adhan.Prayer.asr
        rawTime = _currentPrayerTimes!.asr;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.asrOffset;
        }
        break;
      case 'maghrib': // Reverted from adhan.Prayer.maghrib
        rawTime = _currentPrayerTimes!.maghrib;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.maghribOffset;
        }
        break;
      case 'isha': // Reverted from adhan.Prayer.isha
        rawTime = _currentPrayerTimes!.isha;
        if (currentSettings != null) {
          offsetMinutes = currentSettings.ishaOffset;
        }
        break;
      default:
        _logger.warning('Invalid prayer name for getPrayerTime: $prayer');
        return null;
    }

    if (rawTime != null && offsetMinutes != 0) {
      return rawTime.add(Duration(minutes: offsetMinutes));
    }
    return rawTime;
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
          return await getNextDayFajr(_lastAppSettingsUsed!);
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

  /// Calculates the duration until the next prayer.
  /// Returns Duration.zero if the next prayer time cannot be determined or is in the past.
  Future<Duration> getTimeUntilNextPrayer() async {
    final DateTime? nextTime = await getNextPrayerTime();
    if (nextTime == null) {
      _logger.debug(
        "getTimeUntilNextPrayer: nextTime is null, returning Duration.zero.",
      );
      return Duration.zero;
    }
    final now = DateTime.now();
    if (nextTime.isBefore(now)) {
      _logger.warning(
        "getTimeUntilNextPrayer: nextTime is in the past.",
        data: {
          "nextTime": nextTime.toIso8601String(),
          "now": now.toIso8601String(),
        },
      );
      return Duration.zero;
    }
    return nextTime.difference(now);
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
      } else if (DateTime.now().difference(_lastCalculationTime!) > const Duration(hours: 1)) {
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
            'timeDiffHours': _lastCalculationTime != null ? DateTime.now().difference(_lastCalculationTime!).inHours : null,
            'madhabChanged': _lastParamsUsed?.madhab != currentSettingsParams.madhab,
            'methodChanged': _lastCalculationMethodString != currentMethodNameString,
          }
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

  Future<DateTime?> getNextDayFajr(AppSettings settings) async {
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
}
