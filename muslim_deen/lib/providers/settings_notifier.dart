import 'dart:async';
import 'dart:convert';

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
    milliseconds: 750,
  ); // Increased debounce time
  bool _isInitialized = false;

  @override
  AppSettings build() {
    _storage = ref.read(storageServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);
    _logger = ref.read(loggerServiceProvider);
    _prayerService = ref.read(prayerServiceProvider);

    // Initialize settings synchronously if possible, otherwise async
    _initializeSettings();
    _initializePermissionListener();

    // Return default settings initially, will be updated after loading
    return AppSettings.defaults;
  }

  Future<void> _initializeSettings() async {
    if (_isInitialized) return;

    try {
      // Try to load settings synchronously first
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null) {
        state = AppSettings.fromJson(
          jsonDecode(storedSettings) as Map<String, dynamic>,
        );
        _logger.info("Settings loaded successfully during initialization");
      } else {
        // If no stored settings, save the defaults
        await _saveSettings();
        _logger.info("No stored settings found, saved defaults");
      }
      _isInitialized = true;
    } catch (e) {
      _logger.error('Error initializing settings', error: e);
      // Ensure defaults are saved if loading fails
      await _saveSettings();
      _isInitialized = true;
    }
  }

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  void _initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen(_updateNotificationPermissionStatus);
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.saveData(_settingsKey, jsonEncode(state.toJson()));
      _logger.debug("Settings saved successfully");
    } catch (e) {
      _logger.error('Error saving settings', error: e);
      // Retry saving after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          await _storage.saveData(_settingsKey, jsonEncode(state.toJson()));
          _logger.info("Settings retry save successful");
        } catch (retryError) {
          _logger.error('Settings retry save failed', error: retryError);
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
    state = state.copyWith(timeFormat: format);
    await _forceSaveSettings();
  }

  Future<void> updateCalculationMethod(String method) async {
    state = state.copyWith(calculationMethod: method);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateMadhab(String madhab) async {
    state = state.copyWith(madhab: madhab);
    await _forceSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _forceSaveSettings();
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    state = state.copyWith(dateFormatOption: option);
    await _forceSaveSettings();
  }

  Future<void> updatePrayerNotification(
    PrayerNotification prayer,
    bool isEnabled,
  ) async {
    final newNotifications = Map<PrayerNotification, bool>.from(
      state.notifications,
    );
    newNotifications[prayer] = isEnabled;
    state = state.copyWith(notifications: newNotifications);
    await _forceSaveSettings();
    // No need to call _recalculateAndRescheduleNotifications here as it's handled by HomeView's listener
    // when notification settings change. HomeView will call _scheduleAllPrayerNotifications.
  }

  Future<void> updateAzanSound(String soundFileName) async {
    state = state.copyWith(azanSoundForStandardPrayers: soundFileName);
    await _forceSaveSettings();
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
    state = state.copyWith(language: language);
    await _forceSaveSettings();
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

        // Use PrayerService.getOffsettedPrayerTime for consistent offset handling
        final DateTime? finalPrayerTime = _prayerService.getOffsettedPrayerTime(
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

  void dispose() {
    _permissionSubscription?.cancel();
    _saveSettingsDebounceTimer?.cancel();
  }
}
