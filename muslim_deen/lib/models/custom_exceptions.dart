class PrayerDataException implements Exception {
  final String message;
  PrayerDataException(this.message);

  @override
  String toString() => 'PrayerDataException: $message';
}