import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/storage_service.dart';

final GetIt locator = GetIt.instance;

// Cache SharedPreferences instance to avoid multiple async calls
SharedPreferences? _sharedPrefsCache;

/// Initializes the service locator with optimized loading
Future<void> setupLocator({bool testing = false}) async {
  // Pre-load SharedPreferences for better performance
  _sharedPrefsCache ??= await SharedPreferences.getInstance();

  _registerServices(testing);

  await _initializeCriticalServices();

  // Use batched initialization for better performance
  await _initializeHighPriorityServicesBatch(testing);

  _scheduleRemainingServiceInitialization();
}

/// Registers all services with the locator using optimized patterns
void _registerServices(bool testing) {
  // Register synchronous services first
  locator.registerLazySingleton<LoggerService>(LoggerService.new);
  locator.registerLazySingleton<StorageService>(StorageService.new);
  locator.registerLazySingleton<LocationService>(LocationService.new);
  locator.registerLazySingleton<ErrorHandlerService>(ErrorHandlerService.new);

  if (!testing) {
    locator.registerLazySingleton<NotificationService>(NotificationService.new);
  }

  // Register async services with optimized dependency resolution
  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = _sharedPrefsCache ?? await SharedPreferences.getInstance();
    return CacheService(prefs);
  });

  /// PrayerTimesCache requires async CacheService dependency
  locator.registerLazySingletonAsync<PrayerTimesCache>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    final loggerService = locator<LoggerService>();
    return PrayerTimesCache(cacheService, loggerService);
  });

  /// PrayerService depends on LocationService and async PrayerTimesCache
  locator.registerLazySingletonAsync<PrayerService>(() async {
    final locationService = locator<LocationService>();
    final prayerTimesCache = await locator.getAsync<PrayerTimesCache>();
    return PrayerService(locationService, prayerTimesCache);
  });

  locator.registerLazySingletonAsync<CompassService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return CompassService(cacheService: cacheService);
  });

  locator.registerLazySingletonAsync<MapService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return MapService(cacheService: cacheService);
  });
}

/// Initialize critical services required for app to start
Future<void> _initializeCriticalServices() async {
  final stopwatch = Stopwatch()..start();

  await locator<StorageService>().init();

  stopwatch.stop();
  locator<LoggerService>().info(
    'Critical services initialized in ${stopwatch.elapsedMilliseconds}ms',
  );
}

/// Initialize high priority services in optimized batches
Future<void> _initializeHighPriorityServicesBatch(bool testing) async {
  final stopwatch = Stopwatch()..start();

  // Initialize services in dependency order with batching
  await locator.isReady<CacheService>();

  // Batch services that depend on CacheService
  await Future.wait([
    locator.isReady<PrayerTimesCache>(),
    locator.isReady<CompassService>(),
    locator.isReady<MapService>(),
  ]);

  // Services that depend on PrayerTimesCache
  await locator.isReady<PrayerService>();

  // Initialize platform services
  final initFutures = <Future<void>>[];

  if (!testing) {
    initFutures.add(locator<NotificationService>().init());
  }
  initFutures.add(locator<LocationService>().init());

  if (initFutures.isNotEmpty) {
    await Future.wait(initFutures);
  }

  stopwatch.stop();
  locator<LoggerService>().info(
    'High priority services initialized in ${stopwatch.elapsedMilliseconds}ms',
  );
}

/// Schedule remaining service initialization with error handling
void _scheduleRemainingServiceInitialization() {
  Future.microtask(() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Any additional background initialization can go here

      stopwatch.stop();
      locator<LoggerService>().info(
        'Background services initialized in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      locator<LoggerService>().error(
        'Error initializing background services',
        error: e,
        stackTrace: stackTrace,
      );
    }
  });
}
