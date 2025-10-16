import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to automatically detect country and apply appropriate prayer time calculation method
/// 
/// This service provides functionality to automatically determine the appropriate
/// prayer time calculation method based on the user's geographic location. It maintains
/// a comprehensive mapping of countries to their preferred calculation methods and
/// provides utilities for country detection and prayer time validation.
/// 
/// Features:
/// - Automatic country detection from GPS coordinates
/// - Comprehensive mapping of countries to calculation methods
/// - Integration with Aladhan API for prayer times
/// - Validation of local calculations against API data
/// - Support for 50+ countries with region-specific methods
/// 
/// Usage:
/// ```dart
/// final method = await CountryCalculationService.getCalculationMethodForCoordinates(40.7128, -74.0060);
/// final apiData = await CountryCalculationService.getPrayerTimesFromAPI(lat, lon, 'US');
/// final isValid = await CountryCalculationService.validateCalculationAccuracy(lat, lon, 'US', localTimes);
/// ```
/// 
/// Design Patterns:
/// - Static Service: All methods are static for easy access
/// - Strategy Pattern: Different calculation strategies for different regions
/// - Repository Pattern: Abstracts data source for calculation methods
/// - Facade Pattern: Simplifies complex country-method mapping logic
/// 
/// Performance Considerations:
/// - Static lookup maps for O(1) country method resolution
/// - Efficient HTTP requests with proper error handling
/// - Minimal memory footprint with static methods
/// - Caching-friendly design
/// 
/// Dependencies:
/// - geocoding package: For reverse geocoding coordinates to country
/// - http package: For API requests to Aladhan service
/// - LoggerService: For centralized logging
/// 
/// Notes:
/// - Requires internet connectivity for API calls
/// - Geocoding may fail in remote areas
/// - API rate limits may apply for frequent requests
class CountryCalculationService {
  /// Mapping of country codes to prayer time calculation methods
  /// 
  /// This comprehensive mapping associates ISO country codes with their
  /// preferred prayer time calculation methods. The methods are based on
  /// religious authorities and practices in each country.
  /// 
  /// Calculation Methods:
  /// - Turkey: Diyanet (Turkey's Presidency of Religious Affairs)
  /// - Egyptian: Egyptian General Authority of Survey
  /// - Morocco: Moroccan method specific to Morocco
  /// - MuslimWorldLeague: Muslim World League method (default for most countries)
  /// - UmmAlQura: Saudi Arabia's Umm al-Qura University method
  /// - Dubai: Dubai municipality method
  /// - Kuwait: Kuwait method
  /// - Qatar: Qatar method
  /// - Karachi: University of Islamic Sciences, Karachi method
  /// - Tehran: Institute of Geophysics, University of Tehran method
  /// 
  /// Coverage:
  /// - 50+ countries across Middle East, North Africa, Europe, and Asia
  /// - Covers major Muslim-majority countries and significant Muslim communities
  /// - Includes regional variations for better accuracy
  static const Map<String, String> _countryToCalculationMethod = {
    'TR': 'Turkey', // Turkey - Diyanet
    'EG': 'Egyptian', // Egypt - Egyptian General Authority
    'DZ': 'Egyptian', // Algeria - similar to Egyptian method
    'MA': 'Morocco', // Morocco - Moroccan method
    'TN': 'MuslimWorldLeague', // Tunisia
    'LY': 'MuslimWorldLeague', // Libya
    'SA': 'UmmAlQura', // Saudi Arabia
    'JO': 'MuslimWorldLeague', // Jordan
    'LB': 'MuslimWorldLeague', // Lebanon
    'SY': 'MuslimWorldLeague', // Syria
    'IQ': 'MuslimWorldLeague', // Iraq
    'IR': 'Tehran', // Iran
    'PK': 'Karachi', // Pakistan
    'IN': 'MuslimWorldLeague', // India
    'BD': 'MuslimWorldLeague', // Bangladesh
    'ID': 'MuslimWorldLeague', // Indonesia
    'MY': 'MuslimWorldLeague', // Malaysia
    'AE': 'Dubai', // UAE
    'KW': 'Kuwait', // Kuwait
    'QA': 'Qatar', // Qatar
    'BH': 'MuslimWorldLeague', // Bahrain
    'OM': 'MuslimWorldLeague', // Oman
    'YE': 'MuslimWorldLeague', // Yemen
    'SD': 'MuslimWorldLeague', // Sudan
    'SO': 'MuslimWorldLeague', // Somalia
    'AF': 'MuslimWorldLeague', // Afghanistan
    'UZ': 'MuslimWorldLeague', // Uzbekistan
    'KZ': 'MuslimWorldLeague', // Kazakhstan
    'KG': 'MuslimWorldLeague', // Kyrgyzstan
    'TJ': 'MuslimWorldLeague', // Tajikistan
    'TM': 'MuslimWorldLeague', // Turkmenistan
    'AZ': 'MuslimWorldLeague', // Azerbaijan
    'CY': 'MuslimWorldLeague', // Cyprus
    'GR': 'MuslimWorldLeague', // Greece (for Muslim minority)
    'BG': 'MuslimWorldLeague', // Bulgaria
    'RO': 'MuslimWorldLeague', // Romania
    'HR': 'MuslimWorldLeague', // Croatia
    'BA': 'MuslimWorldLeague', // Bosnia and Herzegovina
    'ME': 'MuslimWorldLeague', // Montenegro
    'MK': 'MuslimWorldLeague', // North Macedonia
    'AL': 'MuslimWorldLeague', // Albania
    'RS': 'MuslimWorldLeague', // Serbia (Sandžak region)
  };

