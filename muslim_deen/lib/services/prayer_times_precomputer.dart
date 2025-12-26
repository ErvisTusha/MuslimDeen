import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/prayer_parameters_service.dart';

/// Service for precomputing prayer times for upcoming days
class PrayerTimesPrecomputer {
  final PrayerTimesCache _prayerTimesCache;
  final LocationService _locationService;
  final PrayerParametersService _parametersService;
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

  PrayerTimesPrecomputer(
    this._prayerTimesCache,
    this._locationService, {
    PrayerParametersService? parametersService,
  }) : _parametersService =
           parametersService ?? locator<PrayerParametersService>();

  /// Initialize the precomputer
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
    final params = _parametersService.getParameters(settings);

    // Calculate prayer times
    final prayerTimes = adhan.PrayerTimes(
      coordinates: coordinates,
      date: date.toUtc(),
      calculationParameters: params,
    );

    // Create model for caching
    final prayerTimesModel = PrayerTimesModel.fromAdhanPrayerTimes(
      prayerTimes,
      date,
    );

    // Cache the result
    await _prayerTimesCache.cachePrayerTimes(
      prayerTimesModel,
      coordinates,
      calculationMethod: settings.calculationMethod,
      madhab: settings.madhab,
    );
  }

  // No longer needed, logic moved to PrayerParametersService

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
