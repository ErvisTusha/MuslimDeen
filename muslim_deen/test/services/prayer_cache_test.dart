import 'dart:convert';
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
  T? getCache<T>(String key) => null;

  @override
  Future<bool> setCache<T>(String key, T data, {int? expirationMinutes}) async {
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
        final savedJson = mockCacheService.getData(expectedKey) as String?;

        expect(savedJson, isNotNull);
        final Map<String, dynamic> decoded =
            jsonDecode(savedJson!) as Map<String, dynamic>;
        expect(decoded.containsKey('data'), true);
        expect(decoded.containsKey('expiresAt'), true);

        // Verify no separate expiration key exists (the old way)
        expect(mockCacheService.getData('${expectedKey}_expiration'), isNull);
      },
    );

    test(
      'Expiration Handling: Should return null and clear if expired',
      () async {
        final date = DateTime(2025, 1, 1);
        final coords = Coordinates(40.7128, -74.0060);
        final expectedKey =
            'prayer_times_2025-01-01_40.713_-74.006_default_default';

        // Manually seed expired data
        final expiredData = <String, dynamic>{
          'data': <String, dynamic>{}, // content doesn't matter for this test
          'expiresAt':
              DateTime.now()
                  .subtract(const Duration(hours: 1))
                  .millisecondsSinceEpoch,
        };
        await mockCacheService.saveData(expectedKey, jsonEncode(expiredData));

        final result = await prayerCache.getCachedPrayerTimes(date, coords);

        expect(result, isNull);
        expect(mockCacheService.getData(expectedKey), isNull);
      },
    );
  });
}
