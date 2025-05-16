import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tasbih';

  @override
  String get qiblaLabel => 'Qibla';

  @override
  String get prayerLabel => 'Prayer';

  @override
  String get mosquesLabel => 'Mosques';

  @override
  String get moreLabel => 'More';

  @override
  String get settings => 'Settings';

  @override
  String get location => 'Location';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get notSet => 'Not Set';

  @override
  String get loading => 'Loading...';

  @override
  String get setLocationManually => 'Set Location Manually';

  @override
  String get prayerCalculation => 'Prayer Calculation';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get asrTime => 'Asr Time (Madhab)';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notifications';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get notificationTiming => 'Notification Timing';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutes before';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get other => 'Other';

  @override
  String get about => 'About';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutAppDescription =>
      'Muslim Deen App\nVersion 1.0.0\n\nDeveloped with Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature coming soon!';
  }

  @override
  String get muslimWorldLeague => 'Muslim World League';

  @override
  String get northAmerica => 'ISNA (North America)';

  @override
  String get egyptian => 'Egyptian General Authority';

  @override
  String get ummAlQura => 'Umm al-Qura University, Makkah';

  @override
  String get karachi => 'University of Islamic Sciences, Karachi';

  @override
  String get tehran => 'Institute of Geophysics, University of Tehran';

  @override
  String get currentPrayerTitle => 'Current Prayer';

  @override
  String get nextPrayerTitle => 'Next Prayer';

  @override
  String get prayerTimesTitle => 'Prayer Times';

  @override
  String get unknownLocation => 'Unknown Location';

  @override
  String get unknown => 'Unknown';

  @override
  String get now => 'Now';

  @override
  String get retry => 'Retry';

  @override
  String get openAppSettings => 'Open App Settings';

  @override
  String get openLocationSettings => 'Open Location Settings';

  @override
  String unexpectedError(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Sunrise';

  @override
  String get prayerNameDhuhr => 'Dhuhr';

  @override
  String get prayerNameAsr => 'Asr';

  @override
  String get prayerNameMaghrib => 'Maghrib';

  @override
  String get prayerNameIsha => 'Isha';

  @override
  String notificationPrayerTitle(String prayerName) {
    return '$prayerName Prayer Time';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return '$prayerName prayer is approaching.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Shia Ithna-Ashari (Jafari)';

  @override
  String get qiblaInstruction => 'Point your phone towards the Qibla';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Current Direction: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Qibla: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Location permission required to determine Qibla direction.';

  @override
  String get qiblaErrorSensor => 'Compass sensor not available or not working.';

  @override
  String get qiblaErrorLocation => 'Could not get current location.';

  @override
  String get qiblaCalibrate => 'Calibrate Compass';

  @override
  String get qiblaCalibrating =>
      'Please move your device in a figure 8 pattern to calibrate the compass.';

  @override
  String tesbihCounter(int count) {
    return 'Counter: $count';
  }

  @override
  String get tesbihReset => 'Reset';

  @override
  String get mosquesLoading => 'Loading nearby mosques...';

  @override
  String mosquesError(String error) {
    return 'Error loading mosques: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Open in Maps';

  @override
  String get mosquesNoResults => 'No mosques found nearby.';

  @override
  String get homeErrorLoading =>
      'Failed to load prayer times. Please check connection and location settings.';

  @override
  String get homeErrorLocationDisabled =>
      'Location services are disabled. Please enable them in your device settings.';

  @override
  String get homeErrorPermissionDenied =>
      'Location permission denied. Please grant permission to show prayer times.';

  @override
  String get homeErrorPermissionPermanent =>
      'Location permission permanently denied. Please enable it in app settings.';

  @override
  String get homeErrorLocationUnknown =>
      'Could not determine your location. Please ensure location services are enabled and permissions granted.';

  @override
  String get homeErrorInitialization =>
      'Initialization error. Please restart the app.';

  @override
  String homeTimeIn(String duration) {
    return 'In $duration';
  }

  @override
  String get homeAppName => 'Muslim Deen';

  @override
  String get useDeviceLocation => 'Use Device Location';

  @override
  String get searchCity => 'Search City';

  @override
  String get search => 'Search';

  @override
  String get noLocationsFound => 'No locations found. Try a different search.';

  @override
  String get searchError => 'Error searching for places. Please try again.';

  @override
  String get deviceLocation => 'Current Device Location';

  @override
  String get errorSetLocation => 'Error setting location. Please try again.';

  // Qibla feature translations
  @override
  String get qiblaAligned => 'Qibla aligned!';

  @override
  String get qiblaNoCompassData => 'No compass data';

  @override
  String get qiblaDirectionNorth => 'N';

  @override
  String get qiblaDirectionEast => 'E';

  @override
  String get qiblaDirectionSouth => 'S';

  @override
  String get qiblaDirectionWest => 'W';

  @override
  String get qiblaNotAvailable => 'N/A';

  @override
  String get qiblaDirectionLabel => 'Qibla Direction';

  @override
  String get qiblaDistance => 'Distance to Kaaba';

  @override
  String get qiblaHelpTitle => 'How to Use Qibla Finder';

  @override
  String get qiblaHelpStep1 => 'Hold your phone flat and level.';

  @override
  String get qiblaHelpStep2 =>
      'Rotate slowly until the arrow points to the Kaaba.';

  @override
  String get qiblaHelpStep3 =>
      'When aligned, you\'ll see a confirmation message.';

  @override
  String get qiblaHelpStep4 =>
      'If compass data is inaccurate, tap the calibrate button.';

  @override
  String get qiblaGotIt => 'Got it';

  // Add missing Qibla turn and almost-there messages
  @override
  String get qiblaTurnRight => 'Turn right to find Qibla';

  @override
  String get qiblaTurnLeft => 'Turn left to find Qibla';

  @override
  String get qiblaAlmostThere => 'Almost there!';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'Set Counter Target';

  @override
  String get tesbihTarget => 'Target';

  @override
  String get tesbihEnterTarget => 'Enter target count';

  @override
  String get tesbihOk => 'OK';

  @override
  String get tesbihSave => 'Save';

  @override
  String get tesbihVibration => 'Vibration';

  @override
  String get tesbihSound => 'Sound';

  @override
  String get tesbihTodaySessions => 'Today\'s Sessions';

  @override
  String get tesbihNoSessions => 'No sessions recorded today';

  @override
  String get errorOpeningMap => 'Could not open map application';

  @override
  String get qiblaCurrentDirectionLabel => 'Current Direction';

  @override
  String get aboutAppSubtitle => 'Learn more about Muslim Deen app';

  @override
  String get dubai => 'Dubai';

  @override
  String get moonsightingCommittee => 'Moonsighting Committee Worldwide';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Qatar';

  @override
  String get singapore => 'Singapore';

  @override
  String get turkey => 'Turkey (Diyanet)';

  @override
  String get startCalibration => 'Start Calibration';

  @override
  String get distanceUnit => 'miles away';

  @override
  String get azanSound => 'Azan Sound';

  @override
  String get makkahAdhan => 'Makkah Adhan';

  @override
  String get madinahAdhan => 'Madinah Adhan';

  @override
  String get alAqsaAdhan => 'Al-Aqsa Adhan';

  @override
  String get turkishAdhan => 'Turkish Adhan';
}
