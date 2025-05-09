import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/services/location_service.dart';
import '../models/app_settings.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';

class PrayerService {
  final LocationService _locationService;
  adhan.PrayerTimes? _currentPrayerTimes;
  DateTime? _lastCalculationTime;
  adhan.CalculationParameters? _lastParamsUsed;
  DateTime? _lastCalculationDate;
  bool _isInitialized = false;
  final LoggerService _logger = locator<LoggerService>();
  String? _lastCalculationMethodString;

  PrayerService(this._locationService);

  Future<void> init() async {
    if (_isInitialized) return;
    await _locationService.init();
    _isInitialized = true;
    _logger.info('PrayerService initialized');
  }

  /// Gets default calculation parameters (MuslimWorldLeague, Hanafi).
  adhan.CalculationParameters getDefaultParams() {
    final params = adhan.CalculationMethod.muslimWorldLeague();
    params.madhab =
        adhan.Madhab.hanafi; // Changed to hanafi to match AppSettings default
    params.highLatitudeRule = adhan.HighLatitudeRule.twilightAngle;
    return params;
  }

  /// Creates CalculationParameters based on the provided settings.
  /// Falls back to defaults if settings are null or invalid.
  adhan.CalculationParameters _getCalculationParams(AppSettings? settings) {
    adhan.CalculationParameters params;
    final calculationMethod =
        settings?.calculationMethod ?? 'MuslimWorldLeague';
    final madhab = settings?.madhab ?? 'hanafi'; // String type

    switch (calculationMethod) {
      case 'MuslimWorldLeague':
        params = adhan.CalculationMethod.muslimWorldLeague();
        break;
      case 'NorthAmerica':
        params = adhan.CalculationMethod.northAmerica();
        break;
      case 'Egyptian':
        params = adhan.CalculationMethod.egyptian();
        break;
      case 'UmmAlQura':
        params = adhan.CalculationMethod.ummAlQura();
        break;
      case 'Karachi':
        params = adhan.CalculationMethod.karachi();
        break;
      case 'Tehran':
        params = adhan.CalculationMethod.tehran();
        break;
      case 'Dubai':
        params = adhan.CalculationMethod.dubai();
        break;
      case 'MoonsightingCommittee':
        params = adhan.CalculationMethod.moonsightingCommittee();
        break;
      case 'Kuwait':
        params = adhan.CalculationMethod.kuwait();
        break;
      case 'Qatar':
        params = adhan.CalculationMethod.qatar();
        break;
      case 'Singapore':
        params = adhan.CalculationMethod.singapore();
        break;
      case 'Turkey':
        _logger.warning(
          "Warning: 'Turkey' calculation method selected, but not directly supported by adhan_dart. Falling back to MuslimWorldLeague.",
        );
        params = adhan.CalculationMethod.muslimWorldLeague();
        break;
      default:
        _logger.warning(
          "Unsupported calculation method '$calculationMethod', using MuslimWorldLeague.",
        );
        params = adhan.CalculationMethod.muslimWorldLeague();
    }

    // Fix madhab comparison by using string comparison correctly
    params.madhab =
        (madhab.toLowerCase() == 'hanafi')
            ? adhan.Madhab.hanafi
            : adhan.Madhab.shafi;
    params.highLatitudeRule = adhan.HighLatitudeRule.twilightAngle;
    return params;
  }

  /// Calculates prayer times for a specific date and position using provided settings.
  Future<adhan.PrayerTimes> calculatePrayerTimes(
    DateTime date,
    Position position,
    AppSettings? settings,
  ) async {
    _lastCalculationDate = date;

    // Calculate fresh times
    _currentPrayerTimes = adhan.PrayerTimes(
      coordinates: adhan.Coordinates(position.latitude, position.longitude),
      date: date.toUtc(),
      calculationParameters: _getCalculationParams(settings),
    );

    return _currentPrayerTimes!;
  }

  /// Calculates today's prayer times for the given position using provided settings.
  Future<adhan.PrayerTimes> calculateTodayPrayerTimes(
    Position position,
    AppSettings? settings,
  ) async {
    return calculatePrayerTimes(DateTime.now(), position, settings);
  }

