import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/services/notification_cache_service.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  late NotificationCacheService cacheService;
  late SharedPreferences prefs;
  late ManualMockLoggerService mockLogger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    mockLogger = ManualMockLoggerService();
    if (locator.isRegistered<LoggerService>()) {
      await locator.unregister<LoggerService>();
    }
    locator.registerSingleton<LoggerService>(mockLogger);

    final cache = CacheService(prefs);
    cacheService = NotificationCacheService(cacheService: cache);
  });

  group('NotificationCacheService Tests', () {
    test('Should cache and retrieve notification schedule', () async {
      final key = 'test_notification';
      final data = {
        'id': 1,
        'title': 'Test',
        'scheduledTime': DateTime.now().toIso8601String(),
      };

      await cacheService.cacheNotificationSchedule(key, data);

      final retrieved = cacheService.getCachedNotificationSchedule(key);
      expect(retrieved, isNotNull);
      expect(retrieved!['id'], 1);
      expect(retrieved['title'], 'Test');
    });

    test('Should handle non-existent keys', () {
      final retrieved = cacheService.getCachedNotificationSchedule('missing');
      expect(retrieved, isNull);
    });

    test('Should clear all cache', () async {
      await cacheService.cacheNotificationSchedule('k1', {'id': 1});
      await cacheService.cacheNotificationSchedule('k2', {'id': 2});

      await cacheService.clearAllNotificationCache();

      expect(cacheService.getCachedNotificationSchedule('k1'), isNull);
      expect(cacheService.getCachedNotificationSchedule('k2'), isNull);
    });

    test('Should identify if notification is already scheduled', () async {
      final key = 'daily_fajr';
      expect(cacheService.getCachedNotificationSchedule(key), isNull);

      await cacheService.cacheNotificationSchedule(key, {
        'status': 'scheduled',
      });
      expect(cacheService.getCachedNotificationSchedule(key), isNotNull);
    });
  });
}
