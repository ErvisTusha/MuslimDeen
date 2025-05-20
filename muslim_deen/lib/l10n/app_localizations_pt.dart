import 'app_localizations.dart';

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([super.locale = 'pt']);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tasbih';

  @override
  String get qiblaLabel => 'Qibla';

  @override
  String get prayerLabel => 'Oração';

  @override
  String get mosquesLabel => 'Mesquitas';

  @override
  String get moreLabel => 'Mais';

  @override
  String get settings => 'Configurações';

  @override
  String get location => 'Localização';

  @override
  String get currentLocation => 'Localização atual';

  @override
  String get notSet => 'Não definida';

  @override
  String get loading => 'A carregar...';

  @override
  String get setLocationManually => 'Definir manualmente';

  @override
  String get prayerCalculation => 'Cálculo de orações';

  @override
  String get calculationMethod => 'Método de cálculo';

  @override
  String get asrTime => 'Horário de Asr (Madhab)';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notificações';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Nascer do sol';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get notificationTiming => 'Tempo de notificação';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutos antes';
  }

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get cancel => 'Cancelar';

  @override
  String get other => 'Outros';

  @override
  String get about => 'Sobre';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutAppDescription =>
      'Muslim Deen App\nVersion 1.0.0\n\nDeveloped with Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature em breve!';
  }

  @override
  String get muslimWorldLeague => 'Liga Mundial Muçulmana';

  @override
  String get northAmerica => 'ISNA (América do Norte)';

  @override
  String get egyptian => 'Autoridade Geral Egípcia';

  @override
  String get ummAlQura => 'Universidade Umm al-Qura, Meca';

  @override
  String get karachi => 'Universidade de Ciências Islâmicas, Karachi';

  @override
  String get tehran => 'Instituto de Geofísica, Universidade de Teerã';

  @override
  String get currentPrayerTitle => 'Oração Atual';

  @override
  String get nextPrayerTitle => 'Próxima Oração';

  @override
  String get prayerTimesTitle => 'Horários de Oração';

  @override
  String get unknownLocation => 'Localização Desconhecida';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get now => 'Agora';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get openAppSettings => 'Abrir Configurações do App';

  @override
  String get openLocationSettings => 'Abrir Configurações de Localização';

  @override
  String unexpectedError(String error) {
    return 'Ocorreu um erro inesperado: $error';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Nascer do sol';

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
    return 'Hora da Oração de $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'A oração de $prayerName está a aproximar-se.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Xiita Ithna-Ashari (Jafari)';

  @override
  String get qiblaInstruction => 'Aponte o seu telemóvel em direção à Qibla';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Direção Atual: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Qibla: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Permissão de localização necessária para determinar a direção da Qibla.';

  @override
  String get qiblaErrorSensor =>
      'Sensor de bússola não disponível ou não funciona.';

  @override
  String get qiblaErrorLocation =>
      'Não foi possível obter a localização atual.';

  @override
  String get qiblaCalibrate => 'Calibrar Bússola';

  @override
  String get qiblaCalibrating =>
      'Por favor, mova o seu dispositivo num padrão em forma de 8 para calibrar a bússola.';

  @override
  String tesbihCounter(int count) {
    return 'Contador: $count';
  }

  @override
  String get tesbihReset => 'Repor';

  @override
  String get mosquesLoading => 'A carregar mesquitas próximas...';

  @override
  String mosquesError(String error) {
    return 'Erro ao carregar mesquitas: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Abrir nos Mapas';

  @override
  String get mosquesNoResults =>
      'Nenhuma mesquita encontrada nas proximidades.';

  @override
  String get homeErrorLoading =>
      'Falha ao carregar os horários de oração. Verifique a ligação e as definições de localização.';

  @override
  String get homeErrorLocationDisabled =>
      'Os serviços de localização estão desativados. Ative-os nas definições do seu dispositivo.';

  @override
  String get homeErrorPermissionDenied =>
      'Permissão de localização negada. Conceda permissão para mostrar os horários de oração.';

  @override
  String get homeErrorPermissionPermanent =>
      'Permissão de localização negada permanentemente. Ative-a nas definições da aplicação.';

  @override
  String get homeErrorLocationUnknown =>
      'Não foi possível determinar a sua localização. Certifique-se de que os serviços de localização estão ativados e as permissões concedidas.';

  @override
  String get homeErrorInitialization =>
      'Erro de inicialização. Reinicie a aplicação.';

  @override
  String homeTimeIn(String duration) {
    return 'Em $duration';
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
  String get errorSetLocation =>
      'Erro ao definir a localização. Por favor, tente novamente.';

  @override
  String get qiblaAligned => 'Qibla alinhada!';

  @override
  String get qiblaNoCompassData => 'Sem dados da bússola';

  @override
  String get qiblaDirectionNorth => 'N';

  @override
  String get qiblaDirectionEast => 'L';

  @override
  String get qiblaDirectionSouth => 'S';

  @override
  String get qiblaDirectionWest => 'O';

  @override
  String get qiblaNotAvailable => 'N/D';

  @override
  String get qiblaDirectionLabel => 'Direção da Qibla';

  @override
  String get qiblaDistance => 'Distância até a Kaaba';

  @override
  String get qiblaHelpTitle => 'Como usar o Localizador de Qibla';

  @override
  String get qiblaHelpStep1 => 'Segure seu telefone plano e nivelado.';

  @override
  String get qiblaHelpStep2 =>
      'Gire lentamente até que a seta aponte para a Kaaba.';

  @override
  String get qiblaHelpStep3 =>
      'Quando alinhado, você verá uma mensagem de confirmação.';

  @override
  String get qiblaHelpStep4 =>
      'Se os dados da bússola forem imprecisos, toque no botão de calibração.';

  @override
  String get qiblaGotIt => 'Entendi';

  // Add missing Qibla turn and alignment messages
  @override
  String get qiblaTurnRight => 'Vire à direita para encontrar a Qibla';

  @override
  String get qiblaTurnLeft => 'Vire à esquerda para encontrar a Qibla';

  @override
  String get qiblaAlmostThere => 'Quase lá!';

  @override
  String get tesbihOk => 'OK';

  @override
  String get tesbihSave => 'Salvar';

  @override
  String get tesbihVibration => 'Vibração';

  @override
  String get tesbihSound => 'Som';

  @override
  String get tesbihTodaySessions => 'Sessões de Hoje';

  @override
  String get tesbihNoSessions => 'Nenhuma sessão registrada hoje';

  @override
  String get errorOpeningMap => 'Não foi possível abrir o aplicativo de mapas';

  @override
  String get qiblaCurrentDirectionLabel => 'Direção atual';

  @override
  String get aboutAppSubtitle => 'Saiba mais sobre o aplicativo Muslim Deen';

  @override
  String get dubai => 'Dubai';

  @override
  String get moonsightingCommittee => 'Comitê Mundial de Observação da Lua';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Catar';

  @override
  String get singapore => 'Singapura';

  @override
  String get turkey => 'Turquia (Diyanet)';

  @override
  String get startCalibration => 'Iniciar Calibração';

  @override
  String get distanceUnit => 'milhas de distância';

  @override
  String get azanSound => 'Som do Azan';

  @override
  String get makkahAdhan => 'Adhan de Makkah';

  @override
  String get madinahAdhan => 'Adhan de Madinah';

  @override
  String get alAqsaAdhan => 'Adhan de Al-Aqsa';

  @override
  String get turkishAdhan => 'Adhan Turco';

  @override
  String get tesbihSetTarget => 'Definir Meta do Contador';

  @override
  String get tesbihTarget => 'Meta';

  @override
  String get tesbihEnterTarget => 'Insira a meta da contagem';
@override
  String get qiblaErrorLocationUnavailable => 'Serviços de localização indisponíveis. Ative os serviços de localização e tente novamente.';

  @override
  String get qiblaErrorPermissionDeniedSettings => 'Permissão de localização negada permanentemente. Ative-a nas configurações do aplicativo.';

  @override
  String get qiblaErrorServiceDisabled => 'Os serviços de localização estão desativados. Ative-os para determinar a direção da Qibla.';

  @override
  String get qiblaErrorUnknown => 'Ocorreu um erro desconhecido ao tentar determinar a direção da Qibla.';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tasbih';

  @override
  String get qiblaLabel => 'Qibla';

  @override
  String get prayerLabel => 'Oração';

  @override
  String get mosquesLabel => 'Mesquitas';

  @override
  String get moreLabel => 'Mais';

  @override
  String get settings => 'Configurações';

  @override
  String get location => 'Localização';

  @override
  String get currentLocation => 'Localização Atual';

  @override
  String get notSet => 'Não definido';

  @override
  String get loading => 'Carregando...';

  @override
  String get setLocationManually => 'Definir Localização Manualmente';

  @override
  String get prayerCalculation => 'Cálculo da Oração';

  @override
  String get calculationMethod => 'Método de Cálculo';

  @override
  String get asrTime => 'Hora do Asr (Madhab)';

  @override
  String get shafi => 'Shafi\'i';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notificações';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Nascer do sol';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get notificationTiming => 'Horário da Notificação';

  @override
  String minutesBefore(int minutes) {
    return '$minutes minutos antes';
  }

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get language => 'Idioma';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get cancel => 'Cancelar';

  @override
  String get other => 'Outro';

  @override
  String get about => 'Sobre';

  @override
  String get aboutTitle => 'Sobre';

  @override
  String get aboutAppDescription =>
      'Aplicativo Muslim Deen\nVersão 1.0.0\n\nDesenvolvido com Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature em breve!';
  }

  @override
  String get muslimWorldLeague => 'Liga Mundial Islâmica';

  @override
  String get northAmerica => 'ISNA (América do Norte)';

  @override
  String get egyptian => 'Autoridade Geral Egípcia';

  @override
  String get ummAlQura => 'Universidade Umm al-Qura, Meca';

  @override
  String get karachi => 'Universidade de Ciências Islâmicas, Karachi';

  @override
  String get tehran => 'Instituto de Geofísica, Universidade de Teerã';

  @override
  String get currentPrayerTitle => 'Oração Atual';

  @override
  String get nextPrayerTitle => 'Próxima Oração';

  @override
  String get prayerTimesTitle => 'Horários das Orações';

  @override
  String get unknownLocation => 'Localização Desconhecida';

  @override
  String get unknown => 'Desconhecido';

  @override
  String get now => 'Agora';

  @override
  String get retry => 'Tentar Novamente';

  @override
  String get openAppSettings => 'Abrir Configurações do Aplicativo';

  @override
  String get openLocationSettings => 'Abrir Configurações de Localização';

  @override
  String unexpectedError(String error) {
    return 'Ocorreu um erro inesperado: $error';
  }

  @override
  String get prayerNameFajr => 'Fajr';

  @override
  String get prayerNameSunrise => 'Nascer do sol';

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
    return 'Hora da Oração de $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'A oração de $prayerName está se aproximando.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Xiita Ithna-Ashari (Jafari)';

  @override
  String get qiblaInstruction => 'Aponte seu celular em direção à Qibla';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Direção Atual: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Qibla: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Permissão de localização necessária para determinar a direção da Qibla.';

  @override
  String get qiblaErrorSensor =>
      'Sensor de bússola não disponível ou não funcionando.';

  @override
  String get qiblaErrorLocation =>
      'Não foi possível obter a localização atual.';

  @override
  String get qiblaCalibrate => 'Calibrar Bússola';

  @override
  String get qiblaCalibrating =>
      'Por favor, mova seu dispositivo em um padrão de 8 para calibrar a bússola.';

  @override
  String tesbihCounter(int count) {
    return 'Contador: $count';
  }

  @override
  String get tesbihReset => 'Redefinir';

  @override
  String get mosquesLoading => 'Carregando mesquitas próximas...';

  @override
  String mosquesError(String error) {
    return 'Erro ao carregar mesquitas: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Abrir no Maps';

  @override
  String get mosquesNoResults =>
      'Nenhuma mesquita encontrada nas proximidades.';

  @override
  String get homeErrorLoading =>
      'Falha ao carregar os horários de oração. Verifique a conexão e as configurações de localização.';

  @override
  String get homeErrorLocationDisabled =>
      'Os serviços de localização estão desativados. Ative-os nas configurações do seu dispositivo.';

  @override
  String get homeErrorPermissionDenied =>
      'Permissão de localização negada. Conceda permissão para mostrar os horários de oração.';

  @override
  String get homeErrorPermissionPermanent =>
      'Permissão de localização negada permanentemente. Ative-a nas configurações do aplicativo.';

  @override
  String get homeErrorLocationUnknown =>
      'Não foi possível determinar sua localização. Certifique-se de que os serviços de localização estão ativados e as permissões concedidas.';

  @override
  String get homeErrorInitialization =>
      'Erro de inicialização. Reinicie o aplicativo.';

  @override
  String homeTimeIn(String duration) {
    return 'Em $duration';
  }

  @override
  String get homeAppName => 'Muslim Deen';

  @override
  String get deviceLocation => 'Localização atual do dispositivo';

  @override
  String get errorSetLocation =>
      'Erro ao definir a localização. Por favor, tente novamente.';

  @override
  String get qiblaAligned => 'Qibla alinhada!';

  @override
  String get qiblaNoCompassData => 'Sem dados da bússola';

  @override
  String get qiblaDirectionNorth => 'N';

  @override
  String get qiblaDirectionEast => 'L';

  @override
  String get qiblaDirectionSouth => 'S';

  @override
  String get qiblaDirectionWest => 'O';

  @override
  String get qiblaNotAvailable => 'N/D';

  @override
  String get qiblaDirectionLabel => 'Direção da Qibla';

  @override
  String get qiblaDistance => 'Distância até a Kaaba';

  @override
  String get qiblaHelpTitle => 'Como usar o Localizador de Qibla';

  @override
  String get qiblaHelpStep1 => 'Segure seu telefone plano e nivelado.';

  @override
  String get qiblaHelpStep2 =>
      'Gire lentamente até que a seta aponte para a Kaaba.';

  @override
  String get qiblaHelpStep3 =>
      'Quando alinhado, você verá uma mensagem de confirmação.';

  @override
  String get qiblaHelpStep4 =>
      'Se os dados da bússola forem imprecisos, toque no botão de calibração.';

  @override
  String get qiblaGotIt => 'Entendi';

  @override
  String get tesbihSetTarget => 'Definir Meta do Contador';

  @override
  String get tesbihTarget => 'Meta';

  @override
  String get tesbihEnterTarget => 'Insira a meta da contagem';

  @override
  String get tesbihOk => 'OK';

  @override
  String get tesbihSave => 'Salvar';

  @override
  String get tesbihVibration => 'Vibração';

  @override
  String get tesbihSound => 'Som';

  @override
  String get tesbihTodaySessions => 'Sessões de Hoje';

  @override
  String get tesbihNoSessions => 'Nenhuma sessão registrada hoje';

  @override
  String get errorOpeningMap => 'Não foi possível abrir o aplicativo de mapas';

  @override
  String get qiblaCurrentDirectionLabel => 'Direção atual';

  @override
  String get aboutAppSubtitle => 'Saiba mais sobre o aplicativo Muslim Deen';

  @override
  String get dubai => 'Dubai';

  @override
  String get moonsightingCommittee => 'Comitê Mundial de Observação da Lua';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Catar';

  @override
  String get singapore => 'Singapura';

  @override
  String get turkey => 'Turquia (Diyanet)';

  @override
  String get startCalibration => 'Iniciar Calibração';

  @override
  String get distanceUnit => 'milhas de distância';

  @override
  String get azanSound => 'Som do Azan';

  @override
  String get makkahAdhan => 'Adhan de Makkah';

  @override
  String get madinahAdhan => 'Adhan de Madinah';

  @override
  String get alAqsaAdhan => 'Adhan de Al-Aqsa';

  @override
  String get turkishAdhan => 'Adhan Turco';
  @override
  String get useDeviceLocation => '[PT_BR] Use Device Location';

  @override
  String get searchCity => '[PT_BR] Search City';

  @override
  String get search => '[PT_BR] Search';

  @override
  String get noLocationsFound => '[PT_BR] No locations found. Try a different search.';

  @override
  String get searchError => '[PT_BR] Error searching for places. Please try again.';
}
