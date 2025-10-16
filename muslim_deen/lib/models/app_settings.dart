import 'package:flutter/material.dart';

/// Enumerations for prayer notification types
/// Represents each of the five daily prayers plus sunrise
enum PrayerNotification { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Time format preferences for displaying prayer times
enum TimeFormat { twelveHour, twentyFourHour }

/// Date format options for displaying dates throughout the app
enum DateFormatOption { dayMonthYear, monthDayYear, yearMonthDay }

/// Notification permission status tracking
/// Used to manage notification permissions and user preferences
enum NotificationPermissionStatus { notDetermined, granted, denied, restricted }

/// Central application configuration model
/// 
/// This model encapsulates all user-configurable settings for the MuslimDeen app.
/// It serves as the single source of truth for app behavior, preferences, and
/// customization options. The model is designed to be immutable with a copyWith
/// pattern for safe state updates.
/// 
/// Key responsibilities:
/// - Store user preferences for prayer calculations and notifications
/// - Manage UI theme and localization settings
/// - Control audio and reminder configurations
/// - Maintain notification permission states
/// 
/// Serialization:
/// - Uses toJson() for persistent storage (SharedPreferences/Database)
/// - Uses fromJson() for deserialization with safe defaults
/// - Handles enum conversions with validation and fallbacks
/// 
/// Performance considerations:
/// - Immutable design prevents accidental mutations
/// - Lazy initialization of notification map with default values
/// - Efficient copyWith for partial updates without full reconstruction
class AppSettings {
  /// Prayer calculation method (e.g., 'Muslim World League', 'Umm Al-Qura')
  /// Valid values depend on the adhan package implementation
  final String calculationMethod;
  
  /// Islamic legal school for prayer time calculations
  /// Valid values: 'hanafi', 'shafi', 'maliki', 'hanbali'
  final String madhab;
  
  /// UI theme mode preference
  /// Uses Flutter's ThemeMode enum for system/light/dark themes
  final ThemeMode themeMode;
  
  /// Language code for app localization
  /// Should be a valid ISO 639-1 language code (e.g., 'en', 'ar', 'ur')
  final String language;
  
  /// Notification preferences for each prayer time
  /// Maps prayer types to boolean enabled/disabled states
  /// Default: all prayers enabled
  final Map<PrayerNotification, bool> notifications;
  
  /// Current notification permission status
  /// Tracks whether app has permission to show notifications
  final NotificationPermissionStatus notificationPermissionStatus;
  
  /// Time display format preference
  /// Determines whether times are shown in 12-hour (AM/PM) or 24-hour format
  final TimeFormat timeFormat;
  
  /// Date display format preference
  /// Controls how dates are formatted throughout the app
  final DateFormatOption dateFormatOption;
  
  /// Audio file name for standard prayer adhan notifications
  /// Should correspond to a file in the assets/audio directory
  final String azanSoundForStandardPrayers;
  
  /// Prayer time adjustments in minutes
  /// Positive values delay the prayer time, negative values advance it
  /// These allow users to customize prayer times based on local observations
  
  /// Fajr prayer time adjustment in minutes (-30 to +30 recommended range)
  final int fajrOffset;
  
  /// Sunrise time adjustment in minutes (-30 to +30 recommended range)
  final int sunriseOffset;
  
  /// Dhuhr prayer time adjustment in minutes (-30 to +30 recommended range)
  final int dhuhrOffset;
  
  /// Asr prayer time adjustment in minutes (-30 to +30 recommended range)
  final int asrOffset;
  
  /// Maghrib prayer time adjustment in minutes (-30 to +30 recommended range)
  final int maghribOffset;
  
  /// Isha prayer time adjustment in minutes (-30 to +30 recommended range)
  final int ishaOffset;
  
  /// Whether dhikr (remembrance) reminders are enabled
  /// Controls periodic notifications for spiritual reminders
  final bool dhikrRemindersEnabled;
  
  /// Interval between dhikr reminders in hours
  /// Valid range: 1-24 hours
  final int dhikrReminderInterval;

