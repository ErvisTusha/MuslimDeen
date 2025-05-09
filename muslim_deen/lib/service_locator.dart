import 'package:get_it/get_it.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator({bool testing = false}) async {
  final sharedPrefs = await SharedPreferences.getInstance();

  // Register logger first so it's available to all other services
  locator.registerLazySingleton<LoggerService>(() => LoggerService());

  locator.registerLazySingleton<StorageService>(() => StorageService());
  // Initialize StorageService immediately after registration
  await locator<StorageService>().init();

  locator.registerLazySingleton<CacheService>(() => CacheService(sharedPrefs));

  // Skip notification service initialization in test environment
  if (!testing) {
    locator.registerLazySingleton<NotificationService>(
      () => NotificationService(),
    );
    // Initialize NotificationService immediately after registration
    await locator<NotificationService>().init();
  }

  locator.registerLazySingleton<LocationService>(() => LocationService());
  // Initialize LocationService immediately after registration
  await locator<LocationService>().init();

  // Register dependent services after their dependencies are initialized
  locator.registerLazySingleton<PrayerService>(
    () => PrayerService(
      locator<LocationService>(),
    ),
  );
  
  locator.registerLazySingleton<CompassService>(
    () => CompassService(cacheService: locator<CacheService>()),
  );
  
  locator.registerLazySingleton<MapService>(
    () => MapService(cacheService: locator<CacheService>()),
  );
}