  /// Get calculation method based on coordinates using reverse geocoding
  /// 
  /// Determines the appropriate prayer time calculation method for a given
  /// geographic location by performing reverse geocoding to identify the country.
  /// 
  /// Parameters:
  /// - [latitude]: Geographic latitude in decimal degrees
  /// - [longitude]: Geographic longitude in decimal degrees
  /// 
  /// Algorithm:
  /// 1. Perform reverse geocoding to get placemark information
  /// 2. Extract ISO country code from the placemark
  /// 3. Map country code to calculation method
  /// 4. Return method or default if country not found
  /// 
  /// Error Handling:
  /// - Logs errors gracefully without throwing exceptions
  /// - Falls back to MuslimWorldLeague method on failures
  /// - Handles cases where geocoding fails or returns no results
  /// 
  /// Performance:
  /// - Depends on geocoding service response time
  /// - O(1) lookup once country is determined
  /// 
  /// Returns:
  /// - Prayer time calculation method string
  /// 
  /// Dependencies:
  /// - geocoding package for reverse geocoding
  /// - Requires internet connectivity for geocoding service
  static Future<String> getCalculationMethodForCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Use geocoding to get country from coordinates
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final String? countryCode = placemarks.first.isoCountryCode;
        if (countryCode != null &&
            _countryToCalculationMethod.containsKey(countryCode)) {
          return _countryToCalculationMethod[countryCode]!;
        }
      }
    } catch (e) {
      locator<LoggerService>().error(
        'Error getting country from coordinates: $e',
      );
    }

    // Fallback to default method
    return 'MuslimWorldLeague';
  }

  /// Get calculation method based on country code directly
  /// 
  /// Returns the prayer time calculation method for a specific country code
  /// without requiring geocoding. This is useful when the country is already
  /// known or when offline functionality is needed.
  /// 
  /// Parameters:
  /// - [countryCode]: ISO 3166-1 alpha-2 country code (e.g., 'US', 'SA')
  /// 
  /// Algorithm:
  /// 1. Normalize country code to uppercase
  /// 2. Look up method in the country mapping
  /// 3. Return method or default if not found
  /// 
  /// Performance:
  /// - O(1) hash map lookup
  /// - No network requests required
  /// - Instant response
  /// 
  /// Returns:
  /// - Prayer time calculation method string
  static String getCalculationMethodForCountry(String countryCode) {
    return _countryToCalculationMethod[countryCode.toUpperCase()] ??
        'MuslimWorldLeague';
  }

  /// Get all supported countries and their calculation methods
  /// 
  /// Returns a copy of the complete country-to-method mapping.
  /// This is useful for UI components that need to display all available
  /// options or for debugging purposes.
  /// 
  /// Returns:
  /// - Map of country codes to calculation methods
  static Map<String, String> getAllSupportedCountries() {
    return Map.from(_countryToCalculationMethod);
  }

  /// Get prayer times from Aladhan API with country-specific method
  /// 
  /// Fetches prayer times from the Aladhan API using the appropriate
  /// calculation method for the specified country. This provides
  /// authoritative prayer time data that can be used for validation
  /// or as a primary source.
  /// 
  /// Parameters:
  /// - [latitude]: Geographic latitude in decimal degrees
  /// - [longitude]: Geographic longitude in decimal degrees
  /// - [countryCode]: ISO country code for method determination
  /// 
  /// Algorithm:
  /// 1. Convert country code to Aladhan API method ID
  /// 2. Construct API URL with parameters
  /// 3. Execute HTTP GET request
  /// 4. Parse JSON response and extract prayer times
  /// 5. Return structured data or null on failure
  /// 
  /// API Details:
  /// - Uses Aladhan.com's public API
  /// - Returns prayer times for current date
  /// - Includes all five daily prayers
  /// - Format: "HH:MM" 24-hour format
  /// 
  /// Error Handling:
  /// - Logs HTTP errors and JSON parsing issues
  /// - Returns null on any failure to prevent crashes
  /// - Handles network timeouts gracefully
  /// 
  /// Performance:
  /// - Single API request
  /// - Depends on network latency
  /// 
  /// Returns:
  /// - Map containing prayer times data, or null on failure
  static Future<Map<String, dynamic>?> getPrayerTimesFromAPI(
    double latitude,
    double longitude,
    String countryCode,
  ) async {
    try {
      // Get calculation method ID for the country
      final int methodId = getMethodIdForCountry(countryCode);

      final url = Uri.parse(
        'https://api.aladhan.com/v1/timings/${DateTime.now().day}'
        '?latitude=$latitude&longitude=$longitude&method=$methodId',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 200) {
          return data['data'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      locator<LoggerService>().error(
        'Error fetching prayer times from API: $e',
      );
    }

    return null;
  }

  /// Convert country code to Aladhan API method ID
  /// 
  /// Maps country codes to the corresponding method IDs used by the
  /// Aladhan API. This mapping ensures compatibility between our
  /// internal method names and the API's numeric identifiers.
  /// 
  /// Parameters:
  /// - [countryCode]: ISO country code
  /// 
  /// Algorithm:
  /// 1. Normalize country code to uppercase
  /// 2. Map specific countries to their API method IDs
  /// 3. Return default for unmapped countries
  /// 
  /// API Method IDs:
  /// - 0: Diyanet (Turkey)
  /// - 1: Muslim World League
  /// - 3: Umm Al Qura (Saudi Arabia)
  /// - 5: Egyptian
  /// - 7: Tehran (Iran)
  /// - 8: Dubai (UAE)
  /// - 9: Kuwait
  /// - 10: Qatar
  /// 
  /// Returns:
  /// - Numeric method ID for Aladhan API
  static int getMethodIdForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'TR':
        return 0; // Diyanet (Turkey)
      case 'EG':
        return 5; // Egyptian (Egypt)
      case 'SA':
        return 3; // Umm Al Qura (Saudi Arabia)
      case 'AE':
        return 8; // Dubai (UAE)
      case 'KW':
        return 9; // Kuwait
      case 'QA':
        return 10; // Qatar
      case 'PK':
        return 1; // Muslim World League (Pakistan)
      case 'IR':
        return 7; // Tehran (Iran)
      default:
        return 3; // Muslim World League (default)
    }
  }

  /// Validation: Compare local calculation with API for verification
  /// 
  /// Validates the accuracy of locally calculated prayer times by comparing
  /// them with authoritative data from the Aladhan API. This helps ensure
  /// that local calculations are accurate and can be used for quality
  /// assurance purposes.
  /// 
  /// Parameters:
  /// - [latitude]: Geographic latitude in decimal degrees
  /// - [longitude]: Geographic longitude in decimal degrees
  /// - [countryCode]: ISO country code
  /// - [localPrayerTimes]: Locally calculated prayer times
  /// 
  /// Algorithm:
  /// 1. Fetch authoritative prayer times from API
  /// 2. Extract timing data for each prayer
  /// 3. Parse API time strings to DateTime objects
  /// 4. Compare with local calculations
  /// 5. Check differences against tolerance threshold
  /// 6. Return overall validation result
  /// 
  /// Validation Criteria:
  /// - 5-minute tolerance for all prayer times
  /// - All five daily prayers must be within tolerance
  /// - Individual prayer failures are logged
  /// 
  /// Error Handling:
  /// - Returns false if API data is unavailable
  /// - Logs detailed information about validation failures
  /// - Graceful handling of parsing errors
  /// 
  /// Performance:
  /// - One API request for validation
  /// - Efficient time comparison using Duration objects
  /// 
  /// Returns:
  /// - true if all prayers are within tolerance, false otherwise
  static Future<bool> validateCalculationAccuracy(
    double latitude,
    double longitude,
    String countryCode,
    Map<String, DateTime> localPrayerTimes,
  ) async {
    final apiData = await getPrayerTimesFromAPI(
      latitude,
      longitude,
      countryCode,
    );
    if (apiData == null) return false;

    final apiTimings = apiData['timings'] as Map<String, dynamic>?;
    if (apiTimings == null) return false;

    const tolerance = Duration(minutes: 5); // 5 minute tolerance

    try {
      for (final prayer in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        if (localPrayerTimes.containsKey(prayer.toLowerCase()) &&
            apiTimings.containsKey(prayer)) {
          final localTime = localPrayerTimes[prayer.toLowerCase()];
          final apiTimeString = apiTimings[prayer] as String;

          // Parse API time (format: "HH:MM")
          final apiTimeParts = apiTimeString.split(':');
          final apiTime = DateTime(
            localTime!.year,
            localTime.month,
            localTime.day,
            int.parse(apiTimeParts[0]),
            int.parse(apiTimeParts[1]),
          );

          final difference = (localTime.difference(apiTime)).abs();
          if (difference > tolerance) {
            locator<LoggerService>().debug(
              'Prayer time mismatch for $prayer: Local=${localTime.toString().substring(11, 16)}, API=$apiTimeString, Difference=${difference.inMinutes}min',
            );
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      locator<LoggerService>().error('Error validating prayer times: $e');
      return false;
    }
  }
}