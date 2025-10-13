import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/services/dhikr_reminder_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';

mixin NotificationSchedulingMixin on Notifier<AppSettings> {
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;

  NotificationService get _notificationService => ref.read(notificationServiceProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);
  PrayerService get _prayerService => ref.read(prayerServiceProvider);
  DhikrReminderService get _dhikrReminderService => ref.read(dhikrReminderServiceProvider);

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  bool get areAllPrayerNotificationsEnabled => PrayerNotification.values.every(
    (prayer) => state.notifications[prayer] ?? false,
  );

  void initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen(_updateNotificationPermissionStatus);
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (state.notificationPermissionStatus != status) {
      state = state.copyWith(notificationPermissionStatus: status);
      // Use debounced save for permission status as it may change frequently
      debouncedSaveSettings();
    }
  }

  Future<void> refreshNotificationPermissionStatus() async {
    await _notificationService.requestPermission();
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
      state = state.copyWith(notifications: newNotifications as Map<PrayerNotification, bool>?);

      await updateCriticalSetting(
        'notification_${prayer.name}',
        isEnabled,
        getter: (settings) => settings.notifications[prayer] ?? false,
        setter: (settings, value) {
          final newNotifs = Map<PrayerNotification, bool>.from(settings.notifications);
          newNotifs[prayer] = value;
          return settings.copyWith(notifications: newNotifs as Map<PrayerNotification, bool>?);
        },
      );
    }
  }

  Future<void> updateAllPrayerNotifications(bool isEnabled) async {
    final newNotifications = Map<PrayerNotification, bool>.from(
      state.notifications,
    );
    for (var prayer in PrayerNotification.values) {
      newNotifications[prayer] = isEnabled;
    }
    state = state.copyWith(notifications: newNotifications as Map<PrayerNotification, bool>?);
    await forceSaveSettings();
  }

  Future<void> updateAzanSound(String soundFileName) async {
    await updateCriticalSetting(
      'azanSound',
      soundFileName,
      getter: (settings) => settings.azanSoundForStandardPrayers,
      setter: (settings, value) => settings.copyWith(azanSoundForStandardPrayers: value),
    );
    await recalculateAndRescheduleNotifications();
  }

  Future<void> recalculateAndRescheduleNotifications() async {
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

      await _notificationService.cancelPrayerNotifications();

      final prayersToReschedule = _getPrayersToReschedule();
      final timeFormatter = DateFormat('HH:mm');

      for (final prayerDetail in prayersToReschedule) {
        await _schedulePrayerNotification(
          prayerDetail,
          prayerTimesToday,
          timeFormatter,
        );
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

  List<Map<String, dynamic>> _getPrayersToReschedule() {
    return [
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
  }

  Future<void> _schedulePrayerNotification(
    Map<String, dynamic> prayerDetail,
    adhan.PrayerTimes prayerTimesToday,
    DateFormat timeFormatter,
  ) async {
    final prayerName = prayerDetail['name'] as String;
    final prayerEnum = prayerDetail['enum'] as PrayerNotification;
    final prayerDisplayName = prayerDetail['displayName'] as String;

    final DateTime? finalPrayerTime = _prayerService.getOffsettedPrayerTimeSync(
      prayerName,
      prayerTimesToday,
      state,
    );

    if (finalPrayerTime != null &&
        state.notifications[prayerEnum] == true) {
      final formattedTime = timeFormatter.format(finalPrayerTime);

      final notificationContent = _getNotificationContent(prayerEnum, prayerDisplayName, formattedTime);

      _logger.info(
        'Rescheduling notification for $prayerDisplayName',
        data: {
          'id': prayerEnum.index,
          'title': notificationContent['title'],
          'body': notificationContent['body'],
          'time': finalPrayerTime.toIso8601String(),
          'prayerType': prayerEnum.name,
          'willUseAdhan': _willUseAdhan(prayerEnum),
          'selectedAdhan': state.azanSoundForStandardPrayers,
        },
      );

      await _notificationService.schedulePrayerNotification(
        id: prayerEnum.index,
        localizedTitle: notificationContent['title']!,
        localizedBody: notificationContent['body']!,
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

  Map<String, String> _getNotificationContent(
    PrayerNotification prayerEnum,
    String prayerDisplayName,
    String formattedTime,
  ) {
    if (_willUseAdhan(prayerEnum)) {
      return {
        'title': "$prayerDisplayName Adhan",
        'body': "Time for $prayerDisplayName prayer - $formattedTime",
      };
    } else {
      return {
        'title': "$prayerDisplayName Prayer",
        'body': "Time for $prayerDisplayName prayer - $formattedTime",
      };
    }
  }

  bool _willUseAdhan(PrayerNotification prayerEnum) {
    return [
      PrayerNotification.dhuhr,
      PrayerNotification.asr,
      PrayerNotification.maghrib,
      PrayerNotification.isha,
    ].contains(prayerEnum);
  }

  Future<void> scheduleDhikrReminders() async {
    try {
      await _dhikrReminderService.scheduleDhikrReminders(state.dhikrReminderInterval);

      _logger.info(
        'Dhikr reminders scheduled via DhikrReminderService',
        data: {
          'intervalHours': state.dhikrReminderInterval,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error scheduling dhikr reminders via DhikrReminderService',
        error: e,
        stackTrace: s,
      );
    }
  }

  void disposeNotifications() {
    _permissionSubscription?.cancel();
  }

  // Abstract methods
  void debouncedSaveSettings();
  Future<void> forceSaveSettings();
  Future<void> updateCriticalSetting<T>(
    String settingName,
    T value, {
    required T Function(AppSettings) getter,
    required AppSettings Function(AppSettings, T) setter,
  });
}