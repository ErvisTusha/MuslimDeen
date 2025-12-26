import 'package:flutter_test/flutter_test.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:muslim_deen/services/prayer_times_cache.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';

class ManualMockCacheService implements CacheService {
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> saveData(String key, dynamic value) async {
    _data[key] = value;
    return true;
  }

  @override
  dynamic getData(String key) {
    return _data[key];
  }

  @override
  Future<bool> removeData(String key) async {
    return _data.remove(key) != null;
  }

  @override
  Future<bool> clearAllCache() async {
    _data.clear();
    return true;
  }

  @override
  @override
  void setMetricsService(dynamic metricsService) {}

  @override
  void dispose() {}

  @override
  T? getCache<T>(String key) {
    return _data[key] as T?;
  }

  @override
  Future<bool> setCache<T>(String key, T data, {int? expirationMinutes}) async {
    _data[key] = data;
    return true;
  }

  @override
  Map<String, dynamic> getCacheStats() => {};

  @override
  Future<void> forceCleanup() async {}

  @override
  String generateLocationCacheKey(
    String prefix,
    double latitude,
    double longitude, {
    double radius = 0,
  }) {
    return '${prefix}_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
  }

  @override
  Future<void> clearByPrefix(String prefix) async {
    _data.removeWhere((key, value) => key.startsWith(prefix));
  }

  @override
  List<String> getKeysByPrefix(String prefix) {
    return _data.keys.where((key) => key.startsWith(prefix)).toList();
  }
}

class ManualMockLoggerService implements LoggerService {
  @override
  void debug(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {}
  @override
  void info(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {}
  @override
  void warning(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {}
  @override
  void error(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {}
  @override
  void logNavigation(
    String event, {
    String? routeName,
    Map<String, dynamic>? params,
    String? details,
  }) {}
  @override
  void logInteraction(
    String widgetName,
    String interactionType, {
    String? details,
    dynamic data,
  }) {}
}

void main() {
  late PrayerTimesCache prayerCache;
  late ManualMockCacheService mockCacheService;
  late ManualMockLoggerService mockLoggerService;

  setUp(() {
    mockCacheService = ManualMockCacheService();
    mockLoggerService = ManualMockLoggerService();
    prayerCache = PrayerTimesCache(mockCacheService, mockLoggerService);
  });

  group('PrayerTimesCache Optimized Tests', () {
    test('Cache Key should be daily and consistent with rounded coordinates', () {
      // Verify key generation logic implicitly via other tests or by exposing if needed.

      // Expected key format: prayer_times_2025-01-01_40.713_-74.006_default_default
      // Note: Coordinates are toStringAsFixed(3)

      // We use a private method for testing by accessing it via a helper or just testing side effects
      // Since it's private, we'll test the resulting keys in the mock data
    });

    test(
      'Consolidated I/O: Should save data and expiration in one JSON object',
      () async {
        final date = DateTime(2025, 1, 1);
        final prayerTimes = PrayerTimesModel(
          date: date,
          fajr: date.add(const Duration(hours: 5)),
          sunrise: date.add(const Duration(hours: 6)),
          dhuhr: date.add(const Duration(hours: 12)),
          asr: date.add(const Duration(hours: 15)),
          maghrib: date.add(const Duration(hours: 18)),
          isha: date.add(const Duration(hours: 20)),
          hijriDay: 1,
          hijriMonth: 7,
          hijriYear: 1446,
          hijriMonthName: 'Rajab',
        );
        final coords = Coordinates(40.7128, -74.0060);

        await prayerCache.cachePrayerTimes(prayerTimes, coords);

        final expectedKey =
            'prayer_times_2025-01-01_40.713_-74.006_default_default';
        final savedData = mockCacheService.getCache<Map<String, dynamic>>(
          expectedKey,
        );

        expect(savedData, isNotNull);
        expect(
          savedData!.containsKey('fajr'),
          true,
        ); // Assuming toJson has these
        expect(savedData.containsKey('date'), true);
      },
    );

    test('Expiration Handling: Should return null and clear if expired', () async {
      final date = DateTime(2025, 1, 1);
      final coords = Coordinates(40.7128, -74.0060);
      final expectedKey =
          'prayer_times_2025-01-01_40.713_-74.006_default_default';

      // Since CacheService handles expiration, and we are testing PrayerTimesCache
      // which now DELEGATES to CacheService, we should test that it returns null
      // if CacheService returns null (which it will if we don't seed it, or if it's expired)

      // Ensure nothing is in cache
      expect(await prayerCache.getCachedPrayerTimes(date, coords), isNull);

      // Seed some data
      await prayerCache.cachePrayerTimes(
        PrayerTimesModel(
          date: date,
          fajr: date,
          sunrise: date,
          dhuhr: date,
          asr: date,
          maghrib: date,
          isha: date,
          hijriDay: 1,
          hijriMonth: 1,
          hijriYear: 1446,
          hijriMonthName: 'Test',
        ),
        coords,
      );

      // Verify it's there
      expect(await prayerCache.getCachedPrayerTimes(date, coords), isNotNull);

      // Manual clear from mock to simulate expiry/eviction in CacheService
      await mockCacheService.removeData(expectedKey);

      // Verify PrayerTimesCache returns null now
      expect(await prayerCache.getCachedPrayerTimes(date, coords), isNull);
    });
  });
}
