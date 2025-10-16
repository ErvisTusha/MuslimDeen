/**
 * Service Locator Configuration
 * 
 * This file sets up the dependency injection system for the MuslimDeen app using
 * the GetIt package. The service locator pattern provides a centralized way to
 * manage and access app services throughout the application lifecycle.
 * 
 * Key features:
 * - Hot reload safety with automatic reset on reinitialization
 * - Prioritized initialization for critical vs. non-critical services
 * - Async service support with dependency resolution
 * - Performance optimizations with batched initialization
 * - Graceful degradation when services fail to initialize
 * 
 * Architecture decisions:
 * - Lazy initialization: Services are created only when first accessed
 * - Singleton pattern: Each service has exactly one instance
 * - Dependency management: Services can depend on other registered services
 * - Error handling: Non-critical services don't prevent app startup
 */

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:muslim_deen/services/cache_metrics_service.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/dhikr_reminder_service.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/fasting_service.dart';
import 'package:muslim_deen/services/hadith_service.dart';
import 'package:muslim_deen/services/islamic_events_service.dart';
import 'package:muslim_deen/services/location_cache_manager.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/services/moon_phases_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/services/tasbih_history_service.dart';
import 'package:muslim_deen/services/widget_service.dart';
import 'package:muslim_deen/services/zakat_calculator_service.dart';
import 'package:muslim_deen/services/audio_player_service.dart';
import 'package:muslim_deen/services/prayer_analytics_service.dart';
import 'package:muslim_deen/services/accessibility_service.dart';

// Global service locator instance
final GetIt locator = GetIt.instance;

// Cache SharedPreferences instance to avoid multiple async calls
// This improves performance by preventing repeated async operations
SharedPreferences? _sharedPrefsCache;

/**
 * Initializes the service locator with optimized loading
 * 
 * This function sets up all app services in a specific order to ensure
 * dependencies are properly resolved. It implements hot reload safety
 * by checking if services are already registered and resetting if necessary.
 * 
 * The initialization process is divided into phases:
 * 1. Service registration (all services are registered but not initialized)
 * 2. Critical services initialization (must succeed for app to function)
 * 3. High priority services initialization (important but non-blocking)
 * 4. Background services initialization (can fail without impacting core functionality)
 * 
 * @param testing Whether the app is running in test mode (excludes certain services)
 * @throws Exception if critical services fail to initialize
 */
Future<void> setupLocator({bool testing = false}) async {
  // Reset locator if already initialized (e.g., hot reload)
  // This prevents double-registration errors during development
  if (locator.isRegistered<LoggerService>()) {
    await locator.reset();
  }

  try {
    // Pre-load SharedPreferences for better performance
    // This avoids multiple async calls later during service initialization
    _sharedPrefsCache ??= await SharedPreferences.getInstance();
  } catch (e) {
    // If SharedPreferences fails, continue anyway
    // Storage is not critical for app functionality
    debugPrint('Failed to load SharedPreferences: $e');
  }

  try {
    // Register all services with the locator
    // This phase only registers service factories, doesn't initialize them
    _registerServices(testing);
  } catch (e) {
    debugPrint('Failed to register services: $e');
    rethrow; // Re-throw as registration failures are critical
  }

  try {
    // Initialize critical services that must succeed
    // These services are essential for the app to function properly
    await _initializeCriticalServices();
  } catch (e) {
    debugPrint('Failed to initialize critical services: $e');
    rethrow; // Re-throw as critical service failures prevent app from running
  }

  // Use batched initialization for better performance
  // High priority services are initialized in parallel where possible
  try {
    await _initializeHighPriorityServicesBatch(testing);
  } catch (e) {
    debugPrint('Failed to initialize high priority services: $e');
    // Continue anyway - don't let this crash the app
  }

  // Schedule remaining service initialization to run after app starts
  // This ensures the app starts quickly while background services initialize
  _scheduleRemainingServiceInitialization();
}

