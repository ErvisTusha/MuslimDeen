import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';

/// Domain model for prayer times, decoupled from the underlying adhan package
class PrayerTimesModel {
  final DateTime? fajr;
  final DateTime? sunrise;
  final DateTime? dhuhr;
  final DateTime? asr;
  final DateTime? maghrib;
  final DateTime? isha;
  final DateTime date;

  // Hijri date information
  final int hijriDay;
  final int hijriMonth;
  final int hijriYear;
  final String hijriMonthName;

  // Added field for caching timestamp, useful for debugging cache
  final DateTime? cachedAt; 

  PrayerTimesModel({
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
    this.cachedAt, // Initialize new field
  });

  /// Create a PrayerTimesModel from adhan package's PrayerTimes
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

  // toJson method
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
      'cachedAt': cachedAt?.toIso8601String() ?? DateTime.now().toIso8601String(), // Store current time if not set
    };
  }

  // fromJson factory
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

  /// Get all prayer times as a list of PrayerTime objects
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

  /// Get the next prayer based on current time
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

/// Represents a single prayer time
class PrayerTime {
  final String name;
  final DateTime? time;
  final IconData iconData;
  final bool isTomorrow;

  PrayerTime({
    required this.name,
    this.time,
    required this.iconData,
    this.isTomorrow = false,
  });

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
