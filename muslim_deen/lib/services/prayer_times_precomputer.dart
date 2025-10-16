import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/location_service.dart';

/// Background service for precomputing prayer times to enhance user experience.
///
/// This service runs in the background to calculate and cache prayer times for
/// upcoming days, ensuring instant availability when users navigate to different
/// dates. It implements intelligent scheduling and error handling to minimize
/// impact on app performance and battery life.
///
/// ## Key Features
/// - Automatic background precomputation of upcoming prayer times
/// - Configurable precomputation window (7 days by default)
/// - Intelligent scheduling to avoid interfering with app usage
/// - Robust error handling with graceful degradation
/// - Status tracking and monitoring capabilities
///
/// ## Performance Strategy
/// - Runs 30 seconds after app startup to avoid blocking initialization
/// - Refreshes every 6 hours to keep data fresh
/// - Prevents concurrent precomputation to avoid resource conflicts
/// - Uses efficient batch processing for multiple days
///
/// ## Dependencies
/// - [PrayerTimesCache]: Stores precomputed prayer times
/// - [LocationService]: Provides current location for calculations
/// - [LoggerService]: Logs precomputation activities and errors
///
/// ## Background Execution
/// The service uses Timer-based scheduling rather than platform-specific
/// background tasks to ensure compatibility across all supported platforms
/// while maintaining simplicity and reliability.
class PrayerTimesPrecomputer {
  final PrayerTimesCache _prayerTimesCache;
  final LocationService _locationService;
  final LoggerService _logger = locator<LoggerService>();

  // Precomputation settings
  static const int _daysToPrecompute = 7; // Precompute for next 7 days
  static const Duration _precomputeInterval = Duration(
    hours: 6,
  ); // Refresh every 6 hours
  static const Duration _backgroundTaskDelay = Duration(
    seconds: 30,
  ); // Delay after app start

  Timer? _precomputeTimer;
  Timer? _backgroundTaskTimer;
  bool _isPrecomputing = false;
  DateTime? _lastPrecomputeTime;

  PrayerTimesPrecomputer(this._prayerTimesCache, this._locationService);

  /// Initializes the precomputer service and schedules background tasks.
  ///
  /// This method sets up two timer-based operations:
  /// 1. Initial background precompute after 30 seconds
  /// 2. Periodic precompute every 6 hours
  ///
  /// The delayed initial task ensures the app can start quickly without
  /// being blocked by prayer time calculations.
  ///
  /// Error Handling: Catches and logs initialization errors but doesn't
  /// prevent the app from starting
  ///
  /// Thread Safety: This method is safe to call multiple times
  Future<void> init() async {
    try {
      // Schedule initial background precompute
      _backgroundTaskTimer = Timer(
        _backgroundTaskDelay,
        _performBackgroundPrecompute,
      );

      // Start periodic precompute
      _startPeriodicPrecompute();

      _logger.info('PrayerTimesPrecomputer initialized');
    } catch (e, s) {
      _logger.error(
        'Error initializing PrayerTimesPrecomputer',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Start periodic precompute timer
  void _startPeriodicPrecompute() {
    _precomputeTimer?.cancel();
    _precomputeTimer = Timer.periodic(_precomputeInterval, (_) {
      _performBackgroundPrecompute();
    });
  }

  /// Perform background precompute of prayer times
  Future<void> _performBackgroundPrecompute() async {
    if (_isPrecomputing) {
      _logger.debug('Precompute already in progress, skipping');
      return;
    }

    _isPrecomputing = true;
    _logger.info('Starting background precompute of prayer times');

    try {
      // Get current position
      final position = await _locationService.getLocation();
      final coordinates = adhan.Coordinates(
        position.latitude,
        position.longitude,
      );

      // Get current settings (use defaults if not available)
      final settings = AppSettings.defaults;

      // Precompute prayer times for upcoming days
      await _precomputePrayerTimes(coordinates, settings);

      _lastPrecomputeTime = DateTime.now();
      _logger.info('Background precompute completed successfully');
    } catch (e, s) {
      _logger.error(
        'Error during background precompute',
        error: e,
        stackTrace: s,
      );
    } finally {
      _isPrecomputing = false;
    }
  }

  /// Precompute prayer times for upcoming days
  Future<void> _precomputePrayerTimes(
    adhan.Coordinates coordinates,
    AppSettings settings,
  ) async {
    final now = DateTime.now();
    int successCount = 0;
    int errorCount = 0;

    for (int i = 0; i < _daysToPrecompute; i++) {
      try {
        final targetDate = now.add(Duration(days: i));
        await _computeAndCachePrayerTimes(targetDate, coordinates, settings);
        successCount++;

        _logger.debug(
          'Precomputed prayer times',
          data: {'date': targetDate.toIso8601String(), 'dayOffset': i},
        );
      } catch (e, s) {
        errorCount++;
        _logger.error(
          'Error precomputing prayer times for day $i',
          error: e,
          stackTrace: s,
          data: {'dayOffset': i},
        );
      }
    }

    _logger.info(
      'Prayer times precompute summary',
      data: {
        'totalDays': _daysToPrecompute,
        'successCount': successCount,
        'errorCount': errorCount,
      },
    );
  }

  /// Compute and cache prayer times for a specific date
  Future<void> _computeAndCachePrayerTimes(
    DateTime date,
    adhan.Coordinates coordinates,
    AppSettings settings,
  ) async {
    // Get calculation parameters
    final params = _getCalculationParams(settings);

    // Calculate prayer times
    final prayerTimes = adhan.PrayerTimes(
      coordinates: coordinates,
      date: date.toUtc(),
      calculationParameters: params,
    );

    // Cache the result
    await _prayerTimesCache.cachePrayerTimes(
      prayerTimes,
      coordinates,
      calculationMethod: settings.calculationMethod,
      madhab: settings.madhab,
    );
  }

  /// Get calculation parameters based on settings
  adhan.CalculationParameters _getCalculationParams(AppSettings settings) {
    final calculationMethod = settings.calculationMethod;
    final madhab = settings.madhab;

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
      default:
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

  /// Force immediate precompute
  Future<void> forcePrecompute() async {
    await _performBackgroundPrecompute();
  }

  /// Check if precompute is needed
  bool isPrecomputeNeeded() {
    if (_lastPrecomputeTime == null) return true;

    final timeSinceLastPrecompute = DateTime.now().difference(
      _lastPrecomputeTime!,
    );
    return timeSinceLastPrecompute > _precomputeInterval;
  }

  /// Get precompute status
  Map<String, dynamic> getPrecomputeStatus() {
    return {
      'isPrecomputing': _isPrecomputing,
      'lastPrecomputeTime': _lastPrecomputeTime?.toIso8601String(),
      'daysToPrecompute': _daysToPrecompute,
      'precomputeIntervalMinutes': _precomputeInterval.inMinutes,
      'isPrecomputeNeeded': isPrecomputeNeeded(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _precomputeTimer?.cancel();
    _backgroundTaskTimer?.cancel();
    _logger.info('PrayerTimesPrecomputer disposed');
  }
}
