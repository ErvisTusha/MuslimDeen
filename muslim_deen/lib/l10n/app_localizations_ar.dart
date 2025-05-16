import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دين المسلم';

  @override
  String get tasbihLabel => 'تسبيح';

  @override
  String get qiblaLabel => 'القبلة';

  @override
  String get prayerLabel => 'الصلاة';

  @override
  String get mosquesLabel => 'المساجد';

  @override
  String get moreLabel => 'المزيد';

  @override
  String get settings => 'الإعدادات';

  @override
  String get location => 'الموقع';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get notSet => 'غير محدد';

  @override
  String get loading => 'جار التحميل...';

  @override
  String get setLocationManually => 'تحديد الموقع يدوياً';

  @override
  String get prayerCalculation => 'حساب الصلاة';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get asrTime => 'وقت العصر (المذهب)';

  @override
  String get shafi => 'الشافعي';

  @override
  String get hanafi => 'الحنفي';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get notificationTiming => 'توقيت الإشعار';

  @override
  String minutesBefore(int minutes) {
    return 'قبل $minutes دقيقة';
  }

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get system => 'النظام';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get other => 'أخرى';

  @override
  String get about => 'حول';

  @override
  String get aboutTitle => 'حول';

  @override
  String get aboutAppDescription =>
      'تطبيق مسلم دين\nالإصدار 1.0.0\n\nتم التطوير باستخدام Flutter.';

  @override
  String comingSoon(String feature) {
    return '$feature قريباً!';
  }

  @override
  String get muslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get northAmerica => 'ISNA (أمريكا الشمالية)';

  @override
  String get egyptian => 'الهيئة المصرية العامة للمساحة';

  @override
  String get ummAlQura => 'جامعة أم القرى، مكة المكرمة';

  @override
  String get karachi => 'جامعة العلوم الإسلامية، كراتشي';

  @override
  String get tehran => 'معهد الجيوفيزياء، جامعة طهران';

  @override
  String get currentPrayerTitle => 'الصلاة الحالية';

  @override
  String get nextPrayerTitle => 'الصلاة التالية';

  @override
  String get prayerTimesTitle => 'أوقات الصلاة';

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get unknown => 'غير معروف';

  @override
  String get now => 'الآن';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get openAppSettings => 'فتح إعدادات التطبيق';

  @override
  String get openLocationSettings => 'فتح إعدادات الموقع';

  @override
  String unexpectedError(String error) {
    return 'حدث خطأ غير متوقع: $error';
  }

  @override
  String get prayerNameFajr => 'الفجر';

  @override
  String get prayerNameSunrise => 'الشروق';

  @override
  String get prayerNameDhuhr => 'الظهر';

  @override
  String get prayerNameAsr => 'العصر';

  @override
  String get prayerNameMaghrib => 'المغرب';

  @override
  String get prayerNameIsha => 'العشاء';

  @override
  String notificationPrayerTitle(String prayerName) {
    return 'وقت صلاة $prayerName';
  }

  @override
  String notificationPrayerBody(String prayerName) {
    return 'صلاة $prayerName تقترب.';
  }

  @override
  String get settingsCalculationMethodJafari =>
      'الشيعة الاثنا عشرية (الجعفرية)';

  @override
  String get qiblaInstruction => 'وجه هاتفك نحو القبلة';

  @override
  String qiblaCurrentDirection(String degrees) {
    return 'الاتجاه الحالي: $degrees°';
  }

  @override
  String qiblaRequiredDirection(String degrees) {
    return 'القبلة: $degrees°';
  }

  @override
  String get qiblaErrorPermission => 'إذن الموقع مطلوب لتحديد اتجاه القبلة.';

  @override
  String get qiblaErrorSensor => 'مستشعر البوصلة غير متوفر أو لا يعمل.';

  @override
  String get qiblaErrorLocation => 'تعذر الحصول على الموقع الحالي.';

  @override
  String get qiblaCalibrate => 'معايرة البوصلة';

  @override
  String get qiblaCalibrating =>
      'يرجى تحريك جهازك على شكل الرقم 8 لمعايرة البوصلة.';

  @override
  String tesbihCounter(int count) {
    return 'العداد: $count';
  }

  @override
  String get tesbihReset => 'إعادة ضبط';

  @override
  String get mosquesLoading => 'جار تحميل المساجد القريبة...';

  @override
  String mosquesError(String error) {
    return 'خطأ في تحميل المساجد: $error';
  }

  @override
  String get mosquesOpenInMaps => 'فتح في الخرائط';

  @override
  String get mosquesNoResults => 'لم يتم العثور على مساجد قريبة.';

  @override
  String get homeErrorLoading =>
      'فشل تحميل أوقات الصلاة. يرجى التحقق من الاتصال وإعدادات الموقع.';

  @override
  String get homeErrorLocationDisabled =>
      'خدمات الموقع معطلة. يرجى تمكينها في إعدادات جهازك.';

  @override
  String get homeErrorPermissionDenied =>
      'تم رفض إذن الموقع. يرجى منح الإذن لعرض أوقات الصلاة.';

  @override
  String get homeErrorPermissionPermanent =>
      'تم رفض إذن الموقع بشكل دائم. يرجى تمكينه في إعدادات التطبيق.';

  @override
  String get homeErrorLocationUnknown =>
      'تعذر تحديد موقعك. يرجى التأكد من تمكين خدمات الموقع ومنح الأذونات.';

  @override
  String get homeErrorInitialization =>
      'خطأ في التهيئة. يرجى إعادة تشغيل التطبيق.';

  @override
  String homeTimeIn(String duration) {
    return 'خلال $duration';
  }

  @override
  String get homeAppName => 'دين المسلم';

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
  String get deviceLocation => 'الموقع الحالي للجهاز';

  @override
  String get errorSetLocation => 'خطأ في تعيين الموقع. يرجى المحاولة مرة أخرى.';

  // Qibla feature translations
  @override
  String get qiblaAligned => 'تم توجيه القبلة!';

  @override
  String get qiblaNoCompassData => 'لا توجد بيانات البوصلة';

  @override
  String get qiblaDirectionNorth => 'ش';

  @override
  String get qiblaDirectionEast => 'ق';

  @override
  String get qiblaDirectionSouth => 'ج';

  @override
  String get qiblaDirectionWest => 'غ';

  @override
  String get qiblaNotAvailable => 'غير متوفر';

  @override
  String get qiblaDirectionLabel => 'اتجاه القبلة';

  @override
  String get qiblaDistance => 'المسافة إلى الكعبة';

  @override
  String get qiblaHelpTitle => 'كيفية استخدام محدد القبلة';

  @override
  String get qiblaHelpStep1 => 'امسك هاتفك بشكل مستوٍ وثابت.';

  @override
  String get qiblaHelpStep2 => 'أدر ببطء حتى يشير السهم إلى الكعبة.';

  @override
  String get qiblaHelpStep3 => 'عند المحاذاة، ستظهر رسالة تأكيد.';

  @override
  String get qiblaHelpStep4 =>
      'إذا كانت بيانات البوصلة غير دقيقة، اضغط على زر المعايرة.';

  @override
  String get qiblaGotIt => 'فهمت';

  // Add missing Qibla turn and almost-there messages
  @override
  String get qiblaTurnRight => 'انتقل إلى اليمين للعثور على القبلة';

  @override
  String get qiblaTurnLeft => 'انتقل إلى اليسار للعثور على القبلة';

  @override
  String get qiblaAlmostThere => 'قريب جداً';

  // Tesbih feature translations
  @override
  String get tesbihSetTarget => 'تعيين هدف العداد';

  @override
  String get tesbihTarget => 'الهدف';

  @override
  String get tesbihEnterTarget => 'أدخل عدد الهدف';

  @override
  String get tesbihOk => 'موافق';

  @override
  String get tesbihSave => 'حفظ';

  @override
  String get tesbihVibration => 'الاهتزاز';

  @override
  String get tesbihSound => 'الصوت';

  @override
  String get tesbihTodaySessions => 'جلسات اليوم';

  @override
  String get tesbihNoSessions => 'لم يتم تسجيل جلسات اليوم';

  @override
  String get errorOpeningMap => 'تعذر فتح تطبيق الخرائط';

  @override
  String get qiblaCurrentDirectionLabel => 'الاتجاه الحالي';

  @override
  String get aboutAppSubtitle => 'تعرف أكثر على تطبيق مسلم دين';

  @override
  String get dubai => 'دبي';

  @override
  String get moonsightingCommittee => 'لجنة رؤية الهلال العالمية';

  @override
  String get kuwait => 'الكويت';

  @override
  String get qatar => 'قطر';

  @override
  String get singapore => 'سنغافورة';

  @override
  String get turkey => 'تركيا (ديانت)';

  @override
  String get startCalibration => 'بدء المعايرة';

  @override
  String get distanceUnit => 'أميال';

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
