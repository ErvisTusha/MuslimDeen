class PrayerDataException implements Exception {
  final String message;
  PrayerDataException(this.message);

  @override
  String toString() => 'PrayerDataException: $message';
}

class LocationServiceException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;

  const LocationServiceException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() {
    String result = 'LocationServiceException: $message';
    if (originalException != null) {
      result += '\nOriginal Exception: $originalException';
    }
    if (stackTrace != null) {
      result += '\nStackTrace: $stackTrace';
    }
    return result;
  }
}
