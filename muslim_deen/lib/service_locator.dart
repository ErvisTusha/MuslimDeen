import 'package:get_it/get_it.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/services/error_handler_service.dart'; // Added import
import 'package:shared_preferences/shared_preferences.dart';

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
  locator.registerLazySingleton<LoggerService>(() => LoggerService());

  // Register storage service
  locator.registerLazySingleton<StorageService>(() => StorageService());
  
  // Register cache service with async shared prefs resolution
  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = await sharedPrefsInstance;
    return CacheService(prefs);
  });

  // Register location service
  locator.registerLazySingleton<LocationService>(() => LocationService());

  // Register notification service (except in testing)
  if (!testing) {
    locator.registerLazySingleton<NotificationService>(() => NotificationService());
  }

  // Register dependent services
  locator.registerLazySingleton<PrayerService>(
    () => PrayerService(locator<LocationService>()),
  );
  
  locator.registerLazySingletonAsync<CompassService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return CompassService(cacheService: cacheService);
  });
  
  locator.registerLazySingletonAsync<MapService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return MapService(cacheService: cacheService);
  });

  // Register ErrorHandlerService
  locator.registerLazySingleton<ErrorHandlerService>(() => ErrorHandlerService());
}

/// Initialize critical services required for app to start
Future<void> _initializeCriticalServices() async {
  // These services must be ready before the app can show UI
  await locator<StorageService>().init();
  // Log startup process
  locator<LoggerService>().info('Critical services initialized');
}

/// Initialize high priority services needed early in app lifecycle
Future<void> _initializeHighPriorityServices(bool testing) async {
  // Initialize services needed soon after app starts
  // Ensure CacheService and MapService are ready before other high-priority services
  // that might depend on them or be accessed by UI components initialized early.
  await locator.isReady<CacheService>(); // CompassService depends on this
  await locator.isReady<CompassService>(); // Ensure CompassService is ready
  await locator.isReady<MapService>();

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
