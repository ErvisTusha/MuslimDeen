import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/settings_notification_mixin.dart';
import 'package:muslim_deen/providers/settings_persistence_mixin.dart';
import 'package:muslim_deen/providers/settings_prayer_mixin.dart';

class SettingsNotifier extends Notifier<AppSettings>
    with
        SettingsPersistenceMixin,
        NotificationSchedulingMixin,
        PrayerCalculationMixin {
  @override
  AppSettings build() {
    // Load settings immediately if storage is ready (synchronous path)
    final loadedSettings = loadSettingsSync();

    // Schedule async initialization for after the provider is built
    Future.microtask(() {
      initializeSettings();
      initializePermissionListener();
    });

    // Return loaded settings if available, otherwise defaults
    return loadedSettings ?? AppSettings.defaults;
  }

  void dispose() {
    disposePersistence();
    disposeNotifications();
  }
}
