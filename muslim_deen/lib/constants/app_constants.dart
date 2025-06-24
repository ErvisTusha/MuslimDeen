import 'package:geolocator/geolocator.dart';

class AppConstants {
  static final Position meccaPosition = Position(
    latitude: 21.422487, // Using the more precise version
    longitude: 39.826206,
    timestamp: DateTime.now(), // Timestamp will be dynamic upon usage
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );

  // Add other app-wide constants here if needed in the future
}
