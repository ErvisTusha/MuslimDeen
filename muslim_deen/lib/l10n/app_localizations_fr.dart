// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tasbih';

  @override
  String get qiblaLabel => 'Qibla';

  @override
  String get prayerLabel => 'Prière';

  @override
  String get mosquesLabel => 'Mosquées';

  @override
  String get moreLabel => 'Plus';

  @override
  String get settings => 'Paramètres';

  @override
  String get location => 'Localisation';

  @override
  String get currentLocation => 'Localisation Actuelle';

  @override
  String get notSet => 'Non défini';

  @override
  String get loading => 'Chargement...';

  @override
  String get setLocationManually => 'Définir la Localisation Manuellement';

  @override
  String get prayerCalculation => 'Calcul de la Prière';

  @override
  String get calculationMethod => 'Méthode de Calcul';

  @override
  String get asrTime => 'Heure d\'Asr (Madhab)';

  @override
  String get shafi => 'Chafi\'i';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notifications';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Lever du soleil';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get notificationTiming => 'Heure de Notification';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutes avant';
  }

  @override
  String get appearance => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get language => 'Langue';

  @override
  String get selectLanguage => 'Sélectionner la Langue';

  @override
  String get cancel => 'Annuler';

  @override
  String get other => 'Autre';

  @override
  String get about => 'À propos';

  @override
  String get aboutTitle => 'À propos';

  @override
  String get aboutAppDescription =>
      'Application Muslim Deen\nVersion 1.0.0\n\nDéveloppée avec Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature bientôt disponible !';
  }

  @override
  String get muslimWorldLeague => 'Ligue Islamique Mondiale';

  @override
  String get northAmerica => 'ISNA (Amérique du Nord)';

  @override
  String get egyptian => 'Autorité Générale Égyptienne';

  @override
  String get ummAlQura => 'Université Umm al-Qura, La Mecque';

  @override
  String get karachi => 'Université des Sciences Islamiques, Karachi';

  @override
  String get tehran => 'Institut de Géophysique, Université de Téhéran';

  @override
  String get currentPrayerTitle => 'Prière Actuelle';

  @override
  String get nextPrayerTitle => 'Prochaine Prière';

  @override
  String get prayerTimesTitle => 'Horaires des Prières';

  @override
  String get unknownLocation => 'Localisation Inconnue';

  @override
  String get unknown => 'Inconnu';

  @override
  String get now => 'Maintenant';

  @override
  String get retry => 'Réessayer';

  @override
  String get openAppSettings => 'Ouvrir les Paramètres de l\'Application';

  @override
  String get openLocationSettings => 'Ouvrir les Paramètres de Localisation';

  @override
  String unexpectedError(String error) {
    return 'Une erreur inattendue s\'est produite : $error';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Lever du soleil';

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
    return 'Heure de la prière de $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'La prière de $prayerName approche.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Chiite Ithna-Ashari (Jafari)';

  @override
  String get qiblaInstruction => 'Pointez votre téléphone vers la Qibla';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Direction Actuelle : $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Qibla : $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Permission de localisation requise pour déterminer la direction de la Qibla.';

  @override
  String get qiblaErrorSensor =>
      'Capteur de boussole non disponible ou ne fonctionne pas.';

  @override
  String get qiblaErrorLocation =>
      'Impossible d\'obtenir la localisation actuelle.';

  @override
  String get qiblaCalibrate => 'Calibrer la Boussole';

  @override
  String get qiblaCalibrating =>
      'Veuillez déplacer votre appareil en formant un 8 pour calibrer la boussole.';

  @override
  String tesbihCounter(int count) {
    return 'Compteur : $count';
  }

  @override
  String get tesbihReset => 'Réinitialiser';

  @override
  String get mosquesLoading => 'Chargement des mosquées à proximité...';

  @override
  String mosquesError(String error) {
    return 'Erreur lors du chargement des mosquées : $error';
  }

  @override
  String get mosquesOpenInMaps => 'Ouvrir dans Maps';

  @override
  String get mosquesNoResults => 'Aucune mosquée trouvée à proximité.';

  @override
  String get homeErrorLoading =>
      'Échec du chargement des horaires de prière. Veuillez vérifier la connexion et les paramètres de localisation.';

  @override
  String get homeErrorLocationDisabled =>
      'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres de votre appareil.';

  @override
  String get homeErrorPermissionDenied =>
      'Permission de localisation refusée. Veuillez accorder la permission pour afficher les horaires de prière.';

  @override
  String get homeErrorPermissionPermanent =>
      'Permission de localisation refusée de manière permanente. Veuillez l\'activer dans les paramètres de l\'application.';

  @override
  String get homeErrorLocationUnknown =>
      'Impossible de déterminer votre localisation. Veuillez vous assurer que les services de localisation sont activés et que les permissions sont accordées.';

  @override
  String get homeErrorInitialization =>
      'Erreur d\'initialisation. Veuillez redémarrer l\'application.';

  @override
  String homeTimeIn(String duration) {
    return 'Dans $duration';
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
  String get deviceLocation => 'Localisation actuelle de l\'appareil';

  @override
  String get errorSetLocation =>
      'Erreur lors de la définition de l\'emplacement. Veuillez réessayer.';

  // Qibla feature translations
  @override
  String get qiblaAligned => 'Qibla alignée !';

  @override
  String get qiblaNoCompassData => 'Pas de données de boussole';

  @override
  String get qiblaDirectionNorth => 'N';

  @override
  String get qiblaDirectionEast => 'E';

  @override
  String get qiblaDirectionSouth => 'S';

  @override
  String get qiblaDirectionWest => 'O';

  @override
  String get qiblaNotAvailable => 'N/D';

  @override
  String get qiblaDirectionLabel => 'Direction de la Qibla';

  @override
  String get qiblaDistance => 'Distance à la Kaaba';

  @override
  String get qiblaHelpTitle => 'Comment utiliser le chercheur de Qibla';

  @override
  String get qiblaHelpStep1 => 'Tenez votre téléphone à plat et de niveau.';

  @override
  String get qiblaHelpStep2 =>
      'Tournez lentement jusqu\'à ce que la flèche pointe vers la Kaaba.';

  @override
  String get qiblaHelpStep3 =>
      'Une fois aligné, vous verrez un message de confirmation.';

  @override
  String get qiblaHelpStep4 =>
      'Si les données de la boussole sont inexactes, appuyez sur le bouton de calibration.';

  @override
  String get qiblaGotIt => 'Compris';

  // Add missing Qibla turn and alignment messages
  @override
  String get qiblaTurnRight => 'Tournez à droite pour trouver la Qibla';

  @override
  String get qiblaTurnLeft => 'Tournez à gauche pour trouver la Qibla';

  @override
  String get qiblaAlmostThere => 'Presque arrivé !';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'Définir l\'objectif du compteur';

  @override
  String get tesbihTarget => 'Objectif';

  @override
  String get tesbihEnterTarget => 'Entrez le nombre cible';

  @override
  String get tesbihOk => 'OK';

  @override
  String get tesbihSave => 'Enregistrer';

  @override
  String get tesbihVibration => 'Vibration';

  @override
  String get tesbihSound => 'Son';

  @override
  String get tesbihTodaySessions => 'Sessions d\'aujourd\'hui';

  @override
  String get tesbihNoSessions => 'Aucune session enregistrée aujourd\'hui';

  @override
  String get errorOpeningMap => 'Impossible d\'ouvrir l\'application de carte';

  @override
  String get qiblaCurrentDirectionLabel => 'Direction actuelle';

  @override
  String get aboutAppSubtitle =>
      'En savoir plus sur l\'application Muslim Deen';

  @override
  String get dubai => 'Dubaï';

  @override
  String get moonsightingCommittee =>
      'Comité mondial d\'observation de la lune';

  @override
  String get kuwait => 'Koweït';

  @override
  String get qatar => 'Qatar';

  @override
  String get singapore => 'Singapour';

  @override
  String get turkey => 'Turquie (Diyanet)';

  @override
  String get startCalibration => 'Démarrer la calibration';

  @override
  String get distanceUnit => 'miles de distance';

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
@override
  String get qiblaErrorLocationUnavailable => 'Services de localisation non disponibles. Veuillez activer les services de localisation et réessayer.';

  @override
  String get qiblaErrorPermissionDeniedSettings => 'Permission de localisation refusée de manière permanente. Veuillez l\'activer dans les paramètres de l\'application.';

  @override
  String get qiblaErrorServiceDisabled => 'Les services de localisation sont désactivés. Veuillez les activer pour déterminer la direction de la Qibla.';

  @override
  String get qiblaErrorUnknown => 'Une erreur inconnue s\'est produite lors de la tentative de détermination de la direction de la Qibla.';
}
