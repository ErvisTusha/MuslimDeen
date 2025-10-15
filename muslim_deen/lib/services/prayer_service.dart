import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';

import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/models/app_settings.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/prayer_times_precomputer.dart';
import 'package:muslim_deen/services/cache_metrics_service.dart';
import 'package:muslim_deen/services/country_calculation_service.dart';

/// Service responsible for calculating and providing prayer times.
///
/// It handles different calculation methods, madhabs, and user-specific offsets.
/// It also caches the latest calculated prayer times and provides information
/// about the current and next prayer.
class PrayerService {
  final LocationService _locationService;
  final PrayerTimesCache _prayerTimesCache;
  PrayerTimesPrecomputer? _precomputer;
  CacheMetricsService? _metricsService;

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
  static const Duration _positionCacheDuration = Duration(
    minutes: AppConstants.positionCacheDurationMinutes,
  );

  // Enhanced cache management
  Timer? _cacheRefreshTimer;
  final Map<String, DateTime> _cacheInvalidationTimes = {};
  static const Duration _cacheRefreshInterval = Duration(hours: 12);
  static const Duration _cacheValidityDuration = Duration(hours: 24);

  PrayerService(this._locationService, this._prayerTimesCache);

  Future<void> init() async {
    if (_isInitialized) return;
    await _locationService.init();

    // Initialize precomputer
    _precomputer = PrayerTimesPrecomputer(_prayerTimesCache, _locationService);
    await _precomputer!.init();

    // Start cache refresh timer
    _startCacheRefreshTimer();

    _isInitialized = true;
    _logger.info('PrayerService initialized with enhanced caching');
  }

  /// Set metrics service for performance tracking
  void setMetricsService(CacheMetricsService metricsService) {
    _metricsService = metricsService;
    _logger.debug('Cache metrics service attached to PrayerService');
  }

  /// Start periodic cache refresh timer
  void _startCacheRefreshTimer() {
    _cacheRefreshTimer?.cancel();
    _cacheRefreshTimer = Timer.periodic(_cacheRefreshInterval, (_) {
      _refreshCacheIfNeeded();
    });
  }

  /// Refresh cache if needed based on invalidation times
  Future<void> _refreshCacheIfNeeded() async {
    try {
      final now = DateTime.now();
      final keysToRefresh = <String>[];

      for (final entry in _cacheInvalidationTimes.entries) {
        if (now.difference(entry.value) > _cacheValidityDuration) {
          keysToRefresh.add(entry.key);
        }
      }

      if (keysToRefresh.isNotEmpty) {
        _logger.info(
          'Refreshing expired cache entries',
          data: {'count': keysToRefresh.length},
        );

        for (final key in keysToRefresh) {
          await _refreshCacheEntry(key);
          _cacheInvalidationTimes.remove(key);
        }
      }
    } catch (e, s) {
      _logger.error('Error refreshing cache', error: e, stackTrace: s);
    }
  }

  /// Refresh a specific cache entry
  Future<void> _refreshCacheEntry(String cacheKey) async {
    try {
      // Parse cache key to extract date, location, and settings
      final parts = cacheKey.split('_');
      if (parts.length < 6) return;

      final dateStr = '${parts[1]}-${parts[2]}-${parts[3]}';
      final date = DateTime.parse(dateStr);
      final method = parts.length > 6 ? parts[6] : 'MuslimWorldLeague';
      final madhab = parts.length > 7 ? parts[7] : 'hanafi';

      final settings = AppSettings(calculationMethod: method, madhab: madhab);

      // Recalculate and cache prayer times
      await calculatePrayerTimesForDate(date, settings);

      _logger.debug('Cache entry refreshed', data: {'key': cacheKey});
    } catch (e, s) {
      _logger.error(
        'Error refreshing cache entry',
        error: e,
        stackTrace: s,
        data: {'key': cacheKey},
      );
    }
  }

  /// Generate optimized cache key with better hit rate
  String _generateOptimizedCacheKey(
    DateTime date,
    adhan.Coordinates coordinates, {
    String? calculationMethod,
    String? madhab,
  }) {
    // Use consistent rounding for coordinates to improve hit rates
    final lat = coordinates.latitude.toStringAsFixed(3);
    final lng = coordinates.longitude.toStringAsFixed(3);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final method = calculationMethod ?? 'MuslimWorldLeague';
    final m = madhab ?? 'hanafi';

    return 'prayer_times_${dateStr}_$lat\_$lng\_$method\_$m';
  }

