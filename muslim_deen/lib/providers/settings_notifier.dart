import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:adhan_dart/adhan_dart.dart' as adhan;

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';
import '../services/prayer_service.dart'; // Added PrayerService import

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  final StorageService _storage;
  final NotificationService _notificationService;
  final LoggerService _logger;
  final PrayerService _prayerService; // Added PrayerService instance
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;
  Timer? _saveSettingsDebounceTimer;
  static const Duration _saveSettingsDebounceDuration = Duration(milliseconds: 750); // Increased debounce time

  SettingsNotifier(
    this._storage,
    this._notificationService,
    this._logger,
    this._prayerService, // Added PrayerService to constructor
  ) : super(AppSettings.defaults) {
    loadSettings();
    _initializePermissionListener();
  }

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  void _initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen(_updateNotificationPermissionStatus);
  }

  Future<void> loadSettings() async {
    try {
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null) {
        state = AppSettings.fromJson(jsonDecode(storedSettings) as Map<String, dynamic>);
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

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    _debouncedSaveSettings();
  }

  Future<void> updateTimeFormat(TimeFormat format) async {
    state = state.copyWith(timeFormat: format);
    _debouncedSaveSettings();
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    state = state.copyWith(dateFormatOption: option);
    _debouncedSaveSettings();
  }

  Future<void> setPrayerNotification(
    PrayerNotification prayer,
    bool enabled,
  ) async {
    if (enabled && _notificationService.isBlocked) {
      // Don't update if notifications are blocked and trying to enable
      return;
    }

    final updatedNotifications = Map<PrayerNotification, bool>.from(
      state.notifications,
    );
    updatedNotifications[prayer] = enabled;
    state = state.copyWith(notifications: updatedNotifications);
    _debouncedSaveSettings();
    // Notification rescheduling is typically handled by HomeView's settings listener
    // or _recalculateAndRescheduleNotifications if called directly by an offset change.
    // For a simple toggle, HomeView's listener should pick it up.
    // If direct reschedule is needed here, call: await _recalculateAndRescheduleNotifications();
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (state.notificationPermissionStatus != status) {
      state = state.copyWith(notificationPermissionStatus: status);
      _debouncedSaveSettings();
    }
  }

  Future<void> updateAzanSoundForStandardPrayers(String sound) async {
    state = state.copyWith(azanSoundForStandardPrayers: sound);
    _debouncedSaveSettings();
    // This change might require rescheduling notifications if the sound is part of the notification payload.
    // Assuming NotificationService handles this or _recalculateAndRescheduleNotifications is called if needed.
  }

  Future<void> checkNotificationPermissionStatus() async {
    await _notificationService.checkPermissionStatus();
  }

  Future<void> updateFajrOffset(int offset) async {
    state = state.copyWith(fajrOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateSunriseOffset(int offset) async {
    state = state.copyWith(sunriseOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateDhuhrOffset(int offset) async {
    state = state.copyWith(dhuhrOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateAsrOffset(int offset) async {
    state = state.copyWith(asrOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateMaghribOffset(int offset) async {
    state = state.copyWith(maghribOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> updateIshaOffset(int offset) async {
    state = state.copyWith(ishaOffset: offset);
    _debouncedSaveSettings();
    await _recalculateAndRescheduleNotifications();
  }

  Future<void> _recalculateAndRescheduleNotifications() async {
    try {
      final adhan.PrayerTimes? prayerTimesToday =
          await _prayerService.calculatePrayerTimesForToday(state);

      if (prayerTimesToday == null) {
        _logger.error(
          'Failed to calculate prayer times for rescheduling notifications. PrayerTimes object is null.',
          data: {'settings': state.toJson()},
        );
        return; // Skip scheduling
      }

      final prayersToReschedule = [
        {'name': "fajr", 'enum': PrayerNotification.fajr, 'displayName': "Fajr"},
        {'name': "sunrise", 'enum': PrayerNotification.sunrise, 'displayName': "Sunrise"},
        {'name': "dhuhr", 'enum': PrayerNotification.dhuhr, 'displayName': "Dhuhr"},
        {'name': "asr", 'enum': PrayerNotification.asr, 'displayName': "Asr"},
        {'name': "maghrib", 'enum': PrayerNotification.maghrib, 'displayName': "Maghrib"},
        {'name': "isha", 'enum': PrayerNotification.isha, 'displayName': "Isha"},
      ];

      final timeFormatter = DateFormat('HH:mm');

      for (final prayerDetail in prayersToReschedule) {
        final prayerName = prayerDetail['name'] as String;
        final prayerEnum = prayerDetail['enum'] as PrayerNotification;
        final prayerDisplayName = prayerDetail['displayName'] as String;

        DateTime? rawTime;
        int offsetMinutes = 0;

        switch (prayerName) {
          case 'fajr':
            rawTime = prayerTimesToday.fajr;
            offsetMinutes = state.fajrOffset;
            break;
          case 'sunrise':
            rawTime = prayerTimesToday.sunrise;
            offsetMinutes = state.sunriseOffset;
            break;
          case 'dhuhr':
            rawTime = prayerTimesToday.dhuhr;
            offsetMinutes = state.dhuhrOffset;
            break;
          case 'asr':
            rawTime = prayerTimesToday.asr;
            offsetMinutes = state.asrOffset;
            break;
          case 'maghrib':
            rawTime = prayerTimesToday.maghrib;
            offsetMinutes = state.maghribOffset;
            break;
          case 'isha':
            rawTime = prayerTimesToday.isha;
            offsetMinutes = state.ishaOffset;
            break;
          default:
            _logger.warning('Unknown prayer name in _recalculateAndRescheduleNotifications: $prayerName');
            continue;
        }

        DateTime? finalPrayerTime;
        if (rawTime != null) {
          finalPrayerTime = rawTime.add(Duration(minutes: offsetMinutes));
        }

        if (finalPrayerTime != null && state.notifications[prayerEnum] == true) {
          final formattedTime = timeFormatter.format(finalPrayerTime);
          final notificationTitle = "$prayerDisplayName Azan";
          final notificationBody = "$prayerDisplayName Azan at $formattedTime";

          _logger.info(
            'Rescheduling notification for $prayerDisplayName',
            data: {
              'id': prayerEnum.index,
              'title': notificationTitle,
              'body': notificationBody,
              'time': finalPrayerTime.toIso8601String(),
              'sound': state.azanSoundForStandardPrayers,
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
              'notificationDisabled': finalPrayerTime != null && state.notifications[prayerEnum] != true,
              'rawTime': rawTime?.toIso8601String(),
              'offsetMinutes': offsetMinutes,
            },
          );
        }
      }
    } catch (e, s) {
      _logger.error(
        'Error in _recalculateAndRescheduleNotifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  void dispose() {
    _permissionSubscription?.cancel();
    _saveSettingsDebounceTimer?.cancel();
    super.dispose();
  }
}
