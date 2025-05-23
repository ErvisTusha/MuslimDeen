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
import 'package:muslim_deen/services/prayer_times_cache.dart'; // Added import
import 'package:muslim_deen/services/storage_service.dart';

final GetIt locator = GetIt.instance;

/// Initializes the service locator with optimized loading
Future<void> setupLocator({bool testing = false}) async {
  // First, register all services without initializing them
  _registerServices(testing);
  
  // Then initialize services based on priority
  await _initializeCriticalServices();
  await _initializeHighPriorityServices(testing);
  
  // Normal and low priority services are initialized lazily
  // or in the background after app is visible to user
  _scheduleRemainingServiceInitialization();
}

/// Registers all services with the locator
void _registerServices(bool testing) {
  final sharedPrefsInstance = SharedPreferences.getInstance();
  
  // Register logger first so it's available to all other services
  locator.registerLazySingleton<LoggerService>(LoggerService.new);

  locator.registerLazySingleton<StorageService>(StorageService.new);
  
  // Register cache service with async shared prefs resolution
  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = await sharedPrefsInstance;
    return CacheService(prefs);
  });

  locator.registerLazySingleton<LocationService>(LocationService.new);

  // Register notification service (except in testing)
  if (!testing) {
    locator.registerLazySingleton<NotificationService>(NotificationService.new);
  }

  // Register PrayerTimesCache
  // It depends on CacheService (async) and LoggerService (sync)
  // To handle async dependency, we can make PrayerTimesCache registration async
  // or ensure CacheService is ready before PrayerTimesCache is potentially created.
  // Given CacheService is initialized in _initializeHighPriorityServices,
  // we can make PrayerTimesCache depend on its readiness if registered as async,
  // or register it lazily assuming CacheService will be ready when PTC is first requested.
  // For simplicity with GetIt's async capabilities, let's register it async if it depends on an async service.
  // However, PrayerTimesCache constructor itself is synchronous.
  // Let's register it as a regular lazy singleton, assuming CacheService will be ready.
  // This means PrayerTimesCache should ideally take CacheService instance directly.
  // The current PrayerTimesCacheProvider in Riverpod does:
  // final cacheService = locator<CacheService>(); -> This is problematic if CacheService is async and not ready.
  // Let's ensure CacheService is ready before PrayerTimesCache is registered, or make PTC async.

  // Simpler: Register PrayerTimesCache as a lazy singleton.
  // Its dependencies (CacheService, LoggerService) should be resolvable by GetIt.
  // CacheService is registered async. This means PrayerTimesCache should also be registered async
  // if it directly depends on awaiting CacheService, OR ensure CacheService is ready first.
  
  // Correct approach: If PrayerTimesCache needs an *instance* of an async-registered service (CacheService)
  // in its constructor, then PrayerTimesCache itself should be registered async.
  locator.registerLazySingletonAsync<PrayerTimesCache>(() async {
    final cacheService = await locator.getAsync<CacheService>(); // Await the async CacheService
    final loggerService = locator<LoggerService>();
    return PrayerTimesCache(cacheService, loggerService);
  });
  
  // PrayerService now depends on LocationService and PrayerTimesCache
  // Since PrayerTimesCache is now async, PrayerService must also be async registered
  // if it awaits PrayerTimesCache in its factory, or if PrayerTimesCache is passed as Future.
  // For direct injection of the instance, we await PrayerTimesCache.
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
  // These services must be ready before the app can show UI
  await locator<StorageService>().init();
  locator<LoggerService>().info('Critical services initialized');
}

/// Initialize high priority services needed early in app lifecycle
Future<void> _initializeHighPriorityServices(bool testing) async {
  // Ensure CacheService and MapService are ready before other high-priority services
  // that might depend on them or be accessed by UI components initialized early.
  await locator.isReady<CacheService>(); 
  await locator.isReady<PrayerTimesCache>(); // Ensure PrayerTimesCache is ready for services that might need it early
  await locator.isReady<CompassService>(); // CompassService depends on CacheService
  await locator.isReady<MapService>(); // MapService depends on CacheService

  if (!testing) {
    await locator<NotificationService>().init();
  }
  await locator<LocationService>().init();
  
  locator<LoggerService>().info('High priority services initialized (including CacheService, CompassService, and MapService)');
}

/// Schedule remaining service initialization
void _scheduleRemainingServiceInitialization() {
  // Use Future.microtask to initialize remaining services after frame is rendered
  Future.microtask(() async {
    try {
      // CacheService readiness is now ensured in _initializeHighPriorityServices
      locator<LoggerService>().info('Normal priority services initialized');
    } catch (e) {
      locator<LoggerService>().error('Error initializing background services', error: e);
    }
  });
}