  /// Creates CalculationParameters based on the provided settings with caching.
  /// Falls back to defaults if settings are null or invalid.
  /// Automatically detects country-specific calculation method if not specified.
  Future<adhan.CalculationParameters> _getCalculationParams(
    AppSettings? settings, {
    Position? position,
  }) async {
    String calculationMethod;

    if (settings?.calculationMethod == 'Auto' ||
        settings?.calculationMethod == null) {
      // Auto-detect calculation method based on location
      calculationMethod = 'MuslimWorldLeague'; // default
      if (position != null) {
        try {
          calculationMethod =
              await CountryCalculationService.getCalculationMethodForCoordinates(
                position.latitude,
                position.longitude,
              );
          _logger.info(
            'Auto-detected calculation method',
            data: {'method': calculationMethod},
          );
        } catch (e) {
          _logger.warning(
            'Failed to auto-detect calculation method, using default',
            error: e,
          );
        }
      }
    } else {
      calculationMethod = settings!.calculationMethod;
    }

    final madhab = settings?.madhab ?? 'hanafi';
    final cacheKey = '$calculationMethod-$madhab';

    // Return cached parameters if available
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

    // Cache the parameters for future use
    _paramCache[cacheKey] = params;

    return params;
  }

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

    // Update service state
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

    final cacheKey = _generateOptimizedCacheKey(
      date,
      coordinates,
      calculationMethod: effectiveSettings.calculationMethod,
      madhab: effectiveSettings.madhab,
    );

    await _prayerTimesCache.cachePrayerTimes(
      newAdhanPrayerTimes,
      coordinates,
      calculationMethod: effectiveSettings.calculationMethod,
      madhab: effectiveSettings.madhab,
    );

    // Track cache invalidation time
    _cacheInvalidationTimes[cacheKey] = DateTime.now();

    _metricsService?.recordHit(cacheKey, 'prayer_times');
    _logger.info(
      'Prayer times for $date cached with optimized key.',
      data: {'cacheKey': cacheKey},
    );

