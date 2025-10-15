import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

mixin SettingsPersistenceMixin on Notifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  Timer? _saveSettingsDebounceTimer;
  static const Duration _saveSettingsDebounceDuration = Duration(
    milliseconds: 200,
  );
  bool _isInitialized = false;

  StorageService get _storage => ref.read(storageServiceProvider);
  LoggerService get _logger => ref.read(loggerServiceProvider);

  AppSettings? loadSettingsSync() {
    if (!_storage.isInitialized) {
      _logger.warning('Storage not initialized during build, will load async');
      return null;
    }

    try {
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null && storedSettings.isNotEmpty) {
        final decodedJson = jsonDecode(storedSettings) as Map<String, dynamic>;
        final loadedSettings = AppSettings.fromJson(decodedJson);
        _isInitialized = true;
        _logger.info(
          "Settings loaded synchronously during build",
          data: {
            'themeMode': loadedSettings.themeMode.toString(),
            'calculationMethod': loadedSettings.calculationMethod,
            'language': loadedSettings.language,
          },
        );
        return loadedSettings;
      }
    } catch (e, s) {
      _logger.error(
        'Error loading settings synchronously',
        error: e,
        stackTrace: s,
      );
    }
    return null;
  }

  Future<void> initializeSettings() async {
    if (_isInitialized) {
      _logger.debug('Settings already initialized, skipping async init');
      return;
    }

    // Ensure storage is initialized
    if (!_storage.isInitialized) {
      _logger.warning(
        'Storage not initialized during settings init, initializing now',
      );
      await _storage.init();
    }

    try {
      // Try to load settings
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null && storedSettings.isNotEmpty) {
        try {
          final decodedJson =
              jsonDecode(storedSettings) as Map<String, dynamic>;
          final loadedSettings = AppSettings.fromJson(decodedJson);
          state = loadedSettings;
          _logger.info(
            "Settings loaded successfully during async initialization",
            data: {
              'themeMode': state.themeMode.toString(),
              'calculationMethod': state.calculationMethod,
              'language': state.language,
              'jsonLength': storedSettings.length,
            },
          );
        } catch (parseError, parseStack) {
          _logger.error(
            'Error parsing stored settings JSON',
            error: parseError,
            stackTrace: parseStack,
            data: {
              'storedSettingsLength': storedSettings.length,
              'storedSettingsPreview': storedSettings.substring(
                0,
                min(100, storedSettings.length),
              ),
            },
          );
          // Reset to defaults and save to fix corrupted data
          state = AppSettings.defaults;
          await forceSaveSettings();
        }
      } else {
        // If no stored settings, use defaults
        _logger.info(
          "No stored settings found during async init, using defaults",
        );
        // Save defaults for first-time users
        await forceSaveSettings();
      }
      _isInitialized = true;
    } catch (e, s) {
      _logger.error(
        'Error initializing settings',
        error: e,
        stackTrace: s,
        data: {
          'storedSettingsLength':
              (_storage.getData(_settingsKey) as String?)?.length,
        },
      );
      // Don't try to save during initialization - just use defaults
      _isInitialized = true;
    }
  }

  Future<void> saveSettings() async {
    // Ensure storage is initialized
    if (!_storage.isInitialized) {
      _logger.warning('Storage not initialized, initializing now');
      await _storage.init();
    }

    try {
      final jsonString = jsonEncode(state.toJson());
      await _storage.saveData(_settingsKey, jsonString);
      _logger.debug(
        "Settings saved successfully",
        data: {
          'jsonLength': jsonString.length,
          'themeMode': state.themeMode.toString(),
          'key': _settingsKey,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error saving settings',
        error: e,
        stackTrace: s,
        data: _getSafeStateData(),
      );
      // Retry saving after a short delay
      Future.delayed(const Duration(seconds: 1), () async {
        try {
          final jsonString = jsonEncode(state.toJson());
          await _storage.saveData(_settingsKey, jsonString);
          _logger.info("Settings retry save successful");
        } catch (retryError, retryStack) {
          _logger.error(
            'Settings retry save failed',
            error: retryError,
            stackTrace: retryStack,
          );
        }
      });
    }
  }

  void debouncedSaveSettings() {
    _saveSettingsDebounceTimer?.cancel();
    _saveSettingsDebounceTimer = Timer(_saveSettingsDebounceDuration, () {
      saveSettings();
      _logger.debug("Debounced _saveSettings executed.");
    });
  }

  Future<void> forceSaveSettings() async {
    _saveSettingsDebounceTimer?.cancel();
    await saveSettings();
  }

  Future<void> updateCriticalSetting<T>(
    String settingName,
    T value, {
    required T Function(AppSettings) getter,
    required AppSettings Function(AppSettings, T) setter,
  }) async {
    if (getter(state) != value) {
      state = setter(state, value);
      _logger.info(
        'Critical setting updated immediately',
        data: {'setting': settingName, 'value': value},
      );
      await forceSaveSettings();
    }
  }

  Future<void> resetToDefaults() async {
    state = AppSettings.defaults;
    await forceSaveSettings();
    await recalculateAndRescheduleNotifications();
  }

  String exportSettings() {
    return jsonEncode(state.toJson());
  }

  Future<bool> importSettings(String settingsJson) async {
    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(settingsJson) as Map<String, dynamic>;
      state = AppSettings.fromJson(jsonData);
      await forceSaveSettings();
      await recalculateAndRescheduleNotifications();
      return true;
    } catch (e) {
      _logger.error('Error importing settings', error: e);
      return false;
    }
  }

  void disposePersistence() {
    _saveSettingsDebounceTimer?.cancel();
  }

  Map<String, dynamic> _getSafeStateData() {
    try {
      return {
        'themeMode': state.themeMode.toString(),
        'calculationMethod': state.calculationMethod,
        'key': _settingsKey,
      };
    } catch (e) {
      // If state is not accessible, return minimal data
      return {'key': _settingsKey, 'stateAccessError': e.toString()};
    }
  }

  // Abstract methods that need to be implemented by the main class
  Future<void> recalculateAndRescheduleNotifications();
}
