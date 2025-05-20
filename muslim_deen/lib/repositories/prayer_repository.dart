import 'package:adhan_dart/adhan_dart.dart';

import '../extensions/location_service_extension.dart';
import '../extensions/prayer_service_extension.dart';
import '../models/prayer_times_model.dart';
import '../services/error_handler_service.dart';
import '../services/location_service.dart';
import '../services/prayer_service.dart';
import '../services/prayer_times_cache.dart';

/// Repository for prayer times implementing the repository pattern
class PrayerRepository {
  final PrayerService _prayerService;
  final ErrorHandlerService _errorHandler;
  final PrayerTimesCache _cache;
  final LocationService _locationService;

  PrayerRepository(
    this._prayerService,
    this._errorHandler,
    this._cache,
    this._locationService,
  ) {
    // Prefetch prayer times for the next week in the background
    _prefetchPrayerTimes();
  }

  /// Gets prayer times for the current location and date
  Future<Result<PrayerTimesModel>> getPrayerTimes(DateTime date) async {
    return _errorHandler.guard(() async {
      // Get current coordinates
      final coordinates = await _locationService.getCurrentCoordinates();

      // Try to get cached prayer times first
      final cachedPrayerTimes = await _cache.getCachedPrayerTimes(
        date,
        coordinates,
      );

      if (cachedPrayerTimes != null) {
        return cachedPrayerTimes;
      }

      // If not in cache, calculate prayer times
      final prayerTimes = await _prayerService.getPrayerTimesForDate(date, null); // Pass null for AppSettings
      final prayerTimesModel = PrayerTimesModel.fromAdhanPrayerTimes(
        prayerTimes,
        date,
      );

      // Cache the results for future use
      await _cache.cachePrayerTimes(prayerTimesModel, coordinates);

      return prayerTimesModel;
    });
  }

  /// Gets prayer times for a specific location and date
  Future<Result<PrayerTimesModel>> getPrayerTimesForLocation({
    required Coordinates coordinates,
    required CalculationParameters parameters,
    required DateTime date,
  }) async {
    return _errorHandler.guard(() async {
      final prayerTimes = await _prayerService.getPrayerTimesForLocation(
        coordinates,
        date,
        parameters,
      );
      return PrayerTimesModel.fromAdhanPrayerTimes(prayerTimes, date);
    });
  }

  /// Gets the next prayer time from the current time
  Future<Result<PrayerInfo>> getNextPrayer() async {
    return _errorHandler.guard(() async {
      final now = DateTime.now();
      final prayerTimes = await _prayerService.getPrayerTimesForDate(now, null); // Pass null for AppSettings

      final prayers = [
        PrayerInfo(name: 'Fajr', time: prayerTimes.fajr ?? now),
        PrayerInfo(name: 'Sunrise', time: prayerTimes.sunrise ?? now),
        PrayerInfo(name: 'Dhuhr', time: prayerTimes.dhuhr ?? now),
        PrayerInfo(name: 'Asr', time: prayerTimes.asr ?? now),
        PrayerInfo(name: 'Maghrib', time: prayerTimes.maghrib ?? now),
        PrayerInfo(name: 'Isha', time: prayerTimes.isha ?? now),
      ];

      // Find next prayer
      for (final prayer in prayers) {
        if (prayer.time.isAfter(now)) {
          return prayer;
        }
      }

      // If no prayer is after current time, get first prayer of next day
      final tomorrowPrayerTimes = await _prayerService.getPrayerTimesForDate(
        DateTime.now().add(const Duration(days: 1)),
        null, // Pass null for AppSettings
      );

      return PrayerInfo(
        name: 'Fajr',
        time: tomorrowPrayerTimes.fajr ?? now.add(const Duration(days: 1)),
      );
    });
  }

  /// Prefetch prayer times for the next several days to improve performance
  Future<void> _prefetchPrayerTimes() async {
    try {
      final coordinates = await _locationService.getCurrentCoordinates();

      await _cache.prefetchPrayerTimes(
        (date) async {
          final prayerTimes = await _prayerService.getPrayerTimesForDate(date, null); // Pass null for AppSettings
          return PrayerTimesModel.fromAdhanPrayerTimes(prayerTimes, date);
        },
        coordinates,
        daysToFetch: 7, // Prefetch a week of prayer times
      );
    } catch (e, stackTrace) {
      // Log the error but don't crash - we'll fetch on-demand when needed
      _errorHandler.reportError(
        AppError(
          message: "Failed to prefetch prayer times",
          originalException: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}

/// Simple model for prayer information
class PrayerInfo {
  final String name;
  final DateTime time;

  PrayerInfo({required this.name, required this.time});
}
