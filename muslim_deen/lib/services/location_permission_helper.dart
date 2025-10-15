import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Helper class for common location-related operations
class LocationPermissionHelper {
  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    final permissionStatus = await Geolocator.checkPermission();
    return permissionStatus == LocationPermission.whileInUse ||
        permissionStatus == LocationPermission.always;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current position with common settings
  static Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Get city name from coordinates with error handling
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

  /// Validate location prerequisites and return appropriate error message
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
