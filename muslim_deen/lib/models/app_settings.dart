import 'package:flutter/material.dart';

import 'package:muslim_deen/services/notification_service.dart';

enum PrayerNotification { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum TimeFormat { twelveHour, twentyFourHour }

enum DateFormatOption { dayMonthYear, monthDayYear, yearMonthDay }

class AppSettings {
  final String calculationMethod;
  final String madhab;
  final ThemeMode themeMode;
  final String language;
  final Map<PrayerNotification, bool> notifications;
  final NotificationPermissionStatus notificationPermissionStatus;
  final TimeFormat timeFormat;
  final DateFormatOption dateFormatOption;
  final String azanSoundForStandardPrayers;
  final int fajrOffset;
  final int sunriseOffset;
  final int dhuhrOffset;
  final int asrOffset;
  final int maghribOffset;
  final int ishaOffset;

  AppSettings({
    this.calculationMethod = 'MuslimWorldLeague',
    this.madhab = 'hanafi',
    this.themeMode = ThemeMode.system,
    this.language = 'en',
    Map<PrayerNotification, bool>? notifications,
    this.notificationPermissionStatus =
        NotificationPermissionStatus.notDetermined,
    this.timeFormat = TimeFormat.twelveHour,
    this.dateFormatOption = DateFormatOption.dayMonthYear,
    this.azanSoundForStandardPrayers = 'makkah_adhan.mp3',
    this.fajrOffset = 0,
    this.sunriseOffset = 0,
    this.dhuhrOffset = 0,
    this.asrOffset = 0,
    this.maghribOffset = 0,
    this.ishaOffset = 0,
  }) : notifications =
           notifications ??
           {for (var prayer in PrayerNotification.values) prayer: true};

  AppSettings copyWith({
    String? calculationMethod,
    String? madhab,
    ThemeMode? themeMode,
    String? language,
    Map<PrayerNotification, bool>? notifications,
    NotificationPermissionStatus? notificationPermissionStatus,
    TimeFormat? timeFormat,
    DateFormatOption? dateFormatOption,
    String? azanSoundForStandardPrayers,
    int? fajrOffset,
    int? sunriseOffset,
    int? dhuhrOffset,
    int? asrOffset,
    int? maghribOffset,
    int? ishaOffset,
  }) {
    return AppSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      notifications: notifications ?? Map.from(this.notifications),
      notificationPermissionStatus:
          notificationPermissionStatus ?? this.notificationPermissionStatus,
      timeFormat: timeFormat ?? this.timeFormat,
      dateFormatOption: dateFormatOption ?? this.dateFormatOption,
      azanSoundForStandardPrayers:
          azanSoundForStandardPrayers ?? this.azanSoundForStandardPrayers,
      fajrOffset: fajrOffset ?? this.fajrOffset,
      sunriseOffset: sunriseOffset ?? this.sunriseOffset,
      dhuhrOffset: dhuhrOffset ?? this.dhuhrOffset,
      asrOffset: asrOffset ?? this.asrOffset,
      maghribOffset: maghribOffset ?? this.maghribOffset,
      ishaOffset: ishaOffset ?? this.ishaOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'themeMode': themeMode.index,
      'language': language,
      'notificationPermissionStatus': notificationPermissionStatus.index,
      'notifications': notifications.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'timeFormat': timeFormat.name,
      'dateFormatOption': dateFormatOption.name,
      'azanSoundForStandardPrayers': azanSoundForStandardPrayers,
      'fajrOffset': fajrOffset,
      'sunriseOffset': sunriseOffset,
      'dhuhrOffset': dhuhrOffset,
      'asrOffset': asrOffset,
      'maghribOffset': maghribOffset,
      'ishaOffset': ishaOffset,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final validNotificationKeys =
        PrayerNotification.values.map((e) => e.name).toSet();
    final notificationsJson = json['notifications'] as Map<String, dynamic>;

    return AppSettings(
      calculationMethod: json['calculationMethod'] as String,
      madhab: json['madhab'] as String,
      themeMode: () {
        // Use a closure to handle logic cleanly inline
        final index = json['themeMode'] as int?;
        if (index != null && index >= 0 && index < ThemeMode.values.length) {
          return ThemeMode.values[index];
        }
        return ThemeMode.system;
      }(),
      language: json['language'] as String,
      notificationPermissionStatus: () {
        final index = json['notificationPermissionStatus'] as int?;
        if (index != null &&
            index >= 0 &&
            index < NotificationPermissionStatus.values.length) {
          return NotificationPermissionStatus.values[index];
        }
        return NotificationPermissionStatus.notDetermined;
      }(),
      notifications: Map.fromEntries(
        notificationsJson.entries
            .where(
              (entry) => validNotificationKeys.contains(entry.key),
            ) // Filter valid keys
            .map(
              (entry) => MapEntry(
                PrayerNotification.values.firstWhere(
                  (e) => e.name == entry.key,
                ), // Now safe
                entry.value as bool,
              ),
            ),
      ),
      timeFormat: () {
        final name = json['timeFormat'] as String?;
        if (name != null && TimeFormat.values.any((e) => e.name == name)) {
          return TimeFormat.values.firstWhere((e) => e.name == name);
        }
        return TimeFormat.twelveHour;
      }(),
      dateFormatOption: () {
        final name = json['dateFormatOption'] as String?;
        if (name != null &&
            DateFormatOption.values.any((e) => e.name == name)) {
          return DateFormatOption.values.firstWhere((e) => e.name == name);
        }
        return DateFormatOption.dayMonthYear;
      }(),
      azanSoundForStandardPrayers:
          json['azanSoundForStandardPrayers'] as String? ?? 'makkah_adhan.mp3',
      fajrOffset: json['fajrOffset'] as int? ?? 0,
      sunriseOffset: json['sunriseOffset'] as int? ?? 0,
      dhuhrOffset: json['dhuhrOffset'] as int? ?? 0,
      asrOffset: json['asrOffset'] as int? ?? 0,
      maghribOffset: json['maghribOffset'] as int? ?? 0,
      ishaOffset: json['ishaOffset'] as int? ?? 0,
    );
  }

  static AppSettings get defaults => AppSettings();
}
