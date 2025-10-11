import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';

/// Service to manage dhikr reminder notifications
class DhikrReminderService {
  static DhikrReminderService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();

  static const int _baseNotificationId = 2000;
  static const int _maxReminders = 10;

  factory DhikrReminderService() {
    _instance ??= DhikrReminderService._internal();
    return _instance!;
  }

  DhikrReminderService._internal();

  /// Schedule dhikr reminders at specified intervals
  Future<void> scheduleDhikrReminders(int intervalHours) async {
    try {
      await cancelDhikrReminders();

      final dhikrList = AppConstants.dhikrOrder;
      final now = DateTime.now();

      _logger.info('Scheduling dhikr reminders every $intervalHours hours');

      for (int i = 0; i < _maxReminders && i < dhikrList.length * 3; i++) {
        final dhikrIndex = i % dhikrList.length;
        final dhikr = dhikrList[dhikrIndex];
        final arabic = AppConstants.dhikrArabic[dhikr] ?? '';

        final scheduledTime = now.add(Duration(hours: intervalHours * (i + 1)));

        // Use the scheduleTesbihNotification method which is similar to what we need
        await _notificationService.scheduleTesbihNotification(
          id: _baseNotificationId + i,
          localizedTitle: 'Time for Dhikr',
          localizedBody: '$dhikr\n$arabic',
          scheduledTime: scheduledTime,
          isEnabled: true,
        );
      }

      _logger.info('Scheduled $_maxReminders dhikr reminder notifications');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to schedule dhikr reminders',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancel all dhikr reminder notifications
  Future<void> cancelDhikrReminders() async {
    try {
      for (int i = 0; i < _maxReminders; i++) {
        await _notificationService.cancelNotification(_baseNotificationId + i);
      }
      _logger.info('Cancelled all dhikr reminder notifications');
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to cancel dhikr reminders',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update dhikr reminders when interval changes
  Future<void> updateDhikrReminders({
    required bool enabled,
    required int intervalHours,
  }) async {
    if (enabled) {
      await scheduleDhikrReminders(intervalHours);
    } else {
      await cancelDhikrReminders();
    }
  }

  /// Get the list of dhikr phrases
  List<String> getDhikrList() {
    return AppConstants.dhikrOrder;
  }

  /// Get Arabic text for a dhikr
  String? getDhikrArabic(String dhikr) {
    return AppConstants.dhikrArabic[dhikr];
  }
}
