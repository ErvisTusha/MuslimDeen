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

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationResponse,
      );

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

  /// Handle notification response when app is in foreground
  void _onNotificationResponse(NotificationResponse response) {
    _handleNotificationResponse(response);
  }

  /// Handle notification response when app is in background
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Initialize minimal services for background
    // For now, just log the response
    // In a full implementation, you'd initialize services and handle the response
  }

  /// Handle notification response
  void _handleNotificationResponse(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final type = data['type'] as String?;

        if (type == 'dhikr_reminder') {
          // Reschedule the next dhikr reminder
          final intervalHours = data['intervalHours'] as int? ?? 4;
          _rescheduleNextDhikrReminder(intervalHours);
        }
      }

      _logger.info(
        'Notification response handled',
        data: {
          'notificationId': response.id,
          'actionId': response.actionId,
          'payload': payload,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error handling notification response',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Reschedule the next dhikr reminder
  Future<void> _rescheduleNextDhikrReminder(int intervalHours) async {
    try {
      final now = DateTime.now();
      final nextReminderTime = now.add(Duration(hours: intervalHours));

      await scheduleTesbihNotification(
        id: 9999,
        localizedTitle: 'Dhikr Reminder',
        localizedBody:
            '🤲 Time for your dhikr. Remember Allah with a peaceful heart.',
        scheduledTime: nextReminderTime,
        isEnabled: true,
        payload: jsonEncode({
          'type': 'dhikr_reminder',
          'intervalHours': intervalHours,
          'scheduledTime': nextReminderTime.toIso8601String(),
        }),
      );

      _logger.info(
        'Next dhikr reminder rescheduled',
        data: {
          'nextReminder': nextReminderTime.toIso8601String(),
          'intervalHours': intervalHours,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error rescheduling next dhikr reminder',
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
      _logger.warning(
        'Failed to initialize background rescheduling - notifications will still work but may not persist across device restarts',
        error: e,
        stackTrace: s,
      );
      // Don't rethrow - background rescheduling is not critical for basic notification functionality
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

  /// Cancels only prayer notifications
  Future<void> cancelPrayerNotifications() async {
    if (!_isInitialized) return;
    try {
      await Future.wait(
        PrayerNotification.values.map(
          (prayer) => _notificationsPlugin.cancel(prayer.index),
        ),
      );
      _logger.info('Cancelled prayer notifications.');
    } catch (e, s) {
      _logger.error(
        'Error cancelling prayer notifications',
        error: e,
        stackTrace: s,
      );
    }
  }

  // Helper utilities keep prayer notifications aligned with their custom azan
  // selection so future changes don't mix audio routing logic.
  PrayerNotification? _mapIdToPrayerNotification(int id) {
    if (id < 0 || id >= PrayerNotification.values.length) {
      return null;
    }
    return PrayerNotification.values[id];
  }

  bool _shouldUseCustomAdhan(PrayerNotification? prayer) {
    if (prayer == null) return false;
    return const {
      PrayerNotification.dhuhr,
      PrayerNotification.asr,
      PrayerNotification.maghrib,
      PrayerNotification.isha,
    }.contains(prayer);
  }

  String _extractAndroidRawResourceName(String? fileName) {
    if (fileName == null || fileName.isEmpty) return 'default';
    final sanitized = fileName.split('/').last;
    final withoutExtension = sanitized.split('.').first;
    return withoutExtension.toLowerCase();
  }

  AndroidNotificationDetails _buildPrayerAndroidDetails({
    required bool useCustomSound,
    required String? azanFileName,
  }) {
    final soundResource =
        useCustomSound
            ? RawResourceAndroidNotificationSound(
              _extractAndroidRawResourceName(azanFileName),
            )
            : null;

    final channelSuffix =
        useCustomSound
            ? _extractAndroidRawResourceName(azanFileName)
            : 'default';

    return AndroidNotificationDetails(
      'prayer_channel_${channelSuffix}_v2',
      'Prayer Notifications${useCustomSound ? ' ($channelSuffix)' : ''}',
      channelDescription:
          'Prayer alerts${useCustomSound ? ' with custom azan audio' : ''}',
      importance: Importance.high,
      priority: Priority.high,
      sound: soundResource,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.notification,
      enableVibration: true,
    );
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
      // Ensure prayer time is in the future by scheduling for next day if needed
      final now = DateTime.now();
      DateTime scheduledTime = prayerTime;

      // If prayer time has already passed today, schedule for tomorrow
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        _logger.debug(
          'Prayer time was in the past, scheduling for tomorrow',
          data: {
            'originalTime': prayerTime.toIso8601String(),
            'scheduledTime': scheduledTime.toIso8601String(),
          },
        );
      }

      final prayer = _mapIdToPrayerNotification(id);
      final bool useCustomSound = _shouldUseCustomAdhan(prayer);

      final androidDetails = _buildPrayerAndroidDetails(
        useCustomSound: useCustomSound,
        azanFileName: appSettings.azanSoundForStandardPrayers,
      );

      final darwinDetails = DarwinNotificationDetails(
        sound: useCustomSound ? appSettings.azanSoundForStandardPrayers : null,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        localizedTitle,
        localizedBody,
        TZDateTime.from(scheduledTime, getLocation('UTC')),
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _logger.info(
        'Scheduled prayer notification',
        data: {'id': id, 'time': scheduledTime.toIso8601String()},
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
      final androidDetails = AndroidNotificationDetails(
        'tesbih_channel_v3',
        'Tesbih Notifications',
        channelDescription:
            'Daily tasbih reminder respecting system sound mode',
        importance: Importance.high,
        priority: Priority.high,
        audioAttributesUsage: AudioAttributesUsage.notification,
        enableVibration: true,
        playSound: true,
        sound: null,
      );
      const darwinDetails = DarwinNotificationDetails();
      final platformDetails = NotificationDetails(
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
