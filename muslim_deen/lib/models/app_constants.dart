/// Application-wide constants and default values
/// 
/// This class serves as a centralized repository for all constant values used
/// throughout the MuslimDeen application. It provides a single source of truth
/// for configuration values, reducing magic numbers and improving maintainability.
/// 
/// Key responsibilities:
/// - Define static constants for UI configurations
/// - Store default values for user preferences
/// - Maintain application-wide thresholds and limits
/// - Provide resource references for assets and media
/// 
/// Organization:
/// - Constants are grouped by functional area (Dhikr, Location, Cache, etc.)
/// - Each group contains related constants with descriptive names
/// - All constants are static const for compile-time optimization
/// 
/// Usage patterns:
/// - Access constants directly via class name: AppConstants.dhikrArabic
/// - Avoid hardcoding values in components
/// - Update constants here when changing application behavior
class AppConstants {
  // ==================== DHIKR CONSTANTS ====================
  
  /// Arabic text mappings for common dhikr phrases
  /// Maps English transliteration to Arabic script
  /// Used in Tasbih and Dhikr reminder features
  static const Map<String, String> dhikrArabic = {
    'Subhanallah': 'سُبْحَانَ اللهِ',          // Glory be to Allah
    'Alhamdulillah': 'الْحَمْدُ لِلَّهِ',    // Praise be to Allah
    'Astaghfirullah': 'أَسْتَغْفِرُ اللهَ',  // I seek forgiveness from Allah
    'Allahu Akbar': 'اللهُ أَكْبَر',          // Allah is the Greatest
  };

  /// Default target counts for each dhikr phrase
  /// Based on traditional Islamic practice after prayers
  /// Used as initial values for Tasbih counters
  static const Map<String, int> defaultDhikrTargets = {
    'Subhanallah': 33,      // 33 times
    'Alhamdulillah': 33,    // 33 times
    'Astaghfirullah': 33,   // 33 times
    'Allahu Akbar': 34,     // 34 times (total 100)
  };

  /// Preferred order for dhikr recitation
  /// Follows the traditional sequence after prayer
  /// Used for automated dhikr sessions and transitions
  static const List<String> dhikrOrder = [
    'Subhanallah',
    'Alhamdulillah',
    'Astaghfirullah',
    'Allahu Akbar',
  ];

  /// Audio file paths for dhikr pronunciation
  /// Maps dhikr phrases to their audio files in assets
  /// Used for audio playback in Tasbih feature
  static const Map<String, String> dhikrAudioFiles = {
    'Subhanallah': 'audio/SubhanAllah.mp3',
    'Alhamdulillah': 'audio/Alhamdulillah.mp3',
    'Astaghfirullah': 'audio/Astaghfirullah.mp3',
    'Allahu Akbar': 'audio/AllahuAkbar.mp3',
  };

  // ==================== LOCATION & QIBLA CONSTANTS ====================
  
  /// Geographic coordinates of the Kaaba in Mecca
  /// Used as the reference point for Qibla direction calculations
  /// Source: Islamic astronomical calculations
  static const double kaabaLatitude = 21.422487;
  static const double kaabaLongitude = 39.826206;

  // ==================== CACHE DURATION CONSTANTS ====================
  
  /// Cache expiration durations in minutes
  /// Balances performance with data freshness
  /// Adjust based on network conditions and data volatility
  
  /// Qibla direction cache validity period
  /// Qibla calculations are location-dependent but relatively stable
  static const int qiblaExpirationMinutes = 30;
  
  /// GPS position cache validity period
  /// User location changes more frequently, shorter cache
  static const int positionCacheDurationMinutes = 5;

  // ==================== NOTIFICATION CONSTANTS ====================
  
  /// Unique identifier for tesbih (dhikr reminder) notifications
  /// Used to schedule, update, and cancel specific notification types
  /// Must be unique across all notification types in the app
  static const int tesbihReminderId = 9876;

  // ==================== UI ANIMATION CONSTANTS ====================
  
  /// Default animation durations in milliseconds
  /// Provides consistent timing across the application
  /// Adjust for different animation speeds and user preferences
  
  /// Standard animation duration for transitions and micro-interactions
  /// Fast enough to feel responsive, slow enough to be visible
  static const int defaultAnimationDurationMs = 200;
  
  /// Delay between dhikr transitions in automated sessions
  /// Allows user to read and internalize each dhikr phrase
  static const int defaultTransitionDelayMs = 1500;

  // ==================== DEFAULT TARGET VALUES ====================
  
  /// Default target counts for various features
  /// Provides sensible starting points for user interactions
  
  /// Default target count for Tasbih sessions
  /// Based on traditional practice (33 rounds of 3 phrases)
  static const int defaultTesbihTarget = 33;
  
  /// Default delay between dhikr phrases in automated sessions
  /// Same as defaultTransitionDelayMs for consistency
  static const int defaultDhikrTransitionDelay = 1500;

  // ==================== UI THEME CONSTANTS ====================
  
  /// Theme identifier for distinguishing dialog types
  /// Used to apply specific styling to different dialog categories
  /// Helps maintain visual consistency across the app
  static const String dialogThemeKey = 'tesbih_dialog_theme';

  // ==================== VALIDATION RANGES ====================
  
  /// Recommended value ranges for user inputs
  /// Used for validation in settings and user inputs
  
  /// Maximum recommended prayer time offset in minutes
  /// Prevents excessive adjustments that could invalidate prayer times
  static const int maxPrayerOffsetMinutes = 30;
  
  /// Minimum recommended prayer time offset in minutes
  /// Allows reasonable customization while maintaining accuracy
  static const int minPrayerOffsetMinutes = -30;
  
  /// Maximum dhikr reminder interval in hours
  /// Prevents spam while maintaining regular reminders
  static const int maxDhikrReminderIntervalHours = 24;
  
  /// Minimum dhikr reminder interval in hours
  /// Ensures reasonable frequency without overwhelming users
  static const int minDhikrReminderIntervalHours = 1;

  // ==================== PERFORMANCE CONSTANTS ====================
  
  /// Performance optimization thresholds
  /// Used to tune application performance and resource usage
  
  /// Maximum number of cached prayer times to store
  /// Balances offline capability with storage efficiency
  static const int maxCachedPrayerTimes = 30;
  
  /// Maximum number of prayer history records to analyze
  /// Prevents performance issues with large datasets
  static const int maxHistoryRecordsForAnalysis = 1000;
}