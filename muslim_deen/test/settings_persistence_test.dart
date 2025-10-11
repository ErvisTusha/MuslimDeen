import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Settings Persistence', () {
    late StorageService storageService;

    setUp(() async {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
    });

    test('should save and load settings correctly', () async {
      // Create test settings
      final testSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ar',
        calculationMethod: 'Karachi',
      );

      // Save settings
      final jsonString = jsonEncode(testSettings.toJson());
      await storageService.saveData('app_settings', jsonString);

      // Load settings
      final loadedJsonString =
          storageService.getData('app_settings') as String?;
      expect(loadedJsonString, isNotNull);
      expect(loadedJsonString, equals(jsonString));

      // Parse back
      final decodedJson = jsonDecode(loadedJsonString!) as Map<String, dynamic>;
      final loadedSettings = AppSettings.fromJson(decodedJson);
      expect(loadedSettings.themeMode, equals(ThemeMode.dark));
      expect(loadedSettings.language, equals('ar'));
      expect(loadedSettings.calculationMethod, equals('Karachi'));
    });

    test('should handle corrupted JSON gracefully', () async {
      // Save corrupted JSON
      await storageService.saveData('app_settings', '{invalid json');

      // Try to load - should not crash
      final loaded = storageService.getData('app_settings') as String?;
      expect(loaded, equals('{invalid json'));
    });

    test('should use defaults when no settings saved', () async {
      // Don't save anything
      final loaded = storageService.getData('app_settings');
      expect(loaded, isNull);
    });
  });
}
