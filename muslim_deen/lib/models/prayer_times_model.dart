import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';

/// Domain model for prayer times, decoupled from the underlying adhan package
/// 
/// This model serves as the core data structure for prayer time information
/// throughout the MuslimDeen application. It encapsulates all prayer times for
/// a specific date along with Hijri calendar information and caching metadata.
/// 
/// Design principles:
/// - Decoupled from external packages to maintain API stability
/// - Includes both Gregorian and Hijri date information
/// - Supports caching strategies with timestamp tracking
/// - Provides business logic for next prayer determination
/// 
/// Key responsibilities:
/// - Store prayer times for all five daily prayers plus sunrise
/// - Maintain Hijri calendar context for Islamic dates
/// - Calculate next prayer based on current time
/// - Support serialization for caching and persistence
/// 
/// Data relationships:
/// - Created from adhan package PrayerTimes objects
/// - Used by CachedPrayerTimes for caching strategies
/// - Consumed by UI components for prayer time display
/// - Referenced by notification services for prayer alerts
class PrayerTimesModel {
  // ==================== PRAYER TIME FIELDS ====================
  
  /// Fajr prayer time (before sunrise)
  /// Null indicates calculation failure or unavailable data
  final DateTime? fajr;
  
  /// Sunrise time (not a prayer time, but important for fasting)
  /// Null indicates calculation failure or unavailable data
  final DateTime? sunrise;
  
  /// Dhuhr prayer time (midday, when sun is at its highest)
  /// Null indicates calculation failure or unavailable data
  final DateTime? dhuhr;
  
  /// Asr prayer time (afternoon)
  /// Null indicates calculation failure or unavailable data
  final DateTime? asr;
  
  /// Maghrib prayer time (sunset)
  /// Null indicates calculation failure or unavailable data
  final DateTime? maghrib;
  
  /// Isha prayer time (night)
  /// Null indicates calculation failure or unavailable data
  final DateTime? isha;

  // ==================== DATE FIELDS ====================
  
  /// Gregorian date for which these prayer times are calculated
  /// Used as the primary reference for prayer time association
  final DateTime date;

  // ==================== HIJRI CALENDAR FIELDS ====================
  
  /// Hijri day number (1-30)
  /// Part of the Islamic lunar calendar date
  final int hijriDay;
  
  /// Hijri month number (1-12, where 1 = Muharram)
  /// Part of the Islamic lunar calendar date
  final int hijriMonth;
  
  /// Hijri year number
  /// Islamic lunar calendar year
  final int hijriYear;
  
  /// Hijri month name in Arabic/English
  /// Localized name of the Hijri month for display purposes
  final String hijriMonthName;

  // ==================== CACHING FIELDS ====================
  
  /// Timestamp when this prayer times data was cached
  /// Used for cache invalidation and debugging
  /// Null indicates fresh calculation (not from cache)
  final DateTime? cachedAt;

  /// Creates a new PrayerTimesModel with complete prayer time information
  /// 
  /// Parameters:
  /// - [fajr] through [isha]: Prayer times for the day (nullable for error handling)
  /// - [date]: Gregorian date for these prayer times (required)
  /// - [hijriDay] through [hijriMonthName]: Hijri calendar information (required)
  /// - [cachedAt]: Cache timestamp (optional, null for fresh data)
  /// 
  /// Notes:
  /// - Prayer times can be null to handle calculation failures gracefully
  /// - Date fields are required for proper data integrity
  /// - Hijri information provides Islamic calendar context
  const PrayerTimesModel({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.date,
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriYear,
    required this.hijriMonthName,
    this.cachedAt,
  });

  /// Creates a PrayerTimesModel from an adhan package PrayerTimes object
  /// 
  /// This factory method converts external prayer time calculations
  /// into our internal domain model, maintaining decoupling from
  /// the adhan package implementation details.
  /// 
  /// Parameters:
  /// - [prayerTimes]: Adhan package PrayerTimes object to convert
  /// - [date]: Gregorian date for the prayer times
  /// 
  /// Returns: New PrayerTimesModel with converted data
  /// 
  /// Notes:
  /// - Hijri date is calculated from the Gregorian date
  /// - cachedAt is null as this represents fresh calculation
  /// - All prayer times are transferred directly
  factory PrayerTimesModel.fromAdhanPrayerTimes(
    adhan.PrayerTimes prayerTimes,
    DateTime date,
  ) {
    final hijri = HijriCalendar.fromDate(date);

    return PrayerTimesModel(
      fajr: prayerTimes.fajr,
      sunrise: prayerTimes.sunrise,
      dhuhr: prayerTimes.dhuhr,
      asr: prayerTimes.asr,
      maghrib: prayerTimes.maghrib,
      isha: prayerTimes.isha,
      date: date,
      hijriDay: hijri.hDay,
      hijriMonth: hijri.hMonth,
      hijriYear: hijri.hYear,
      hijriMonthName: hijri.longMonthName,
      // cachedAt is not set here as this is for fresh calculation
    );
  }

