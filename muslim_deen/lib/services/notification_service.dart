import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_rescheduler_service.dart';

/// Service responsible for managing local notifications in the application
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final LoggerService _logger = locator<LoggerService>();
  bool _isInitialized = false;
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.notDetermined;
  final _permissionStatusController =
      StreamController<NotificationPermissionStatus>.broadcast();

  NotificationService();

  /// Whether notifications are blocked
  bool get isBlocked =>
      _permissionStatus == NotificationPermissionStatus.denied ||
      _permissionStatus == NotificationPermissionStatus.restricted;

  /// Stream of permission status changes
  Stream<NotificationPermissionStatus> get permissionStatusStream =>
      _permissionStatusController.stream;

  /// Initializes the notification service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings();

      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _notificationsPlugin.initialize(initializationSettings);

      _isInitialized = true;
      _logger.info('NotificationService initialized successfully.');

      // Initialize background rescheduling
      await _initBackgroundRescheduling();
    } catch (e, s) {
      _isInitialized = false;
      _logger.error(
        'Failed to initialize NotificationService',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Requests notification permission
  Future<bool> requestPermission() async {
    try {
      final PermissionStatus status = await Permission.notification.request();
      switch (status) {
        case PermissionStatus.granted:
          _permissionStatus = NotificationPermissionStatus.granted;
          break;
        case PermissionStatus.denied:
          _permissionStatus = NotificationPermissionStatus.denied;
          break;
        case PermissionStatus.restricted:
          _permissionStatus = NotificationPermissionStatus.restricted;
          break;
        case PermissionStatus.permanentlyDenied:
          _permissionStatus = NotificationPermissionStatus.denied;
          break;
        case PermissionStatus.limited:
          _permissionStatus = NotificationPermissionStatus.granted;
          break;
        case PermissionStatus.provisional:
          _permissionStatus = NotificationPermissionStatus.granted;
          break;
      }
      _permissionStatusController.add(_permissionStatus);
      _logger.info(
        "Permission request result",
        data: {"status": status.toString()},
      );
      return status.isGranted;
    } catch (e, s) {
      _logger.error(
        'Error requesting notification permission',
        error: e,
        stackTrace: s,
      );
      _permissionStatus = NotificationPermissionStatus.denied;
      _permissionStatusController.add(_permissionStatus);
      return false;
    }
  }

  /// Initialize background rescheduling service
  Future<void> _initBackgroundRescheduling() async {
    try {
      final rescheduler = NotificationReschedulerService();
      await rescheduler.init();
      _logger.info('Background notification rescheduling initialized');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize background rescheduling',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Cancels all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancelAll();
      _logger.info('Cancelled all notifications.');
    } catch (e, s) {
      _logger.error(
        'Error cancelling all notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Reschedule all notifications (called on app start and boot)
  Future<void> rescheduleAllNotifications() async {
    try {
      final rescheduler = NotificationReschedulerService();
      await rescheduler.rescheduleAllNotifications();
      _logger.info('All notifications rescheduled on app start');
    } catch (e, s) {
      _logger.error(
        'Failed to reschedule notifications on app start',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Cancels a specific notification
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(id);
      _logger.info('Cancelled notification', data: {'id': id});
    } catch (e, s) {
      _logger.error('Error cancelling notification', error: e, stackTrace: s);
    }
  }

  /// Schedules a prayer notification
  Future<void> schedulePrayerNotification({
    required int id,
    required String localizedTitle,
    required String localizedBody,
    required DateTime prayerTime,
    required bool isEnabled,
    required AppSettings appSettings,
  }) async {
    if (!isEnabled || !_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        localizedTitle,
        localizedBody,
        TZDateTime.from(prayerTime, getLocation('UTC')),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _logger.info(
        'Scheduled prayer notification',
        data: {'id': id, 'time': prayerTime.toIso8601String()},
      );
    } catch (e, s) {
      _logger.error(
        'Error scheduling prayer notification',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Schedules a Tesbih notification
  Future<void> scheduleTesbihNotification({
    required int id,
    required String localizedTitle,
    required String localizedBody,
    required DateTime scheduledTime,
    required bool isEnabled,
    String? payload,
  }) async {
    if (!isEnabled || !_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'tesbih_channel',
        'Tesbih Notifications',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final effectivePayload =
          payload ??
          jsonEncode({
            'scheduledTime': scheduledTime.toIso8601String(),
            'title': localizedTitle,
            'type': 'tesbih',
          });

      await _notificationsPlugin.zonedSchedule(
        id,
        localizedTitle,
        localizedBody,
        TZDateTime.from(scheduledTime, getLocation('UTC')),
        platformDetails,
        payload: effectivePayload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _logger.info('Scheduled tesbih notification', data: {'id': id});
    } catch (e, s) {
      _logger.error(
        'Error scheduling tesbih notification',
        error: e,
        stackTrace: s,
      );
    }
  }
}
