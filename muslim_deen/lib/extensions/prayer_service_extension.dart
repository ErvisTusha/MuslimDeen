import 'package:adhan_dart/adhan_dart.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/models/app_settings.dart'; // Added import

// Extension methods to add the required functionality for PrayerService
extension PrayerServiceExtension on PrayerService {
  /// Gets prayer times for the specified date using user's location and settings.
  Future<PrayerTimes> getPrayerTimesForDate(DateTime date, AppSettings? settings) async {
    // Calls the method in PrayerService which correctly uses LocationService and AppSettings
    return calculatePrayerTimesForDate(date, settings);
  }

  /// Gets prayer times for a specific location and date
  Future<PrayerTimes> getPrayerTimesForLocation(
    Coordinates coordinates,
    DateTime date,
    CalculationParameters parameters,
  ) async {
    return PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: parameters,
    );
  }
}
