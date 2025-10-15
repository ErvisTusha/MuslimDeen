import 'dart:async';
import 'package:hijri/hijri_calendar.dart';

import 'package:muslim_deen/models/islamic_event.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service for managing Islamic events, holidays, and calendar calculations
class IslamicEventsService {
  final LoggerService _logger = locator<LoggerService>();

  // Cache for calculated events
  final Map<String, IslamicEvent> _eventCache = {};
  final Map<int, List<IslamicEvent>> _yearlyEventsCache = {};

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _precalculateEventsForCurrentYear();
      _isInitialized = true;
      _logger.info('IslamicEventsService initialized successfully');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize IslamicEventsService',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  /// Pre-calculate events for the current year
  Future<void> _precalculateEventsForCurrentYear() async {
    final now = DateTime.now();
    final hijriNow = HijriCalendar.fromDate(now);

    await _calculateEventsForYear(hijriNow.hYear);
    await _calculateEventsForYear(hijriNow.hYear + 1); // Next year too
  }

  /// Calculate all events for a specific Hijri year
  Future<void> _calculateEventsForYear(int hijriYear) async {
    if (_yearlyEventsCache.containsKey(hijriYear)) return;

    final events = <IslamicEvent>[];

    for (final baseEvent in IslamicEventsDatabase.allEvents) {
      if (!baseEvent.isRecurring && baseEvent.gregorianDate != null) {
        // Non-recurring event with fixed Gregorian date
        events.add(baseEvent);
        continue;
      }

      if (baseEvent.hijriDay != null && baseEvent.hijriMonth != null) {
        // Recurring event with fixed Hijri date
        final gregorianDate = baseEvent.getGregorianDateForYear(hijriYear);
        final eventHijri = HijriCalendar.fromDate(gregorianDate);

        final calculatedEvent = baseEvent.copyWith(
          id: '${baseEvent.id}_$hijriYear',
          hijriDate: eventHijri,
          gregorianDate: gregorianDate,
        );

        events.add(calculatedEvent);
        _eventCache[calculatedEvent.id] = calculatedEvent;
      }
    }

    _yearlyEventsCache[hijriYear] = events;

    _logger.debug(
      'Calculated events for Hijri year $hijriYear',
      data: {'eventCount': events.length},
    );
  }

  /// Get all events for a specific Gregorian year
  Future<List<IslamicEvent>> getEventsForYear(int year) async {
    await init();

    final hijri = HijriCalendar.fromDate(DateTime(year, 1, 1));
    final hijriYear = hijri.hYear;

    await _calculateEventsForYear(hijriYear);

    // Also check if events from previous Hijri year spill into this Gregorian year
    final prevYearEvents = _yearlyEventsCache[hijriYear - 1] ?? [];
    final currentYearEvents = _yearlyEventsCache[hijriYear] ?? [];

    final allEvents = [...prevYearEvents, ...currentYearEvents];

    // Filter events that actually occur in the requested Gregorian year
    return allEvents.where((event) {
      final eventDate =
          event.gregorianDate ?? event.getGregorianDateForYear(year);
      return eventDate.year == year;
    }).toList();
  }

  /// Get events for a specific month
  Future<List<IslamicEvent>> getEventsForMonth(int year, int month) async {
    final yearEvents = await getEventsForYear(year);

    return yearEvents.where((event) {
      final eventDate =
          event.gregorianDate ?? event.getGregorianDateForYear(year);
      return eventDate.month == month;
    }).toList();
  }

  /// Get events for a specific date
  Future<List<IslamicEvent>> getEventsForDate(DateTime date) async {
    final monthEvents = await getEventsForMonth(date.year, date.month);

    return monthEvents.where((event) => event.occursOnDate(date)).toList();
  }

  /// Get upcoming events from a specific date
  Future<List<IslamicEvent>> getUpcomingEvents(
    DateTime fromDate, {
    int limit = 10,
  }) async {
    final currentYear = fromDate.year;
    final nextYear = currentYear + 1;

    final currentYearEvents = await getEventsForYear(currentYear);
    final nextYearEvents = await getEventsForYear(nextYear);

    final allEvents = [...currentYearEvents, ...nextYearEvents];

    final upcomingEvents =
        allEvents.where((event) {
          final eventDate =
              event.gregorianDate ??
              event.getGregorianDateForYear(DateTime.now().year);
          return eventDate.isAfter(fromDate) ||
              eventDate.isAtSameMomentAs(fromDate);
        }).toList();

    upcomingEvents.sort((a, b) {
      final aDate =
          a.gregorianDate ?? a.getGregorianDateForYear(DateTime.now().year);
      final bDate =
          b.gregorianDate ?? b.getGregorianDateForYear(DateTime.now().year);
      return aDate.compareTo(bDate);
    });

    return upcomingEvents.take(limit).toList();
  }

