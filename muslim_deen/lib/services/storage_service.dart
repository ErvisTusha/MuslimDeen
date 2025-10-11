import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to handle local storage operations using SharedPreferences.
class StorageService {
  StorageService();

  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyLocationName = 'user_location_name';

  SharedPreferences? _prefs;

  /// Initializes the SharedPreferences instance. Must be called once before using other methods.
  Future<void> init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      // Log only if locator is available (for production)
      try {
        locator<LoggerService>().info("StorageService initialized.");
      } catch (_) {
        // Ignore if logger not available (e.g., in tests)
      }
    }
  }

  /// Check if the service is initialized
  bool get isInitialized => _prefs != null;

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

    try {
      locator<LoggerService>().info(
        "User location data (lat, lon, name) saved to SharedPreferences.",
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'locationName': locationName ?? 'N/A',
        },
      );
    } catch (_) {
      // Ignore if logger not available
    }
  }

  /// Generic method to save data of various types
  Future<void> saveData(String key, dynamic value) async {
    final prefs = _getPrefs();
    try {
      final success = await _saveValueByType(prefs, key, value);
      if (!success) {
        try {
          locator<LoggerService>().warning(
            'StorageService: Unsupported data type for key',
            data: {'key': key, 'type': value.runtimeType.toString()},
          );
        } catch (_) {
          // Ignore if logger not available
        }
      }
    } catch (e, s) {
      try {
        locator<LoggerService>().error(
          'Error saving data for key: $key',
          error: e,
          stackTrace: s,
        );
      } catch (_) {
        // Ignore if logger not available
      }
    }
  }

  /// Helper method to save different value types to SharedPreferences
  Future<bool> _saveValueByType(
    SharedPreferences prefs,
    String key,
    dynamic value,
  ) async {
    if (value is String) {
      await prefs.setString(key, value);
      return true;
    } else if (value is int) {
      await prefs.setInt(key, value);
      return true;
    } else if (value is double) {
      await prefs.setDouble(key, value);
      return true;
    } else if (value is bool) {
      await prefs.setBool(key, value);
      return true;
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
      return true;
    }
    return false;
  }

  /// Generic method to retrieve data
  dynamic getData(String key) {
    return _getPrefs().get(key);
  }

  /// Remove data for a specific key
  Future<void> removeData(String key) async {
    final prefs = _getPrefs();
    try {
      await prefs.remove(key);
      try {
        locator<LoggerService>().debug('Data removed for key: $key');
      } catch (_) {
        // Ignore if logger not available
      }
    } catch (e, s) {
      try {
        locator<LoggerService>().error(
          'Error removing data for key: $key',
          error: e,
          stackTrace: s,
        );
      } catch (_) {
        // Ignore if logger not available
      }
    }
  }
}
