import 'dart:async';
import 'package:hijri/hijri_calendar.dart';

import 'package:muslim_deen/models/islamic_event.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service for managing Islamic events, holidays, and calendar calculations
/// 
/// This service provides comprehensive functionality for managing Islamic events,
/// holidays, and calendar calculations. It handles the conversion between Hijri
/// and Gregorian calendars, calculates Islamic events for specific years, and
/// provides various query methods for accessing event information.
/// 
/// Features:
/// - Calculate Islamic events for specific Hijri years
/// - Convert between Hijri and Gregorian calendars
/// - Get events by date, month, year, type, or category
/// - Search events by name or description
/// - Provide Ramadan information and Islamic month details
/// - Generate Islamic calendar data for date ranges
/// - Multi-level caching for performance optimization
/// 
/// Usage:
/// ```dart
/// final eventsService = IslamicEventsService();
/// await eventsService.init();
/// final todayEvents = await eventsService.getEventsForDate(DateTime.now());
/// final ramadanInfo = await eventsService.getRamadanInfo();
/// ```
/// 
/// Design Patterns:
/// - Repository: Abstracts Islamic calendar calculations and event management
/// - Cache-Aside: Implements caching with explicit invalidation
/// - Lazy Loading: Pre-calculates events on demand
/// - Strategy Pattern: Different calculation strategies for event types
/// 
/// Performance Considerations:
/// - Caches calculated events to avoid recomputation
/// - Pre-calculates events for current and next year on initialization
/// - Uses efficient date range filtering
/// - Implements cache invalidation for testing
/// 
/// Dependencies:
/// - hijri package: For Hijri calendar calculations
/// - IslamicEventsDatabase: Predefined Islamic events database
/// - LoggerService: For centralized logging
class IslamicEventsService {
  final LoggerService _logger = locator<LoggerService>();

  // Cache for calculated events
  final Map<String, IslamicEvent> _eventCache = {};
  final Map<int, List<IslamicEvent>> _yearlyEventsCache = {};

  bool _isInitialized = false;

  /// Initialize the service
  /// 
  /// Initializes the service by pre-calculating events for the current
  /// and next Hijri year. This ensures that commonly accessed events
  /// are available immediately without calculation delays.
  /// 
  /// Algorithm:
  /// 1. Checks if already initialized (idempotent)
  /// 2. Calculates current Hijri year from current date
  /// 3. Pre-calculates events for current and next year
  /// 4. Sets initialization flag
  /// 
  /// Error Handling:
  /// - Logs detailed error information
  /// - Re-throws exceptions for proper error handling by callers
  /// 
  /// Performance:
  /// - Pre-calculation improves user experience
  /// - Reduces calculation delays for common queries
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
  /// 
  /// Calculates events for the current Hijri year and the next year.
  /// This ensures that events spanning across Gregorian year boundaries
  /// are properly handled.
  /// 
  /// Algorithm:
  /// 1. Gets current Hijri date
  /// 2. Calculates events for current year
  /// 3. Calculates events for next year
  /// 
  /// Performance:
  /// - Reduces calculation delays for common queries
  /// - Ensures smooth user experience
  Future<void> _precalculateEventsForCurrentYear() async {
    final now = DateTime.now();
    final hijriNow = HijriCalendar.fromDate(now);

    await _calculateEventsForYear(hijriNow.hYear);
    await _calculateEventsForYear(hijriNow.hYear + 1); // Next year too
  }

