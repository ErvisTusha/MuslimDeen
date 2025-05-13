import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_deen/models/prayer_times_model.dart';
import 'package:clock/clock.dart'; // Import the clock package

void main() {
  group("PrayerTimesModel Tests", () {
    late PrayerTimesModel prayerTimesModel;
    
    setUp(() {
      // Create a fixed date for testing
      final today = DateTime(2025, 5, 13);
      
      // Create prayer times that we know the ordering of
      prayerTimesModel = PrayerTimesModel(
        fajr: DateTime(2025, 5, 13, 4, 30),
        sunrise: DateTime(2025, 5, 13, 6, 0),
        dhuhr: DateTime(2025, 5, 13, 12, 30),
        asr: DateTime(2025, 5, 13, 16, 0),
        maghrib: DateTime(2025, 5, 13, 20, 0),
        isha: DateTime(2025, 5, 13, 21, 30),
        date: today,
        hijriDay: 1,
        hijriMonth: 1,
        hijriYear: 1447,
        hijriMonthName: "Muharram",
      );
    });
    
    test("getAllPrayers returns all six prayers in correct order", () {
      final prayers = prayerTimesModel.getAllPrayers();
      
      expect(prayers.length, 6);
      expect(prayers[0].name, "Fajr");
      expect(prayers[1].name, "Sunrise");
      expect(prayers[2].name, "Dhuhr");
      expect(prayers[3].name, "Asr");
      expect(prayers[4].name, "Maghrib");
      expect(prayers[5].name, "Isha");
    });
    
    test("getNextPrayer returns the correct next prayer", () {
      // Mock current time as 10:00 AM - Next prayer should be Dhuhr
      final mockTime = DateTime(2025, 5, 13, 10, 0);
      
      withClock(Clock.fixed(mockTime), () {
        final nextPrayer = prayerTimesModel.getNextPrayer();
        expect(nextPrayer.name, "Dhuhr");
      });
      
      // Mock current time as 22:00 (10 PM) - Next prayer should be Fajr tomorrow
      final lateTime = DateTime(2025, 5, 13, 22, 0);
      
      withClock(Clock.fixed(lateTime), () {
        final nextPrayer = prayerTimesModel.getNextPrayer();
        expect(nextPrayer.name, "Fajr");
        expect(nextPrayer.isTomorrow, true);
      });
    });
    
    test("PrayerTime.formatTimeRemaining returns correct format", () {
      final now = DateTime(2025, 5, 13, 12, 0);
      
      // 30 minutes until prayer
      final prayer = PrayerTime(
        name: "Dhuhr", 
        time: DateTime(2025, 5, 13, 12, 30),
        iconData: Icons.access_time,
      );
      
      withClock(Clock.fixed(now), () {
        final formatted = prayer.formatTimeRemaining();
        expect(formatted, "30 minutes");
      });
      
      // 1 hour and 30 minutes until prayer
      final laterPrayer = PrayerTime(
        name: "Asr", 
        time: DateTime(2025, 5, 13, 13, 30),
        iconData: Icons.access_time,
      );
      
      withClock(Clock.fixed(now), () {
        final formatted = laterPrayer.formatTimeRemaining();
        expect(formatted, "1 hour 30 minutes");
      });
      
      // 2 hours until prayer
      final evenLaterPrayer = PrayerTime(
        name: "Asr", 
        time: DateTime(2025, 5, 13, 14, 0),
        iconData: Icons.access_time,
      );
      
      withClock(Clock.fixed(now), () {
        final formatted = evenLaterPrayer.formatTimeRemaining();
        expect(formatted, "2 hours 0 minutes");
      });
    });
  });
}
