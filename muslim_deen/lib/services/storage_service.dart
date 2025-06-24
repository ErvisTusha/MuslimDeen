import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to handle local storage operations using SharedPreferences.
class StorageService {
  StorageService();

  SharedPreferences? _prefs;

  /// Initializes the SharedPreferences instance. Must be called once before using other methods.
  Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      locator<LoggerService>().info("StorageService initialized.");
    }
  }

  /// Helper to ensure prefs is initialized
  SharedPreferences _getPrefs() {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// Generic method to save data of various types
  Future<void> saveData(String key, dynamic value) async {
    final prefs = _getPrefs();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    } else {
      locator<LoggerService>().warning(
        'StorageService: Unsupported data type for key',
        data: {'key': key, 'type': value.runtimeType.toString()},
      );
    }
  }

  /// Generic method to retrieve data
  dynamic getData(String key) {
    return _getPrefs().get(key);
  }
}
