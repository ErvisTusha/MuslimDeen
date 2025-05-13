import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

/// Domain model for prayer times, decoupled from the underlying adhan package
class PrayerTimesModel {
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
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
      fajr: prayerTimes.fajr ?? DateTime.now(),
      sunrise: prayerTimes.sunrise ?? DateTime.now(),
      dhuhr: prayerTimes.dhuhr ?? DateTime.now(),
      asr: prayerTimes.asr ?? DateTime.now(),
      maghrib: prayerTimes.maghrib ?? DateTime.now(),
      isha: prayerTimes.isha ?? DateTime.now(),
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
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // If no prayer is upcoming today, return first prayer but mark it as tomorrow
    final tomorrow = prayers.first.copyWith(
      time: DateTime(
        date.year,
        date.month,
        date.day + 1,
        prayers.first.time.hour,
        prayers.first.time.minute,
      ),
      isTomorrow: true,
    );

    return tomorrow;
  }
}

/// Represents a single prayer time
class PrayerTime {
  final String name;
  final DateTime time;
  final IconData iconData;
  final bool isTomorrow;

  PrayerTime({
    required this.name,
    required this.time,
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
    return time.difference(DateTime.now());
  }

  /// Format the remaining time as a string
  String formatTimeRemaining() {
    final duration = timeUntil();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }
}
