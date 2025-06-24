import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/utils/prayer_display_utils.dart' as pdu;
import 'package:muslim_deen/services/prayer_service.dart';

class WidgetService {
  final LoggerService _logger = locator<LoggerService>();
  final PrayerService _prayerService = locator<PrayerService>();

  static const String _groupId = 'group.muslim_deen.widgets';
  static const String _iOSWidgetName = 'MuslimDeenWidget';

  /// Initialize the widget service
  Future<void> initialize() async {
    try {
      await HomeWidget.setAppGroupId(_groupId);
      _logger.info('Widget service initialized');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize widget service',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
    }
  }

  /// Update current/next prayer widget with current prayer data
  Future<void> updateAllWidgets({
    required AppSettings appSettings,
    required adhan.PrayerTimes prayerTimes,
    String? locationName,
  }) async {
    try {
      // Update current/next prayer widget
      await updateCurrentNextPrayerWidget(
        appSettings: appSettings,
        prayerTimes: prayerTimes,
        locationName: locationName,
      );

      _logger.info('Widget updated successfully');
    } catch (e, s) {
      _logger.error(
        'Failed to update widget',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
    }
  }

  /// Update the current/next prayer widget
  Future<void> updateCurrentNextPrayerWidget({
    required AppSettings appSettings,
    required adhan.PrayerTimes prayerTimes,
    String? locationName,
  }) async {
    try {
      // Create formatter respecting user's time format preference
      final timeFormatter = DateFormat(
        appSettings.timeFormat == TimeFormat.twentyFourHour
            ? 'HH:mm'
            : 'hh:mm a',
      );

      // Create date formatter respecting user's date format preference
      final dateFormatter = DateFormat(
        _getDateFormatPattern(appSettings.dateFormatOption),
      );

      // Get current and next prayer using the provided prayer times object
      // instead of relying on the cached service state
      final now = DateTime.now();
      final String currentPrayerStr =
          prayerTimes.currentPrayer(date: now) as String;
      final String nextPrayerStr = prayerTimes.nextPrayer(date: now) as String;

      final PrayerNotification? currentPrayerEnum =
          _getPrayerNotificationFromAdhanPrayer(currentPrayerStr);
      final PrayerNotification? nextPrayerEnum =
          _getPrayerNotificationFromAdhanPrayer(nextPrayerStr);

      String currentPrayerName = 'None';
      String currentPrayerTime = '--:--';
      if (currentPrayerEnum != null) {
        final currentInfo = _getPrayerDisplayInfo(
          currentPrayerEnum,
          prayerTimes,
          appSettings,
        );
        currentPrayerName = currentInfo.name;
        currentPrayerTime =
            currentInfo.time != null
                ? timeFormatter.format(currentInfo.time!)
                : '--:--';
      }

      String nextPrayerName = 'None';
      String nextPrayerTime = '--:--';
      String timeRemaining = '--:--';
      if (nextPrayerEnum != null) {
        final nextInfo = _getPrayerDisplayInfo(
          nextPrayerEnum,
          prayerTimes,
          appSettings,
        );
        nextPrayerName = nextInfo.name;
        nextPrayerTime =
            nextInfo.time != null
                ? timeFormatter.format(nextInfo.time!)
                : '--:--';

        // Calculate time remaining with better formatting
        if (nextInfo.time != null) {
          final now = DateTime.now();
          final duration = nextInfo.time!.difference(now);

          _logger.debug(
            'Time remaining calculation',
            data: {
              'next_prayer_time': nextInfo.time!.toIso8601String(),
              'current_time': now.toIso8601String(),
              'duration_minutes': duration.inMinutes,
              'is_negative': duration.isNegative,
            },
          );

          if (duration.isNegative) {
            timeRemaining = '00:00';
          } else {
            final hours = duration.inHours;
            final minutes = duration.inMinutes % 60;
            if (hours > 0) {
              timeRemaining = '${hours}h ${minutes}m';
            } else {
              timeRemaining = '${minutes}m';
            }
          }
        }
      }

      // Prepare widget data with theme and settings information
      final Map<String, dynamic> widgetData = {
        'current_prayer_name': currentPrayerName,
        'current_prayer_time': currentPrayerTime,
        'next_prayer_name': nextPrayerName,
        'next_prayer_time': nextPrayerTime,
        'time_remaining': timeRemaining,
        'formatted_date': dateFormatter.format(DateTime.now()),
        'theme_mode': appSettings.themeMode.name,
        'time_format': appSettings.timeFormat.name,
        'date_format': appSettings.dateFormatOption.name,
        'last_update': DateTime.now().toIso8601String(),
      };

      // Save data to widget
      for (final entry in widgetData.entries) {
        await HomeWidget.saveWidgetData<dynamic>(entry.key, entry.value);
      }

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: 'MuslimDeenWidgetProvider',
        iOSName: '${_iOSWidgetName}CurrentNext',
      );

      _logger.debug('Current/Next prayer widget updated', data: widgetData);
    } catch (e, s) {
      _logger.error(
        'Failed to update current/next prayer widget',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
    }
  }

  /// Get date format pattern based on user preference
  String _getDateFormatPattern(DateFormatOption option) {
    switch (option) {
      case DateFormatOption.dayMonthYear:
        return 'd MMM yyyy';
      case DateFormatOption.monthDayYear:
        return 'MMM d, yyyy';
      case DateFormatOption.yearMonthDay:
        return 'yyyy MMM d';
    }
  }

  /// Get prayer display information
  PrayerDisplayInfoData _getPrayerDisplayInfo(
    PrayerNotification prayerEnum,
    adhan.PrayerTimes prayerTimes,
    AppSettings appSettings,
  ) {
    return pdu.getPrayerDisplayInfo(
      prayerEnum: prayerEnum,
      prayerTimes: prayerTimes,
      appSettings: appSettings,
      getOffsettedTime: _prayerService.getOffsettedPrayerTime,
    );
  }

  /// Convert adhan prayer string to PrayerNotification enum
  PrayerNotification? _getPrayerNotificationFromAdhanPrayer(
    String adhanPrayer,
  ) {
    if (adhanPrayer == adhan.Prayer.fajr) return PrayerNotification.fajr;
    if (adhanPrayer == adhan.Prayer.sunrise) return PrayerNotification.sunrise;
    if (adhanPrayer == adhan.Prayer.dhuhr) return PrayerNotification.dhuhr;
    if (adhanPrayer == adhan.Prayer.asr) return PrayerNotification.asr;
    if (adhanPrayer == adhan.Prayer.maghrib) return PrayerNotification.maghrib;
    if (adhanPrayer == adhan.Prayer.isha) return PrayerNotification.isha;
    return null;
  }
}
