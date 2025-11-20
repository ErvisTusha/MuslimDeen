/// Prayer-related providers for the MuslimDeen application
///
/// This file contains providers that manage prayer-related state including location,
/// prayer times calculation, and current/next prayer detection. These providers
/// form the core of the prayer functionality and implement caching strategies
/// for optimal performance.
///
/// Architecture Notes:
/// - Uses FutureProvider for async operations (location, prayer times)
/// - Implements caching strategy to reduce network requests
/// - Leverages service locator for dependency injection
/// - Provides derived state for current and next prayers
/// - Handles loading and error states gracefully

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/providers/providers.dart';

/// Location provider for device GPS coordinates
///
/// This provider asynchronously retrieves the device's current location using
/// the LocationService. It handles permission requests and provides the
/// geographical coordinates needed for prayer times calculation.
///
/// Provider Type: FutureProvider<Position>
///
/// Why FutureProvider was chosen:
/// - Location retrieval is an asynchronous operation that may require user permission
/// - Provides automatic loading and error state handling
/// - Handles location service failures gracefully
/// - Integrates with Riverpod's dependency tracking system
///
/// State Lifecycle:
/// - Loading: Requesting location permissions and retrieving GPS coordinates
/// - Data: Position object with latitude and longitude available
/// - Error: Location access denied, service unavailable, or timeout
///
/// Dependencies:
/// - LocationService (from service locator)
/// - Device GPS hardware and location permissions
///
/// Error Handling:
/// - Permission denied errors are handled by the FutureProvider
/// - Location service unavailability is propagated as error state
/// - Timeouts are handled by the underlying location service
///
/// Usage Example:
/// ```dart
/// final locationAsync = ref.watch(locationProvider);
/// return locationAsync.when(
///   data: (position) => Text('Lat: ${position.latitude}, Lon: ${position.longitude}'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Location error: $error'),
/// );
/// ```
final locationProvider = FutureProvider<Position>((ref) async {
  final locationService = locator<LocationService>();
  return await locationService.getLocation();
});

/// Location information provider with geocoding for city/country display
///
/// This provider extends the basic location provider by performing reverse
/// geocoding to convert GPS coordinates into human-readable location names.
/// It provides city and country information for display in the UI.
///
/// Provider Type: FutureProvider<LocationInfo>
///
/// Why FutureProvider was chosen:
/// - Location retrieval and geocoding are asynchronous operations
/// - Provides automatic loading and error state handling
/// - Handles geocoding failures gracefully with fallbacks
/// - Reacts to location changes automatically
///
/// State Lifecycle:
/// - Loading: Retrieving GPS coordinates and performing geocoding
/// - Data: LocationInfo object with coordinates, city, and country
/// - Error: Location unavailable or geocoding failed
///
/// Dependencies:
/// - locationProvider (for GPS coordinates)
/// - Geocoding package (for reverse geocoding)
///
/// Error Handling:
/// - Geocoding failures fall back to coordinate display
/// - Network issues are handled gracefully
/// - Invalid coordinates return coordinate-only info
///
/// Usage Example:
/// ```dart
/// final locationInfoAsync = ref.watch(locationInfoProvider);
/// return locationInfoAsync.when(
///   data: (info) => Text('${info.city}, ${info.country}'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Location unavailable'),
/// );
/// ```
final locationInfoProvider = FutureProvider<LocationInfo>((ref) async {
  final position = await ref.watch(locationProvider.future);

  try {
    // Perform reverse geocoding to get city and country
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      return LocationInfo(
        position: position,
        city: placemark.locality ?? placemark.subAdministrativeArea,
        country: placemark.country,
      );
    }
  } catch (e) {
    // If geocoding fails, return coordinates-only info
  }

  // Fallback to coordinates-only if geocoding fails
  return LocationInfo(
    position: position,
    city: null,
    country: null,
  );
});

/// Prayer times provider with caching strategy
///
/// This provider calculates prayer times for the current day based on the user's
/// location and settings. It relies on PrayerService's internal caching mechanism
/// which provides location-aware caching with PrayerTimesCache.
///
/// Provider Type: FutureProvider<adhan.PrayerTimes>
///
/// Why FutureProvider was chosen:
/// - Prayer times calculation involves async operations and potential network requests
/// - Handles caching logic and error states automatically
/// - Provides loading state during calculation
/// - Reacts to location and settings changes
///
/// Caching Strategy:
/// - PrayerService uses PrayerTimesCache with location-aware keys
/// - Cache keys include coordinates rounded to 4 decimal places
/// - Automatic cache invalidation on location changes
/// - Background precomputation for upcoming days
///
/// Dependencies:
/// - PrayerService (for calculation and caching)
/// - settingsProvider (for calculation parameters)
/// - locationProvider (for geographical coordinates)
///
/// State Lifecycle:
/// - Loading: Calculating prayer times or checking cache
/// - Data: PrayerTimes object with all prayer times for the day
/// - Error: Location unavailable, calculation failed, or service errors
///
/// Rebuild Triggers:
/// - Location changes (new coordinates)
/// - Settings changes (calculation method, madhab, offsets)
/// - Date changes (new day)
///
/// Usage Example:
/// ```dart
/// final prayerTimesAsync = ref.watch(prayerTimesProvider);
/// return prayerTimesAsync.when(
///   data: (prayerTimes) => PrayerTimesWidget(times: prayerTimes),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Prayer times error: $error'),
/// );
/// ```
final prayerTimesProvider = FutureProvider<adhan.PrayerTimes>((ref) async {
  final prayerService = locator<PrayerService>();
  final settings = ref.watch(settingsProvider);
  
  // PrayerService handles caching internally with location-aware PrayerTimesCache
  final prayerTimes = await prayerService.calculatePrayerTimesForToday(settings);

  return prayerTimes;
});

