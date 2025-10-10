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

  @override
  AppSettings build() {
    _storage = ref.read(storageServiceProvider);
    _notificationService = ref.read(notificationServiceProvider);
    _logger = ref.read(loggerServiceProvider);
    _prayerService = ref.read(prayerServiceProvider);
    _loadSettings();
    _initializePermissionListener();
    return AppSettings.defaults;
  }

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  void _initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen(_updateNotificationPermissionStatus);
  }

  Future<void> _loadSettings() async {
    try {
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null) {
        state = AppSettings.fromJson(
          jsonDecode(storedSettings) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      _logger.error('Error loading settings', error: e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.saveData(_settingsKey, jsonEncode(state.toJson()));
    } catch (e) {
      _logger.error('Error saving settings', error: e);
    }
  }

  void _debouncedSaveSettings() {
    _saveSettingsDebounceTimer?.cancel();
    _saveSettingsDebounceTimer = Timer(_saveSettingsDebounceDuration, () {
      _saveSettings();
      _logger.debug("Debounced _saveSettings executed.");
    });
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (state.notificationPermissionStatus != status) {
      state = state.copyWith(notificationPermissionStatus: status);
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
    _debouncedSaveSettings();
  }

  Future<void> updateCalculationMethod(String method) async {
    state = state.copyWith(calculationMethod: method);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateMadhab(String madhab) async {
    state = state.copyWith(madhab: madhab);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    _debouncedSaveSettings();
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    state = state.copyWith(dateFormatOption: option);
    _debouncedSaveSettings();
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
    _debouncedSaveSettings();
    // No need to call _recalculateAndRescheduleNotifications here as it's handled by HomeView's listener
    // when notification settings change. HomeView will call _scheduleAllPrayerNotifications.
  }

  Future<void> updateAzanSound(String soundFileName) async {
    state = state.copyWith(azanSoundForStandardPrayers: soundFileName);
    _debouncedSaveSettings();
    // Reschedule notifications if sound changed, as it's part of the notification content/payload
    await _recalculateAndRescheduleNotifications();
  }

  // Removed updateCalculationMethod as it's unused
  // Removed updateAzanSoundForStandardPrayers as it's unused
  // Other methods like updateMadhab, updateThemeMode, updateLanguage, updateTimeFormat,
  // updateDateFormatOption, setPrayerNotification, checkNotificationPermissionStatus,
  // and all individual offset update methods were already removed in a previous refactoring pass
  // or were not present in the version of the file read for this operation.
  // The method loadSettings() is already private (_loadSettings) and correctly called.

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
      await _notificationService.cancelAllNotifications();

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
