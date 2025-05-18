import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tesbih';

  @override
  String get qiblaLabel => 'Kibla';

  @override
  String get prayerLabel => 'Namazi';

  @override
  String get mosquesLabel => 'Xhamitë';

  @override
  String get moreLabel => 'Më shumë';

  @override
  String get settings => 'Cilësimet';

  @override
  String get location => 'Vendndodhja';

  @override
  String get currentLocation => 'Vendndodhja Aktuale';

  @override
  String get notSet => 'E pacaktuar';

  @override
  String get loading => 'Duke u ngarkuar...';

  @override
  String get setLocationManually => 'Cakto Vendndodhjen Manualisht';

  @override
  String get prayerCalculation => 'Llogaritja e Namazit';

  @override
  String get calculationMethod => 'Metoda e Llogaritjes';

  @override
  String get asrTime => 'Koha e Ikindisë (Medhhebi)';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanefi';

  @override
  String get notifications => 'Njoftimet';

  @override
  String get fajr => 'Sabahu';

  @override
  String get sunrise => 'Lindja e Diellit';

  @override
  String get dhuhr => 'Dreka';

  @override
  String get asr => 'Ikindia';

  @override
  String get maghrib => 'Akshami';

  @override
  String get isha => 'Jacia';

  @override
  String get notificationTiming => 'Koha e Njoftimit';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minuta para';
  }

  @override
  String get appearance => 'Pamja';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistemi';

  @override
  String get light => 'E çelët';

  @override
  String get dark => 'E errët';

  @override
  String get language => 'Gjuha';

  @override
  String get selectLanguage => 'Zgjidh Gjuhën';

  @override
  String get cancel => 'Anulo';

  @override
  String get other => 'Të tjera';

  @override
  String get about => 'Rreth';

  @override
  String get aboutTitle => 'Rreth';

  @override
  String get aboutAppDescription =>
      'Aplikacioni Muslim Deen\nVersioni 1.0.0\n\nZhvilluar me Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature vjen së shpejti!';
  }

  @override
  String get muslimWorldLeague => 'Liga Botërore Muslimane';

  @override
  String get northAmerica => 'ISNA (Amerika e Veriut)';

  @override
  String get egyptian => 'Autoriteti i Përgjithshëm Egjiptian';

  @override
  String get ummAlQura => 'Universiteti Umm al-Qura, Meka';

  @override
  String get karachi => 'Universiteti i Shkencave Islame, Karaçi';

  @override
  String get tehran => 'Instituti i Gjeofizikës, Universiteti i Teheranit';

  @override
  String get currentPrayerTitle => 'Namazi Aktual';

  @override
  String get nextPrayerTitle => 'Namazi Tjetër';

  @override
  String get prayerTimesTitle => 'Kohët e Namazit';

  @override
  String get unknownLocation => 'Vendndodhje e Panjohur';

  @override
  String get unknown => 'E panjohur';

  @override
  String get now => 'Tani';

  @override
  String get retry => 'Provo Përsëri';

  @override
  String get openAppSettings => 'Hap Cilësimet e Aplikacionit';

  @override
  String get openLocationSettings => 'Hap Cilësimet e Vendndodhjes';

  @override
  String unexpectedError(String error) {
    return 'Ndodhi një gabim i papritur: $error';
  }

  @override
  String get prayerNameFajr => 'Sabahut';

  @override
  String get prayerNameSunrise => 'Lindjes së Diellit';

  @override
  String get prayerNameDhuhr => 'Drekës';

  @override
  String get prayerNameAsr => 'Ikindisë';

  @override
  String get prayerNameMaghrib => 'Akshamit';

  @override
  String get prayerNameIsha => 'Jacisë';

  @override
  String notificationPrayerTitle(String prayerName) {
    return 'Koha e Namazit të $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'Namazi i $prayerName po afrohet.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Shiit Ithna-Ashari (Xhaferi)';

  @override
  String get qiblaInstruction => 'Drejtoje telefonin drejt Kiblës';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Drejtimi Aktual: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Kibla: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Kërkohet leja e vendndodhjes për të përcaktuar drejtimin e Kiblës.';

  @override
  String get qiblaErrorSensor =>
      'Sensori i busullës nuk është i disponueshëm ose nuk funksionon.';

  @override
  String get qiblaErrorLocation => 'Nuk mund të merrej vendndodhja aktuale.';

  @override
  String get qiblaCalibrate => 'Kalibro Busullën';

  @override
  String get qiblaCalibrating =>
      'Ju lutemi lëvizni pajisjen tuaj në formën e një 8-she për të kalibruar busullën.';

  @override
  String tesbihCounter(int count) {
    return 'Numëruesi: $count';
  }

  @override
  String get tesbihReset => 'Rivendos';

  @override
  String get mosquesLoading => 'Duke ngarkuar xhamitë afër...';

  @override
  String mosquesError(String error) {
    return 'Gabim gjatë ngarkimit të xhamive: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Hap në Harta';

  @override
  String get mosquesNoResults => 'Nuk u gjetën xhami afër.';

  @override
  String get homeErrorLoading =>
      'Dështoi ngarkimi i kohëve të namazit. Ju lutemi kontrolloni lidhjen dhe cilësimet e vendndodhjes.';

  @override
  String get homeErrorLocationDisabled =>
      'Shërbimet e vendndodhjes janë çaktivizuar. Ju lutemi aktivizojini ato në cilësimet e pajisjes tuaj.';

  @override
  String get homeErrorPermissionDenied =>
      'Leja e vendndodhjes u refuzua. Ju lutemi jepni leje për të shfaqur kohët e namazit.';

  @override
  String get homeErrorPermissionPermanent =>
      'Leja e vendndodhjes u refuzua përgjithmonë. Ju lutemi aktivizojeni atë në cilësimet e aplikacionit.';

  @override
  String get homeErrorLocationUnknown =>
      'Nuk mund të përcaktohej vendndodhja juaj. Ju lutemi sigurohuni që shërbimet e vendndodhjes janë të aktivizuara dhe lejet janë dhënë.';

  @override
  String get homeErrorInitialization =>
      'Gabim inicializimi. Ju lutemi rinisni aplikacionin.';

  @override
  String homeTimeIn(String duration) {
    return 'Pas $duration';
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
  String get deviceLocation => 'Vendndodhja aktuale e pajisjes';

  @override
  String get errorSetLocation =>
      'Gabim në vendosjen e vendndodhjes. Ju lutemi provoni përsëri.';

  // Qibla feature translations
  @override
  String get qiblaAligned => 'Kibla e rreshtuar!';

  @override
  String get qiblaNoCompassData => 'Nuk ka të dhëna të busullës';

  @override
  String get qiblaDirectionNorth => 'V';

  @override
  String get qiblaDirectionEast => 'L';

  @override
  String get qiblaDirectionSouth => 'J';

  @override
  String get qiblaDirectionWest => 'P';

  @override
  String get qiblaNotAvailable => 'N/A';

  @override
  String get qiblaDirectionLabel => 'Drejtimi i Kibles';

  @override
  String get qiblaDistance => 'Distanca deri në Kaba';

  @override
  String get qiblaHelpTitle => 'Si të përdorni gjetësin e Kibles';

  @override
  String get qiblaHelpStep1 => 'Mbani telefonin tuaj të sheshtë dhe në nivel.';

  @override
  String get qiblaHelpStep2 =>
      'Rrotulloni ngadalë derisa shigjeta të tregojë në drejtim të Kabes.';

  @override
  String get qiblaHelpStep3 =>
      'Kur të rreshtohet, do të shihni një mesazh konfirmimi.';

  @override
  String get qiblaHelpStep4 =>
      'Nëse të dhënat e busullës janë të pasakta, shtypni butonin e kalibrimit.';

  @override
  String get qiblaGotIt => 'E kuptova';

  // Add missing Qibla turn and almost-there messages
  @override
  String get qiblaTurnRight => 'Rrotullojeni djathtas për të gjetur Kiblën';

  @override
  String get qiblaTurnLeft => 'Rrotullojeni majtas për të gjetur Kiblën';

  @override
  String get qiblaAlmostThere => 'Gati e arritura!';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'Vendos objektivin e numëruesit';

  @override
  String get tesbihTarget => 'Objektivi';

  @override
  String get tesbihEnterTarget => 'Vendosni numrin objektiv';

  @override
  String get tesbihOk => 'OK';

  @override
  String get tesbihSave => 'Ruaj';

  @override
  String get tesbihVibration => 'Dridhje';

  @override
  String get tesbihSound => 'Zë';

  @override
  String get tesbihTodaySessions => 'Seancat e sotme';

  @override
  String get tesbihNoSessions => 'Asnjë seancë nuk është regjistruar sot';

  @override
  String get errorOpeningMap => 'Nuk mund të hapej aplikacioni i hartave';

  @override
  String get qiblaCurrentDirectionLabel => 'Drejtimi aktual';

  @override
  String get aboutAppSubtitle => 'Mëso më shumë për aplikacionin Muslim Deen';

  @override
  String get dubai => 'Dubai';

  @override
  String get moonsightingCommittee => 'Komiteti Botëror i Vëzhgimit të Hënës';

  @override
  String get kuwait => 'Kuvajt';

  @override
  String get qatar => 'Katar';

  @override
  String get singapore => 'Singapor';

  @override
  String get turkey => 'Turqi (Diyanet)';

  @override
  String get startCalibration => 'Fillo Kalibrimin';

  @override
  String get distanceUnit => 'milje larg';

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
  String get qiblaErrorLocationUnavailable => 'Shërbimet e vendndodhjes nuk janë të disponueshme. Ju lutemi aktivizoni shërbimet e vendndodhjes dhe provoni përsëri.';

  @override
  String get qiblaErrorPermissionDeniedSettings => 'Leja e vendndodhjes u refuzua përgjithmonë. Ju lutemi aktivizojeni atë nga cilësimet e aplikacionit.';

  @override
  String get qiblaErrorServiceDisabled => 'Shërbimet e vendndodhjes janë çaktivizuar. Ju lutemi aktivizojini ato për të përcaktuar drejtimin e Kiblës.';

  @override
  String get qiblaErrorUnknown => 'Ndodhi një gabim i panjohur gjatë përpjekjes për të përcaktuar drejtimin e Kiblës.';
}
