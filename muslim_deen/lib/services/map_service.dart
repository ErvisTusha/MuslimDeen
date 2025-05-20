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

  // Added to support serialization for caching
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

  // Added to support deserialization from cache
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

  MapService({this.cacheService});

  Future<List<Mosque>> findNearbyMosques(
    Position position, {
    double radius = 5000.0,
    int limit = 20,
    bool useCache = true,
  }) async {
    if (useCache && cacheService != null) {
      final cacheKey = cacheService!.generateLocationCacheKey(
        'mosques',
        position.latitude,
        position.longitude,
        radius: radius,
      );
      final cachedData = cacheService!.getCache<List<dynamic>>(cacheKey);

      if (cachedData != null) {
        _logger.info('Returning cached mosques');
        return cachedData
            .map((item) => Mosque.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }

    _logger.info(
      'Searching for mosques',
      data: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'radius': radius,
      },
    );

    try {
      final double radiusDegrees = radius / 111000;

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

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
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

              if (element['type'] == 'node') {
                lat = element['lat'] as double;
                lon = element['lon'] as double;
              } else {
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

              final String mosqueName;
              if (tags != null &&
                  tags['name'] != null &&
                  (tags['name'] as String).isNotEmpty) {
                mosqueName = tags['name'] as String;
              } else if (tags != null &&
                  tags['name:en'] != null &&
                  (tags['name:en'] as String).isNotEmpty) {
                mosqueName = tags['name:en'] as String;
              } else {
                mosqueName = 'Unnamed Mosque';
              }

              return Mosque(
                id: element['id'].toString(),
                name: mosqueName,
                location: mosqueLocation,
                distance: distanceInMeters,
              );
            }).toList();

        mosques.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );

        final result = mosques.take(limit).toList();

        // Cache the result
        if (cacheService != null) {
          final cacheKey = cacheService!.generateLocationCacheKey(
            'mosques',
            position.latitude,
            position.longitude,
            radius: radius,
          );
          final jsonList = result.map((mosque) => mosque.toJson()).toList();
          cacheService!.setCache(
            cacheKey,
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
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      return [];
    }
  }

  Future<Map<String, dynamic>?> getMosqueDetails(String id) async {
    if (cacheService != null) {
      final cacheKey = 'mosque_detail_$id';
      final cachedDetails = cacheService!.getCache<Map<String, dynamic>>(
        cacheKey,
      );

      if (cachedDetails != null) {
        _logger.info('Returning cached mosque details for id: $id');
        return cachedDetails;
      }
    }

    try {
      final String overpassQuery = '''[out:json];
(
  node(id:$id);
  way(id:$id);
  relation(id:$id);
);
out body;''';

      final Uri requestUri = Uri.parse(
        'https://overpass-api.de/api/interpreter',
      );
      final http.Response response = await http.post(
        requestUri,
        headers: {'Content-Type': 'text/plain'},
        body: overpassQuery,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(
          utf8.decode(response.bodyBytes),
        ) as Map<String, dynamic>;
        final List<dynamic> elements = json['elements'] as List<dynamic>;
        if (elements.isNotEmpty) {
          final result = elements.first as Map<String, dynamic>;

          // Cache the result
          if (cacheService != null) {
            final cacheKey = 'mosque_detail_$id';
            cacheService!.setCache(
              cacheKey,
              result,
              expirationMinutes: CacheService.mosquesExpirationMinutes,
            );
          }

          return result;
        }
      }
      _logger.warning(
        'Could not fetch mosque details for id: $id, status: ${response.statusCode}',
      );
      return null;
    } catch (error, s) {
      _logger.error(
        'Failed to fetch mosque details for id: $id',
        data: {'error': error.toString(), 'stackTrace': s.toString()},
      );
      return null;
    }
  }

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
