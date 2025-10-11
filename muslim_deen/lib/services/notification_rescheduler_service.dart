import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:workmanager/workmanager.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';

/// Background service responsible for rescheduling notifications periodically
/// to ensure they persist even when the app hasn't been opened for days
class NotificationReschedulerService {
  static const String _rescheduleTaskName = 'reschedule_notifications';
  static const String _tesbihReminderTaskName = 'reschedule_tesbih_reminder';

  final NotificationService _notificationService;
  final PrayerService _prayerService;
  final StorageService _storageService;
  final LoggerService _logger;

  NotificationReschedulerService()
    : _notificationService = locator<NotificationService>(),
      _prayerService = locator<PrayerService>(),
      _storageService = locator<StorageService>(),
      _logger = locator<LoggerService>();

  /// Initialize the background service
  Future<void> init() async {
    try {
      await Workmanager().initialize(_callbackDispatcher);
      _logger.info('Workmanager initialized successfully');
    } catch (e, s) {
      _logger.warning(
        'Workmanager initialization failed - background rescheduling will not be available',
        error: e,
        stackTrace: s,
      );
      // Don't rethrow - background rescheduling is not critical for app functionality
      return;
    }

    try {
      // Register periodic tasks
      await _registerPeriodicTasks();
      _logger.info('NotificationReschedulerService initialized');
    } catch (e, s) {
      _logger.error(
        'Failed to register periodic tasks',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Register periodic background tasks
  Future<void> _registerPeriodicTasks() async {
    try {
      // Reschedule prayer notifications every 24 hours
      await Workmanager().registerPeriodicTask(
        _rescheduleTaskName,
        _rescheduleTaskName,
        frequency: const Duration(hours: 24),
        initialDelay: const Duration(hours: 1), // Start after 1 hour
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      // Reschedule tesbih/dhikr reminder every 6 hours
      await Workmanager().registerPeriodicTask(
        _tesbihReminderTaskName,
        _tesbihReminderTaskName,
        frequency: const Duration(hours: 6),
        initialDelay: const Duration(minutes: 30),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(hours: 1),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      );

      _logger.info('Periodic notification reschedule tasks registered');
    } catch (e, s) {
      _logger.error(
        'Failed to register periodic tasks',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Cancel all background tasks
  Future<void> cancelAllTasks() async {
    await Workmanager().cancelByUniqueName(_rescheduleTaskName);
    await Workmanager().cancelByUniqueName(_tesbihReminderTaskName);
    _logger.info('All notification reschedule tasks cancelled');
  }

  /// Force immediate reschedule of all notifications
  Future<void> rescheduleAllNotifications() async {
    await _reschedulePrayerNotifications();
    await _rescheduleTesbihReminder();
    _logger.info('All notifications rescheduled immediately');
  }

  /// Reschedule prayer notifications
  Future<void> _reschedulePrayerNotifications() async {
    try {
      // Load settings from storage
      final settingsJson = _storageService.getData('app_settings') as String?;
      if (settingsJson == null) {
        _logger.warning(
          'No app settings found, skipping prayer notification reschedule',
        );
        return;
      }

      final settings = AppSettings.fromJson(
        jsonDecode(settingsJson) as Map<String, dynamic>,
      );

      // Cancel existing prayer notifications only
      await _notificationService.cancelPrayerNotifications();

      // Get today's prayer times
      final prayerTimes = await _prayerService.calculatePrayerTimesForDate(
        DateTime.now(),
        settings,
      );

      // Schedule notifications for each enabled prayer
      final prayerNotifications = [
        ('Fajr', 0, settings.notifications[PrayerNotification.fajr] ?? false),
        ('Dhuhr', 1, settings.notifications[PrayerNotification.dhuhr] ?? false),
        ('Asr', 2, settings.notifications[PrayerNotification.asr] ?? false),
        (
          'Maghrib',
          3,
          settings.notifications[PrayerNotification.maghrib] ?? false,
        ),
        ('Isha', 4, settings.notifications[PrayerNotification.isha] ?? false),
      ];

      for (final prayer in prayerNotifications) {
        final prayerName = prayer.$1;
        final id = prayer.$2;
        final enabled = prayer.$3;

        if (!enabled) continue;

        final prayerTime = _getPrayerTimeByName(
          prayerTimes,
          prayerName.toLowerCase(),
        );
        if (prayerTime == null) continue;

        final offsettedTime = _prayerService.getOffsettedPrayerTime(
          prayerName.toLowerCase(),
          prayerTimes,
          settings,
        );

        if (offsettedTime != null && offsettedTime.isAfter(DateTime.now())) {
          await _notificationService.schedulePrayerNotification(
            id: id,
            localizedTitle: '$prayerName Prayer',
            localizedBody: 'Time for $prayerName prayer',
            prayerTime: offsettedTime,
            isEnabled: true,
            appSettings: settings,
          );
        }
      }

      _logger.info('Prayer notifications rescheduled in background');
    } catch (e, s) {
      _logger.error(
        'Error rescheduling prayer notifications in background',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Reschedule tesbih/dhikr reminder
  Future<void> _rescheduleTesbihReminder() async {
    try {
      final settingsJson = _storageService.getData('app_settings') as String?;
      if (settingsJson == null) {
        _logger.warning(
          'No app settings found, skipping dhikr reminder reschedule',
        );
        return;
      }

      final settings = AppSettings.fromJson(
        jsonDecode(settingsJson) as Map<String, dynamic>,
      );

      if (!settings.dhikrRemindersEnabled) {
        // Cancel any existing dhikr reminders if disabled
        await _notificationService.cancelNotification(9999);
        _logger.info('Dhikr reminders disabled, cancelled existing reminders');
        return;
      }

      // Check if there's already a dhikr reminder scheduled
      // For simplicity, we'll always reschedule to ensure it's up to date
      final now = DateTime.now();
      final nextReminderTime = now.add(
        Duration(hours: settings.dhikrReminderInterval),
      );

      await _notificationService.scheduleTesbihNotification(
        id: 9999,
        localizedTitle: 'Dhikr Reminder',
        localizedBody:
            '🤲 Time for your dhikr. Remember Allah with a peaceful heart.',
        scheduledTime: nextReminderTime,
        isEnabled: true,
        payload: jsonEncode({
          'type': 'dhikr_reminder',
          'intervalHours': settings.dhikrReminderInterval,
          'scheduledTime': nextReminderTime.toIso8601String(),
        }),
      );

      _logger.info(
        'Dhikr reminder rescheduled in background',
        data: {
          'enabled': settings.dhikrRemindersEnabled,
          'intervalHours': settings.dhikrReminderInterval,
          'nextReminder': nextReminderTime.toIso8601String(),
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error rescheduling dhikr reminder in background',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Get prayer time by name from prayer times object
  DateTime? _getPrayerTimeByName(
    adhan.PrayerTimes prayerTimes,
    String prayerName,
  ) {
    try {
      switch (prayerName) {
        case 'fajr':
          return prayerTimes.fajr;
        case 'dhuhr':
          return prayerTimes.dhuhr;
        case 'asr':
          return prayerTimes.asr;
        case 'maghrib':
          return prayerTimes.maghrib;
        case 'isha':
          return prayerTimes.isha;
        default:
          return null;
      }
    } catch (e) {
      _logger.error('Error getting prayer time for $prayerName', error: e);
      return null;
    }
  }
}

/// Callback dispatcher for Workmanager
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize minimal services for background execution
      await _setupBackgroundServices();

      final service = NotificationReschedulerService();

      switch (task) {
        case NotificationReschedulerService._rescheduleTaskName:
          await service._reschedulePrayerNotifications();
          break;
        case NotificationReschedulerService._tesbihReminderTaskName:
          await service._rescheduleTesbihReminder();
          break;
        default:
          locator<LoggerService>().warning('Unknown background task: $task');
      }

      return true;
    } catch (e, s) {
      // Log error but don't crash the background task
      try {
        locator<LoggerService>().error(
          'Error in background task $task',
          error: e,
          stackTrace: s,
        );
      } catch (_) {
        // If even logging fails, just return false
      }
      return false;
    }
  });
}

/// Setup minimal services for background execution
Future<void> _setupBackgroundServices() async {
  // Initialize timezone data
  // Note: We can't use the full locator setup in background
  // So we initialize only what's needed
}
