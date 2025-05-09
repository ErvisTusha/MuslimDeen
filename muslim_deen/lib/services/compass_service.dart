import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

  /// Fetches magnetic declination for a given latitude, longitude, and altitude.
  ///
  /// Altitude is optional and defaults to 0 if not provided.
  /// The year is determined automatically.
  Future<double?> getMagneticDeclination(double latitude, double longitude, {double altitude = 0.0}) async {
    final cacheKey = cacheService?.generateLocationCacheKey('declination', latitude, longitude) ?? 'declination_${latitude}_$longitude';
    final cachedDeclination = cacheService?.getCache<double>(cacheKey);

    if (cachedDeclination != null) {
      _logger.debug('Using cached magnetic declination: $cachedDeclination for $latitude, $longitude');
      return cachedDeclination;
    }

    final year = DateTime.now().year;
    final month = DateTime.now().month;
    final day = DateTime.now().day;
    final date = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    // NOAA API endpoint for magnetic declination
    // Reference: https://www.ngdc.noaa.gov/geomag/calculators/magcalc.shtml#api
    final uri = Uri.parse(
        'https://www.ngdc.noaa.gov/geomag-web/calculators/calculateDeclination?lat1=$latitude&lon1=$longitude&elevation=$altitude&elevationUnits=M&model=WMM&startMonth=$month&startDay=$day&startYear=$year&resultFormat=json');

    _logger.info('Fetching magnetic declination from NOAA for $latitude, $longitude, date: $date');

    try {
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['result'] != null && data['result'].isNotEmpty) {
          final declinationData = data['result'][0];
          if (declinationData != null && declinationData['declination'] != null) {
            final declination = declinationData['declination'] as double;
            _logger.info('[DEBUG-QIBLA] Fetched magnetic declination: $declination for $latitude, $longitude');
            cacheService?.setCache(cacheKey, declination, expirationMinutes: CacheService.oneDayInMinutes);
            return declination;
          }
        }
        _logger.error('[DEBUG-QIBLA] Error parsing declination data: ${response.body}');
        return null; // Or throw an exception
      } else {
        _logger.error('[DEBUG-QIBLA] Error fetching declination: ${response.statusCode} ${response.reasonPhrase}');
        return null; // Or throw an exception
      }
    } catch (e) {
      _logger.error('[DEBUG-QIBLA] Exception fetching declination', error: e.toString());
      return null; // Or throw an exception
    }
  }


  /// Calculates the bearing (angle) between two geographical points.
  double calculateBearing(double startLat, double startLng, double endLat, double endLng) {
    final startLatRad = _degreesToRadians(startLat);
    final startLngRad = _degreesToRadians(startLng);
    final endLatRad = _degreesToRadians(endLat);
    final endLngRad = _degreesToRadians(endLng);

    final dLng = endLngRad - startLngRad;

    final y = math.sin(dLng) * math.cos(endLatRad);
    final x = math.cos(startLatRad) * math.sin(endLatRad) -
        math.sin(startLatRad) * math.cos(endLatRad) * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    final result = (bearingDeg + 360) % 360;
    _logger.debug('[DEBUG-QIBLA] Calculated bearing: $result° from ($startLat,$startLng) to ($endLat,$endLng)');
    return result;
  }

  /// Calculates the Qibla direction (bearing to Kaaba) from the device's current location.
  Future<double?> getQiblaDirection(Position position) async {
    _logger.info('[DEBUG-QIBLA] Starting Qibla calculation for position: (${position.latitude}, ${position.longitude}, alt: ${position.altitude})');
    
    // Try to get cached qibla direction first
    final cacheKey = cacheService?.generateLocationCacheKey('qibla_true', position.latitude, position.longitude) ?? 'qibla_true_${position.latitude}_${position.longitude}';
    final cachedDirection = cacheService?.getCache<double>(cacheKey);

    if (cachedDirection != null) {
      _logger.debug('[DEBUG-QIBLA] Using cached true Qibla direction: $cachedDirection');
      return cachedDirection;
    }

    final declination = await getMagneticDeclination(position.latitude, position.longitude, altitude: position.altitude);
    _logger.info('[DEBUG-QIBLA] Obtained magnetic declination: ${declination ?? "NULL (unavailable)"}');

    if (declination == null) {
      _logger.error('[DEBUG-QIBLA] Could not get magnetic declination, falling back to magnetic north calculation');
      // Fallback to calculation without declination or handle error appropriately
      // For now, let's calculate with magnetic north if declination is unavailable
      // This is not ideal but better than failing completely.
      // A more robust solution might involve retrying or notifying the user.
      return _calculateQiblaFromMagneticNorth(position);
    }
    
    // Calculate user's location in radians
    final startLatRad = _degreesToRadians(position.latitude);
    final startLngRad = _degreesToRadians(position.longitude);

    // Calculate difference in longitude
    final dLng = _kaabaLngRad - startLngRad;

    // Calculate bearing using optimized formula
    final y = math.sin(dLng) * _cosKaabaLatRad;
    final x = math.cos(startLatRad) * _sinKaabaLatRad -
        math.sin(startLatRad) * _cosKaabaLatRad * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    // Normalize bearing to 0-360 degrees
    final result = (bearingDeg + 360) % 360; // This is bearing from True North

    _logger.info('[DEBUG-QIBLA] Calculated true Qibla direction: $result° (with declination: $declination°)');
    _logger.debug('[DEBUG-QIBLA] Calculation details: y=$y, x=$x, bearingRad=$bearingRad, bearingDeg=$bearingDeg');
    
    cacheService?.setCache(cacheKey, result, expirationMinutes: CacheService.qiblaExpirationMinutes);
    return result;
  }

  /// Calculates Qibla direction using magnetic north (fallback if declination is not available).
  double _calculateQiblaFromMagneticNorth(Position position) {
    _logger.info('[DEBUG-QIBLA] Calculating Qibla direction using magnetic north (declination unavailable)');
    
    // Calculate user's location in radians
    final startLatRad = _degreesToRadians(position.latitude);
    final startLngRad = _degreesToRadians(position.longitude);

    // Calculate difference in longitude
    final dLng = _kaabaLngRad - startLngRad;

    // Calculate bearing using optimized formula
    final y = math.sin(dLng) * _cosKaabaLatRad;
    final x = math.cos(startLatRad) * _sinKaabaLatRad -
        math.sin(startLatRad) * _cosKaabaLatRad * math.cos(dLng);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);
    
    final magneticQibla = (bearingDeg + 360) % 360;

    _logger.info('[DEBUG-QIBLA] Calculated magnetic Qibla direction: $magneticQibla° (no declination applied)');
    _logger.debug('[DEBUG-QIBLA] Magnetic calculation details: y=$y, x=$x, bearingRad=$bearingRad, bearingDeg=$bearingDeg');

    // Cache this magnetic Qibla direction separately if needed, or just return it.
    // For simplicity, not caching the magnetic-only version here as the primary cache
    // is for true Qibla.
    final magneticCacheKey = cacheService?.generateLocationCacheKey('qibla_magnetic_fallback', position.latitude, position.longitude) ?? 'qibla_magnetic_fallback_${position.latitude}_${position.longitude}';
    cacheService?.setCache(magneticCacheKey, magneticQibla, expirationMinutes: CacheService.qiblaExpirationMinutes);


    return magneticQibla;
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