import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';

// Create the PrayerTimesCache provider
final prayerTimesCacheProvider = Provider<PrayerTimesCache>((ref) {
  final cacheService = locator<CacheService>();
  final logger = locator<LoggerService>();
  return PrayerTimesCache(cacheService, logger);
});
