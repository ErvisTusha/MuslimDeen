import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tasbih';

  @override
  String get qiblaLabel => 'Qibla';

  @override
  String get prayerLabel => 'Oración';

  @override
  String get mosquesLabel => 'Mezquitas';

  @override
  String get moreLabel => 'Más';

  @override
  String get settings => 'Ajustes';

  @override
  String get location => 'Ubicación';

  @override
  String get currentLocation => 'Ubicación Actual';

  @override
  String get notSet => 'No establecido';

  @override
  String get loading => 'Cargando...';

  @override
  String get setLocationManually => 'Establecer Ubicación Manualmente';

  @override
  String get prayerCalculation => 'Cálculo de la Oración';

  @override
  String get calculationMethod => 'Método de Cálculo';

  @override
  String get asrTime => 'Hora del Asr (Madhab)';

  @override
  String get shafi => 'Shafi\'i';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Amanecer';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get notificationTiming => 'Hora de Notificación';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutos antes';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get cancel => 'Cancelar';

  @override
  String get other => 'Otro';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutTitle => 'Acerca de';

  @override
  String get aboutAppDescription =>
      'Aplicación Muslim Deen\nVersión 1.0.0\n\nDesarrollada con Flutter.';

  @override
  String comingSoon(String feature) {
    return '¡$feature próximamente!';
  }

  @override
  String get muslimWorldLeague => 'Liga Mundial Musulmana';

  @override
  String get northAmerica => 'ISNA (Norteamérica)';

  @override
  String get egyptian => 'Autoridad General Egipcia';

  @override
  String get ummAlQura => 'Universidad Umm al-Qura, La Meca';

  @override
  String get karachi => 'Universidad de Ciencias Islámicas, Karachi';

  @override
  String get tehran => 'Instituto de Geofísica, Universidad de Teherán';

  @override
  String get currentPrayerTitle => 'Oración Actual';

  @override
  String get nextPrayerTitle => 'Próxima Oración';

  @override
  String get prayerTimesTitle => 'Horarios de Oración';

  @override
  String get unknownLocation => 'Ubicación Desconocida';

  @override
  String get unknown => 'Desconocido';

  @override
  String get now => 'Ahora';

  @override
  String get retry => 'Reintentar';

  @override
  String get openAppSettings => 'Abrir Ajustes de la Aplicación';

  @override
  String get openLocationSettings => 'Abrir Ajustes de Ubicación';

  @override
  String unexpectedError(String error) {
    return 'Ocurrió un error inesperado: $error';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Amanecer';

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
    return 'Hora de la Oración de $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'La oración de $prayerName se acerca.';
  }

  @override
  String get settingsCalculationMethodJafari =>
      'Chiita Ithna-\'Ashari (Jafari)';

  @override
  String get qiblaInstruction => 'Apunta tu teléfono hacia la Qibla';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Dirección Actual: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Qibla: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Se requiere permiso de ubicación para determinar la dirección de la Qibla.';

  @override
  String get qiblaErrorSensor =>
      'El sensor de la brújula no está disponible o no funciona.';

  @override
  String get qiblaErrorLocation => 'No se pudo obtener la ubicación actual.';

  @override
  String get qiblaCalibrate => 'Calibrar Brújula';

  @override
  String get qiblaCalibrating =>
      'Por favor, mueve tu dispositivo describiendo un 8 para calibrar la brújula.';

  @override
  String tesbihCounter(int count) {
    return 'Contador: $count';
  }

  @override
  String get tesbihReset => 'Reiniciar';

  @override
  String get mosquesLoading => 'Cargando mezquitas cercanas...';

  @override
  String mosquesError(String error) {
    return 'Error al cargar mezquitas: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Abrir en Mapas';

  @override
  String get mosquesNoResults => 'No se encontraron mezquitas cercanas.';

  @override
  String get homeErrorLoading =>
      'Error al cargar los horarios de oración. Por favor, comprueba la conexión y los ajustes de ubicación.';

  @override
  String get homeErrorLocationDisabled =>
      'Los servicios de ubicación están desactivados. Por favor, actívalos en los ajustes de tu dispositivo.';

  @override
  String get homeErrorPermissionDenied =>
      'Permiso de ubicación denegado. Por favor, concede permiso para mostrar los horarios de oración.';

  @override
  String get homeErrorPermissionPermanent =>
      'Permiso de ubicación denegado permanentemente. Por favor, actívalo en los ajustes de la aplicación.';

  @override
  String get homeErrorLocationUnknown =>
      'No se pudo determinar tu ubicación. Por favor, asegúrate de que los servicios de ubicación están activados y los permisos concedidos.';

  @override
  String get homeErrorInitialization =>
      'Error de inicialización. Por favor, reinicia la aplicación.';

  @override
  String homeTimeIn(String duration) {
    return 'En $duration';
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
  String get deviceLocation => 'Ubicación actual del dispositivo';

  @override
  String get errorSetLocation =>
      'Error al configurar la ubicación. Por favor, inténtelo de nuevo.';

  // Qibla feature translations
  @override
  String get qiblaAligned => '¡Qibla alineada!';

  @override
  String get qiblaNoCompassData => 'No hay datos de brújula';

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
  String get qiblaDirectionLabel => 'Dirección de la Qibla';

  @override
  String get qiblaDistance => 'Distancia a la Kaaba';

  @override
  String get qiblaHelpTitle => 'Cómo usar el buscador de Qibla';

  @override
  String get qiblaHelpStep1 => 'Sostenga su teléfono plano y nivelado.';

  @override
  String get qiblaHelpStep2 =>
      'Gire lentamente hasta que la flecha apunte hacia la Kaaba.';

  @override
  String get qiblaHelpStep3 =>
      'Cuando esté alineado, verá un mensaje de confirmación.';

  @override
  String get qiblaHelpStep4 =>
      'Si los datos de la brújula son inexactos, toque el botón de calibración.';

  @override
  String get qiblaGotIt => 'Entendido';

  // Add missing Qibla turn and almost-there messages
  @override
  String get qiblaTurnRight => 'Gira a la derecha para encontrar la Qibla';

  @override
  String get qiblaTurnLeft => 'Gira a la izquierda para encontrar la Qibla';

  @override
  String get qiblaAlmostThere => '¡Casi listo!';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'Establecer objetivo del contador';

  @override
  String get tesbihTarget => 'Objetivo';

  @override
  String get tesbihEnterTarget => 'Introduzca el recuento objetivo';

  @override
  String get tesbihOk => 'Aceptar';

  @override
  String get tesbihSave => 'Guardar';

  @override
  String get tesbihVibration => 'Vibración';

  @override
  String get tesbihSound => 'Sonido';

  @override
  String get tesbihTodaySessions => 'Sesiones de hoy';

  @override
  String get tesbihNoSessions => 'No hay sesiones registradas hoy';

  @override
  String get errorOpeningMap => 'No se pudo abrir la aplicación de mapas';

  @override
  String get qiblaCurrentDirectionLabel => 'Dirección actual';

  @override
  String get aboutAppSubtitle =>
      'Más información sobre la aplicación Muslim Deen';

  @override
  String get dubai => 'Dubái';

  @override
  String get moonsightingCommittee => 'Comité Mundial de Avistamiento de Luna';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Qatar';

  @override
  String get singapore => 'Singapur';

  @override
  String get turkey => 'Turquía (Diyanet)';

  @override
  String get startCalibration => 'Iniciar calibración';

  @override
  String get distanceUnit => 'millas de distancia';

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
  String get qiblaErrorLocationUnavailable => 'Servicios de ubicación no disponibles. Por favor, active los servicios de ubicación e inténtelo de nuevo.';

  @override
  String get qiblaErrorPermissionDeniedSettings => 'Permiso de ubicación denegado permanentemente. Por favor, actívelo en los ajustes de la aplicación.';

  @override
  String get qiblaErrorServiceDisabled => 'Los servicios de ubicación están desactivados. Por favor, actívelos para determinar la dirección de la Qibla.';

  @override
  String get qiblaErrorUnknown => 'Ocurrió un error desconocido al intentar determinar la dirección de la Qibla.';
}
