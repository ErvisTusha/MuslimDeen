import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Extension methods to enhance LocationService functionality for specific use cases
extension LocationServiceExtension on LocationService {
  /// Gets the current coordinates of the device formatted for Adhan package
  ///
  /// Returns device location coordinates if available, falls back to cached location,
  /// or ultimately to default Mecca coordinates (21.4225, 39.8262) if no location data
  /// is available. This ensures prayer calculations always have coordinates to work with.
  ///
  /// @return [Coordinates] The location coordinates for prayer time calculations
  Future<Coordinates> getCurrentCoordinates() async {
    final logger = locator<LoggerService>();

    try {
      final position = await getLocation();
      return Coordinates(position.latitude, position.longitude);
    } catch (e, stackTrace) {
      logger.error(
        'Failed to get current coordinates for prayer calculations',
        error: e,
        stackTrace: stackTrace,
      );
      return _getFallbackCoordinates(logger);
    }
  }

  /// Provides fallback coordinates when location services fail
  ///
  /// @param logger The logger service to record the fallback use
  /// @return [Coordinates] Default Mecca coordinates (21.4225, 39.8262)
  Coordinates _getFallbackCoordinates(LoggerService logger) {
    logger.info('Using fallback Mecca coordinates for prayer calculations');
    return Coordinates(21.4225, 39.8262); // Default to Mecca coordinates
  }
}
