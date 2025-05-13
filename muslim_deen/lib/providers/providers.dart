// Core providers for the application
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/providers/cache_providers.dart';
import 'package:muslim_deen/repositories/prayer_repository.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/location_service.dart';

import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'settings_notifier.dart';

// Service providers - Make services available through Riverpod
final loggerServiceProvider = Provider<LoggerService>(
  (ref) => locator<LoggerService>(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => locator<LocationService>(),
);

final prayerServiceProvider = Provider<PrayerService>(
  (ref) => locator<PrayerService>(),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => locator<StorageService>(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => locator<NotificationService>(),
);

// Settings provider with state notifier
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(notificationServiceProvider),
    ref.watch(loggerServiceProvider),
  );
});

// Prayer notification status provider
final notificationsBlockedProvider = StreamProvider<bool>((ref) {
  return ref.watch(notificationServiceProvider).permissionStatusStream
      .map((status) => status == NotificationPermissionStatus.denied);
});

// Error handler provider
final errorHandlerProvider = Provider<ErrorHandlerService>((ref) {
  final errorHandler = ErrorHandlerService();
  ref.onDispose(() => errorHandler.dispose());
  return errorHandler;
});

// Repository providers
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository(
    ref.watch(prayerServiceProvider),
    ref.watch(errorHandlerProvider),
    ref.watch(prayerTimesCacheProvider),
    ref.watch(locationServiceProvider),
  );
});

// Prayer times providers
final prayerTimesProvider = FutureProvider.family<PrayerTimesModel?, DateTime>((ref, date) async {
  final repository = ref.watch(prayerRepositoryProvider);
  final result = await repository.getPrayerTimes(date);
  
  return result.fold(
    (success) => success,
    (error) => null, // Return null on error - the error is already handled by the error handler
  );
});

final nextPrayerProvider = FutureProvider<PrayerTime?>((ref) async {
  // Automatically refresh every minute
  final _ = DateTime.now().minute;
  
  final repository = ref.watch(prayerRepositoryProvider);
  final prayerTimesResult = await repository.getPrayerTimes(DateTime.now());
  
  return prayerTimesResult.fold(
    (prayerTimes) => prayerTimes.getNextPrayer(),
    (error) => null,
  );
});