  /// Creates a new AppSettings instance with default or provided values
  /// 
  /// Parameters:
  /// - [calculationMethod]: Prayer calculation method, defaults to 'Auto'
  /// - [madhab]: Islamic legal school, defaults to 'hanafi'
  /// - [themeMode]: UI theme, defaults to system theme
  /// - [language]: Language code, defaults to 'en'
  /// - [notifications]: Prayer notification preferences, defaults to all enabled
  /// - [notificationPermissionStatus]: Permission status, defaults to notDetermined
  /// - [timeFormat]: Time display format, defaults to 12-hour
  /// - [dateFormatOption]: Date display format, defaults to dayMonthYear
  /// - [azanSoundForStandardPrayers]: Adhan audio file, defaults to 'makkah_adhan.mp3'
  /// - [fajrOffset] through [ishaOffset]: Prayer time adjustments, defaults to 0
  /// - [dhikrRemindersEnabled]: Dhikr reminders toggle, defaults to false
  /// - [dhikrReminderInterval]: Reminder interval in hours, defaults to 4
  AppSettings({
    this.calculationMethod = 'Auto',
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
    this.dhikrRemindersEnabled = false,
    this.dhikrReminderInterval = 4,
  }) : notifications =
           notifications ??
           Map.fromEntries(PrayerNotification.values.map((prayer) => MapEntry(prayer, true)));

  /// Creates a copy of this AppSettings with specified fields replaced
  /// 
  /// This method implements the immutable update pattern, allowing safe
  /// modification of settings without affecting the original instance.
  /// Only the provided parameters are updated; all others retain their
  /// original values.
  /// 
  /// Parameters:
  /// - All fields are optional and nullable
  /// - When a parameter is null, the original value is preserved
  /// - When provided, the new value replaces the original
  /// 
  /// Returns: A new AppSettings instance with updated values
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
    bool? dhikrRemindersEnabled,
    int? dhikrReminderInterval,
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
      dhikrRemindersEnabled:
          dhikrRemindersEnabled ?? this.dhikrRemindersEnabled,
      dhikrReminderInterval:
          dhikrReminderInterval ?? this.dhikrReminderInterval,
    );
  }

  /// Serializes this AppSettings instance to a JSON map
  /// 
  /// This method converts the settings object into a format suitable for
  /// persistent storage in databases, SharedPreferences, or network transmission.
  /// 
  /// Serialization details:
  /// - ThemeMode and enums are converted to their index values
  /// - PrayerNotification enum keys are converted to string names
  /// - All primitive types are stored directly
  /// - DateTime objects are not present in this model
  /// 
  /// Returns: A Map<String, dynamic> containing all settings data
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
      'dhikrRemindersEnabled': dhikrRemindersEnabled,
      'dhikrReminderInterval': dhikrReminderInterval,
    };
  }

  /// Deserializes an AppSettings instance from a JSON map
  /// 
  /// This factory method reconstructs an AppSettings object from stored data,
  /// with robust error handling and fallback values for missing or invalid data.
  /// 
  /// Deserialization details:
  /// - ThemeMode is reconstructed from index with bounds checking
  /// - Prayer notifications are filtered to only include valid enum values
  /// - All string-based enums use name matching with fallbacks
  /// - Primitive values have type-safe defaults
  /// 
  /// Parameters:
  /// - [json]: Map containing serialized settings data
  /// 
  /// Returns: A new AppSettings instance with restored values
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final validNotificationKeys =
        PrayerNotification.values.map((e) => e.name).toSet();
    final notificationsJson =
        json['notifications'] as Map<String, dynamic>? ?? {};

    return AppSettings(
      calculationMethod: json['calculationMethod'] as String? ?? 'Auto',
      madhab: json['madhab'] as String? ?? 'hanafi',
      themeMode: () {
        // Use a closure to handle logic cleanly inline
        final index = json['themeMode'] as int?;
        if (index != null && index >= 0 && index < ThemeMode.values.length) {
          return ThemeMode.values[index];
        }
        return ThemeMode.system;
      }(),
      language: json['language'] as String? ?? 'en',
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
                entry.value as bool? ?? true,
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
      dhikrRemindersEnabled: json['dhikrRemindersEnabled'] as bool? ?? false,
      dhikrReminderInterval: json['dhikrReminderInterval'] as int? ?? 4,
    );
  }

  /// Provides a default AppSettings instance
  /// 
  /// This static getter returns a new AppSettings with all default values.
  /// It's useful for initialization or reset operations.
  /// 
  /// Returns: A new AppSettings instance with default configuration
  static AppSettings get defaults => AppSettings();
}