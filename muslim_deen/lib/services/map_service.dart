import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

class Mosque {
  final String name;
  final LatLng location;
  final String? id;
  final double? distance;

  Mosque({required this.name, required this.location, this.id, this.distance});

  // Supports serialization for caching
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'id': id,
      'distance': distance,
    };
  }

  // Supports deserialization from cache
  factory Mosque.fromJson(Map<String, dynamic> json) {
    return Mosque(
      name: json['name'] as String,
      location: LatLng(
        json['location']['latitude'] as double,
        json['location']['longitude'] as double,
      ),
      id: json['id'] as String?,
      distance: json['distance'] as double?,
    );
  }
}

class MapService {
  final CacheService? cacheService;
  final LoggerService _logger = locator<LoggerService>();

  static const String _overpassApiUrl =
      'https://overpass-api.de/api/interpreter';

  MapService({this.cacheService});

  Future<List<Mosque>> findNearbyMosques(
    Position position, {
    double radius = 5000.0, // Default radius in meters
    int limit = 20, // Default limit for number of results
    bool useCache = true,
  }) async {
    final String cacheKey =
        cacheService?.generateLocationCacheKey(
          'mosques',
          position.latitude,
          position.longitude,
          radius: radius,
        ) ??
        'mosques_${position.latitude}_${position.longitude}_$radius'; // Fallback key if cacheService is null

    if (useCache && cacheService != null) {
      final cachedData = cacheService!.getCache<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        _logger.info('Returning cached mosques for key: $cacheKey');
        return cachedData
            .map((item) => Mosque.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    _logger.info(
      'Searching for mosques (cache miss or cache disabled)',
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius': radius,
      },
    );

    try {
      // Approximate conversion: 1 degree of latitude ~ 111 km.
      // This is a simplification; longitude conversion varies with latitude.
      final double radiusDegrees = radius / 111000.0;

      // Overpass QL query to find Muslim places of worship
      final query = '''
      [out:json];
      (
        node["amenity"="place_of_worship"]["religion"="muslim"]
          (${position.latitude - radiusDegrees},${position.longitude - radiusDegrees},
           ${position.latitude + radiusDegrees},${position.longitude + radiusDegrees});
        way["amenity"="place_of_worship"]["religion"="muslim"]
          (${position.latitude - radiusDegrees},${position.longitude - radiusDegrees},
           ${position.latitude + radiusDegrees},${position.longitude + radiusDegrees});
        relation["amenity"="place_of_worship"]["religion"="muslim"]
          (${position.latitude - radiusDegrees},${position.longitude - radiusDegrees},
           ${position.latitude + radiusDegrees},${position.longitude + radiusDegrees});
      );
      out center;
      ''';

      final url = Uri.parse(_overpassApiUrl);
      final response = await http.post(
        url,
        body: query,
        headers: {'Content-Type': 'text/plain'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final elements = data['elements'] as List;

        final mosques =
            elements.map((element) {
              double lat, lon;

              // Extract coordinates based on element type
              if (element['type'] == 'node') {
                lat = element['lat'] as double;
                lon = element['lon'] as double;
              } else {
                // 'way' or 'relation'
                lat = element['center']['lat'] as double;
                lon = element['center']['lon'] as double;
              }

              final tags = element['tags'] as Map<String, dynamic>?;

              final userLocation = LatLng(
                position.latitude,
                position.longitude,
              );
              final mosqueLocation = LatLng(lat, lon);

              const Distance distanceCalculator = Distance();
              final distanceInMeters = distanceCalculator(
                userLocation,
                mosqueLocation,
              );

              // Determine mosque name, falling back to English name or a default
              final String mosqueName =
                  tags?['name'] as String? ??
                  tags?['name:en'] as String? ??
                  'Unnamed Mosque';

              // Ensure name is not empty after fallbacks
              final finalMosqueName =
                  mosqueName.isNotEmpty ? mosqueName : 'Unnamed Mosque';

              return Mosque(
                id: element['id'].toString(),
                name: finalMosqueName,
                location: mosqueLocation,
                distance: distanceInMeters,
              );
            }).toList();

        // Sort mosques by distance (ascending)
        mosques.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );

        final result = mosques.take(limit).toList();

        // Cache the result if cacheService is available
        if (cacheService != null) {
          final jsonList = result.map((mosque) => mosque.toJson()).toList();
          cacheService!.setCache(
            cacheKey, // Use the same cacheKey generated earlier
            jsonList,
            expirationMinutes: CacheService.mosquesExpirationMinutes,
          );
        }

        _logger.info('Found ${result.length} mosques nearby');
        return result;
      } else {
        _logger.error(
          'Overpass API Error while finding mosques',
          data: {'statusCode': response.statusCode, 'body': response.body},
        );
        return [];
      }
    } catch (e, s) {
      _logger.error(
        'Error in findNearbyMosques',
        error: e, // Pass the actual error object
        data: {'details': e.toString()}, // Keep original string data if needed
        stackTrace: s,
      );
      return [];
    }
  }

  /* TODO: Implement mosque detail fetching logic if needed in the future.
  // This might involve another Overpass API query using the mosque's ID (node/way/relation ID)
  // or querying a different API if available.
  Future<Map<String, dynamic>?> getMosqueDetails(String id) async {
    _logger.warning('getMosqueDetails is not yet implemented.', data: {'id': id});
    return null;
  }
  */

  void clearCache() {
    if (cacheService != null) {
      // Clear all mosque-related caches
      // The loop was redundant as clearAllCache clears everything.
      // Keeping the call to clearAllCache as it seems intended.
      cacheService!.clearAllCache();
      _logger.info('MapService cache cleared');
    }
  }
}
