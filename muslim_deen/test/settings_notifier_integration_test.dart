import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Storage Integration', () {
    late StorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = StorageService();
      await storage.init();
    });

    test('should persist theme mode correctly', () async {
      // Save dark theme
      final darkSettings = AppSettings(themeMode: ThemeMode.dark);
      final jsonString = jsonEncode(darkSettings.toJson());
      await storage.saveData('app_settings', jsonString);

      // Load back
      final loaded = storage.getData('app_settings') as String?;
      expect(loaded, isNotNull);

      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );
      expect(loadedSettings.themeMode, equals(ThemeMode.dark));
    });

    test('should persist light theme correctly', () async {
      // Save light theme
      final lightSettings = AppSettings(themeMode: ThemeMode.light);
      final jsonString = jsonEncode(lightSettings.toJson());
      await storage.saveData('app_settings', jsonString);

      // Load back
      final loaded = storage.getData('app_settings') as String?;
      expect(loaded, isNotNull);

      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );
      expect(loadedSettings.themeMode, equals(ThemeMode.light));
    });

    test('should persist system theme correctly', () async {
      // Save system theme
      final systemSettings = AppSettings(themeMode: ThemeMode.system);
      final jsonString = jsonEncode(systemSettings.toJson());
      await storage.saveData('app_settings', jsonString);

      // Load back
      final loaded = storage.getData('app_settings') as String?;
      expect(loaded, isNotNull);

      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );
      expect(loadedSettings.themeMode, equals(ThemeMode.system));
    });

    test('should persist language correctly', () async {
      final settings = AppSettings(language: 'ar');
      final jsonString = jsonEncode(settings.toJson());
      await storage.saveData('app_settings', jsonString);

      final loaded = storage.getData('app_settings') as String?;
      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );
      expect(loadedSettings.language, equals('ar'));
    });

    test('should persist calculation method correctly', () async {
      final settings = AppSettings(calculationMethod: 'Karachi');
      final jsonString = jsonEncode(settings.toJson());
      await storage.saveData('app_settings', jsonString);

      final loaded = storage.getData('app_settings') as String?;
      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );
      expect(loadedSettings.calculationMethod, equals('Karachi'));
    });

    test('should persist complex settings correctly', () async {
      final settings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ar',
        calculationMethod: 'Karachi',
        madhab: 'shafi',
        timeFormat: TimeFormat.twentyFourHour,
        fajrOffset: 5,
        dhikrRemindersEnabled: true,
      );

      final jsonString = jsonEncode(settings.toJson());
      await storage.saveData('app_settings', jsonString);

      final loaded = storage.getData('app_settings') as String?;
      final loadedSettings = AppSettings.fromJson(
        jsonDecode(loaded!) as Map<String, dynamic>,
      );

      expect(loadedSettings.themeMode, equals(ThemeMode.dark));
      expect(loadedSettings.language, equals('ar'));
      expect(loadedSettings.calculationMethod, equals('Karachi'));
      expect(loadedSettings.madhab, equals('shafi'));
      expect(loadedSettings.timeFormat, equals(TimeFormat.twentyFourHour));
      expect(loadedSettings.fajrOffset, equals(5));
      expect(loadedSettings.dhikrRemindersEnabled, equals(true));
    });
  });
}
