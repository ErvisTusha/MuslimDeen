import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/material.dart';
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
  });

  /// Create a PrayerTimesModel from adhan package's PrayerTimes
  factory PrayerTimesModel.fromAdhanPrayerTimes(
    adhan.PrayerTimes prayerTimes,
    DateTime date,
  ) {
    // Convert to Hijri date
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
    );
  }

  /// Get all prayer times as a list of PrayerTime objects
  List<PrayerTime> getAllPrayers() {
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
    final prayers = getAllPrayers();

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
  final DateTime? time; // Made nullable
  final IconData iconData;
  final bool isTomorrow;

  PrayerTime({
    required this.name,
    this.time, // Made nullable
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

  /// Get the remaining time until this prayer
  Duration timeUntil() {
    if (time == null) return Duration.zero; // Handle null time
    return time!.difference(DateTime.now());
  }

  /// Format the remaining time as a string
  String formatTimeRemaining() {
    if (time == null) return "N/A";

    final duration = timeUntil();
    if (duration.isNegative) return "Passed"; // Explicitly handle passed time first

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    // final seconds = duration.inSeconds % 60; // If you need seconds too

    if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (minutes > 0) { // Changed from minutes >= 0 to minutes > 0
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (duration.inSeconds > 0) { // Handle cases where only seconds remain
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'second' : 'seconds'}';
    }
    return "Now"; // If duration is exactly zero or very small (less than a second)
  }
}
