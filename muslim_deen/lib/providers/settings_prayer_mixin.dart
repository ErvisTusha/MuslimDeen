/// Prayer calculation settings mixin for managing prayer-related configuration
///
/// This mixin provides functionality for managing prayer calculation settings
/// including offsets, calculation methods, time formats, and other prayer-related
/// preferences. It's designed to be mixed into the main SettingsNotifier to
/// provide focused prayer settings management.
///
/// Architecture Pattern: Mixin for Separation of Concerns
///
/// Why This Mixin:
/// - Isolates prayer-specific settings logic from other settings concerns
/// - Enables focused testing of prayer settings functionality
/// - Provides reusable prayer settings management for other notifiers
/// - Maintains clean code organization by functionality domain
/// - Follows single responsibility principle for prayer calculations
///
/// Key Features:
/// - Prayer time offset management for each prayer
/// - Calculation method and madhab configuration
/// - Time format and date format preferences
/// - Dhikr reminder settings management
/// - Automatic notification rescheduling on critical changes
///
/// State Impact:
/// - All prayer setting changes trigger notification rescheduling
/// - Critical settings use immediate persistence
/// - Non-critical settings use debounced persistence
/// - Settings changes affect prayer time calculations throughout the app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/service_providers.dart';

/// Enumeration of prayer types for offset management
///
/// This enum defines all prayer types that can have custom time offsets.
/// Offsets allow users to adjust prayer times by minutes to account for
/// local variations, personal preferences, or mosque-specific timings.
///
/// Prayer Types:
/// - fajr: Pre-dawn prayer
/// - sunrise: Sunrise time (not a prayer but used for tracking)
/// - dhuhr: Midday prayer
/// - asr: Afternoon prayer
/// - maghrib: Sunset prayer
/// - isha: Night prayer
enum PrayerType { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Mixin providing prayer calculation settings management
///
/// This mixin encapsulates all prayer-related settings functionality including
/// offset management, calculation parameters, and prayer-specific preferences.
/// It automatically handles notification rescheduling when critical prayer
/// settings change.
///
/// Usage:
/// ```dart
/// class SettingsNotifier extends Notifier<AppSettings>
///     with PrayerCalculationMixin {
///   // Inherits all prayer settings methods
/// }
/// ```
///
/// Design Patterns:
/// - Template Method: Defines abstract methods for persistence and notifications
/// - Strategy Pattern: Different calculation methods can be selected
/// - Observer Pattern: Settings changes trigger notification updates
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
