import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sq.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('pt'),
    Locale('pt', 'BR'),
    Locale('sq'),
    Locale('tr'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Muslim Deen'**
  String get appTitle;

  /// Label for the Tasbih feature
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get tasbihLabel;

  /// Label for the Qibla feature
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get qiblaLabel;

  /// Label for the Prayer feature
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayerLabel;

  /// Label for the Mosques feature
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get mosquesLabel;

  /// Label for the More section
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreLabel;

  /// Label for the Settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for Location settings
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Label indicating the current location
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// Indicator that a value is not set
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Button text to set location manually
  ///
  /// In en, this message translates to:
  /// **'Set Location Manually'**
  String get setLocationManually;

  /// Label for Prayer Calculation settings
  ///
  /// In en, this message translates to:
  /// **'Prayer Calculation'**
  String get prayerCalculation;

  /// Label for Calculation Method setting
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethod;

  /// Label for Asr Time (Madhab) setting
  ///
  /// In en, this message translates to:
  /// **'Asr Time (Madhab)'**
  String get asrTime;

  /// Shafi Madhab option
  ///
  /// In en, this message translates to:
  /// **'Shafi'**
  String get shafi;

  /// Hanafi Madhab option
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get hanafi;

  /// Label for Notifications settings
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Fajr prayer name
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// Sunrise time name
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// Dhuhr prayer name
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// Asr prayer name
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// Maghrib prayer name
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// Isha prayer name
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// Label for Notification Timing setting
  ///
  /// In en, this message translates to:
  /// **'Notification Timing'**
  String get notificationTiming;

  /// Notification timing option
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes before'**
  String minutesBefore(int minutes);

  /// Label for Appearance settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Label for Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Label for Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Prompt to select a language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Label for Other settings/options
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// Label for the About screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Title for the About screen
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// Static text shown in the About screen, including app name, version, and development info.
  ///
  /// In en, this message translates to:
  /// **'Muslim Deen App\nVersion 1.0.0\n\nDeveloped with Flutter.'**
  String get aboutAppDescription;

  /// Placeholder text for upcoming features
  ///
  /// In en, this message translates to:
  /// **'{feature} coming soon!'**
  String comingSoon(String feature);

  /// Muslim World League calculation method
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get muslimWorldLeague;

  /// ISNA (North America) calculation method
  ///
  /// In en, this message translates to:
  /// **'ISNA (North America)'**
  String get northAmerica;

  /// Egyptian General Authority calculation method
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get egyptian;

  /// Umm al-Qura University, Makkah calculation method
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura University, Makkah'**
  String get ummAlQura;

  /// University of Islamic Sciences, Karachi calculation method
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get karachi;

  /// Institute of Geophysics, University of Tehran calculation method
  ///
  /// In en, this message translates to:
  /// **'Institute of Geophysics, University of Tehran'**
  String get tehran;

  /// Title for the current prayer section
  ///
  /// In en, this message translates to:
  /// **'Current Prayer'**
  String get currentPrayerTitle;

  /// Title for the next prayer section
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayerTitle;

  /// Title for the prayer times screen/section
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimesTitle;

  /// Indicator for unknown location
  ///
  /// In en, this message translates to:
  /// **'Unknown Location'**
  String get unknownLocation;

  /// Generic unknown indicator
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Indicator for the current time
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button text to open app settings
  ///
  /// In en, this message translates to:
  /// **'Open App Settings'**
  String get openAppSettings;

  /// Button text to open location settings
  ///
  /// In en, this message translates to:
  /// **'Open Location Settings'**
  String get openLocationSettings;

  /// Generic unexpected error message
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String unexpectedError(String error);

  /// Display name for Fajr prayer
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerNameFajr;

  /// Display name for Sunrise
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerNameSunrise;

  /// Display name for Dhuhr prayer
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerNameDhuhr;

  /// Display name for Asr prayer
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerNameAsr;

  /// Display name for Maghrib prayer
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerNameMaghrib;

  /// Display name for Isha prayer
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerNameIsha;

  /// Title for the prayer time notification
  ///
  /// In en, this message translates to:
  /// **'{prayerName} Prayer Time'**
  String notificationPrayerTitle(String prayerName);

  /// Body for the prayer time notification
  ///
  /// In en, this message translates to:
  /// **'{prayerName} prayer is approaching.'**
  String notificationPrayerBody(String prayerName);

  /// Jafari (Shia Ithna-Ashari) calculation method
  ///
  /// In en, this message translates to:
  /// **'Shia Ithna-Ashari (Jafari)'**
  String get settingsCalculationMethodJafari;

  /// Instruction text for the Qibla compass
  ///
  /// In en, this message translates to:
  /// **'Point your phone towards the Qibla'**
  String get qiblaInstruction;

  /// Instruction to turn right to find Qibla direction
  String get qiblaTurnRight;

  /// Instruction to turn left to find Qibla direction
  String get qiblaTurnLeft;

  /// Message when the Qibla direction is very close but not perfectly aligned
  String get qiblaAlmostThere;

  /// Displays the current direction in degrees for Qibla
  ///
  /// In en, this message translates to:
  /// **'Current Direction: {degrees}°'**
  String qiblaCurrentDirection(String degrees);

  /// Displays the required Qibla direction in degrees
  ///
  /// In en, this message translates to:
  /// **'Qibla: {degrees}°'**
  String qiblaRequiredDirection(String degrees);

  /// Error message when location permission is missing for Qibla
  ///
  /// In en, this message translates to:
  /// **'Location permission required to determine Qibla direction.'**
  String get qiblaErrorPermission;

  /// Error message when compass sensor is unavailable for Qibla
  ///
  /// In en, this message translates to:
  /// **'Compass sensor not available or not working.'**
  String get qiblaErrorSensor;

  /// Error message when current location cannot be obtained for Qibla
  ///
  /// In en, this message translates to:
  /// **'Could not get current location.'**
  String get qiblaErrorLocation;

  /// Button text to start compass calibration
  ///
  /// In en, this message translates to:
  /// **'Calibrate Compass'**
  String get qiblaCalibrate;

  /// Instruction text during compass calibration
  ///
  /// In en, this message translates to:
  /// **'Please move your device in a figure 8 pattern to calibrate the compass.'**
  String get qiblaCalibrating;

  /// Displays the current count on the Tesbih counter
  ///
  /// In en, this message translates to:
  /// **'Counter: {count}'**
  String tesbihCounter(int count);

  /// Button text to reset the Tesbih counter
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get tesbihReset;

  /// Loading message while fetching nearby mosques
  ///
  /// In en, this message translates to:
  /// **'Loading nearby mosques...'**
  String get mosquesLoading;

  /// Error message when loading mosques fails
  ///
  /// In en, this message translates to:
  /// **'Error loading mosques: {error}'**
  String mosquesError(String error);

  /// Button text to open a mosque location in a map application
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get mosquesOpenInMaps;

  /// Message displayed when no nearby mosques are found
  ///
  /// In en, this message translates to:
  /// **'No mosques found nearby.'**
  String get mosquesNoResults;

  /// Error message on the home screen when loading prayer times fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load prayer times. Please check connection and location settings.'**
  String get homeErrorLoading;

  /// Error message on the home screen when location services are disabled
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in your device settings.'**
  String get homeErrorLocationDisabled;

  /// Error message on the home screen when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please grant permission to show prayer times.'**
  String get homeErrorPermissionDenied;

  /// Error message on the home screen when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location permission permanently denied. Please enable it in app settings.'**
  String get homeErrorPermissionPermanent;

  /// Error message on the home screen when the location is unknown
  ///
  /// In en, this message translates to:
  /// **'Could not determine your location. Please ensure location services are enabled and permissions granted.'**
  String get homeErrorLocationUnknown;

  /// Error message on the home screen during initialization failure
  ///
  /// In en, this message translates to:
  /// **'Initialization error. Please restart the app.'**
  String get homeErrorInitialization;

  /// Displays the time remaining until the next prayer
  ///
  /// In en, this message translates to:
  /// **'In {duration}'**
  String homeTimeIn(String duration);

  /// Application name displayed on the home screen (potentially redundant with appTitle)
  ///
  /// In en, this message translates to:
  /// **'Muslim Deen'**
  String get homeAppName;

  /// Button text to use device location
  ///
  /// In en, this message translates to:
  /// **'Use Device Location'**
  String get useDeviceLocation;

  /// Button text to search for a city
  ///
  /// In en, this message translates to:
  /// **'Search City'**
  String get searchCity;

  /// Button text for search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Message shown when no locations are found in search
  ///
  /// In en, this message translates to:
  /// **'No locations found. Try a different search.'**
  String get noLocationsFound;

  /// Error message during location search
  ///
  /// In en, this message translates to:
  /// **'Error searching for places. Please try again.'**
  String get searchError;

  /// Current device location option
  ///
  /// In en, this message translates to:
  /// **'Current Device Location'**
  String get deviceLocation;

  /// Error message when setting location fails
  ///
  /// In en, this message translates to:
  /// **'Error setting location. Please try again.'**
  String get errorSetLocation;

  /// Error message when opening map application fails
  ///
  /// In en, this message translates to:
  /// **'Could not open map application'**
  String get errorOpeningMap;

  /// Message displayed when Qibla is aligned correctly
  ///
  /// In en, this message translates to:
  /// **'Qibla aligned!'**
  String get qiblaAligned;

  /// Message displayed when no compass data is available
  ///
  /// In en, this message translates to:
  /// **'No compass data'**
  String get qiblaNoCompassData;

  /// North direction label for compass
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get qiblaDirectionNorth;

  /// East direction label for compass
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get qiblaDirectionEast;

  /// South direction label for compass
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get qiblaDirectionSouth;

  /// Label for the current direction in Qibla view
  ///
  /// In en, this message translates to:
  /// **'Current Direction'**
  String get qiblaCurrentDirectionLabel;

  /// West direction label for compass
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get qiblaDirectionWest;

  /// Label for when compass data is not available
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get qiblaNotAvailable;

  /// Label for the Qibla direction
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaDirectionLabel;

  /// Label for distance to Kaaba
  ///
  /// In en, this message translates to:
  /// **'Distance to Kaaba'**
  String get qiblaDistance;

  /// Title for the Qibla help dialog
  ///
  /// In en, this message translates to:
  /// **'How to Use Qibla Finder'**
  String get qiblaHelpTitle;

  /// First step in Qibla help instructions
  ///
  /// In en, this message translates to:
  /// **'Hold your phone flat and level.'**
  String get qiblaHelpStep1;

  /// Second step in Qibla help instructions
  ///
  /// In en, this message translates to:
  /// **'Rotate slowly until the arrow points to the Kaaba.'**
  String get qiblaHelpStep2;

  /// Third step in Qibla help instructions
  ///
  /// In en, this message translates to:
  /// **'When aligned, you'll see a confirmation message.'**
  String get qiblaHelpStep3;

  /// Fourth step in Qibla help instructions
  ///
  /// In en, this message translates to:
  /// **'If compass data is inaccurate, tap the calibrate button.'**
  String get qiblaHelpStep4;

  /// Button text to dismiss Qibla help dialog
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get qiblaGotIt;

  /// Title for setting the tesbih counter target
  ///
  /// In en, this message translates to:
  /// **'Set Counter Target'**
  String get tesbihSetTarget;

  /// Label for tesbih target count
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get tesbihTarget;

  /// Hint text for entering tesbih target count
  ///
  /// In en, this message translates to:
  /// **'Enter target count'**
  String get tesbihEnterTarget;

  /// OK button text in tesbih target dialog
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get tesbihOk;

  /// Save button text for tesbih sessions
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tesbihSave;

  /// Label for vibration toggle in tesbih settings
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get tesbihVibration;

  /// Label for sound toggle in tesbih settings
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get tesbihSound;

  /// Label for today's tesbih sessions section
  ///
  /// In en, this message translates to:
  /// **'Today's Sessions'**
  String get tesbihTodaySessions;

  /// Message when no tesbih sessions are recorded
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded today'**
  String get tesbihNoSessions;

  /// Subtitle for the About section in settings
  ///
  /// In en, this message translates to:
  /// **'Learn more about Muslim Deen app'**
  String get aboutAppSubtitle;

  /// Prayer calculation method: Dubai
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get dubai;

  /// Prayer calculation method: Moonsighting Committee
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee Worldwide'**
  String get moonsightingCommittee;

  /// Prayer calculation method: Kuwait
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get kuwait;

  /// Prayer calculation method: Qatar
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get qatar;

  /// Prayer calculation method: Singapore
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get singapore;

  /// Prayer calculation method: Turkey
  ///
  /// In en, this message translates to:
  /// **'Turkey (Diyanet)'**
  String get turkey;

  /// Label for Azan sound selection
  ///
  /// In en, this message translates to:
  /// **'Azan Sound'**
  String get azanSound;

  /// Makkah Adhan option
  ///
  /// In en, this message translates to:
  /// **'Makkah Adhan'**
  String get makkahAdhan;

  /// Madinah Adhan option
  ///
  /// In en, this message translates to:
  /// **'Madinah Adhan'**
  String get madinahAdhan;

  /// Al-Aqsa Adhan option
  ///
  /// In en, this message translates to:
  /// **'Al-Aqsa Adhan'**
  String get alAqsaAdhan;

  /// Turkish Adhan option
  ///
  /// In en, this message translates to:
  /// **'Turkish Adhan'**
  String get turkishAdhan;

  /// Button text to start calibration
  ///
  /// In en, this message translates to:
  /// **'Start Calibration'**
  String get startCalibration;

  /// Unit for distance measurement (miles, kilometers)
  ///
  /// In en, this message translates to:
  /// **'miles away'**
  String get distanceUnit;

  //String get qiblaAlmostThere;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'en',
    'es',
    'fr',
    'pt',
    'sq',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'sq':
      return AppLocalizationsSq();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
