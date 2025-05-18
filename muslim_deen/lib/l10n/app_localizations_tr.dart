import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Muslim Deen';

  @override
  String get tasbihLabel => 'Tesbih';

  @override
  String get qiblaLabel => 'Kıble';

  @override
  String get prayerLabel => 'Namaz';

  @override
  String get mosquesLabel => 'Camiler';

  @override
  String get moreLabel => 'Daha Fazla';

  @override
  String get settings => 'Ayarlar';

  @override
  String get location => 'Konum';

  @override
  String get currentLocation => 'Mevcut Konum';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get loading => 'Yükleniyor...';

  @override
  String get setLocationManually => 'Konumu Manuel Olarak Ayarla';

  @override
  String get prayerCalculation => 'Namaz Hesaplama';

  @override
  String get calculationMethod => 'Hesaplama Yöntemi';

  @override
  String get asrTime => 'İkindi Vakti (Mezhep)';

  @override
  String get shafi => 'Şafi';

  @override
  String get hanafi => 'Hanefi';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get fajr => 'İmsak';

  @override
  String get sunrise => 'Güneş';

  @override
  String get dhuhr => 'Öğle';

  @override
  String get asr => 'İkindi';

  @override
  String get maghrib => 'Akşam';

  @override
  String get isha => 'Yatsı';

  @override
  String get notificationTiming => 'Bildirim Zamanlaması';

  @override
  String minutesBefore(int minutes) {
    return '$minutes dakika önce';
  }

  @override
  String get appearance => 'Görünüm';

  @override
  String get theme => 'Tema';

  @override
  String get system => 'Sistem';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get language => 'Dil';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get cancel => 'İptal';

  @override
  String get other => 'Diğer';

  @override
  String get about => 'Hakkında';

  @override
  String get aboutTitle => 'Hakkında';

  @override
  String get aboutAppDescription =>
      'Muslim Deen Uygulaması\nSürüm 1.0.0\n\nFlutter ile geliştirildi.';

  @override
  String comingSoon(String feature) {
    return '$feature yakında geliyor!';
  }

  @override
  String get muslimWorldLeague => 'Müslüman Dünya Ligi';

  @override
  String get northAmerica => 'ISNA (Kuzey Amerika)';

  @override
  String get egyptian => 'Mısır Genel Otoritesi';

  @override
  String get ummAlQura => 'Ümmü\'l-Kurra Üniversitesi, Mekke';

  @override
  String get karachi => 'İslami İlimler Üniversitesi, Karaçi';

  @override
  String get tehran => 'Tahran Üniversitesi Jeofizik Enstitüsü';

  @override
  String get currentPrayerTitle => 'Mevcut Namaz';

  @override
  String get nextPrayerTitle => 'Sonraki Namaz';

  @override
  String get prayerTimesTitle => 'Namaz Vakitleri';

  @override
  String get unknownLocation => 'Bilinmeyen Konum';

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get now => 'Şimdi';

  @override
  String get retry => 'Tekrar Dene';

  @override
  String get openAppSettings => 'Uygulama Ayarlarını Aç';

  @override
  String get openLocationSettings => 'Konum Ayarlarını Aç';

  @override
  String unexpectedError(String error) {
    return 'Beklenmeyen bir hata oluştu: $error';
  }

  @override
  String get prayerNameFajr => 'İmsak';

  @override
  String get prayerNameSunrise => 'Güneş';

  @override
  String get prayerNameDhuhr => 'Öğle';

  @override
  String get prayerNameAsr => 'İkindi';

  @override
  String get prayerNameMaghrib => 'Akşam';

  @override
  String get prayerNameIsha => 'Yatsı';

  @override
  String notificationPrayerTitle(String prayerName) {
    return '$prayerName Namaz Vakti';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return '$prayerName namazı yaklaşıyor.';
  }

  @override
  String get settingsCalculationMethodJafari => 'Şii İsnâaşeriyye (Caferi)';

  @override
  String get qiblaInstruction => 'Telefonunuzu Kıble\'ye doğru çevirin';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'Mevcut Yön: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'Kıble: $degrees°';
  }

  @override
  String get qiblaErrorPermission =>
      'Kıble yönünü belirlemek için konum izni gerekli.';

  @override
  String get qiblaErrorSensor => 'Pusula sensörü mevcut değil veya çalışmıyor.';

  @override
  String get qiblaErrorLocation => 'Mevcut konum alınamadı.';

  @override
  String get qiblaCalibrate => 'Pusulayı Kalibre Et';

  @override
  String get qiblaCalibrating =>
      'Pusulayı kalibre etmek için lütfen cihazınızı 8 şeklinde hareket ettirin.';

  @override
  String tesbihCounter(int count) {
    return 'Sayaç: $count';
  }

  @override
  String get tesbihReset => 'Sıfırla';

  @override
  String get mosquesLoading => 'Yakındaki camiler yükleniyor...';

  @override
  String mosquesError(String error) {
    return 'Camiler yüklenirken hata oluştu: $error';
  }

  @override
  String get mosquesOpenInMaps => 'Haritalarda Aç';

  @override
  String get mosquesNoResults => 'Yakında cami bulunamadı.';

  @override
  String get homeErrorLoading =>
      'Namaz vakitleri yüklenemedi. Lütfen bağlantıyı ve konum ayarlarını kontrol edin.';

  @override
  String get homeErrorLocationDisabled =>
      'Konum servisleri devre dışı. Lütfen cihaz ayarlarınızdan etkinleştirin.';

  @override
  String get homeErrorPermissionDenied =>
      'Konum izni reddedildi. Namaz vakitlerini göstermek için lütfen izin verin.';

  @override
  String get homeErrorPermissionPermanent =>
      'Konum izni kalıcı olarak reddedildi. Lütfen uygulama ayarlarından etkinleştirin.';

  @override
  String get homeErrorLocationUnknown =>
      'Konumunuz belirlenemedi. Lütfen konum servislerinin etkin olduğundan ve izinlerin verildiğinden emin olun.';

  @override
  String get homeErrorInitialization =>
      'Başlatma hatası. Lütfen uygulamayı yeniden başlatın.';

  @override
  String homeTimeIn(String duration) {
    return '$duration içinde';
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
  String get deviceLocation => 'Cihazın mevcut konumu';

  @override
  String get errorSetLocation =>
      'Konum ayarlanırken hata oluştu. Lütfen tekrar deneyin.';

  // Qibla feature translations
  @override
  String get qiblaAligned => 'Kıble hizalandı!';

  @override
  String get qiblaNoCompassData => 'Pusula verisi yok';

  @override
  String get qiblaDirectionNorth => 'K';

  @override
  String get qiblaDirectionEast => 'D';

  @override
  String get qiblaDirectionSouth => 'G';

  @override
  String get qiblaDirectionWest => 'B';

  @override
  String get qiblaNotAvailable => 'Mevcut değil';

  @override
  String get qiblaDirectionLabel => 'Kıble Yönü';

  @override
  String get qiblaDistance => 'Kabe\'ye Uzaklık';

  @override
  String get qiblaHelpTitle => 'Kıble Bulucu Nasıl Kullanılır';

  @override
  String get qiblaHelpStep1 => 'Telefonunuzu düz ve dengeli tutun.';

  @override
  String get qiblaHelpStep2 => 'Ok Kabe\'yi gösterene kadar yavaşça döndürün.';

  @override
  String get qiblaHelpStep3 => 'Hizalandığında, bir onay mesajı göreceksiniz.';

  @override
  String get qiblaHelpStep4 =>
      'Pusula verileri hatalıysa, kalibrasyon düğmesine dokunun.';

  @override
  String get qiblaGotIt => 'Anladım';

  // Add missing Qibla turn and alignment messages
  @override
  String get qiblaTurnRight => 'Kıbleyi bulmak için sağa dönün';

  @override
  String get qiblaTurnLeft => 'Kıbleyi bulmak için sola dönün';

  @override
  String get qiblaAlmostThere => 'Neredeyse oradasınız!';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'Sayaç Hedefini Ayarla';

  @override
  String get tesbihTarget => 'Hedef';

  @override
  String get tesbihEnterTarget => 'Hedef sayısını girin';

  @override
  String get tesbihOk => 'Tamam';

  @override
  String get tesbihSave => 'Kaydet';

  @override
  String get tesbihVibration => 'Titreşim';

  @override
  String get tesbihSound => 'Ses';

  @override
  String get tesbihTodaySessions => 'Bugünün Oturumları';

  @override
  String get tesbihNoSessions => 'Bugün kaydedilmiş oturum yok';

  @override
  String get errorOpeningMap => 'Harita uygulaması açılamadı';

  @override
  String get qiblaCurrentDirectionLabel => 'Mevcut Yön';

  @override
  String get aboutAppSubtitle =>
      'Muslim Deen uygulaması hakkında daha fazla bilgi edinin';

  @override
  String get dubai => 'Dubai';

  @override
  String get moonsightingCommittee => 'Dünya Hilal Gözlem Komitesi';

  @override
  String get kuwait => 'Kuveyt';

  @override
  String get qatar => 'Katar';

  @override
  String get singapore => 'Singapur';

  @override
  String get turkey => 'Türkiye (Diyanet)';

  @override
  String get startCalibration => 'Kalibrasyonu Başlat';

  @override
  String get distanceUnit => 'mil uzakta';

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
  String get qiblaErrorUnknown => 'An unknown error occurred while trying to determine the Qibla direction.';

  @override
  String get qiblaErrorPermissionDeniedSettings => 'Location permission is required for Qibla finder. Please enable it in your browser/device settings.';

  @override
  String get qiblaErrorServiceDisabled => 'Location services are disabled. Please enable them to use the Qibla feature.';

  @override
  String get qiblaErrorLocationUnavailable => 'Could not access your current location. Please ensure location services are on and permissions are granted.';
}
