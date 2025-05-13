import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/services/location_service.dart';

// Extension methods to add the required functionality
extension LocationServiceExtension on LocationService {
  /// Gets the current coordinates of the device
  Future<Coordinates> getCurrentCoordinates() async {
    try {
      // Get current position from location service implementation
      final position = await Geolocator.getCurrentPosition();
      return Coordinates(position.latitude, position.longitude);
    } catch (e) {
      // Fall back to default coordinates if unable to get location
      // This would typically be the last saved location or a default
      return Coordinates(21.4225, 39.8262); // Default to Mecca coordinates
    }
  }
}
