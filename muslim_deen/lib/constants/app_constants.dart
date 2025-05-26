import 'package:geolocator/geolocator.dart';

class AppConstants {
  static final Position meccaPosition = Position(
    latitude: 21.4225,
    longitude: 39.8262,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    accuracy: 0.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  static const double meccaLatitude = 21.4225;
  static const double meccaLongitude = 39.8262;
}
