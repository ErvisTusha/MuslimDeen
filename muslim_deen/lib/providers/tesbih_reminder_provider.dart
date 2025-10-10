import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

class TesbihReminderState {
  final TimeOfDay? reminderTime;
  final bool reminderEnabled;
  final bool isLoading;

  TesbihReminderState({
    this.reminderTime,
    this.reminderEnabled = false,
    this.isLoading = false,
  });

  TesbihReminderState copyWith({
    TimeOfDay? reminderTime,
    bool? reminderEnabled,
    bool? isLoading,
  }) {
    return TesbihReminderState(
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TesbihReminderNotifier extends Notifier<TesbihReminderState> {
  late final NotificationService _notificationService;
  late final StorageService _storageService;
  late final LoggerService _logger;

  @override
  TesbihReminderState build() {
    _notificationService = ref.read(notificationServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    _logger = ref.read(loggerServiceProvider);
    _loadSettings();
    return TesbihReminderState();
  }

  Future<void> _loadSettings() async {
    try {
      final reminderHour =
          _storageService.getData('tesbih_reminder_hour') as int?;
      final reminderMinute =
          _storageService.getData('tesbih_reminder_minute') as int?;
      final enabled =
          _storageService.getData('tesbih_reminder_enabled') as bool?;

      if (reminderHour != null && reminderMinute != null) {
        final reminderTime = TimeOfDay(
          hour: reminderHour,
          minute: reminderMinute,
        );
        state = state.copyWith(
          reminderTime: reminderTime,
          reminderEnabled: enabled ?? false,
        );

        if (enabled == true) {
          _scheduleReminder(reminderTime);
        }
      }
    } catch (e) {
      _logger.error('Error loading tesbih reminder settings', error: e);
    }
  }

  /// Helper method to save reminder settings
  Future<void> _saveReminderSettings(int hour, int minute, bool enabled) async {
    await _storageService.saveData('tesbih_reminder_hour', hour);
    await _storageService.saveData('tesbih_reminder_minute', minute);
    await _storageService.saveData('tesbih_reminder_enabled', enabled);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(isLoading: true);

    try {
      await _saveReminderSettings(time.hour, time.minute, true);
      await _scheduleReminder(time);

      state = state.copyWith(
        reminderTime: time,
        reminderEnabled: true,
        isLoading: false,
      );
    } catch (e) {
      _logger.error('Error setting reminder time', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> toggleReminder(bool enabled) async {
    state = state.copyWith(isLoading: true);

    try {
      await _storageService.saveData('tesbih_reminder_enabled', enabled);

      if (enabled && state.reminderTime != null) {
        await _scheduleReminder(state.reminderTime!);
      } else {
        await _notificationService.cancelNotification(9876);
      }

      state = state.copyWith(reminderEnabled: enabled, isLoading: false);
    } catch (e) {
      _logger.error('Error toggling reminder', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _scheduleReminder(TimeOfDay reminderTime) async {
    try {
      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        reminderTime.hour,
        reminderTime.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      await _notificationService.schedulePrayerNotification(
        id: 9876,
        localizedTitle:
            "Tasbih Reminder", // Provide localization in implementation
        localizedBody:
            "🤲 Time for your dhikr. Remember Allah with a peaceful heart.",
        prayerTime: scheduledDateTime,
        isEnabled: true,
      );

      _logger.info(
        'Tesbih reminder scheduled for ${scheduledDateTime.toIso8601String()}',
      );
    } catch (e) {
      _logger.error('Error scheduling tesbih reminder', error: e);
      rethrow;
    }
  }
}

final tesbihReminderProvider =
    NotifierProvider<TesbihReminderNotifier, TesbihReminderState>(
      TesbihReminderNotifier.new,
    );