  /// Gets user location based on their preference (manual or device)
  /// and calculates prayer times for the given date using provided settings.
  Future<adhan.PrayerTimes> calculatePrayerTimesForDate(
    DateTime date,
    AppSettings? settings,
  ) async {
    if (!_isInitialized) await init();
    Position position;
    final effectiveSettings = settings ?? AppSettings.defaults;

    try {
      position = await _locationService.getLocation();
    } catch (e) {
      _logger.error(
        'Error getting location for PrayerTimes (date)',
        error: e,
        data: {'date': date.toIso8601String()},
      );
      position = _getFallbackPosition();
    }

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
  Future<adhan.PrayerTimes> calculatePrayerTimesForToday(
    AppSettings? settings,
  ) async {
    if (!_isInitialized) await init();
    Position position;
    final effectiveSettings = settings ?? AppSettings.defaults;

    try {
      position = await _locationService.getLocation();
    } catch (e) {
      _logger.error('Error getting location for PrayerTimes (today)', error: e);
      position = _getFallbackPosition();
    }

    final params = _getCalculationParams(effectiveSettings);
    _currentPrayerTimes = adhan.PrayerTimes(
      date: DateTime.now(),
      coordinates: adhan.Coordinates(position.latitude, position.longitude),
      calculationParameters: params,
    );
    _lastCalculationTime = DateTime.now();
    _lastParamsUsed = params;
    _lastCalculationMethodString = effectiveSettings.calculationMethod;
    _lastCalculationDate = DateTime.now();
    _logger.debug(
      'Prayer times calculated for today',
      data: {
        'lat': position.latitude,
        'lon': position.longitude,
        'method': effectiveSettings.calculationMethod,
        'madhab': effectiveSettings.madhab,
        'fajr': _currentPrayerTimes?.fajr?.toIso8601String(),
      },
    );
    return _currentPrayerTimes!;
  }

  /// Provides a fallback position when location services fail
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
      throw Exception('Prayer times have not been calculated yet.');
    }
    return _currentPrayerTimes!;
  }

  /// Gets the specific time for a given prayer from the cached prayer times.
  /// [prayer] should be one of 'fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'.
  /// Returns null if the prayer name is invalid.
  /// Throws an exception if times haven't been calculated yet.
  DateTime? getPrayerTime(String prayer) {
    if (_currentPrayerTimes == null) {
      throw Exception('Prayer times have not been calculated yet.');
    }

    // Use string literals for case statements to avoid potential const issues
    switch (prayer) {
      case 'fajr':
        return _currentPrayerTimes!.fajr;
      case 'sunrise':
        return _currentPrayerTimes!.sunrise;
      case 'dhuhr':
        return _currentPrayerTimes!.dhuhr;
      case 'asr':
        return _currentPrayerTimes!.asr;
      case 'maghrib':
        return _currentPrayerTimes!.maghrib;
      case 'isha':
        return _currentPrayerTimes!.isha;
      default:
        return null;
    }
  }

  /// Determines the current prayer based on the current time and cached prayer times.
  /// Returns the standardized prayer name ('fajr', 'dhuhr', etc.) or 'none'.
  /// Throws an exception if times haven't been calculated yet.
  String getCurrentPrayer() {
    if (_currentPrayerTimes == null) {
      _logger.warning('Attempted to get current prayer before calculation.');
      return adhan.Prayer.none;
    }
    return _currentPrayerTimes!.currentPrayer(date: DateTime.now());
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
    return _currentPrayerTimes!.nextPrayer(date: DateTime.now());
  }

  /// Calculates the time of the next prayer.
  /// Returns the DateTime of the next prayer, or null if calculation fails.
  /// Throws an exception if initial calculation hasn't happened.
  DateTime? getNextPrayerTime() {
    if (_currentPrayerTimes == null) {
      _logger.warning('Attempted to get next prayer time before calculation.');
      return null;
    }
    final nextPrayerName = getNextPrayer();
    if (nextPrayerName == adhan.Prayer.none &&
        getCurrentPrayer() == adhan.Prayer.isha) {
      _logger.debug(
        "Current prayer is Isha, next prayer is Fajr tomorrow (not handled by currentPrayerTimes.timeForPrayer(none)).",
      );
      return null;
    }
    return _currentPrayerTimes!.timeForPrayer(nextPrayerName);
  }

  Duration getTimeUntilNextPrayer() {
    final nextTime = getNextPrayerTime();
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
    String currentMethodNameString = settings.calculationMethod;

    bool needsRecalculation =
        _currentPrayerTimes == null ||
        _lastCalculationTime == null ||
        DateTime.now().difference(_lastCalculationTime!) >
            const Duration(hours: 1) ||
        _lastParamsUsed?.madhab != currentSettingsParams.madhab ||
        _lastCalculationMethodString != currentMethodNameString ||
        _lastCalculationDate?.day != DateTime.now().day;

    if (needsRecalculation) {
      _logger.info(
        'Recalculating prayer times due to settings/time change',
        data: {
          'reason':
              _currentPrayerTimes == null
                  ? 'initial_calc'
                  : _lastCalculationTime == null
                  ? 'no_last_calc_time'
                  : DateTime.now().difference(_lastCalculationTime!).inMinutes >
                      60
                  ? 'time_elapsed'
                  : _lastParamsUsed?.madhab != currentSettingsParams.madhab
                  ? 'madhab_changed'
                  : _lastCalculationMethodString != currentMethodNameString
                  ? 'method_name_changed'
                  : _lastCalculationDate?.day != DateTime.now().day
                  ? 'date_changed'
                  : 'unknown',
        },
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
    Position position;
    try {
      position = await _locationService.getLocation();
    } catch (e) {
      _logger.error('Error getting location for next day Fajr', error: e);
      position = _getFallbackPosition();
    }
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
