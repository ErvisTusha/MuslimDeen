import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/service_providers.dart';

enum PrayerType {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha,
}

mixin PrayerCalculationMixin on Notifier<AppSettings> {
  Future<void> updatePrayerOffset(PrayerType prayer, int offsetMinutes) async {
    final currentOffset = _getCurrentOffset(prayer);
    if (currentOffset != offsetMinutes) {
      state = _setOffset(prayer, offsetMinutes);
      await forceSaveSettings();
      await recalculateAndRescheduleNotifications();
    }
  }

  int _getCurrentOffset(PrayerType prayer) {
    switch (prayer) {
      case PrayerType.fajr:
        return state.fajrOffset;
      case PrayerType.sunrise:
        return state.sunriseOffset;
      case PrayerType.dhuhr:
        return state.dhuhrOffset;
      case PrayerType.asr:
        return state.asrOffset;
      case PrayerType.maghrib:
        return state.maghribOffset;
      case PrayerType.isha:
        return state.ishaOffset;
    }
  }

  AppSettings _setOffset(PrayerType prayer, int offsetMinutes) {
    switch (prayer) {
      case PrayerType.fajr:
        return state.copyWith(fajrOffset: offsetMinutes);
      case PrayerType.sunrise:
        return state.copyWith(sunriseOffset: offsetMinutes);
      case PrayerType.dhuhr:
        return state.copyWith(dhuhrOffset: offsetMinutes);
      case PrayerType.asr:
        return state.copyWith(asrOffset: offsetMinutes);
      case PrayerType.maghrib:
        return state.copyWith(maghribOffset: offsetMinutes);
      case PrayerType.isha:
        return state.copyWith(ishaOffset: offsetMinutes);
    }
  }

  Future<void> updateTimeFormat(TimeFormat format) async {
    if (state.timeFormat != format) {
      state = state.copyWith(timeFormat: format);
      debouncedSaveSettings();
    }
  }

  Future<void> updateCalculationMethod(String method) async {
    await updateCriticalSetting(
      'calculationMethod',
      method,
      getter: (settings) => settings.calculationMethod,
      setter: (settings, value) => settings.copyWith(calculationMethod: value),
    );
    await recalculateAndRescheduleNotifications();
  }

  Future<void> updateMadhab(String madhab) async {
    await updateCriticalSetting(
      'madhab',
      madhab,
      getter: (settings) => settings.madhab,
      setter: (settings, value) => settings.copyWith(madhab: value),
    );
    await recalculateAndRescheduleNotifications();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    if (state.themeMode != mode) {
      state = state.copyWith(themeMode: mode);
      debouncedSaveSettings();
    }
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    if (state.dateFormatOption != option) {
      state = state.copyWith(dateFormatOption: option);
      debouncedSaveSettings();
    }
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
    await forceSaveSettings();

    if (enabled) {
      await scheduleDhikrReminders();
    } else {
      await _cancelDhikrReminders();
    }
  }

  Future<void> updateDhikrReminderInterval(int intervalHours) async {
    state = state.copyWith(dhikrReminderInterval: intervalHours);
    await forceSaveSettings();

    if (state.dhikrRemindersEnabled) {
      await _cancelDhikrReminders();
      await scheduleDhikrReminders();
    }
  }

  Future<void> _cancelDhikrReminders() async {
    try {
      final dhikrReminderService = ref.read(dhikrReminderServiceProvider);
      await dhikrReminderService.cancelDhikrReminders();
      final logger = ref.read(loggerServiceProvider);
      logger.info('Dhikr reminders cancelled via DhikrReminderService');
    } catch (e, s) {
      final logger = ref.read(loggerServiceProvider);
      logger.error(
        'Error cancelling dhikr reminders via DhikrReminderService',
        error: e,
        stackTrace: s,
      );
    }
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
  Future<void> recalculateAndRescheduleNotifications();
  Future<void> scheduleDhikrReminders();
}