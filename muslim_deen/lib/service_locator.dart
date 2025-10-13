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

final GetIt locator = GetIt.instance;

// Cache SharedPreferences instance to avoid multiple async calls
SharedPreferences? _sharedPrefsCache;

/// Initializes the service locator with optimized loading
Future<void> setupLocator({bool testing = false}) async {
  try {
    // Pre-load SharedPreferences for better performance
    _sharedPrefsCache ??= await SharedPreferences.getInstance();
  } catch (e) {
    // If SharedPreferences fails, continue anyway
    debugPrint('Failed to load SharedPreferences: $e');
  }

  try {
    _registerServices(testing);
  } catch (e) {
    debugPrint('Failed to register services: $e');
    rethrow;
  }

  try {
    await _initializeCriticalServices();
  } catch (e) {
    debugPrint('Failed to initialize critical services: $e');
    rethrow;
  }

  // Use batched initialization for better performance
  try {
    await _initializeHighPriorityServicesBatch(testing);
  } catch (e) {
    debugPrint('Failed to initialize high priority services: $e');
    // Continue anyway - don't let this crash the app
  }

  _scheduleRemainingServiceInitialization();
}

/// Registers all services with the locator using optimized patterns
void _registerServices(bool testing) {
  // Register synchronous services first
  locator.registerLazySingleton<LoggerService>(LoggerService.new);
  locator.registerLazySingleton<DatabaseService>(DatabaseService.new);
  locator.registerLazySingleton<StorageService>(StorageService.new);
  locator.registerLazySingleton<LocationService>(LocationService.new);
  locator.registerLazySingleton<ErrorHandlerService>(ErrorHandlerService.new);
  locator.registerLazySingleton<NavigationService>(NavigationService.new);
  locator.registerLazySingleton<PrayerHistoryService>(PrayerHistoryService.new);
  locator.registerLazySingleton<PrayerAnalyticsService>(PrayerAnalyticsService.new);
  locator.registerLazySingleton<DhikrReminderService>(DhikrReminderService.new);
  locator.registerLazySingleton<TasbihHistoryService>(TasbihHistoryService.new);
  locator.registerLazySingleton<HadithService>(HadithService.new);
  locator.registerLazySingleton<MoonPhasesService>(MoonPhasesService.new);
  locator.registerLazySingleton<IslamicEventsService>(IslamicEventsService.new);

  if (!testing) {
    locator.registerLazySingleton<NotificationService>(NotificationService.new);
  }

  // Register async services with optimized dependency resolution
  locator.registerLazySingletonAsync<CacheService>(() async {
    final prefs = _sharedPrefsCache ?? await SharedPreferences.getInstance();
    return CacheService(prefs);
  });

  locator.registerLazySingletonAsync<CacheMetricsService>(() async {
    final prefs = _sharedPrefsCache ?? await SharedPreferences.getInstance();
    return CacheMetricsService(prefs);
  });

  locator.registerLazySingletonAsync<LocationCacheManager>(() async {
    final cacheManager = LocationCacheManager();
    await cacheManager.init();
    // Attach metrics service if available
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

  locator.registerLazySingletonAsync<CompassService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return CompassService(cacheService: cacheService);
  });

  locator.registerLazySingletonAsync<MapService>(() async {
    final cacheService = await locator.getAsync<CacheService>();
    return MapService(cacheService: cacheService);
  });

  /// WidgetService depends on async PrayerService
  locator.registerLazySingletonAsync<WidgetService>(() async {
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

  /// AudioPlayerService depends on CacheService
  locator.registerLazySingleton<AudioPlayerService>(AudioPlayerService.new);
}

/// Initialize critical services required for app to start
Future<void> _initializeCriticalServices() async {
  final stopwatch = Stopwatch()..start();

  try {
    await locator<DatabaseService>().init();
  } catch (e) {
    debugPrint('Failed to initialize DatabaseService: $e');
    rethrow;
  }

  try {
    await locator<StorageService>().init();
  } catch (e) {
    debugPrint('Failed to initialize StorageService: $e');
    // Continue anyway - storage is not critical
  }

  try {
    await locator<AudioPlayerService>().init();
  } catch (e) {
    debugPrint('Failed to initialize AudioPlayerService: $e');
    // Continue anyway - audio is not critical
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

  // Initialize new services
  await Future.wait([
    locator.isReady<FastingService>(),
    locator.isReady<ZakatCalculatorService>(),
  ]);

  // Initialize IslamicEventsService and MoonPhasesService (synchronous)
  await locator<IslamicEventsService>().init();
  await locator<MoonPhasesService>().init();

  // Initialize WidgetService
  await locator.isReady<WidgetService>();

  // Initialize platform services
  final initFutures = <Future<void>>[];

  if (!testing) {
    initFutures.add(locator<NotificationService>().init());
    // Initialize WidgetService
    initFutures.add(locator<WidgetService>().initialize());
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
