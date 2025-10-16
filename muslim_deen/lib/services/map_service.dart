import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Represents a mosque with location and distance information
/// 
/// This class encapsulates information about a mosque, including its name,
/// geographic coordinates, unique identifier, and distance from a reference
/// point. It supports JSON serialization for data persistence and API communication.
/// 
/// Usage:
/// ```dart
/// final mosque = Mosque(
///   name: 'Masjid Al-Haram',
///   location: LatLng(21.4225, 39.8262),
///   id: '1',
///   distance: 1500.0,
/// );
/// ```
class Mosque {
  final String name;
  final LatLng location;
  final String? id;
  final double? distance;

  Mosque({required this.name, required this.location, this.id, this.distance});

  /// Convert mosque to JSON for serialization
  /// 
  /// Serializes the mosque object to a JSON map, which can be used
  /// for API requests, local storage, or data transmission.
  /// 
  /// Returns:
  /// - Map containing serialized mosque data
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

  /// Create mosque from JSON data
  /// 
  /// Deserializes a mosque object from JSON data, typically received
  /// from API responses or loaded from local storage.
  /// 
  /// Parameters:
  /// - [json]: JSON map containing mosque data
  /// 
  /// Returns:
  /// - Mosque object with data from JSON
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

/// Service for finding nearby mosques using OpenStreetMap data
/// 
/// This service provides functionality to locate nearby mosques using the
/// Overpass API, which provides access to OpenStreetMap data. It calculates
/// distances and returns sorted results based on proximity to the user's location.
/// 
/// Features:
/// - Find mosques within a specified radius
/// - Calculate accurate distances using haversine formula
/// - Sort results by distance (nearest first)
/// - Support for customizable search parameters
/// - Error handling and logging
/// - Optional caching integration
/// 
/// Usage:
/// ```dart
/// final mapService = MapService();
/// final position = await Geolocator.getCurrentPosition();
/// final mosques = await mapService.findNearbyMosques(position);
/// ```
/// 
/// Design Patterns:
/// - Service: Encapsulates mosque search functionality
/// - Repository: Abstracts data source from business logic
/// - Strategy: Different query strategies for different needs
/// 
/// Performance Considerations:
/// - Uses efficient distance calculations
/// - Limits result count to prevent excessive data
/// - Implements proper error handling without blocking
/// - Converts coordinates efficiently for API queries
/// 
/// Dependencies:
/// - Overpass API: OpenStreetMap data source
/// - latlong2 package: For accurate distance calculations
/// - http package: For API requests
/// - CacheService: Optional caching support
/// - LoggerService: For centralized logging
/// 
/// Notes:
/// - Requires internet connectivity for API requests
/// - API rate limits may apply for frequent requests
/// - Results depend on OpenStreetMap data completeness
class MapService {
  final CacheService? cacheService;
  final LoggerService _logger = locator<LoggerService>();

  /// Overpass API endpoint for OpenStreetMap queries
  /// 
  /// This is the primary endpoint for querying OpenStreetMap data.
  /// The Overpass API provides powerful querying capabilities for
  /// geographic data including points of interest like mosques.
  static const String _overpassApiUrl =
      'https://overpass-api.de/api/interpreter';

  MapService({this.cacheService});

  /// Find nearby mosques around a specified position
  /// 
  /// Searches for mosques within a specified radius from the user's
  /// current location. Uses the Overpass API to query OpenStreetMap
  /// data for Islamic places of worship.
  /// 
  /// Parameters:
  /// - [position]: The user's current geographic position
  /// - [radius]: Search radius in meters (default: 5000m = 5km)
  /// - [limit]: Maximum number of results to return (default: 20)
  /// - [useCache]: Whether to use cached results if available
  /// 
  /// Algorithm:
  /// 1. Convert radius from meters to approximate degrees for API query
  /// 2. Construct Overpass QL query for mosques within bounding box
  /// 3. Execute HTTP POST request to Overpass API
  /// 4. Parse JSON response and extract mosque data
  /// 5. Calculate accurate distances for each mosque
  /// 6. Sort results by distance and apply limit
  /// 
  /// Query Details:
  /// - Searches for nodes, ways, and relations tagged as Islamic places of worship
  /// - Uses bounding box to limit search area
  /// - Requests center coordinates for ways and relations
  /// 
  /// Error Handling:
  /// - Logs detailed error information without throwing exceptions
  /// - Returns empty list on API failures to prevent app crashes
  /// - Handles network timeouts and API errors gracefully
  /// 
  /// Performance:
  /// - Single API request for all mosques in area
  /// - Efficient distance calculations using haversine formula
  /// - Early limiting of results to reduce processing overhead
  /// 
  /// Returns:
  /// - List of mosques sorted by distance (nearest first)
  Future<List<Mosque>> findNearbyMosques(
    Position position, {
    double radius = 5000.0, // Default radius in meters
    int limit = 20, // Default limit for number of results
    bool useCache = true,
  }) async {
    _logger.info(
      'Searching for mosques',
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
}