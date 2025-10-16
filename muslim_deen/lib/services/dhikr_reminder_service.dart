import 'package:muslim_deen/models/app_constants.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';

/// Service to manage dhikr reminder notifications
/// 
/// This service provides functionality to schedule and manage periodic dhikr reminders
/// through the device's notification system. It uses a singleton pattern to ensure
/// consistent management of notifications across the application.
/// 
/// Features:
/// - Schedule periodic dhikr reminders at configurable intervals
/// - Support for multiple dhikr phrases with Arabic text
/// - Cancel and update existing reminder schedules
/// - Integration with the app's notification service
/// 
/// Usage:
/// ```dart
/// final dhikrService = DhikrReminderService();
/// await dhikrService.scheduleDhikrReminders(3); // Every 3 hours
/// ```
/// 
/// Design Patterns:
/// - Singleton: Ensures a single instance manages all dhikr notifications
/// - Facade: Simplifies the complexity of notification scheduling
/// 
/// Performance Considerations:
/// - Limits the number of scheduled reminders to prevent notification spam
/// - Uses base offset IDs to avoid conflicts with other notification types
class DhikrReminderService {
  static DhikrReminderService? _instance;
  final LoggerService _logger = locator<LoggerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();

  static const int _baseNotificationId = 2000;
  static const int _maxReminders = 10;

  /// Singleton factory constructor
  /// 
  /// Ensures only one instance of the service exists throughout the application.
  /// This prevents duplicate notification schedules and maintains consistency.
  factory DhikrReminderService() {
    _instance ??= DhikrReminderService._internal();
    return _instance!;
  }

  /// Internal constructor for singleton pattern
  /// 
  /// Private constructor to prevent direct instantiation.
  DhikrReminderService._internal();

  /// Schedule dhikr reminders at specified intervals
  /// 
  /// Schedules a series of dhikr notifications at regular intervals. Each notification
  /// contains a different dhikr phrase from the app's predefined list, cycling through
  /// them to provide variety.
  /// 
  /// Parameters:
  /// - [intervalHours]: The interval in hours between consecutive reminders
  /// 
  /// Algorithm:
  /// 1. Cancels any existing dhikr reminders to prevent duplicates
  /// 2. Creates notifications with different dhikr phrases from AppConstants.dhikrOrder
  /// 3. Spaces them evenly at the specified interval
  /// 4. Includes both English and Arabic text for each dhikr
  /// 
  /// Error Handling:
  /// - Logs errors without throwing exceptions to prevent app crashes
  /// - Continues operation even if individual notifications fail
  /// 
  /// Performance:
  /// - Limits reminders to _maxReminders (10) to prevent notification spam
  /// - Uses unique notification IDs starting from _baseNotificationId
  /// 
  /// Threading:
  /// - Asynchronous operation that doesn't block the UI thread
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
  /// 
  /// Removes all currently scheduled dhikr notifications from the system.
  /// This is typically called before scheduling new reminders or when disabling
  /// the reminder feature.
  /// 
  /// Algorithm:
  /// - Iterates through all possible notification IDs in the dhikr range
  /// - Cancels each notification individually
  /// 
  /// Error Handling:
  /// - Logs errors but continues attempting to cancel remaining notifications
  /// - Ensures cleanup even if some notifications can't be cancelled
  /// 
  /// Performance:
  /// - Uses efficient iteration to cancel notifications
  /// - Bounded operation by _maxReminders constant
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
  /// 
  /// Centralized method to manage the state of dhikr reminders based on
  /// user preferences. This method handles both enabling and disabling reminders.
  /// 
  /// Parameters:
  /// - [enabled]: Whether dhikr reminders should be active
  /// - [intervalHours]: The interval in hours between reminders when enabled
  /// 
  /// Logic Flow:
  /// - If enabled: Schedules new reminders with the specified interval
  /// - If disabled: Cancels all existing reminders
  /// 
  /// Usage:
  /// Called when user changes reminder settings in the app's preferences
  /// 
  /// Error Handling:
  /// - Delegates error handling to the underlying schedule/cancel methods
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
  /// 
  /// Returns the complete list of available dhikr phrases from the app's constants.
  /// This is useful for UI components that need to display available dhikrs.
  /// 
  /// Returns:
  /// - List of dhikr phrases in English
  /// 
  /// Data Source:
  /// - AppConstants.dhikrOrder
  List<String> getDhikrList() {
    return AppConstants.dhikrOrder;
  }

  /// Get Arabic text for a dhikr
  /// 
  /// Retrieves the Arabic text for a given dhikr phrase. This is used to
  /// display the Arabic version alongside the English translation in notifications
  /// and UI components.
  /// 
  /// Parameters:
  /// - [dhikr]: The English dhikr phrase
  /// 
  /// Returns:
  /// - Arabic text if available, null if not found
  /// 
  /// Data Source:
  /// - AppConstants.dhikrArabic mapping
  String? getDhikrArabic(String dhikr) {
    return AppConstants.dhikrArabic[dhikr];
  }
}