/**
 * Registers all services with the locator using optimized patterns
 * 
 * This function registers all app services with the GetIt service locator.
 * Services are registered as lazy singletons, meaning they are created
 * only when first accessed. The registration order respects dependencies
 * between services.
 * 
 * Registration patterns used:
 * - registerLazySingleton: For synchronous services with no dependencies
 * - registerLazySingletonAsync: For services requiring async initialization
 * - Conditional registration: Some services are skipped in testing mode
 * 
 * @param testing Whether the app is running in test mode
 */
void _registerServices(bool testing) {
  // Register synchronous services first (no async dependencies)
  // These are lightweight services that can be created immediately
  locator.registerLazySingleton<LoggerService>(LoggerService.new);
  locator.registerLazySingleton<DatabaseService>(DatabaseService.new);
  locator.registerLazySingleton<StorageService>(StorageService.new);
  locator.registerLazySingleton<LocationService>(LocationService.new);
  locator.registerLazySingleton<ErrorHandlerService>(ErrorHandlerService.new);
  locator.registerLazySingleton<NavigationService>(NavigationService.new);
  locator.registerLazySingleton<PrayerHistoryService>(PrayerHistoryService.new);
  locator.registerLazySingleton<PrayerAnalyticsService>(
    PrayerAnalyticsService.new,
  );
  locator.registerLazySingleton<DhikrReminderService>(DhikrReminderService.new);
  locator.registerLazySingleton<TasbihHistoryService>(TasbihHistoryService.new);
  locator.registerLazySingleton<HadithService>(HadithService.new);
  locator.registerLazySingleton<MoonPhasesService>(MoonPhasesService.new);
  locator.registerLazySingleton<IslamicEventsService>(IslamicEventsService.new);

  // Register NotificationService conditionally (skip in testing)
  // Notifications can't be tested in unit test environments
  if (!testing) {
    locator.registerLazySingleton<NotificationService>(NotificationService.new);
  }

  // Register async services with optimized dependency resolution
  // These services require async initialization or depend on other async services
  
  /// CacheService requires SharedPreferences which is async
  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = _sharedPrefsCache ?? await SharedPreferences.getInstance();
    return CacheService(prefs);
  });

  /// CacheMetricsService requires SharedPreferences which is async
  locator.registerLazySingletonAsync<CacheMetricsService>(() async {
    final prefs = _sharedPrefsCache ?? await SharedPreferences.getInstance();
    return CacheMetricsService(prefs);
  });

  /// LocationCacheManager requires async initialization
  locator.registerLazySingletonAsync<LocationCacheManager>(() async {
    final cacheManager = LocationCacheManager();
    await cacheManager.init();
    // Attach metrics service if available (optional dependency)
    try {
      final metricsService = await locator.getAsync<CacheMetricsService>();
      cacheManager.setMetricsService(metricsService);
    } catch (e) {
      // Metrics service not available, continue without it
    }
    return cacheManager;
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

  /// CompassService requires async CacheService dependency
  locator.registerLazySingletonAsync<CompassService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return CompassService(cacheService: cacheService);
  });

  /// MapService requires async CacheService dependency
  locator.registerLazySingletonAsync<MapService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return MapService(cacheService: cacheService);
  });

  /// WidgetService depends on async PrayerService
  locator.registerLazySingletonAsync<WidgetService>(() async {
    // Ensure PrayerService is ready before creating WidgetService
    await locator.isReady<PrayerService>();
    return WidgetService();
  });

  /// FastingService depends on DatabaseService
  locator.registerLazySingletonAsync<FastingService>(() async {
    final databaseService = await locator.getAsync<DatabaseService>();
    final service = FastingService(databaseService);
    await service.init();
    return service;
  });

  /// ZakatCalculatorService depends on StorageService
  locator.registerLazySingletonAsync<ZakatCalculatorService>(() async {
    final storageService = locator<StorageService>();
    final service = ZakatCalculatorService(storageService);
    await service.init();
    return service;
  });

  /// AudioPlayerService and AccessibilityService are registered synchronously
  /// but require initialization later
  locator.registerLazySingleton<AudioPlayerService>(AudioPlayerService.new);
  locator.registerLazySingleton<AccessibilityService>(AccessibilityService.new);
}

