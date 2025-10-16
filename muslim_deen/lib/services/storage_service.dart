import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Simple key-value storage service using SharedPreferences.
///
/// This service provides a straightforward interface for storing and retrieving
/// primitive data types using SharedPreferences. It's designed for simple
/// configuration and user preference storage with type safety and error handling.
///
/// ## Key Features
/// - Type-safe storage for primitive data types
/// - Generic save/get methods for flexibility
/// - Comprehensive error handling with logging
/// - Initialization state management
/// - Location-specific convenience methods
///
/// ## Supported Data Types
/// - String: Text data and JSON strings
/// - int: Integer values
/// - double: Floating-point numbers
/// - bool: Boolean flags
/// - List<String>: String arrays
///
/// ## Use Cases
/// - User preferences and settings
/// - App configuration data
/// - Simple state persistence
/// - Location coordinate storage
///
/// ## Dependencies
/// - [SharedPreferences]: Persistent key-value storage
/// - [LoggerService]: Centralized logging
///
/// ## Design Pattern
/// Simple wrapper around SharedPreferences with added type safety
/// and logging capabilities. For more complex storage needs, use
/// [DatabaseService] for structured data storage.
class StorageService {
  StorageService();

  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyLocationName = 'user_location_name';

  SharedPreferences? _prefs;

  /// Initializes the SharedPreferences instance for storage operations.
  ///
  /// This method must be called before any other storage operations to
  /// ensure the SharedPreferences instance is properly initialized.
  /// It implements lazy initialization to prevent multiple initializations.
  ///
  /// ## Initialization Process
  /// 1. Checks if already initialized (idempotent)
  /// 2. Gets SharedPreferences instance
  /// 3. Logs successful initialization
  ///
  /// ## Error Handling
  /// - Graceful handling of initialization failures
  /// - Logger availability checking for test environments
  /// - State management to prevent repeated initializations
  ///
  /// Thread Safety: Safe to call multiple times (idempotent)
  ///
  /// Performance: Blocks until initialization completes
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

  /// Saves user location data with coordinates and optional location name.
  ///
  /// This convenience method provides a streamlined way to store location
  /// data with proper key management and type safety. It handles both
  /// coordinate storage and optional location name storage.
  ///
  /// Parameters:
  /// - [latitude]: Geographic latitude coordinate
  /// - [longitude]: Geographic longitude coordinate
  /// - [locationName]: Optional human-readable location name
  ///
  /// ## Storage Keys
  /// - user_latitude: Stored as double
  /// - user_longitude: Stored as double
  /// - user_location_name: Stored as string (removed if null/empty)
  ///
  /// ## Data Management
  /// - Removes location name if null or empty string provided
  /// - Maintains separate keys for each location component
  /// - Does not affect manual location mode flag
  ///
  /// Use Case: Storing user's preferred or current location
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