  /// Get events by type
  Future<List<IslamicEvent>> getEventsByType(
    IslamicEventType type, {
    int? year,
  }) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.type == type).toList();
  }

  /// Get events by category
  Future<List<IslamicEvent>> getEventsByCategory(
    IslamicEventCategory category, {
    int? year,
  }) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.category == category).toList();
  }

  /// Get holidays
  Future<List<IslamicEvent>> getHolidays({int? year}) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.isHoliday).toList();
  }

  /// Search events
  Future<List<IslamicEvent>> searchEvents(String query, {int? year}) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return IslamicEventsDatabase.searchEvents(
      query,
    ).where(events.contains).toList();
  }

  /// Get all events (across multiple years)
  Future<List<IslamicEvent>> _getAllEvents() async {
    final now = DateTime.now();
    final currentYearEvents = await getEventsForYear(now.year);
    final nextYearEvents = await getEventsForYear(now.year + 1);

    return [...currentYearEvents, ...nextYearEvents];
  }

  /// Get Ramadan information for current year
  Future<Map<String, dynamic>> getRamadanInfo() async {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);

    // Ramadan starts on 1st of Ramadan
    final ramadanStart = DateTime(hijri.hYear + 578, 3, 1); // Approximate
    final ramadanEnd = DateTime(hijri.hYear + 578, 3, 30); // Approximate

    // If we're past this year's Ramadan, get next year's
    final effectiveRamadanStart =
        now.isAfter(ramadanEnd)
            ? DateTime(hijri.hYear + 579, 3, 1)
            : ramadanStart;
    final effectiveRamadanEnd =
        now.isAfter(ramadanEnd)
            ? DateTime(hijri.hYear + 579, 3, 30)
            : ramadanEnd;

    final isCurrentlyRamadan =
        now.isAfter(effectiveRamadanStart.subtract(const Duration(days: 1))) &&
        now.isBefore(effectiveRamadanEnd.add(const Duration(days: 1)));

    int? currentDay;
    if (isCurrentlyRamadan) {
      currentDay = now.difference(effectiveRamadanStart).inDays + 1;
    }

    final daysUntilRamadan = effectiveRamadanStart.difference(now).inDays + 1;

    return {
      'isRamadan': isCurrentlyRamadan,
      'currentDay': currentDay,
      'totalDays': 30,
      'daysUntilRamadan': daysUntilRamadan > 0 ? daysUntilRamadan : 0,
      'ramadanStart': effectiveRamadanStart,
      'ramadanEnd': effectiveRamadanEnd,
      'year': hijri.hYear + (now.isAfter(ramadanEnd) ? 1 : 0),
    };
  }

  /// Get Islamic month information
  Map<String, dynamic> getIslamicMonthInfo(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);

    final monthNames = [
      'Muharram',
      'Safar',
      'Rabi\' al-awwal',
      'Rabi\' al-thani',
      'Jumada al-awwal',
      'Jumada al-thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];

    return {
      'monthNumber': hijri.hMonth,
      'monthName': monthNames[hijri.hMonth - 1],
      'day': hijri.hDay,
      'year': hijri.hYear,
      'isRamadan': hijri.hMonth == 9,
      'isDhulHijjah': hijri.hMonth == 12,
      'daysInMonth': _getDaysInIslamicMonth(hijri.hMonth, hijri.hYear),
    };
  }

  /// Get number of days in an Islamic month
  int _getDaysInIslamicMonth(int month, int year) {
    if (month == 12) {
      // Dhul-Hijjah always has 30 days
      return 30;
    }

    // For other months, check if next month starts on day 1
    final nextMonth = HijriCalendar();
    nextMonth.hYear = year;
    nextMonth.hMonth = month + 1;
    nextMonth.hDay = 1;
    return nextMonth.hDay == 1 ? 29 : 30;
  }

  /// Get Islamic calendar information for a date range
  Future<List<Map<String, dynamic>>> getIslamicCalendarForRange(
    DateTime start,
    DateTime end,
  ) async {
    final calendar = <Map<String, dynamic>>[];
    final current = DateTime(start.year, start.month, start.day);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      final events = await getEventsForDate(current);
      final monthInfo = getIslamicMonthInfo(current);

      calendar.add({
        'date': current,
        'hijri': monthInfo,
        'events': events,
        'isHoliday': events.any((event) => event.isHoliday),
        'hasFasting': events.any((event) => event.fasting == 'obligatory'),
      });

      current.add(const Duration(days: 1));
    }

    return calendar;
  }

  /// Clear cache (useful for testing or when dates change)
  void clearCache() {
    _eventCache.clear();
    _yearlyEventsCache.clear();
    _logger.info('IslamicEventsService cache cleared');
  }

  /// Dispose of resources
  void dispose() {
    clearCache();
    _logger.info('IslamicEventsService disposed');
  }
}
