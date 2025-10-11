import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Complete Persistence Test', () {
    late StorageService storageService;
    const String settingsKey = 'app_settings';

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
    });

    test('should save and load ALL settings fields correctly', () async {
      // Create comprehensive test settings with non-default values
      final testSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ar',
        calculationMethod: 'Karachi',
        madhab: 'shafi',
        timeFormat: TimeFormat.twentyFourHour,
        dateFormatOption: DateFormatOption.monthDayYear,
        azanSoundForStandardPrayers: 'madinah_adhan.mp3',
        fajrOffset: 5,
        sunriseOffset: -3,
        dhuhrOffset: 2,
        asrOffset: -1,
        maghribOffset: 4,
        ishaOffset: -2,
        dhikrRemindersEnabled: true,
        dhikrReminderInterval: 6,
        notifications: {
          PrayerNotification.fajr: false,
          PrayerNotification.sunrise: true,
          PrayerNotification.dhuhr: false,
          PrayerNotification.asr: true,
          PrayerNotification.maghrib: false,
          PrayerNotification.isha: true,
        },
      );

      // Convert to JSON and save
      final jsonString = jsonEncode(testSettings.toJson());
      await storageService.saveData(settingsKey, jsonString);

      // Load settings back
      final loadedJsonString = storageService.getData(settingsKey) as String?;
      expect(loadedJsonString, isNotNull);
      expect(loadedJsonString, equals(jsonString));

      // Parse back
      final decodedJson = jsonDecode(loadedJsonString!) as Map<String, dynamic>;
      final loadedSettings = AppSettings.fromJson(decodedJson);

      // Verify ALL fields are preserved
      expect(
        loadedSettings.themeMode,
        equals(ThemeMode.dark),
        reason: 'Theme mode not persisted',
      );
      expect(
        loadedSettings.language,
        equals('ar'),
        reason: 'Language not persisted',
      );
      expect(
        loadedSettings.calculationMethod,
        equals('Karachi'),
        reason: 'Calculation method not persisted',
      );
      expect(
        loadedSettings.madhab,
        equals('shafi'),
        reason: 'Madhab not persisted',
      );
      expect(
        loadedSettings.timeFormat,
        equals(TimeFormat.twentyFourHour),
        reason: 'Time format not persisted',
      );
      expect(
        loadedSettings.dateFormatOption,
        equals(DateFormatOption.monthDayYear),
        reason: 'Date format not persisted',
      );
      expect(
        loadedSettings.azanSoundForStandardPrayers,
        equals('madinah_adhan.mp3'),
        reason: 'Azan sound not persisted',
      );

      // Verify prayer offsets
      expect(
        loadedSettings.fajrOffset,
        equals(5),
        reason: 'Fajr offset not persisted',
      );
      expect(
        loadedSettings.sunriseOffset,
        equals(-3),
        reason: 'Sunrise offset not persisted',
      );
      expect(
        loadedSettings.dhuhrOffset,
        equals(2),
        reason: 'Dhuhr offset not persisted',
      );
      expect(
        loadedSettings.asrOffset,
        equals(-1),
        reason: 'Asr offset not persisted',
      );
      expect(
        loadedSettings.maghribOffset,
        equals(4),
        reason: 'Maghrib offset not persisted',
      );
      expect(
        loadedSettings.ishaOffset,
        equals(-2),
        reason: 'Isha offset not persisted',
      );

      // Verify dhikr settings
      expect(
        loadedSettings.dhikrRemindersEnabled,
        equals(true),
        reason: 'Dhikr reminders enabled not persisted',
      );
      expect(
        loadedSettings.dhikrReminderInterval,
        equals(6),
        reason: 'Dhikr reminder interval not persisted',
      );

      // Verify notifications map
      expect(
        loadedSettings.notifications[PrayerNotification.fajr],
        equals(false),
        reason: 'Fajr notification not persisted',
      );
      expect(
        loadedSettings.notifications[PrayerNotification.sunrise],
        equals(true),
        reason: 'Sunrise notification not persisted',
      );
      expect(
        loadedSettings.notifications[PrayerNotification.dhuhr],
        equals(false),
        reason: 'Dhuhr notification not persisted',
      );
      expect(
        loadedSettings.notifications[PrayerNotification.asr],
        equals(true),
        reason: 'Asr notification not persisted',
      );
      expect(
        loadedSettings.notifications[PrayerNotification.maghrib],
        equals(false),
        reason: 'Maghrib notification not persisted',
      );
      expect(
        loadedSettings.notifications[PrayerNotification.isha],
        equals(true),
        reason: 'Isha notification not persisted',
      );
    });

    test('should verify JSON structure contains all fields', () async {
      final testSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ar',
      );

      final json = testSettings.toJson();

      // Verify all expected keys exist in JSON
      expect(
        json.containsKey('themeMode'),
        true,
        reason: 'themeMode missing from JSON',
      );
      expect(
        json.containsKey('language'),
        true,
        reason: 'language missing from JSON',
      );
      expect(
        json.containsKey('calculationMethod'),
        true,
        reason: 'calculationMethod missing from JSON',
      );
      expect(
        json.containsKey('madhab'),
        true,
        reason: 'madhab missing from JSON',
      );
      expect(
        json.containsKey('timeFormat'),
        true,
        reason: 'timeFormat missing from JSON',
      );
      expect(
        json.containsKey('dateFormatOption'),
        true,
        reason: 'dateFormatOption missing from JSON',
      );
      expect(
        json.containsKey('azanSoundForStandardPrayers'),
        true,
        reason: 'azanSoundForStandardPrayers missing from JSON',
      );
      expect(
        json.containsKey('notifications'),
        true,
        reason: 'notifications missing from JSON',
      );
      expect(
        json.containsKey('fajrOffset'),
        true,
        reason: 'fajrOffset missing from JSON',
      );
      expect(
        json.containsKey('sunriseOffset'),
        true,
        reason: 'sunriseOffset missing from JSON',
      );
      expect(
        json.containsKey('dhuhrOffset'),
        true,
        reason: 'dhuhrOffset missing from JSON',
      );
      expect(
        json.containsKey('asrOffset'),
        true,
        reason: 'asrOffset missing from JSON',
      );
      expect(
        json.containsKey('maghribOffset'),
        true,
        reason: 'maghribOffset missing from JSON',
      );
      expect(
        json.containsKey('ishaOffset'),
        true,
        reason: 'ishaOffset missing from JSON',
      );
      expect(
        json.containsKey('dhikrRemindersEnabled'),
        true,
        reason: 'dhikrRemindersEnabled missing from JSON',
      );
      expect(
        json.containsKey('dhikrReminderInterval'),
        true,
        reason: 'dhikrReminderInterval missing from JSON',
      );
      expect(
        json.containsKey('notificationPermissionStatus'),
        true,
        reason: 'notificationPermissionStatus missing from JSON',
      );

      print('JSON Structure: ${jsonEncode(json)}');
    });

    test('should handle theme mode enum serialization correctly', () async {
      for (final themeMode in ThemeMode.values) {
        final settings = AppSettings(themeMode: themeMode);
        final json = settings.toJson();

        // Save and load
        final jsonString = jsonEncode(json);
        await storageService.saveData(settingsKey, jsonString);

        final loadedJsonString = storageService.getData(settingsKey) as String;
        final loadedJson = jsonDecode(loadedJsonString) as Map<String, dynamic>;
        final loadedSettings = AppSettings.fromJson(loadedJson);

        expect(
          loadedSettings.themeMode,
          equals(themeMode),
          reason: 'Theme mode $themeMode not properly serialized/deserialized',
        );
      }
    });
  });
}
