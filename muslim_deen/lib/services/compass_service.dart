import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to handle compass functionality and Qibla direction calculations
class CompassService {
  final LoggerService _logger = locator<LoggerService>();
  static const double _kaabaLatDeg = 21.422487;
  static const double _kaabaLngDeg = 39.826206;

  static final double _kaabaLatRad = _degreesToRadians(_kaabaLatDeg);
  static final double _kaabaLngRad = _degreesToRadians(_kaabaLngDeg);

  // Pre-calculated sin/cos of Kaaba latitude for optimization
  static final double _sinKaabaLatRad = math.sin(_kaabaLatRad);
  static final double _cosKaabaLatRad = math.cos(_kaabaLatRad);

  final CacheService? cacheService;

  CompassService({this.cacheService});

  /// Stream providing compass heading updates.
  Stream<CompassEvent>? get compassEvents => FlutterCompass.events;

  /// Calculates the Qibla direction (bearing to Kaaba) from the device's current location.
  Future<double?> getQiblaDirection(Position position) async {
    _logger.info(
      '[DEBUG-QIBLA] Starting Qibla calculation for position: (${position.latitude}, ${position.longitude}, alt: ${position.altitude})',
    );

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

    final startLatRad = _degreesToRadians(position.latitude);
    final startLngRad = _degreesToRadians(position.longitude);

    final dLng = _kaabaLngRad - startLngRad;

    final y = math.sin(dLng) * _cosKaabaLatRad;
    final x =
        math.cos(startLatRad) * _sinKaabaLatRad -
        math.sin(startLatRad) * _cosKaabaLatRad * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    final result = (bearingDeg + 360) % 360; // This is bearing from True North

    _logger.info('[DEBUG-QIBLA] Calculated true Qibla direction: $result°');
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

  /// Helper function to convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Helper function to convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180.0 / math.pi);
  }
}
