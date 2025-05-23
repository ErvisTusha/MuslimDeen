import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to handle local storage operations using SharedPreferences.
class StorageService {
  // Removed Singleton pattern - instance managed by get_it

  StorageService();

  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyLocationName = 'user_location_name';

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

  /// Saves the user's location coordinates and optional location name.
  /// Does not affect the 'useManualLocation' flag; that should be set separately via [setUseManualLocation].
  Future<void> saveLocation(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    final prefs = _getPrefs();
    await prefs.setDouble(_keyLatitude, latitude);
    await prefs.setDouble(_keyLongitude, longitude);

    if (locationName != null && locationName.isNotEmpty) {
      await prefs.setString(_keyLocationName, locationName);
    } else {
      // If locationName is null or empty, remove it to keep data clean.
      await prefs.remove(_keyLocationName);
    }

    locator<LoggerService>().info(
      "User location data (lat, lon, name) saved to SharedPreferences.",
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName ?? 'N/A',
      },
    );
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