  // ==================== SERIALIZATION METHODS ====================

  /// Serializes this PrayerTimesModel to a JSON map
  /// 
  /// Converts the model to a format suitable for storage in databases,
  /// SharedPreferences, or network transmission. Handles null prayer times
  /// gracefully and includes caching metadata.
  /// 
  /// Serialization details:
  /// - DateTime objects converted to ISO8601 strings
  /// - Null prayer times stored as null values
  /// - cachedAt defaults to current time if null (for caching)
  /// - All fields preserved for complete reconstruction
  /// 
  /// Returns: Map<String, dynamic> containing all model data
  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr?.toIso8601String(),
      'sunrise': sunrise?.toIso8601String(),
      'dhuhr': dhuhr?.toIso8601String(),
      'asr': asr?.toIso8601String(),
      'maghrib': maghrib?.toIso8601String(),
      'isha': isha?.toIso8601String(),
      'date': date.toIso8601String(),
      'hijriDay': hijriDay,
      'hijriMonth': hijriMonth,
      'hijriYear': hijriYear,
      'hijriMonthName': hijriMonthName,
      'cachedAt':
          cachedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(), // Store current time if not set
    };
  }

  /// Deserializes a PrayerTimesModel from a JSON map
  /// 
  /// Reconstructs the model from stored data with robust error handling
  /// for date parsing and null value management. Used for loading
  /// cached prayer times or persistent storage.
  /// 
  /// Parameters:
  /// - [json]: Map containing serialized prayer times data
  /// 
  /// Returns: New PrayerTimesModel with restored data
  /// 
  /// Error handling:
  /// - Invalid date strings result in null prayer times
  /// - Required date field throws if invalid (data integrity)
  /// - All other fields use safe parsing with null fallbacks
  factory PrayerTimesModel.fromJson(Map<String, dynamic> json) {
    DateTime? safeParseDateTime(String? dateString) {
      return dateString == null ? null : DateTime.tryParse(dateString);
    }

    return PrayerTimesModel(
      fajr: safeParseDateTime(json['fajr'] as String?),
      sunrise: safeParseDateTime(json['sunrise'] as String?),
      dhuhr: safeParseDateTime(json['dhuhr'] as String?),
      asr: safeParseDateTime(json['asr'] as String?),
      maghrib: safeParseDateTime(json['maghrib'] as String?),
      isha: safeParseDateTime(json['isha'] as String?),
      date: DateTime.parse(json['date'] as String),
      hijriDay: json['hijriDay'] as int,
      hijriMonth: json['hijriMonth'] as int,
      hijriYear: json['hijriYear'] as int,
      hijriMonthName: json['hijriMonthName'] as String,
      cachedAt: safeParseDateTime(json['cachedAt'] as String?),
    );
  }

  // ==================== BUSINESS LOGIC METHODS ====================

  /// Gets all prayer times as a list of PrayerTime objects
  /// 
  /// Internal helper method that converts individual prayer time fields
  /// into structured PrayerTime objects with display metadata. This
  /// centralizes prayer time configuration and presentation logic.
  /// 
  /// Returns: List of PrayerTime objects in chronological order
  /// 
  /// Performance considerations:
  /// - Creates new list on each call (intentional for immutability)
  /// - Includes icons for UI consistency
  /// - Order matches traditional Islamic prayer sequence
  List<PrayerTime> _getAllPrayers() {
    return [
      PrayerTime(name: 'Fajr', time: fajr, iconData: Icons.nights_stay),
      PrayerTime(
        name: 'Sunrise',
        time: sunrise,
        iconData: Icons.wb_sunny_outlined,
      ),
      PrayerTime(name: 'Dhuhr', time: dhuhr, iconData: Icons.wb_sunny),
      PrayerTime(name: 'Asr', time: asr, iconData: Icons.wb_sunny_outlined),
      PrayerTime(
        name: 'Maghrib',
        time: maghrib,
        iconData: Icons.nights_stay_outlined,
      ),
      PrayerTime(name: 'Isha', time: isha, iconData: Icons.nights_stay),
    ];
  }

  /// Determines the next prayer based on the current time
  /// 
  /// This core business logic method identifies which prayer comes next
  /// from the current moment. It handles edge cases like end-of-day
  /// scenarios and null prayer times gracefully.
  /// 
  /// Business rules:
  /// - Returns the first prayer after current time
  /// - If all prayers have passed, returns tomorrow's Fajr
  /// - Handles null prayer times with appropriate fallbacks
  /// - Maintains prayer time for tomorrow's calculations
  /// 
  /// Returns: PrayerTime object representing the next prayer
  /// 
  /// Edge cases handled:
  /// - All prayer times are null (returns Fajr template)
  /// - Current time is after all prayers (returns tomorrow's Fajr)
  /// - Individual prayer times are null (skipped in calculations)
  PrayerTime getNextPrayer() {
    final now = DateTime.now();
    final prayers = _getAllPrayers();

    for (final prayer in prayers) {
      if (prayer.time != null && prayer.time!.isAfter(now)) {
        return prayer;
      }
    }

    // If all prayers for today have passed or their times are null,
    // the next prayer is Fajr of the next day.
    // 'this.date' is the date for which the current PrayerTimesModel instance was created.

    final fajrPrayerTemplate = prayers.first; // Assuming prayers.first is Fajr

    // If Fajr time itself is null in the template, we can't determine a specific time for tomorrow's Fajr.
    if (fajrPrayerTemplate.time == null) {
      return fajrPrayerTemplate.copyWith(
        isTomorrow: true,
        // time will remain null, name remains 'Fajr' (or whatever prayers.first is)
      );
    }

    // Construct the DateTime for Fajr tomorrow
    // using the hour and minute from today's Fajr prayer time.
    final DateTime fajrTimeTomorrow = DateTime(
      date.year,
      date.month,
      date.day + 1, // Advance to the next day from the model's date
      fajrPrayerTemplate.time!.hour,
      fajrPrayerTemplate.time!.minute,
    );

    return fajrPrayerTemplate.copyWith(
      time: fajrTimeTomorrow,
      isTomorrow: true,
    );
  }
}