/// Current prayer provider
///
/// This provider determines which prayer is currently active based on the
/// current time and calculated prayer times. It derives its state from the
/// prayerTimesProvider and provides a simple string representation.
///
/// Provider Type: Provider<String>
///
/// Why Provider was chosen:
/// - Synchronous computation based on existing async data
/// - No need for additional async operations
/// - Provides immediate state updates when prayer times change
/// - Simple state type (String) for easy consumption
///
/// State Logic:
/// - Watches prayerTimesProvider for changes
/// - When prayer times are available, determines current prayer
/// - Returns 'Loading...' during calculation
/// - Returns 'Error' if prayer times calculation failed
///
/// Dependencies:
/// - prayerTimesProvider (for prayer times data)
/// - PrayerService.getCurrentPrayer() method
///
/// State Values:
/// - String prayer name (e.g., 'Fajr', 'Dhuhr', 'Asr', etc.)
/// - 'Loading...' when prayer times are being calculated
/// - 'Error' when prayer times calculation failed
///
/// Usage Example:
/// ```dart
/// final currentPrayer = ref.watch(currentPrayerProvider);
/// return Text(
///   currentPrayer == 'Loading...' ? 'Calculating...' :
///   currentPrayer == 'Error' ? 'Cannot determine prayer' :
///   'Current: $currentPrayer'
/// );
/// ```
final currentPrayerProvider = Provider<String>((ref) {
  final prayerTimes = ref.watch(prayerTimesProvider);
  return prayerTimes.when(
    data: (times) => locator<PrayerService>().getCurrentPrayer(),
    loading: () => 'Loading...',
    error: (error, stackTrace) => 'Error',
  );
});

/// Next prayer provider
///
/// This provider determines the next upcoming prayer based on the current
/// time and calculated prayer times. It helps users prepare for the next
/// prayer and is essential for countdown functionality.
///
/// Provider Type: Provider<String>
///
/// Why Provider was chosen:
/// - Synchronous computation based on existing async data
/// - No additional async operations required
/// - Provides immediate state updates when prayer times change
/// - Simple state type for easy consumption by UI components
///
/// State Logic:
/// - Watches prayerTimesProvider for changes
/// - When prayer times are available, determines next prayer
/// - Returns 'Loading...' during calculation
/// - Returns 'Error' if prayer times calculation failed
///
/// Dependencies:
/// - prayerTimesProvider (for prayer times data)
/// - PrayerService.getNextPrayer() method
///
/// State Values:
/// - String prayer name (e.g., 'Dhuhr', 'Asr', 'Maghrib', etc.)
/// - 'Loading...' when prayer times are being calculated
/// - 'Error' when prayer times calculation failed
///
/// Usage Example:
/// ```dart
/// final nextPrayer = ref.watch(nextPrayerProvider);
/// return Text(
///   nextPrayer == 'Loading...' ? 'Calculating...' :
///   nextPrayer == 'Error' ? 'Cannot determine next prayer' :
///   'Next: $nextPrayer'
/// );
/// ```
final nextPrayerProvider = Provider<String>((ref) {
  final prayerTimes = ref.watch(prayerTimesProvider);
  return prayerTimes.when(
    data: (times) => locator<PrayerService>().getNextPrayer(),
    loading: () => 'Loading...',
    error: (error, stackTrace) => 'Error',
  );
});

/// Data class for location information including geocoded city and country
class LocationInfo {
  final Position position;
  final String? city;
  final String? country;

  const LocationInfo({
    required this.position,
    this.city,
    this.country,
  });

  /// Returns a display-friendly city name, falling back to coordinates if geocoding failed
  String get displayCity {
    if (city != null && city!.isNotEmpty) {
      return city!;
    }
    // Fallback to coordinates if geocoding failed
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  /// Returns a display-friendly country name, or empty string if not available
  String get displayCountry {
    return country ?? '';
  }
}
