import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Service to handle compass functionality and Qibla direction calculations
class CompassService {
  final LoggerService _logger = locator<LoggerService>();
  // Kaaba coordinates
  static const double _kaabaLatDeg = 21.422487;
  static const double _kaabaLngDeg = 39.826206;

  // Pre-calculated Kaaba coordinates in radians
  static final double _kaabaLatRad = _degreesToRadians(_kaabaLatDeg);
  static final double _kaabaLngRad = _degreesToRadians(_kaabaLngDeg);

  // Pre-calculated sin/cos of Kaaba latitude for optimization
  static final double _sinKaabaLatRad = math.sin(_kaabaLatRad);
  static final double _cosKaabaLatRad = math.cos(_kaabaLatRad);

  final CacheService? cacheService;

  CompassService({this.cacheService});

  /// Stream providing compass heading updates.
  Stream<CompassEvent>? get compassEvents => FlutterCompass.events;


  /// Calculates the bearing (angle) between two geographical points.
  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final startLatRad = _degreesToRadians(startLat);
    final startLngRad = _degreesToRadians(startLng);
    final endLatRad = _degreesToRadians(endLat);
    final endLngRad = _degreesToRadians(endLng);

    final dLng = endLngRad - startLngRad;

    final y = math.sin(dLng) * math.cos(endLatRad);
    final x =
        math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    final result = (bearingDeg + 360) % 360;
    _logger.debug(
      '[DEBUG-QIBLA] Calculated bearing: $result° from ($startLat,$startLng) to ($endLat,$endLng)',
    );
    return result;
  }

  /// Calculates the Qibla direction (bearing to Kaaba) from the device's current location.
  Future<double?> getQiblaDirection(Position position) async {
    _logger.info(
      '[DEBUG-QIBLA] Starting Qibla calculation for position: (${position.latitude}, ${position.longitude}, alt: ${position.altitude})',
    );

    // Try to get cached qibla direction first
    final cacheKey =
        cacheService?.generateLocationCacheKey(
          'qibla_true',
          position.latitude,
          position.longitude,
        ) ??
        () {
          final lat = position.latitude.toStringAsFixed(4);
          final lon = position.longitude.toStringAsFixed(4);
          return 'qibla_true_${lat}_$lon';
        }();
    final cachedDirection = cacheService?.getCache<double>(cacheKey);

    if (cachedDirection != null) {
      _logger.debug(
        '[DEBUG-QIBLA] Using cached true Qibla direction: $cachedDirection',
      );
      return cachedDirection;
    }

    // Calculate user's location in radians
    final startLatRad = _degreesToRadians(position.latitude);
    final startLngRad = _degreesToRadians(position.longitude);

    // Calculate difference in longitude
    final dLng = _kaabaLngRad - startLngRad;

    // Calculate bearing using optimized formula
    final y = math.sin(dLng) * _cosKaabaLatRad;
    final x =
        math.cos(startLatRad) * _sinKaabaLatRad -
        math.sin(startLatRad) * _cosKaabaLatRad * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    // Normalize bearing to 0-360 degrees
    final result = (bearingDeg + 360) % 360; // This is bearing from True North

    _logger.info(
      '[DEBUG-QIBLA] Calculated true Qibla direction: $result°',
    );
    _logger.debug(
      '[DEBUG-QIBLA] Calculation details: y=$y, x=$x, bearingRad=$bearingRad, bearingDeg=$bearingDeg',
    );

    cacheService?.setCache(
      cacheKey,
      result,
      expirationMinutes: CacheService.qiblaExpirationMinutes,
    );
    return result;
  }


/// Calculates the Qibla direction based on user's latitude and longitude.
  ///
  /// This method implements the Qibla calculation algorithm using spherical trigonometry.
  ///
  /// Parameters:
  ///   [userLatitudeDegrees] - The user's current latitude in degrees.
  ///   [userLongitudeDegrees] - The user's current longitude in degrees.
  ///
  /// Returns:
  ///   The Qibla direction in degrees, normalized between 0 and 360.
  double calculateQiblaDirection(
    double userLatitudeDegrees,
    double userLongitudeDegrees,
  ) {
    _logger.info(
      '[DEBUG-QIBLA] Calculating Qibla direction for user at: ($userLatitudeDegrees, $userLongitudeDegrees)',
    );

    // 1. Define Constants and Convert Kaaba's Coordinates to Radians
    // Kaaba's Coordinates (as per algorithm specification)
    const double kaabaLatitudeDegrees = 21.4225;
    const double kaabaLongitudeDegrees = 39.8262;

    final double phiKRad = _degreesToRadians(kaabaLatitudeDegrees); // φ_K_rad
    final double lambdaKRad = _degreesToRadians(kaabaLongitudeDegrees); // λ_K_rad

    // 3. Convert user's coordinates to radians
    final double phiURad = _degreesToRadians(userLatitudeDegrees); // φ_U_rad
    final double lambdaURad = _degreesToRadians(userLongitudeDegrees); // λ_U_rad

    // 4. Calculate the Difference in Longitudes
    final double deltaLambdaRad = lambdaKRad - lambdaURad; // Δλ_rad

    // 5. Calculate the Qibla Direction using atan2
    // Y = sin(Δλ_rad) * cos(φ_K_rad)
    final double y = math.sin(deltaLambdaRad) * math.cos(phiKRad);
    // X = cos(φ_U_rad) * sin(φ_K_rad) - sin(φ_U_rad) * cos(φ_K_rad) * cos(Δλ_rad)
    final double x = math.cos(phiURad) * math.sin(phiKRad) -
        math.sin(phiURad) * math.cos(phiKRad) * math.cos(deltaLambdaRad);
    
    // Q_rad = atan2(Y, X)
    final double qiblaRad = math.atan2(y, x);

    // 6. Convert Qibla Direction from Radians to Degrees
    final double qiblaDeg = _radiansToDegrees(qiblaRad);

    // 7. Normalize the Qibla Direction
    final double qiblaNormalizedDeg = (qiblaDeg + 360) % 360;

    _logger.info(
      '[DEBUG-QIBLA] Calculated Qibla direction (offline): $qiblaNormalizedDeg°',
    );
    _logger.debug(
      '[DEBUG-QIBLA] Offline calculation details: phiKRad=$phiKRad, lambdaKRad=$lambdaKRad, phiURad=$phiURad, lambdaURad=$lambdaURad, deltaLambdaRad=$deltaLambdaRad, Y=$y, X=$x, qiblaRad=$qiblaRad, qiblaDeg=$qiblaDeg',
    );

    return qiblaNormalizedDeg;
  }
  /// Helper function to convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Helper function to convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }
}
