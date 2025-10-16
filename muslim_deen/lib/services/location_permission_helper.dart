import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Utility helper class for common location-related operations.
///
/// This static helper class provides convenient methods for location
/// permission checking, GPS access, and coordinate-to-place conversion.
/// It's designed as a utility class to simplify common location operations
/// that don't require the full [LocationService] infrastructure.
///
/// ## Key Features
/// - Simplified permission checking API
/// - Common GPS settings configuration
/// - Reverse geocoding for place names
/// - Comprehensive location validation
///
/// ## Usage Context
/// - Qibla compass features
/// - Location-dependent UI components
/// - Quick location validation
/// - Background location checks
///
/// ## Dependencies
/// - [Geolocator]: GPS functionality and permission checks
/// - [Geocoding]: Reverse geocoding for place names
///
/// ## Design Pattern
/// Static utility class with stateless methods for simple operations.
/// More complex location management should use [LocationService].
class LocationPermissionHelper {
  /// Checks if location permission has been granted by the user.
  ///
  /// This method provides a simple boolean check for location permission
  /// status, abstracting away the complexity of different permission levels.
  ///
  /// ## Permission Levels Checked
  /// - LocationPermission.whileInUse: App can use location when open
  /// - LocationPermission.always: App can use location in background
  ///
  /// Returns:
  /// - true if either whileInUse or always permission is granted
  /// - false if permission is denied, deniedForever, or unableToDetermine
  ///
  /// Use Case: Quick permission validation before location-dependent operations
  ///
  /// Thread Safety: Safe to call from any thread
  static Future<bool> hasLocationPermission() async {
    final permissionStatus = await Geolocator.checkPermission();
    return permissionStatus == LocationPermission.whileInUse ||
        permissionStatus == LocationPermission.always;
  }

  /// Checks if device location services are enabled at the system level.
  ///
  /// This method verifies that location services are turned on in the
  /// device settings, which is separate from app-specific permissions.
  ///
  /// Device Settings Checked:
  /// - Android: Location services enabled in settings
  /// - iOS: Location services enabled in privacy settings
  ///
  /// Returns:
  /// - true if system location services are enabled
  /// - false if disabled or unable to determine
  ///
  /// Use Case: Pre-flight check before requesting GPS location
  ///
  /// Note: This is different from app permission - both must be true for GPS
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Gets current GPS position using standardized high-accuracy settings.
  ///
  /// This method provides a simplified way to get the current location
  /// with commonly used settings optimized for prayer time calculations:
  ///
  /// ## GPS Settings Used
  /// - Accuracy: LocationAccuracy.high
  /// - Timeout: 10 seconds
  ///
  /// Returns: Current [Position] with GPS coordinates
  ///
  /// Throws: Can throw various exceptions from Geolocator:
  /// - Permission denied errors
  /// - Location service disabled errors
  /// - Timeout exceptions
  ///
  /// Use Case: Quick location access for simple use cases
  ///
  /// Note: For more advanced caching and error handling, use [LocationService]
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Converts GPS coordinates to a city name using reverse geocoding.
  ///
  /// This method performs reverse geocoding to find the city or locality
  /// name for given coordinates, useful for displaying location information
  /// to users or for location-based features.
  ///
  /// Parameters:
  /// - [latitude]: GPS latitude coordinate
  /// - [longitude]: GPS longitude coordinate
  ///
  /// Returns:
  /// - City/locality name if found
  /// - null if geocoding fails or no city found
  ///
  /// Error Handling:
  /// - Network failures: Returns null
  /// - Invalid coordinates: Returns null
  /// - No geocoding results: Returns null
  ///
  /// Use Case: Display user's current city, location-based prayer times
  ///
  /// Performance: Network-dependent operation, may be slow
  static Future<String?> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      return placemarks.isNotEmpty ? placemarks.first.locality : null;
    } catch (_) {
      return null;
    }
  }

  /// Performs comprehensive location access validation with user-friendly error messages.
  ///
  /// This method provides a complete validation workflow for location access,
  /// checking both system settings and app permissions while providing
  /// specific error messages for different failure scenarios.
  ///
  /// ## Validation Steps
  /// 1. Check if location services are enabled at system level
  /// 2. Check current app permission status
  /// 3. Request permission if denied
  /// 4. Handle permanently denied permissions
  ///
  /// Returns: [LocationValidationResult] with validation status and error message
  ///
  /// Error Messages Provided:
  /// - Location service disabled: "Location service is disabled. Please enable it."
  /// - Permission denied: "Location permission is required to find the Qibla direction."
  /// - Permanently denied: "Location permission is permanently denied. Please enable it in your device settings."
  ///
  /// Use Case: Pre-flight validation before location-dependent features
  ///
  /// Thread Safety: Safe to call from any thread
  static Future<LocationValidationResult> validateLocationAccess() async {
    // 1. Check if location services are enabled
    final isServiceEnabled = await isLocationServiceEnabled();
    if (!isServiceEnabled) {
      return LocationValidationResult(
        isValid: false,
        errorMessage: 'Location service is disabled. Please enable it.',
      );
    }

    // 2. Check permission status
    var permission = await Geolocator.checkPermission();

    // 3. If denied, request it
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationValidationResult(
          isValid: false,
          errorMessage:
              'Location permission is required to find the Qibla direction.',
        );
      }
    }

    // 4. If denied forever, show error
    if (permission == LocationPermission.deniedForever) {
      return LocationValidationResult(
        isValid: false,
        errorMessage:
            'Location permission is permanently denied. Please enable it in your device settings.',
      );
    }

    // 5. If granted, return success
    return LocationValidationResult(isValid: true);
  }
}

/// Result class for location validation
class LocationValidationResult {
  final bool isValid;
  final String? errorMessage;

  const LocationValidationResult({required this.isValid, this.errorMessage});
}