  /// Calculate all events for a specific Hijri year
  /// 
  /// Processes all Islamic events and calculates their Gregorian dates
  /// for the specified Hijri year. Handles both recurring events with
  /// fixed Hijri dates and non-recurring events with fixed Gregorian dates.
  /// 
  /// Parameters:
  /// - [hijriYear]: The Hijri year to calculate events for
  /// 
  /// Algorithm:
  /// 1. Checks if already calculated for the year (cache hit)
  /// 2. Processes each base event from the database
  /// 3. Handles non-recurring events with fixed Gregorian dates
  /// 4. Calculates Gregorian dates for recurring Hijri events
  /// 5. Creates calculated event objects with proper IDs
  /// 6. Caches results for future use
  /// 
  /// Performance:
  /// - Caches results to avoid recalculation
  /// - Batch processing for efficiency
  /// 
  /// Error Handling:
  /// - Logs debug information for monitoring
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
  /// 
  /// Retrieves all Islamic events that occur within a specific Gregorian year.
  /// This method handles the complexity of the Hijri-Gregorian calendar
  /// conversion where Islamic events can span across Gregorian years.
  /// 
  /// Parameters:
  /// - [year]: The Gregorian year to get events for
  /// 
  /// Algorithm:
  /// 1. Initializes service if needed
  /// 2. Determines corresponding Hijri year(s)
  /// 3. Calculates events for relevant Hijri years
  /// 4. Filters events to those occurring in the requested Gregorian year
  /// 
  /// Complexity:
  /// - O(n) where n is the number of events in relevant Hijri years
  /// - Optimized with caching to avoid recalculation
  /// 
  /// Returns:
  /// - List of Islamic events occurring in the specified Gregorian year
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
  /// 
  /// Retrieves all Islamic events occurring in a specific month of a year.
  /// This is useful for month-specific views or calendar displays.
  /// 
  /// Parameters:
  /// - [year]: The Gregorian year
  /// - [month]: The Gregorian month (1-12)
  /// 
  /// Algorithm:
  /// 1. Gets all events for the year
  /// 2. Filters by month
  /// 
  /// Performance:
  /// - Leverages cached yearly events
  /// - Efficient filtering operation
  /// 
  /// Returns:
  /// - List of events occurring in the specified month
  Future<List<IslamicEvent>> getEventsForMonth(int year, int month) async {
    final yearEvents = await getEventsForYear(year);

    return yearEvents.where((event) {
      final eventDate =
          event.gregorianDate ?? event.getGregorianDateForYear(year);
      return eventDate.month == month;
    }).toList();
  }

  /// Get events for a specific date
  /// 
  /// Retrieves all Islamic events occurring on a specific date.
  /// This is useful for daily views or notifications.
  /// 
  /// Parameters:
  /// - [date]: The Gregorian date to get events for
  /// 
  /// Algorithm:
  /// 1. Gets all events for the month
  /// 2. Filters by exact date
  /// 
  /// Performance:
  /// - Leverages cached monthly events
  /// - Uses event's occursOnDate method for accurate matching
  /// 
  /// Returns:
  /// - List of events occurring on the specified date
  Future<List<IslamicEvent>> getEventsForDate(DateTime date) async {
    final monthEvents = await getEventsForMonth(date.year, date.month);

    return monthEvents.where((event) => event.occursOnDate(date)).toList();
  }

