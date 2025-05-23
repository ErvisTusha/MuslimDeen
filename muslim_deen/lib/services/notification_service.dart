import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Represents the current status of notification permissions
enum NotificationPermissionStatus { granted, denied, notDetermined, restricted }

// Removed class NotificationConfig

/// Represents different notification channels with their specific settings
enum NotificationChannel {
  prayer(
    id: 'muslim_deen_prayer_channel',
    name: 'Prayer Time Notifications',
    description: 'Channel for upcoming prayer time alerts.',
    importance: Importance.max,
    priority: Priority.high,
  ),
  general(
    id: 'muslim_deen_general_channel',
    name: 'General Notifications',
    description: 'Channel for general app notifications.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  final String id;
  final String name;
  final String description;
  final Importance importance;
  final Priority priority;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.priority,
  });
}

// Removed class NotificationException

/// Service responsible for managing local notifications in the application
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final LoggerService _logger = locator<LoggerService>();
  bool _isInitialized = false;
  NotificationPermissionStatus _permissionStatus =
      NotificationPermissionStatus.notDetermined;
  bool _hasExactAlarmPermission = false;
  final bool _disposed = false;

  final _permissionStatusController =
      StreamController<NotificationPermissionStatus>.broadcast();

  NotificationService();

  Stream<NotificationPermissionStatus> get permissionStatusStream =>
      _permissionStatusController.stream;

  bool get isBlocked =>
      _permissionStatus == NotificationPermissionStatus.denied ||
      _permissionStatus == NotificationPermissionStatus.restricted;

  // Removed getter canRequestPermission

  Future<void> init() async {
    if (_isInitialized || _disposed) return;
    _logger.info('NotificationService initialization started.');

    await _initializeTimezone();
    await _initializeNotificationsPlugin();
    // Clean up expired notifications on startup
    if (_isInitialized && !_disposed) {
      _cleanupExpiredNotifications();
    }
  }

  Future<void> _initializeTimezone() async {
    try {
      tz_data.initializeTimeZones();
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
        if (!_isValidTimeZone(timeZoneName)) {
          _logger.warning(
            'Invalid timezone: $timeZoneName. Falling back to UTC.',
          );
          timeZoneName = 'UTC';
        }
      } catch (tzError, s) {
        _logger.error(
          'Error getting timezone. Falling back to UTC.',
          error: tzError,
          stackTrace: s,
        );
        timeZoneName = 'UTC';
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _logger.info('Timezone initialized', data: {'timezone': timeZoneName});
    } catch (e, s) {
      _logger.error(
        'Error initializing timezone data. Falling back to UTC.',
        error: e,
        stackTrace: s,
      );
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        _logger.error('Failed to set UTC as fallback timezone.');
      }
    }
  }

  Future<void> _initializeNotificationsPlugin() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
            _handleBackgroundNotificationResponse,
      );

      await _checkInitialPermissions();
      await _checkExactAlarmsSupport(checkOnly: true);
      _isInitialized = true;
      _logger.info('NotificationService initialized successfully.');
    } catch (e, s) {
      _isInitialized = false;
      _logger.error(
        'Error initializing notifications plugin',
        error: e,
        stackTrace: s,
      );
    }
  }

  bool _isValidTimeZone(String timeZoneName) {
    try {
      tz.getLocation(timeZoneName);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Removed method dispose()
  // Removed method checkPermissionStatus()

  void _updatePermissionStatus(NotificationPermissionStatus status) {
    if (_permissionStatus != status && !_disposed) {
      _permissionStatus = status;
      _logger.info(
        'Notification permission status updated',
        data: {'status': status.toString()},
      );
      if (!_permissionStatusController.isClosed) {
        _permissionStatusController.add(status);
      }
    }
  }

  Future<bool> requestPermission() async {
    if (_disposed) return false;
    _logger.info('Requesting notification permissions explicitly.');
    if (_permissionStatus == NotificationPermissionStatus.granted) {
      _logger.info("Permissions already granted.");
      return true;
    }
    if (_permissionStatus == NotificationPermissionStatus.denied ||
        _permissionStatus == NotificationPermissionStatus.restricted) {
      _logger.warning(
        'Permissions are denied/restricted. User must enable them in settings.',
      );
      return false;
    }

    try {
      bool? granted = false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();
        granted = await androidPlugin?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: false,
            );
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        granted = await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
              critical: false,
            );
      }
      granted ??= false;
      _updatePermissionStatus(
        granted
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied,
      );
      _logger.info("Permission request result", data: {"granted": granted});
      return granted;
    } catch (e, s) {
      _logger.error(
        'Error requesting notifications permission',
        error: e,
        stackTrace: s,
      );
      _updatePermissionStatus(NotificationPermissionStatus.denied);
      return false;
    }
  }

  Future<void> _handleNotificationResponse(NotificationResponse details) async {
    _logger.info(
      'Notification tapped',
      data: {
        'id': details.id,
        'payload': details.payload,
        'actionId': details.actionId,
      },
    );
    if (details.payload != null && details.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> payloadData =
            jsonDecode(details.payload!) as Map<String, dynamic>;
        _logger.debug("Decoded notification payload", data: payloadData);
        // Handle navigation or actions based on payload
      } catch (e) {
        _logger.warning(
          "Error decoding notification payload",
          data: {"payload": details.payload, "error": e.toString()},
        );
      }
    }
  }

  static void _handleBackgroundNotificationResponse(
    NotificationResponse details,
  ) {
    if (kDebugMode) {
      print(
        '[BACKGROUND] Notification tapped: id=${details.id}, actionId=${details.actionId}, payload=${details.payload}',
      );
    }
  }

  Future<bool> _checkExactAlarmsSupport({bool checkOnly = false}) async {
    if (defaultTargetPlatform != TargetPlatform.android || _disposed) {
      // For non-Android or if disposed, exact alarms are not an issue or service is down.
      // Consider non-Android as having "exact alarm" capability by default.
      _hasExactAlarmPermission =
          (defaultTargetPlatform != TargetPlatform.android && !_disposed);
      return _hasExactAlarmPermission;
    }

    try {
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidPlugin != null) {
        // First check if we can schedule exact alarms
        final bool? canScheduleExact =
            await androidPlugin.canScheduleExactNotifications();

        _hasExactAlarmPermission = canScheduleExact ?? false;

        if (_hasExactAlarmPermission) {
          _logger.info('Exact alarm permission is granted.');
          return true;
        }

        // Permission not granted, try to request it if not in checkOnly mode
        if (!checkOnly) {
          _logger.info('Requesting exact alarm permission...');

          final bool? exactRequested =
              await androidPlugin.requestExactAlarmsPermission();
          _hasExactAlarmPermission = exactRequested ?? false;

          if (_hasExactAlarmPermission) {
            _logger.info('Exact alarm permission GRANTED after request.');
          } else {
            _logger.warning(
              'Exact alarm permission DENIED. User needs to enable in settings.',
            );
          }
        } else {
          // checkOnly was true, and permission was not initially granted
          _logger.warning(
            'Exact alarm permission is NOT granted (checkOnly mode).',
          );
        }

        return _hasExactAlarmPermission;
      }

      // Non-Android platforms don't need exact alarm permission
      // This case should ideally be caught by the initial check, but as a fallback:
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        _hasExactAlarmPermission =
            true; // iOS/macOS don't have this specific "exact alarm" permission concept like Android S+
        return true;
      }

      return false; // Should not be reached if platform is Android, iOS, or macOS
    } catch (e, s) {
      _logger.error(
        'Error checking/requesting exact alarms support',
        error: e,
        stackTrace: s,
      );
      _hasExactAlarmPermission = false; // Ensure flag is false on error
      return false;
    }
  }

  // Removed method displayInstantNotification()

  Future<void> schedulePrayerNotification({
    required int id,
    required String localizedTitle,
    required String localizedBody,
    required DateTime prayerTime,
    required bool isEnabled,
    String? payload,
    AppSettings? appSettings,
  }) async {
    if (!isEnabled || _disposed) {
      if (isEnabled == false) await cancelNotification(id);
      return;
    }

    // If the prayer time has already passed today, schedule for next day
    DateTime scheduledTime = prayerTime;
    if (prayerTime.isBefore(DateTime.now())) {
      scheduledTime = prayerTime.add(const Duration(days: 1));
      _logger.info(
        'Prayer time passed, scheduling for next day',
        data: {
          'id': id,
          'title': localizedTitle,
          'originalTime': prayerTime.toIso8601String(),
          'scheduledTime': scheduledTime.toIso8601String(),
        },
      );
    }

    if (!_isInitialized) await init();
    if (isBlocked) {
      _logger.warning(
        'Notifications are blocked. Cannot schedule prayer notification.',
        data: {'id': id, 'title': localizedTitle},
      );
      return;
    }

    bool useExact = _hasExactAlarmPermission;
    if (defaultTargetPlatform == TargetPlatform.android && !useExact) {
      useExact = await _checkExactAlarmsSupport(checkOnly: true);
      if (!useExact) {
        _logger.warning(
          'Scheduling prayer notification without exact alarm permission. Timing might be inexact.',
          data: {'id': id, 'title': localizedTitle},
        );
      }
    }

    // Enhanced sound selection logic for prayer notifications
    String? soundName;
    bool useCustomSound = false;

    // Map notification ID to PrayerNotification enum
    PrayerNotification? prayerType;
    if (id >= 0 && id < PrayerNotification.values.length) {
      prayerType = PrayerNotification.values[id];
    }

    // Apply sound selection rules based on prayer type
    if (prayerType != null) {
      switch (prayerType) {
        case PrayerNotification.dhuhr:
        case PrayerNotification.asr:
        case PrayerNotification.maghrib:
        case PrayerNotification.isha:
          // Use selected Adhan for main prayers
          soundName =
              appSettings?.azanSoundForStandardPrayers ?? 'makkah_adhan.mp3';
          useCustomSound = true;
          _logger.info(
            'Using custom Adhan sound for ${prayerType.name}',
            data: {'soundName': soundName},
          );
          break;
        case PrayerNotification.fajr:
        case PrayerNotification.sunrise:
          // Use default system sound for Fajr and Sunrise
          soundName = null;
          useCustomSound = false;
          _logger.info('Using default system sound for ${prayerType.name}');
          break;
      }
    } else {
      // For non-prayer notifications (like Tesbih reminders), use default system sound
      soundName = null;
      useCustomSound = false;
      _logger.info(
        'Using default system sound for non-prayer notification',
        data: {'id': id},
      );
    }

    _logger.info(
      'Notification sound configuration',
      data: {
        'id': id,
        'prayerType': prayerType?.name ?? 'unknown',
        'soundName': soundName ?? 'default_system',
        'useCustomSound': useCustomSound,
        'selectedAdhan': appSettings?.azanSoundForStandardPrayers,
      },
    );

    final androidDetails = _createAndroidPrayerDetails(
      soundName,
      useCustomSound,
    );
    final darwinDetails = _createDarwinPrayerDetails(soundName, useCustomSound);

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final String effectivePayload =
        payload ??
        jsonEncode({
          'prayerTime': scheduledTime.toIso8601String(),
          'title': localizedTitle,
          'prayerType': prayerType?.name,
        });

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        localizedTitle,
        localizedBody,
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        androidScheduleMode:
            useExact
                ? AndroidScheduleMode.exactAllowWhileIdle
                : AndroidScheduleMode.alarmClock,
        payload: effectivePayload,
      );

      _logger.info(
        'Scheduled prayer notification successfully',
        data: {
          'id': id,
          'title': localizedTitle,
          'prayerType': prayerType?.name ?? 'unknown',
          'time': scheduledTime.toIso8601String(),
          'exact': useExact,
          'sound': soundName ?? 'default_system',
          'useCustomSound': useCustomSound,
        },
      );
    } catch (e, s) {
      _logger.error(
        'Error scheduling notification',
        error: e,
        stackTrace: s,
        data: {
          'id': id,
          'title': localizedTitle,
          'prayerType': prayerType?.name ?? 'unknown',
        },
      );
    }
  }

  AndroidNotificationDetails _createAndroidPrayerDetails(
    String? soundName,
    bool useCustomSound,
  ) {
    // For Android, if using custom sound, it must be in res/raw and name without extension
    final String? androidSound =
        useCustomSound && soundName != null
            ? (soundName.endsWith('.mp3')
                ? soundName.substring(0, soundName.length - 4)
                : soundName)
            : null;

    return AndroidNotificationDetails(
      NotificationChannel.prayer.id,
      NotificationChannel.prayer.name,
      channelDescription: NotificationChannel.prayer.description,
      importance: NotificationChannel.prayer.importance,
      priority: NotificationChannel.prayer.priority,
      enableLights: true,
      ledColor: Colors.green,
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true, // Always true, sound selection handles custom/default
      sound:
          useCustomSound && androidSound != null
              ? RawResourceAndroidNotificationSound(androidSound)
              : null,
      showWhen: true,
      usesChronometer: false,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
    );
  }

  DarwinNotificationDetails _createDarwinPrayerDetails(
    String? soundName,
    bool useCustomSound,
  ) {
    // For iOS/macOS, if using custom sound, it's the full filename in the bundle
    return DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true, // Always true, sound selection handles custom/default
      sound:
          useCustomSound && soundName != null
              ? soundName
              : null, // Use null for default system sound
      categoryIdentifier: 'prayerTime',
    );
  }

  Future<void> cancelNotification(int id) async {
    if (kIsWeb || _disposed) {
      if (kIsWeb) {
        _logger.debug(
          'Skipping cancelNotification on web platform.',
          data: {'id': id},
        );
      }
      return;
    }
    try {
      await _notificationsPlugin.cancel(id);
      _logger.info('Cancelled notification', data: {'id': id});
    } catch (e, s) {
      _logger.error(
        'Error cancelling notification',
        error: e,
        stackTrace: s,
        data: {'id': id},
      );
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb || _disposed) {
      if (kIsWeb) {
        _logger.debug('Skipping cancelAllNotifications on web platform.');
      }
      return;
    }
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

  Future<void> _cleanupExpiredNotifications() async {
    if (!_isInitialized || _disposed) return;

    try {
      final List<PendingNotificationRequest> pendingNotifications =
          await _notificationsPlugin.pendingNotificationRequests();

      final now = tz.TZDateTime.now(tz.local);
      int cleanedCount = 0;

      for (final notification in pendingNotifications) {
        if (notification.payload != null && notification.payload!.isNotEmpty) {
          try {
            final Map<String, dynamic> payloadData =
                jsonDecode(notification.payload!) as Map<String, dynamic>;
            if (payloadData.containsKey('prayerTime')) {
              final scheduledTime = DateTime.tryParse(
                payloadData['prayerTime'] as String,
              );
              if (scheduledTime != null && scheduledTime.isBefore(now)) {
                await cancelNotification(notification.id);
                cleanedCount++;
              }
            }
          } catch (e) {
            _logger.warning(
              'Error parsing notification payload during cleanup',
              data: {
                'payload': notification.payload,
                'id': notification.id,
                'error_string': e.toString(),
              },
            );
          }
        }
      }

      if (cleanedCount > 0) {
        _logger.info('Cleaned up $cleanedCount expired notifications');
      }
    } catch (e) {
      _logger.error('Error cleaning up notifications', error: e);
    }
  }

  // Removed method requestExactAlarmPermission()
  // Removed getter permissionStatus
  // Removed getter isInitialized
  // Removed getter hasExactAlarmPermission

  Future<void> _checkInitialPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      final bool? enabled = await androidPlugin?.areNotificationsEnabled();
      _updatePermissionStatus(
        enabled == true
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied,
      );
      if (enabled != true) {
        _logger.info(
          "Android notifications are not enabled. User needs to enable them in system settings.",
        );
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      // Note: This will prompt the user for permission if it hasn't been determined yet.
      // This is because requestPermission() is called, which actively seeks user consent.
      // DarwinInitializationSettings are set not to request permission on init,
      // so this explicit call handles the initial request if needed.
      await requestPermission();
    }
  }
}
