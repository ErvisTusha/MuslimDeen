/// Application-wide constants and default values
class AppConstants {
  // Dhikr constants
  static const Map<String, String> dhikrArabic = {
    'Subhanallah': 'سُبْحَانَ اللهِ',
    'Alhamdulillah': 'الْحَمْدُ لِلَّهِ',
    'Astaghfirullah': 'أَسْتَغْفِرُ اللهَ',
    'Allahu Akbar': 'اللهُ أَكْبَر',
  };

  static const Map<String, int> defaultDhikrTargets = {
    'Subhanallah': 33,
    'Alhamdulillah': 33,
    'Astaghfirullah': 33,
    'Allahu Akbar': 34,
  };

  static const List<String> dhikrOrder = [
    'Subhanallah',
    'Alhamdulillah',
    'Astaghfirullah',
    'Allahu Akbar',
  ];

  static const Map<String, String> dhikrAudioFiles = {
    'Subhanallah': 'audio/SubhanAllah.mp3',
    'Alhamdulillah': 'audio/Alhamdulillah.mp3',
    'Astaghfirullah': 'audio/Astaghfirullah.mp3',
    'Allahu Akbar': 'audio/AllahuAkbar.mp3',
  };

  // Kaaba coordinates
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  // Cache durations (in minutes)
  static const int qiblaExpirationMinutes = 30;
  static const int positionCacheDurationMinutes = 5;

  // Notification IDs
  static const int tesbihReminderId = 9876;

  // Default animation durations
  static const int defaultAnimationDurationMs = 200;
  static const int defaultTransitionDelayMs = 1500;

  // File paths
  static const String tesbihCounterSound = 'audio/click.mp3';

  // Default target values
  static const int defaultTesbihTarget = 33;
  static const int defaultDhikrTransitionDelay = 1500;

  // Dialog theme identifier for distinguishing dialog types
  static const String dialogThemeKey = 'tesbih_dialog_theme';
}
