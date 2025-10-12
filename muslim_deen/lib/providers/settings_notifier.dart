import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  late final StorageService _storage;
  late final NotificationService _notificationService;
  late final LoggerService _logger;
  late final PrayerService _prayerService;
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;
  Timer? _saveSettingsDebounceTimer;
  static const Duration _saveSettingsDebounceDuration = Duration(
    milliseconds: 200,
  ); // Reduced debounce time from 750ms to 200ms for better responsiveness
  bool _isInitialized = false;

  @override
  AppSettings build() {
    _storage = ref.read(storageServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);
    _logger = ref.read(loggerServiceProvider);
    _prayerService = ref.read(prayerServiceProvider);

    // Load settings immediately if storage is ready (synchronous path)
    final loadedSettings = _loadSettingsSync();

    // Still initialize async for any cleanup/validation
    _initializeSettings();
    _initializePermissionListener();

    // Return loaded settings if available, otherwise defaults
    return loadedSettings ?? AppSettings.defaults;
  }

  /// Attempt to load settings synchronously if storage is already initialized
  AppSettings? _loadSettingsSync() {
    if (!_storage.isInitialized) {
      _logger.warning('Storage not initialized during build, will load async');
      return null;
    }

    try {
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null && storedSettings.isNotEmpty) {
        final decodedJson = jsonDecode(storedSettings) as Map<String, dynamic>;
        final loadedSettings = AppSettings.fromJson(decodedJson);
        _isInitialized = true;
        _logger.info(
          "Settings loaded synchronously during build",
          data: {
            'themeMode': loadedSettings.themeMode.toString(),
            'calculationMethod': loadedSettings.calculationMethod,
            'language': loadedSettings.language,
          },
        );
        return loadedSettings;
      }
    } catch (e, s) {
      _logger.error(
        'Error loading settings synchronously',
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  Future<void> _initializeSettings() async {
    if (_isInitialized) {
      _logger.debug('Settings already initialized, skipping async init');
      return;
    }

    // Ensure storage is initialized
    if (!_storage.isInitialized) {
      _logger.warning(
        'Storage not initialized during settings init, initializing now',
      );
      await _storage.init();
    }

    try {
      // Try to load settings
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null && storedSettings.isNotEmpty) {
        try {
          final decodedJson =
              jsonDecode(storedSettings) as Map<String, dynamic>;
          final loadedSettings = AppSettings.fromJson(decodedJson);
          state = loadedSettings;
          _logger.info(
            "Settings loaded successfully during async initialization",
            data: {
              'themeMode': state.themeMode.toString(),
              'calculationMethod': state.calculationMethod,
              'language': state.language,
              'jsonLength': storedSettings.length,
            },
          );
        } catch (parseError, parseStack) {
          _logger.error(
            'Error parsing stored settings JSON',
            error: parseError,
            stackTrace: parseStack,
            data: {
              'storedSettingsLength': storedSettings.length,
              'storedSettingsPreview': storedSettings.substring(
                0,
                min(100, storedSettings.length),
              ),
            },
          );
          // Reset to defaults and save to fix corrupted data
          state = AppSettings.defaults;
          await _forceSaveSettings();
        }
      } else {
        // If no stored settings, use defaults
        _logger.info(
          "No stored settings found during async init, using defaults",
        );
        // Save defaults for first-time users
        await _forceSaveSettings();
      }
      _isInitialized = true;
    } catch (e, s) {
      _logger.error(
        'Error initializing settings',
        error: e,
        stackTrace: s,
        data: {
          'storedSettingsLength':
              (_storage.getData(_settingsKey) as String?)?.length,
        },
      );
      // Don't try to save during initialization - just use defaults
      _isInitialized = true;
    }
  }

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  bool get areAllPrayerNotificationsEnabled => PrayerNotification.values.every(
    (prayer) => state.notifications[prayer] ?? false,
  );

  void _initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen(_updateNotificationPermissionStatus);
  }

  Future<void> _saveSettings() async {
    // Ensure storage is initialized
    if (!_storage.isInitialized) {
      _logger.warning('Storage not initialized, initializing now');
      await _storage.init();
    }

    try {
      final jsonString = jsonEncode(state.toJson());
      await _storage.saveData(_settingsKey, jsonString);
      _logger.debug(
        "Settings saved successfully",
        data: {
          'jsonLength': jsonString.length,
          'themeMode': state.themeMode.toString(),
          'key': _settingsKey,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error saving settings',
        error: e,
        stackTrace: s,
        data: {
          'themeMode': state.themeMode.toString(),
          'calculationMethod': state.calculationMethod,
          'key': _settingsKey,
        },
      );
      // Retry saving after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          final jsonString = jsonEncode(state.toJson());
          await _storage.saveData(_settingsKey, jsonString);
          _logger.info("Settings retry save successful");
        } catch (retryError, retryStack) {
          _logger.error(
            'Settings retry save failed',
            error: retryError,
            stackTrace: retryStack,
          );
        }
      });
    }
  }

  void _debouncedSaveSettings() {
    _saveSettingsDebounceTimer?.cancel();
    _saveSettingsDebounceTimer = Timer(_saveSettingsDebounceDuration, () {
      _saveSettings();
      _logger.debug("Debounced _saveSettings executed.");
    });
  }

  /// Force immediate save of settings without debouncing
  Future<void> _forceSaveSettings() async {
    _saveSettingsDebounceTimer?.cancel();
    await _saveSettings();
  }
  
  /// Update critical settings with immediate save (no debouncing)
  /// Critical settings are those that need to be persisted immediately
  /// such as notification permissions, calculation method changes, etc.
  Future<void> updateCriticalSetting<T>(
    String settingName,
    T value, {
    required T Function(AppSettings) getter,
    required AppSettings Function(AppSettings, T) setter,
  }) async {
    if (getter(state) != value) {
      state = setter(state, value);
      _logger.info('Critical setting updated immediately', data: {
        'setting': settingName,
        'value': value,
      });
      await _forceSaveSettings();
    }
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (state.notificationPermissionStatus != status) {
      state = state.copyWith(notificationPermissionStatus: status);
      // Use debounced save for permission status as it may change frequently
      _debouncedSaveSettings();
    }
  }

  /// Triggers a refresh of the notification permission status from the NotificationService.
  /// The SettingsNotifier's internal listener will then update the state.
  Future<void> refreshNotificationPermissionStatus() async {
    // Calling requestPermission will re-evaluate and update the permission status,
    // which then updates the stream that this notifier listens to.
    await _notificationService.requestPermission();
  }

  Future<void> updateTimeFormat(TimeFormat format) async {
    // Time format is less critical, can use debounced save
    if (state.timeFormat != format) {
      state = state.copyWith(timeFormat: format);
      _debouncedSaveSettings();
    }
  }

  Future<void> updateCalculationMethod(String method) async {
    await updateCriticalSetting(
      'calculationMethod',
      method,
      getter: (settings) => settings.calculationMethod,
      setter: (settings, value) => settings.copyWith(calculationMethod: value),
    );
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateMadhab(String madhab) async {
    await updateCriticalSetting(
      'madhab',
      madhab,
      getter: (settings) => settings.madhab,
      setter: (settings, value) => settings.copyWith(madhab: value),
    );
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    // Theme mode is less critical, can use debounced save
    if (state.themeMode != mode) {
      state = state.copyWith(themeMode: mode);
      _debouncedSaveSettings();
    }
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    // Date format is less critical, can use debounced save
    if (state.dateFormatOption != option) {
      state = state.copyWith(dateFormatOption: option);
      _debouncedSaveSettings();
    }
  }

  Future<void> updatePrayerNotification(
    PrayerNotification prayer,
    bool isEnabled,
  ) async {
    final currentStatus = state.notifications[prayer] ?? false;
    if (currentStatus != isEnabled) {
      final newNotifications = Map<PrayerNotification, bool>.from(
        state.notifications,
      );
      newNotifications[prayer] = isEnabled;
      state = state.copyWith(notifications: newNotifications);
      
      // Use critical setting update for notification changes
      await updateCriticalSetting(
        'notification_${prayer.name}',
        isEnabled,
        getter: (settings) => settings.notifications[prayer] ?? false,
        setter: (settings, value) {
          final newNotifs = Map<PrayerNotification, bool>.from(settings.notifications);
          newNotifs[prayer] = value;
          return settings.copyWith(notifications: newNotifs);
        },
      );
    }
    // No need to call _recalculateAndRescheduleNotifications here as it's handled by HomeView's listener
    // when notification settings change. HomeView will call _scheduleAllPrayerNotifications.
  }

  Future<void> updateAllPrayerNotifications(bool isEnabled) async {
    final newNotifications = Map<PrayerNotification, bool>.from(
      state.notifications,
    );
    for (var prayer in PrayerNotification.values) {
      newNotifications[prayer] = isEnabled;
    }
    state = state.copyWith(notifications: newNotifications);
    await _forceSaveSettings();
    // No need to call _recalculateAndRescheduleNotifications here as it's handled by HomeView's listener
    // when notification settings change. HomeView will call _scheduleAllPrayerNotifications.
  }

  Future<void> updateAzanSound(String soundFileName) async {
    await updateCriticalSetting(
      'azanSound',
      soundFileName,
      getter: (settings) => settings.azanSoundForStandardPrayers,
      setter: (settings, value) => settings.copyWith(azanSoundForStandardPrayers: value),
    );
    // Reschedule notifications if sound changed, as it's part of the notification content/payload
    await _recalculateAndRescheduleNotifications();
  }

  // Prayer offset update methods
  Future<void> updateFajrOffset(int offsetMinutes) async {
    state = state.copyWith(fajrOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateSunriseOffset(int offsetMinutes) async {
    state = state.copyWith(sunriseOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateDhuhrOffset(int offsetMinutes) async {
    state = state.copyWith(dhuhrOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateAsrOffset(int offsetMinutes) async {
    state = state.copyWith(asrOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateMaghribOffset(int offsetMinutes) async {
    state = state.copyWith(maghribOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateIshaOffset(int offsetMinutes) async {
    state = state.copyWith(ishaOffset: offsetMinutes);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateLanguage(String language) async {
    await updateCriticalSetting(
      'language',
      language,
      getter: (settings) => settings.language,
      setter: (settings, value) => settings.copyWith(language: value),
    );
  }

  Future<void> updateDhikrRemindersEnabled(bool enabled) async {
    state = state.copyWith(dhikrRemindersEnabled: enabled);
    await _forceSaveSettings();

    if (enabled) {
      await _scheduleDhikrReminders();
    } else {
      await _cancelDhikrReminders();
    }
  }

  Future<void> updateDhikrReminderInterval(int intervalHours) async {
    state = state.copyWith(dhikrReminderInterval: intervalHours);
    await _forceSaveSettings();

    if (state.dhikrRemindersEnabled) {
      await _cancelDhikrReminders();
      await _scheduleDhikrReminders();
    }
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    state = AppSettings.defaults;
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  /// Export settings as JSON string
  String exportSettings() {
    return jsonEncode(state.toJson());
  }

  /// Import settings from JSON string
  Future<bool> importSettings(String settingsJson) async {
    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(settingsJson) as Map<String, dynamic>;
      state = AppSettings.fromJson(jsonData);
      await _forceSaveSettings();
      await _recalculateAndRescheduleNotifications();
      return true;
    } catch (e) {
      _logger.error('Error importing settings', error: e);
      return false;
    }
  }

  Future<void> _recalculateAndRescheduleNotifications() async {
    try {
      final adhan.PrayerTimes? prayerTimesToday = await _prayerService
          .calculatePrayerTimesForToday(state);

      if (prayerTimesToday == null) {
        _logger.error(
          'Failed to calculate prayer times for rescheduling notifications. PrayerTimes object is null.',
          data: {'settings': state.toJson()},
        );
        return;
      }

      // Cancel all existing prayer notifications before rescheduling
      await _notificationService.cancelPrayerNotifications();

      final prayersToReschedule = [
        {
          'name': "fajr",
          'enum': PrayerNotification.fajr,
          'displayName': "Fajr",
        },
        {
          'name': "sunrise",
          'enum': PrayerNotification.sunrise,
          'displayName': "Sunrise",
        },
        {
          'name': "dhuhr",
          'enum': PrayerNotification.dhuhr,
          'displayName': "Dhuhr",
        },
        {'name': "asr", 'enum': PrayerNotification.asr, 'displayName': "Asr"},
        {
          'name': "maghrib",
          'enum': PrayerNotification.maghrib,
          'displayName': "Maghrib",
        },
        {
          'name': "isha",
          'enum': PrayerNotification.isha,
          'displayName': "Isha",
        },
      ];

      final timeFormatter = DateFormat('HH:mm');

      for (final prayerDetail in prayersToReschedule) {
        final prayerName = prayerDetail['name'] as String;
        final prayerEnum = prayerDetail['enum'] as PrayerNotification;
        final prayerDisplayName = prayerDetail['displayName'] as String;

        // Use PrayerService.getOffsettedPrayerTimeSync for consistent offset handling
        final DateTime? finalPrayerTime = _prayerService.getOffsettedPrayerTimeSync(
          prayerName,
          prayerTimesToday,
          state,
        );

        if (finalPrayerTime != null &&
            state.notifications[prayerEnum] == true) {
          final formattedTime = timeFormatter.format(finalPrayerTime);

          // Use different notification content based on prayer type
          String notificationTitle;
          String notificationBody;

          switch (prayerEnum) {
            case PrayerNotification.dhuhr:
            case PrayerNotification.asr:
            case PrayerNotification.maghrib:
            case PrayerNotification.isha:
              // These prayers will use custom Adhan sound
              notificationTitle = "$prayerDisplayName Adhan";
              notificationBody =
                  "Time for $prayerDisplayName prayer - $formattedTime";
              break;
            case PrayerNotification.fajr:
            case PrayerNotification.sunrise:
              // These prayers will use default system sound
              notificationTitle = "$prayerDisplayName Prayer";
              notificationBody =
                  "Time for $prayerDisplayName prayer - $formattedTime";
              break;
          }

          _logger.info(
            'Rescheduling notification for $prayerDisplayName',
            data: {
              'id': prayerEnum.index,
              'title': notificationTitle,
              'body': notificationBody,
              'time': finalPrayerTime.toIso8601String(),
              'prayerType': prayerEnum.name,
              'willUseAdhan': [
                PrayerNotification.dhuhr,
                PrayerNotification.asr,
                PrayerNotification.maghrib,
                PrayerNotification.isha,
              ].contains(prayerEnum),
              'selectedAdhan': state.azanSoundForStandardPrayers,
            },
          );

          await _notificationService.schedulePrayerNotification(
            id: prayerEnum.index,
            localizedTitle: notificationTitle,
            localizedBody: notificationBody,
            prayerTime: finalPrayerTime,
            isEnabled: true,
            appSettings: state,
          );
        } else {
          _logger.info(
            'Skipping reschedule for $prayerDisplayName',
            data: {
              'finalPrayerTimeNull': finalPrayerTime == null,
              'notificationDisabled':
                  finalPrayerTime != null &&
                  state.notifications[prayerEnum] != true,
              'prayerType': prayerEnum.name,
            },
          );
        }
      }

      _logger.info(
        'Completed rescheduling all prayer notifications',
        data: {
          'selectedAdhan': state.azanSoundForStandardPrayers,
          'enabledNotifications':
              state.notifications.entries
                  .where((entry) => entry.value)
                  .map((entry) => entry.key.name)
                  .toList(),
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error in _recalculateAndRescheduleNotifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _scheduleDhikrReminders() async {
    try {
      // Cancel any existing dhikr reminders first
      await _cancelDhikrReminders();

      // Schedule the first dhikr reminder
      final now = DateTime.now();
      final nextReminderTime = now.add(
        Duration(hours: state.dhikrReminderInterval),
      );

      await _notificationService.scheduleTesbihNotification(
        id: 9999, // Use a unique ID for dhikr reminders
        localizedTitle: 'Dhikr Reminder',
        localizedBody:
            '🤲 Time for your dhikr. Remember Allah with a peaceful heart.',
        scheduledTime: nextReminderTime,
        isEnabled: true,
        payload: jsonEncode({
          'type': 'dhikr_reminder',
          'intervalHours': state.dhikrReminderInterval,
          'scheduledTime': nextReminderTime.toIso8601String(),
        }),
      );

      _logger.info(
        'Dhikr reminder scheduled',
        data: {
          'nextReminder': nextReminderTime.toIso8601String(),
          'intervalHours': state.dhikrReminderInterval,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error scheduling dhikr reminders',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _cancelDhikrReminders() async {
    try {
      // Cancel the dhikr reminder notification
      await _notificationService.cancelNotification(9999);

      _logger.info('Dhikr reminders cancelled');
    } catch (e, s) {
      _logger.error(
        'Error cancelling dhikr reminders',
        error: e,
        stackTrace: s,
      );
    }
  }

  void dispose() {
    _permissionSubscription?.cancel();
    _saveSettingsDebounceTimer?.cancel();
  }
}
