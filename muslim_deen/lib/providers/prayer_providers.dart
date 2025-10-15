import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:adhan_dart/adhan_dart.dart' show Coordinates;
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/providers/providers.dart';

import 'package:muslim_deen/services/cache_service.dart';

final locationProvider = FutureProvider<Position>((ref) async {
  final locationService = locator<LocationService>();
  return await locationService.getLocation();
});

final prayerTimesProvider = FutureProvider<adhan.PrayerTimes>((ref) async {
  final prayerService = locator<PrayerService>();
  final settings = ref.watch(settingsProvider);
  final cacheService = locator<CacheService>();
  final location = await ref.watch(locationProvider.future);

  // Check for cached prayer times
  final cachedPrayerTimes = await cacheService.getCachedPrayerTimes(
    settings,
    Coordinates(location.latitude, location.longitude),
  );
  if (cachedPrayerTimes != null) {
    return cachedPrayerTimes;
  }

  // If no cached data, fetch from network
  final prayerTimes = await prayerService.calculatePrayerTimesForToday(
    settings,
  );

  // Cache the new prayer times
  await cacheService.cachePrayerTimes(prayerTimes);

  return prayerTimes;
});

final currentPrayerProvider = Provider<String>((ref) {
  final prayerTimes = ref.watch(prayerTimesProvider);
  return prayerTimes.when(
    data: (times) => locator<PrayerService>().getCurrentPrayer(),
    loading: () => 'Loading...',
    error: (error, stackTrace) => 'Error',
  );
});

final nextPrayerProvider = Provider<String>((ref) {
  final prayerTimes = ref.watch(prayerTimesProvider);
  return prayerTimes.when(
    data: (times) => locator<PrayerService>().getNextPrayer(),
    loading: () => 'Loading...',
    error: (error, stackTrace) => 'Error',
  );
});
