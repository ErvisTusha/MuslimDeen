import 'package:shared_preferences/shared_preferences.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';

/// Service to handle local storage operations using SharedPreferences.
class StorageService {
  // Removed Singleton pattern - instance managed by get_it

  StorageService();

  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyLocationName = 'user_location_name';
  static const String _keyCalcMethod = 'prayer_calc_method';
  static const String _keyMadhab = 'prayer_madhab';
  static const String _keyLanguage = 'app_language';
  static const String _keyUseManualLocation = 'use_manual_location';

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

  /// Saves the user's location coordinates and optional location name
  Future<void> saveLocation(
    double latitude,
    double longitude, {
    String? locationName,
    bool setManualMode =
        true, // Add parameter with default value true for backward compatibility
  }) async {
    final prefs = _getPrefs();
    await prefs.setDouble(_keyLatitude, latitude);
    await prefs.setDouble(_keyLongitude, longitude);
    if (locationName != null) {
      await prefs.setString(_keyLocationName, locationName);
    }
    // Only set manual location flag if requested
    if (setManualMode) {
      await prefs.setBool(_keyUseManualLocation, true);
      locator<LoggerService>().info(
        "Location saved (manual)",
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'locationName': locationName,
          'manual': true,
        },
      );
    } else {
      locator<LoggerService>().info(
        "Location saved (device)",
        data: {
          'latitude': latitude,
          'longitude': longitude,
          'locationName': locationName,
          'manual': false,
        },
      );
    }
  }

  /// Returns the stored latitude or null if not set
  double? getLatitude() {
    return _getPrefs().getDouble(_keyLatitude);
  }

  /// Returns the stored longitude or null if not set
  double? getLongitude() {
    return _getPrefs().getDouble(_keyLongitude);
  }

  /// Returns the stored location name or null if not set
  String? getLocationName() {
    return _getPrefs().getString(_keyLocationName);
  }

  /// Checks if user has chosen to use manual location
  bool isUsingManualLocation() {
    return _getPrefs().getBool(_keyUseManualLocation) ?? false;
  }

  /// Sets whether to use manual location
  Future<void> setUseManualLocation(bool useManual) async {
    await _getPrefs().setBool(_keyUseManualLocation, useManual);
    locator<LoggerService>().info(
      "Using manual location",
      data: {'manual': useManual},
    );
  }

  /// Clears all stored location data and resets to use device location
  Future<void> clearLocation() async {
    final prefs = _getPrefs();
    await prefs.remove(_keyLatitude);
    await prefs.remove(_keyLongitude);
    await prefs.remove(_keyLocationName);
    await prefs.setBool(_keyUseManualLocation, false);
    locator<LoggerService>().info(
      "Location settings reset to use device location",
    );
  }

  /// Saves the prayer calculation method
  Future<void> saveCalculationMethod(String methodName) async {
    await _getPrefs().setString(_keyCalcMethod, methodName);
  }

  /// Returns the stored prayer calculation method or null if not set
  String? getCalculationMethod() {
    return _getPrefs().getString(_keyCalcMethod);
  }

  /// Saves the madhab setting
  Future<void> saveMadhab(String madhabName) async {
    await _getPrefs().setString(_keyMadhab, madhabName);
  }

  /// Returns the stored madhab or null if not set
  String? getMadhab() {
    return _getPrefs().getString(_keyMadhab);
  }

  /// Saves the app language setting
  Future<void> saveLanguage(String languageCode) async {
    await _getPrefs().setString(_keyLanguage, languageCode);
  }

  /// Returns the stored language code or null if not set
  String? getLanguage() {
    return _getPrefs().getString(_keyLanguage);
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

  /// Removes a specific data entry
  Future<bool> removeData(String key) async {
    return await _getPrefs().remove(key);
  }

  /// Clears all stored data
  Future<bool> clearAllData() async {
    return await _getPrefs().clear();
  }
}