/**
 * Initialize critical services required for app to start
 * 
 * These services must initialize successfully for the app to function.
 * If any of these fail, the app will not start. This includes core services
 * like database, storage, and logging that are essential for basic functionality.
 * 
 * @throws Exception if any critical service fails to initialize
 */
Future<void> _initializeCriticalServices() async {
  final stopwatch = Stopwatch()..start();

  try {
    // DatabaseService is critical for storing prayer records, settings, etc.
    await locator<DatabaseService>().init();
  } catch (e) {
    debugPrint('Failed to initialize DatabaseService: $e');
    rethrow; // Database is critical - rethrow to stop app startup
  }

  try {
    // StorageService is important for user preferences and app data
    await locator<StorageService>().init();
  } catch (e) {
    debugPrint('Failed to initialize StorageService: $e');
    // Continue anyway - storage is not critical for basic functionality
  }

  try {
    // AudioPlayerService for prayer notifications and audio features
    await locator<AudioPlayerService>().init();
  } catch (e) {
    debugPrint('Failed to initialize AudioPlayerService: $e');
    // Continue anyway - audio is not critical for basic functionality
  }

  stopwatch.stop();
  try {
    locator<LoggerService>().info(
      'Critical services initialized in ${stopwatch.elapsedMilliseconds}ms',
    );
  } catch (e) {
    debugPrint('Logger not available for critical services message: $e');
  }
}

/**
 * Initialize high priority services in optimized batches
 * 
 * These services are important for the user experience but won't prevent
 * the app from starting if they fail. They are initialized in batches
 * where possible to improve performance, taking into account their
 * dependencies on each other.
 * 
 * @param testing Whether the app is running in test mode
 */
Future<void> _initializeHighPriorityServicesBatch(bool testing) async {
  final stopwatch = Stopwatch()..start();

  // Initialize services in dependency order with batching
  
  // First, ensure CacheService is ready (many services depend on it)
  await locator.isReady<CacheService>();

  // Batch services that depend on CacheService
  // These can be initialized in parallel as they don't depend on each other
  await Future.wait([
    locator.isReady<PrayerTimesCache>(),
    locator.isReady<CompassService>(),
    locator.isReady<MapService>(),
  ]);

  // Services that depend on PrayerTimesCache
  await locator.isReady<PrayerService>();

  // Initialize new services that were added
  await Future.wait([
    locator.isReady<FastingService>(),
    locator.isReady<ZakatCalculatorService>(),
  ]);

  // Initialize IslamicEventsService and MoonPhasesService (synchronous)
  // These don't have async dependencies but need to be initialized
  await locator<IslamicEventsService>().init();
  await locator<MoonPhasesService>().init();

  // Initialize WidgetService (depends on PrayerService)
  await locator.isReady<WidgetService>();

  // Initialize platform-specific services
  final initFutures = <Future<void>>[];

  if (!testing) {
    // NotificationService requires platform permissions
    initFutures.add(locator<NotificationService>().init());
    // WidgetService for home screen widgets
    initFutures.add(locator<WidgetService>().initialize());
  }
  
  // LocationService requires platform permissions
  initFutures.add(locator<LocationService>().init());
  // AccessibilityService for enhanced accessibility features
  initFutures.add(locator<AccessibilityService>().initialize());

  if (initFutures.isNotEmpty) {
    await Future.wait(initFutures);
  }

  stopwatch.stop();
  locator<LoggerService>().info(
    'High priority services initialized in ${stopwatch.elapsedMilliseconds}ms',
  );
}

/**
 * Schedule remaining service initialization with error handling
 * 
 * This function schedules any remaining background service initialization
 * to run after the app has started. This ensures fast app startup while
 * still initializing all services. Errors here are logged but don't
 * affect the app's ability to run.
 */
void _scheduleRemainingServiceInitialization() {
  // Use microtask to run after the current event loop
  Future.microtask(() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Any additional background initialization can go here
      // Currently, all services are initialized in the previous steps

      stopwatch.stop();
      locator<LoggerService>().info(
        'Background services initialized in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e, stackTrace) {
      // Log errors but don't let them crash the app
      locator<LoggerService>().error(
        'Error initializing background services',
        error: e,
        stackTrace: stackTrace,
      );
    }
  });
}