    return newAdhanPrayerTimes;
  }

  /// Helper method to get the effective position with caching, handling errors and fallback.
  Future<Position> _getEffectivePosition(String operationContext) async {
    // Check if cached position is still valid
    if (_cachedPosition != null &&
        _positionCacheTime != null &&
        DateTime.now().difference(_positionCacheTime!) <
            _positionCacheDuration) {
      return _cachedPosition!;
    }

    try {
      final position = await _locationService.getLocation();

      // Cache the position
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

    // Performance optimization: Check if we can reuse current calculation
    if (_canReuseCurrentCalculation(date, effectiveSettings, coordinates)) {
      _logger.debug('Reusing current prayer time calculation');
      return _currentPrayerTimes!;
    }

    // Check cache first with optimized key
    final cacheKey = _generateOptimizedCacheKey(
      date,
      coordinates,
      calculationMethod: effectiveSettings.calculationMethod,
      madhab: effectiveSettings.madhab,
    );

    final cachedTimes = await _prayerTimesCache.getCachedPrayerTimes(
      date,
      coordinates,
      calculationMethod: effectiveSettings.calculationMethod,
      madhab: effectiveSettings.madhab,
    );

    if (cachedTimes != null) {
      // Use cached prayer times - reconstruct adhan.PrayerTimes
      final currentParams = await _getCalculationParams(
        effectiveSettings,
        position: position,
      );
      final adhanPrayerTimes = adhan.PrayerTimes(
        coordinates: coordinates,
        date: date.toUtc(),
        calculationParameters: currentParams,
      );

      // Update service state from cache
      _currentPrayerTimes = adhanPrayerTimes;
      _lastCalculationTime = DateTime.now();
      _lastParamsUsed = currentParams;
      _lastCalculationDate = date.toUtc();
      _lastCalculationMethodString = effectiveSettings.calculationMethod;
      _lastAppSettingsUsed = effectiveSettings;

      // Update cache invalidation time for LRU
      _cacheInvalidationTimes[cacheKey] = DateTime.now();

      _metricsService?.recordHit(cacheKey, 'prayer_times');
      _logger.debug('Prayer times loaded from cache with optimized key');
      return adhanPrayerTimes;
    }

    _metricsService?.recordMiss(cacheKey, 'prayer_times');

    // Calculate new prayer times
    final currentParams = await _getCalculationParams(
      effectiveSettings,
      position: position,
    );
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

    final isSameSettings =
        _lastCalculationMethodString == settings.calculationMethod &&
        _lastParamsUsed?.madhab.toString() == settings.madhab;

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
    // This method now correctly calls the updated calculatePrayerTimesForDate
    return calculatePrayerTimesForDate(DateTime.now(), settings);
    // The logging and state update for _currentPrayerTimes will be handled within calculatePrayerTimesForDate
    // or _calculateAndPersistPrayerTimes. We can add a specific log here if needed.
    // _logger.info(
    //   'Successfully calculated and updated prayer times for today via main pathway.',
    //   data: {
    //     'lat': _currentPrayerTimes?.coordinates.latitude, // Assuming _currentPrayerTimes is updated
    //     'lon': _currentPrayerTimes?.coordinates.longitude,
    //     'method': settings?.calculationMethod ?? AppSettings.defaults.calculationMethod,
    //     'madhab': settings?.madhab ?? AppSettings.defaults.madhab,
    //     'fajr': _currentPrayerTimes!.fajr?.toIso8601String(),
    //   },
    // );
    // return _currentPrayerTimes!; // This will be returned by calculatePrayerTimesForDate
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
    final position = await _getEffectivePosition('prayer time recalculation');

    final currentSettingsParams = await _getCalculationParams(
      settings,
      position: position,
    );
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
      final params = await _getCalculationParams(settings, position: position);
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

  // Within the PrayerService class
  Future<DateTime?> getOffsettedPrayerTime(
    String prayerName,
    adhan.PrayerTimes rawPrayerTimes,
    AppSettings settings, {
    Position? currentPosition,
  }) async {
    DateTime? rawTime;
    int offsetMinutes = 0;

    switch (prayerName.toLowerCase()) {
      case 'fajr':
        rawTime = rawPrayerTimes.fajr;
        offsetMinutes = settings.fajrOffset;
        break;
      case 'sunrise': // Sunrise typically isn't offset for notifications, but include for completeness if needed elsewhere
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
        // Optionally log a warning or return null for unknown prayer names
        _logger.warning(
          'getOffsettedPrayerTime called with unknown prayer name: $prayerName',
        );
        return null;
    }

    if (rawTime == null) {
      return null;
    }

    // No country-specific adjustments applied
    // Using standard MWL calculation for all countries

    return rawTime.add(Duration(minutes: offsetMinutes));
  }

  /// Precompute prayer times for upcoming days
  Future<void> precomputeUpcomingPrayerTimes() async {
    if (_precomputer != null) {
      await _precomputer!.forcePrecompute();
    }
  }

  /// Check if precompute is needed
  bool isPrecomputeNeeded() {
    return _precomputer?.isPrecomputeNeeded() ?? false;
  }

  /// Get precompute status
  Map<String, dynamic> getPrecomputeStatus() {
    return _precomputer?.getPrecomputeStatus() ?? {'status': 'not_initialized'};
  }

  /// Get prayer time with user-specific offsets only (sync version for widgets)
  /// This version doesn't apply Albania adjustments to maintain compatibility with sync contexts
  DateTime? getOffsettedPrayerTimeSync(
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
          'getOffsettedPrayerTimeSync called with unknown prayer name: $prayerName',
        );
        return null;
    }

    if (rawTime == null) {
      return null;
    }

    return rawTime.add(Duration(minutes: offsetMinutes));
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cacheEntries': _cacheInvalidationTimes.length,
      'parameterCacheSize': _paramCache.length,
      'positionCacheValid':
          _cachedPosition != null &&
          _positionCacheTime != null &&
          DateTime.now().difference(_positionCacheTime!) <
              _positionCacheDuration,
      'precomputeStatus': getPrecomputeStatus(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _cacheRefreshTimer?.cancel();
    _precomputer?.dispose();
    _logger.info('PrayerService disposed');
  }
}
