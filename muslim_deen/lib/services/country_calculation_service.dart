import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service to automatically detect country and apply appropriate prayer time calculation method
class CountryCalculationService {
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
  static String getCalculationMethodForCountry(String countryCode) {
    return _countryToCalculationMethod[countryCode.toUpperCase()] ??
        'MuslimWorldLeague';
  }

  /// Get all supported countries and their calculation methods
  static Map<String, String> getAllSupportedCountries() {
    return Map.from(_countryToCalculationMethod);
  }

  /// Get prayer times from Aladhan API with country-specific method
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
