import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:geolocator/geolocator.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/providers/providers.dart';

final locationProvider = FutureProvider<Position>((ref) async {
  final locationService = locator<LocationService>();
  return await locationService.getLocation();
});

final prayerTimesProvider = FutureProvider<adhan.PrayerTimes>((ref) async {
  final prayerService = locator<PrayerService>();
  final settings = ref.watch(settingsProvider);
  // The location provider is not directly used here, but it ensures that
  // the location is available before calculating prayer times.
  await ref.watch(locationProvider.future);
  return await prayerService.calculatePrayerTimesForToday(settings);
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