/// Represents a single prayer time with display metadata
/// 
/// This lightweight data class encapsulates all information needed to
/// display a prayer time in the UI, including the prayer name, actual time,
/// appropriate icon, and temporal context (today vs tomorrow).
/// 
/// Design considerations:
/// - Immutable data structure for safe UI updates
/// - Includes UI-specific metadata (icons, temporal flags)
/// - Supports copyWith pattern for efficient updates
/// - Separates display concerns from calculation logic
class PrayerTime {
  /// Display name of the prayer (e.g., 'Fajr', 'Dhuhr')
  final String name;
  
  /// Actual prayer time, can be null for calculation failures
  final DateTime? time;
  
  /// Material Design icon for visual representation
  /// Chosen to match the prayer's time of day
  final IconData iconData;
  
  /// Flag indicating if this prayer time is for tomorrow
  /// Used for UI display when current time is after all today's prayers
  final bool isTomorrow;

  /// Creates a new PrayerTime with specified properties
  /// 
  /// Parameters:
  /// - [name]: Display name of the prayer (required)
  /// - [time]: Actual prayer time (nullable for error handling)
  /// - [iconData]: Material Design icon (required)
  /// - [isTomorrow]: Whether this is tomorrow's prayer (defaults to false)
  const PrayerTime({
    required this.name,
    this.time,
    required this.iconData,
    this.isTomorrow = false,
  });

  /// Creates a copy of this PrayerTime with specified fields replaced
  /// 
  /// Implements the immutable update pattern for safe modifications.
  /// Only the provided parameters are updated; all others retain
  /// their original values.
  /// 
  /// Parameters:
  /// - All fields are optional and nullable
  /// - When a parameter is null, the original value is preserved
  /// 
  /// Returns: New PrayerTime instance with updated values
  PrayerTime copyWith({
    String? name,
    DateTime? time,
    IconData? iconData,
    bool? isTomorrow,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      iconData: iconData ?? this.iconData,
      isTomorrow: isTomorrow ?? this.isTomorrow,
    );
  }
}