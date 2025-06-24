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
}