  /// Get upcoming events from a specific date
  /// 
  /// Retrieves the next set of Islamic events occurring after a given date.
  /// This is useful for upcoming events displays or notifications.
  /// 
  /// Parameters:
  /// - [fromDate]: The starting date for the search
  /// - [limit]: Maximum number of events to return (default: 10)
  /// 
  /// Algorithm:
  /// 1. Gets events for current and next year
  /// 2. Filters for events on or after the start date
  /// 3. Sorts by date chronologically
  /// 4. Limits to specified count
  /// 
  /// Performance:
  /// - Searches across two years for comprehensive results
  /// - Efficient sorting and limiting
  /// 
  /// Returns:
  /// - Chronologically sorted list of upcoming events
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
  /// 
  /// Retrieves events filtered by their Islamic event type.
  /// This is useful for category-specific views or analysis.
  /// 
  /// Parameters:
  /// - [type]: The Islamic event type to filter by
  /// - [year]: Optional year to limit the search scope
  /// 
  /// Algorithm:
  /// 1. Gets events for specified year or all years
  /// 2. Filters by event type
  /// 
  /// Returns:
  /// - List of events matching the specified type
  Future<List<IslamicEvent>> getEventsByType(
    IslamicEventType type, {
    int? year,
  }) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.type == type).toList();
  }

  /// Get events by category
  /// 
  /// Retrieves events filtered by their Islamic event category.
  /// This is useful for category-specific displays or filtering.
  /// 
  /// Parameters:
  /// - [category]: The Islamic event category to filter by
  /// - [year]: Optional year to limit the search scope
  /// 
  /// Returns:
  /// - List of events matching the specified category
  Future<List<IslamicEvent>> getEventsByCategory(
    IslamicEventCategory category, {
    int? year,
  }) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.category == category).toList();
  }

  /// Get holidays
  /// 
  /// Retrieves all events marked as holidays in the Islamic calendar.
  /// This is useful for holiday planning or special notifications.
  /// 
  /// Parameters:
  /// - [year]: Optional year to limit the search scope
  /// 
  /// Returns:
  /// - List of events marked as holidays
  Future<List<IslamicEvent>> getHolidays({int? year}) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return events.where((event) => event.isHoliday).toList();
  }

  /// Search events
  /// 
  /// Searches for events by name or description using the database
  /// search functionality. This is useful for finding specific events.
  /// 
  /// Parameters:
  /// - [query]: The search query string
  /// - [year]: Optional year to limit the search scope
  /// 
  /// Algorithm:
  /// 1. Uses database search to find matching events
  /// 2. Filters results to specified year if provided
  /// 
  /// Returns:
  /// - List of events matching the search query
  Future<List<IslamicEvent>> searchEvents(String query, {int? year}) async {
    final events =
        year != null ? await getEventsForYear(year) : await _getAllEvents();

    return IslamicEventsDatabase.searchEvents(
      query,
    ).where(events.contains).toList();
  }

  /// Get all events (across multiple years)
  /// 
  /// Retrieves events for the current and next year. This is a helper
  /// method used by other query methods when no specific year is provided.
  /// 
  /// Algorithm:
  /// 1. Gets events for current year
  /// 2. Gets events for next year
  /// 3. Combines results
  /// 
  /// Returns:
  /// - Combined list of events for current and next year
  Future<List<IslamicEvent>> _getAllEvents() async {
    final now = DateTime.now();
    final currentYearEvents = await getEventsForYear(now.year);
    final nextYearEvents = await getEventsForYear(now.year + 1);

    return [...currentYearEvents, ...nextYearEvents];
  }

  /// Get Ramadan information for current year
  /// 
  /// Calculates comprehensive Ramadan information including start/end dates,
  /// current status, day of Ramadan, and days until Ramadan. This is essential
  /// for Ramadan-specific features and notifications.
  /// 
  /// Algorithm:
  /// 1. Calculates approximate Ramadan dates (simplified calculation)
  /// 2. Determines if current date is during Ramadan
  /// 3. Calculates current day if in Ramadan
  /// 4. Calculates days until Ramadan if not started
  /// 
  /// Note:
  /// This uses simplified calculations. In practice, Ramadan start/end dates
  /// depend on moon sightings and may vary by location.
  /// 
  /// Returns:
  /// - Map containing comprehensive Ramadan information
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
  /// 
  /// Provides detailed information about the Islamic month for a given
  /// Gregorian date, including month name, day, year, and special properties.
  /// 
  /// Parameters:
  /// - [date]: The Gregorian date to get Islamic month info for
  /// 
  /// Returns:
  /// - Map containing comprehensive Islamic month information
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
  /// 
  /// Calculates the number of days in an Islamic month. Islamic months
  /// alternate between 29 and 30 days, with Dhul-Hijjah always having 30 days.
  /// 
  /// Parameters:
  /// - [month]: The Islamic month number (1-12)
  /// - [year]: The Islamic year
  /// 
  /// Algorithm:
  /// 1. Dhul-Hijjah (month 12) always has 30 days
  /// 2. For other months, checks if next month starts on day 1
  /// 3. If next month starts on day 1, current month has 29 days
  /// 4. Otherwise, current month has 30 days
  /// 
  /// Returns:
  /// - Number of days in the specified Islamic month
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
  /// 
  /// Generates comprehensive Islamic calendar data for a date range,
  /// including events, holidays, and fasting information for each day.
  /// This is useful for calendar views or comprehensive date information.
  /// 
  /// Parameters:
  /// - [start]: The start date of the range
  /// - [end]: The end date of the range
  /// 
  /// Algorithm:
  /// 1. Iterates through each day in the range
  /// 2. Gets events for each day
  /// 3. Gets Islamic month information
  /// 4. Determines holiday and fasting status
  /// 5. Compiles comprehensive daily information
  /// 
  /// Performance:
  /// - O(n) where n is the number of days in the range
  /// - Optimized with cached event queries
  /// 
  /// Returns:
  /// - List of daily Islamic calendar information
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
  /// 
  /// Clears all cached events and calculations. This is useful for
  /// testing scenarios or when date-related data needs to be refreshed.
  /// 
  /// Usage:
  /// Call this method in test setups or when date calculations
  /// might be affected by system date changes.
  void clearCache() {
    _eventCache.clear();
    _yearlyEventsCache.clear();
    _logger.info('IslamicEventsService cache cleared');
  }

  /// Dispose of resources
  /// 
  /// Cleans up resources when the service is no longer needed.
  /// Clears all caches to prevent memory leaks.
  void dispose() {
    clearCache();
    _logger.info('IslamicEventsService disposed');
  }
}