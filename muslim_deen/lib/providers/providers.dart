// Core providers for the application
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/providers/cache_providers.dart';
import 'package:muslim_deen/providers/settings_notifier.dart';
import 'package:muslim_deen/repositories/prayer_repository.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

final loggerServiceProvider = Provider<LoggerService>(
  (ref) => locator<LoggerService>(),
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
    ref.watch(prayerServiceProvider),
  );
});
