import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Initializes the service locator with optimized loading
Future<void> setupLocator({bool testing = false}) async {
  _registerServices(testing);

  await _initializeCriticalServices();
  await _initializeHighPriorityServices(testing);

  _scheduleRemainingServiceInitialization();
}

/// Registers all services with the locator
void _registerServices(bool testing) {
  final sharedPrefsInstance = SharedPreferences.getInstance();

  locator.registerLazySingleton<LoggerService>(LoggerService.new);

  locator.registerLazySingleton<StorageService>(StorageService.new);

  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = await sharedPrefsInstance;
    return CacheService(prefs);
  });

  locator.registerLazySingleton<LocationService>(LocationService.new);

  if (!testing) {
    locator.registerLazySingleton<NotificationService>(NotificationService.new);
  }

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

  locator.registerLazySingleton<ErrorHandlerService>(ErrorHandlerService.new);
}

/// Initialize critical services required for app to start
Future<void> _initializeCriticalServices() async {
  await locator<StorageService>().init();
  locator<LoggerService>().info('Critical services initialized');
}

/// Initialize high priority services needed early in app lifecycle
Future<void> _initializeHighPriorityServices(bool testing) async {
  await locator.isReady<CacheService>();
  await locator.isReady<PrayerTimesCache>();
  await locator.isReady<CompassService>();
  await locator.isReady<MapService>();
  await locator.isReady<PrayerService>();

  if (!testing) {
    await locator<NotificationService>().init();
  }
  await locator<LocationService>().init();

  locator<LoggerService>().info(
    'High priority services initialized (including CacheService, CompassService, and MapService)',
  );
}

/// Schedule remaining service initialization
void _scheduleRemainingServiceInitialization() {
  Future.microtask(() async {
    try {
      locator<LoggerService>().info('Normal priority services initialized');
    } catch (e) {
      locator<LoggerService>().error(
        'Error initializing background services',
        error: e,
      );
    }
  });
}
