import 'dart:convert';
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/dhikr_reminder_service.dart';

class ManualMockNotificationService implements NotificationService {
  @override
  bool get isBlocked => false;
  @override
  Stream<NotificationPermissionStatus> get permissionStatusStream =>
      Stream.empty();
  @override
  Future<void> init() async {}
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> cancelPrayerNotifications() async {}
  @override
  Future<void> cancelNotification(int id) async {}
  @override
  Future<void> cancelAllNotifications() async {}
  @override
  Future<void> schedulePrayerNotification({
    required int id,
    required String localizedTitle,
    required String localizedBody,
    required DateTime prayerTime,
    required bool isEnabled,
    required AppSettings appSettings,
  }) async {}
  @override
  Future<void> scheduleTesbihNotification({
    required int id,
    required String localizedTitle,
    required String localizedBody,
    required DateTime scheduledTime,
    required bool isEnabled,
    String? payload,
  }) async {}
  @override
  void dispose() {}
  @override
  Map<String, dynamic> getNotificationCacheStatistics() => {};
  @override
  Future<void> clearNotificationCache() async {}
  @override
  Map<String, dynamic>? getCachedNotificationPreferences() => null;
  @override
  Future<void> cacheNotificationPreferences(AppSettings settings) async {}
  @override
  Future<void> rescheduleAllNotifications() async {}
}

class ManualMockPrayerService implements PrayerService {
  @override
  Future<void> init() async {}
  @override
  Future<adhan.PrayerTimes> calculatePrayerTimesForToday(
    AppSettings? settings,
  ) async {
    throw UnimplementedError();
  }

  @override
  DateTime? getOffsettedPrayerTimeSync(
    String prayerName,
    adhan.PrayerTimes rawPrayerTimes,
    AppSettings settings,
  ) => null;
  @override
  Future<adhan.PrayerTimes> calculatePrayerTimesForDate(
    DateTime date,
    AppSettings? settings,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> recalculatePrayerTimesIfNeeded(AppSettings settings) async {}
  @override
  Future<void> precomputeUpcomingPrayerTimes() async {}
  @override
  bool isPrecomputeNeeded() => false;
  @override
  Map<String, dynamic> getPrecomputeStatus() => {};
  @override
  Map<String, dynamic> getCacheStatistics() => {};
  @override
  void setMetricsService(dynamic metricsService) {}
  @override
  void dispose() {}
  @override
  String getCurrentPrayer() => 'none';
  @override
  String getNextPrayer() => 'none';
  @override
  Future<DateTime?> getNextPrayerTime() async => null;
  @override
  Future<DateTime?> getOffsettedPrayerTime(
    String prayerName,
    adhan.PrayerTimes rawPrayerTimes,
    AppSettings settings, {
    dynamic currentPosition,
  }) async => null;
}

class ManualMockDhikrReminderService implements DhikrReminderService {
  @override
  Future<void> scheduleDhikrReminders(int intervalHours) async {}
  @override
  Future<void> cancelDhikrReminders() async {}
  @override
  Future<void> updateDhikrReminders({
    required bool enabled,
    required int intervalHours,
  }) async {}
  @override
  List<String> getDhikrList() => [];
  @override
  String? getDhikrArabic(String dhikr) => null;
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
  TestWidgetsFlutterBinding.ensureInitialized();
  late StorageService storageService;
  late ManualMockLoggerService mockLogger;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockLogger = ManualMockLoggerService();

    storageService = StorageService();
    await storageService.init();

    // Setup Service Locator (still needed by some parts)
    if (locator.isRegistered<LoggerService>()) {
      await locator.unregister<LoggerService>();
    }
    locator.registerSingleton<LoggerService>(mockLogger);

    if (locator.isRegistered<StorageService>()) {
      await locator.unregister<StorageService>();
    }
    locator.registerSingleton<StorageService>(storageService);
  });

  // Helper to create a container with overrides
  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        loggerServiceProvider.overrideWithValue(mockLogger),
        notificationServiceProvider.overrideWithValue(
          ManualMockNotificationService(),
        ),
        prayerServiceProvider.overrideWithValue(ManualMockPrayerService()),
        dhikrReminderServiceProvider.overrideWithValue(
          ManualMockDhikrReminderService(),
        ),
      ],
    );
  }

  group('SettingsNotifier Tests', () {
    test('Should load default settings on fresh start', () {
      final container = createContainer();
      addTearDown(container.dispose);

      final state = container.read(settingsProvider);

      expect(state.calculationMethod, AppSettings.defaults.calculationMethod);
      expect(state.madhab, AppSettings.defaults.madhab);
    });

    test('Should persist settings when updated', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      final newMethod = 'NorthAmerica';

      await notifier.updateCalculationMethod(newMethod);

      expect(container.read(settingsProvider).calculationMethod, newMethod);

      // Verify persistence in SharedPreferences
      final storedJson = storageService.getData('app_settings');
      expect(storedJson, isNotNull);
      final decoded = jsonDecode(storedJson as String);
      expect(decoded['calculationMethod'], newMethod);
    });

    test('Should reset to defaults correctly', () async {
      final container = createContainer();
      addTearDown(container.dispose);

      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateMadhab('shafi');
      expect(container.read(settingsProvider).madhab, 'shafi');

      await notifier.resetToDefaults();

      expect(
        container.read(settingsProvider).madhab,
        AppSettings.defaults.madhab,
      );

      // Verify storage reflects reset
      final storedJson = storageService.getData('app_settings');
      final decoded = jsonDecode(storedJson as String);
      expect(decoded['madhab'], AppSettings.defaults.madhab);
    });
  });
}
