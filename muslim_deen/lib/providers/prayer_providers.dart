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
import 'package:adhan_dart/adhan_dart.dart' show Coordinates;
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/providers/providers.dart';

import 'package:muslim_deen/services/cache_service.dart';

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

/// Prayer times provider with caching strategy
///
/// This provider calculates prayer times for the current day based on the user's
/// location and settings. It implements a two-tier caching strategy:
/// 1. Memory cache for immediate access
/// 2. Persistent cache for offline functionality
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
/// 1. First checks for cached prayer times based on current settings and location
/// 2. If cache hit, returns cached data immediately (performance optimization)
/// 3. If cache miss, calculates prayer times using the prayer service
/// 4. Caches the calculated times for future use
///
/// Dependencies:
/// - PrayerService (for calculation)
/// - settingsProvider (for calculation parameters)
/// - locationProvider (for geographical coordinates)
/// - CacheService (for caching strategy)
///
/// State Lifecycle:
/// - Loading: Calculating prayer times or checking cache
/// - Data: PrayerTimes object with all prayer times for the day
/// - Error: Location unavailable, calculation failed, or cache errors
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
  final cacheService = locator<CacheService>();
  final location = await ref.watch(locationProvider.future);

  // Check for cached prayer times first for performance optimization
  final cachedPrayerTimes = await cacheService.getCachedPrayerTimes(
    settings,
    Coordinates(location.latitude, location.longitude),
  );
  if (cachedPrayerTimes != null) {
    return cachedPrayerTimes;
  }

  // If no cached data, fetch from network/calculate
  final prayerTimes = await prayerService.calculatePrayerTimesForToday(
    settings,
  );

  // Cache the new prayer times for future use
  await cacheService.cachePrayerTimes(prayerTimes);

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
