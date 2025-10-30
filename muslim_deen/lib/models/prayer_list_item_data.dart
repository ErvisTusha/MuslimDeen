import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart'
    show PrayerNotification, TimeFormat;
import 'package:muslim_deen/models/prayer_times_model.dart' show PrayerTime;

/// UI data model for prayer list items
///
/// This lightweight data class encapsulates all information needed to display
/// a single prayer in a list or grid format within the MuslimDeen application.
/// It serves as a bridge between the core prayer time data and the UI components,
/// providing display-specific metadata and formatting information.
///
/// Design principles:
/// - Focused on UI presentation concerns only
/// - Minimal data footprint for efficient list rendering
/// - Includes visual metadata (icons, colors) for consistent UI
/// - Maintains reference to prayer enum for business logic integration
/// - Immutable design with copyWith methods for safe updates
///
/// Key responsibilities:
/// - Provide prayer name and time for display
/// - Supply appropriate icons for visual identification
/// - Maintain prayer type reference for notifications and settings
/// - Support efficient list rendering with minimal object creation
/// - Handle time formatting according to user preferences
///
/// Usage patterns:
/// - Created by UI components from PrayerTimesModel data
/// - Used in ListView/GridView builders for prayer time displays
/// - Passed to prayer item widgets for consistent rendering
/// - Referenced by notification systems for prayer-specific alerts
///
/// Performance considerations:
/// - Uses const constructor for compile-time instantiation
/// - Computed properties cached for repeated access
/// - Minimal dependencies to avoid unnecessary rebuilds
/// - Efficient equality and hashCode for list diffing
///
/// Data flow:
/// PrayerTimesModel -> PrayerListItemData -> UI Widgets -> Display
///
/// This separation allows UI components to focus on presentation while
/// the data model handles display logic and formatting.
class PrayerListItemData {
  /// Display name of the prayer (e.g., 'Fajr', 'Dhuhr', 'Asr')
  /// Used as the primary text label in UI components
  /// Should be localized according to app language settings
  final String name;

  /// Actual prayer time for display
  /// Can be null when prayer times are unavailable or calculation failed
  /// UI components should handle null values gracefully (show placeholder)
  final DateTime? time;

  /// Prayer notification enum type for business logic integration
  /// Links this UI item to notification settings, audio preferences,
  /// and other prayer-specific configurations
  final PrayerNotification prayerEnum;

  /// Material Design icon for visual prayer identification
  /// Chosen to match the prayer's time of day and spiritual significance:
  /// - Night prayers (Fajr, Isha): Moon/star icons
  /// - Day prayers (Dhuhr, Asr): Sun icons
  /// - Sunrise: Special sun icon to distinguish from Dhuhr
  final IconData iconData;

  /// Creates a new PrayerListItemData with required display information
  ///
  /// This constructor enforces the creation of complete prayer display data,
  /// ensuring all UI components have the necessary information for proper rendering.
  /// The const keyword allows for compile-time instantiation and efficient
  /// widget rebuilding in Flutter's reactive framework.
  ///
  /// Design Decision: All parameters are required to prevent incomplete UI states.
  /// Nullable time allows graceful handling of calculation failures without
  /// breaking the UI layout.
  ///
  /// Parameters:
  /// - [name]: Display name of the prayer (required for UI labels)
  /// - [time]: Actual prayer time (nullable for error handling)
  /// - [prayerEnum]: Prayer notification enum (required for settings integration)
  /// - [iconData]: Material Design icon (required for visual consistency)
  ///
  /// Example:
  /// ```dart
  /// const PrayerListItemData(
  ///   name: 'Fajr',
  ///   time: DateTime(2023, 1, 1, 5, 30),
  ///   prayerEnum: PrayerNotification.fajr,
  ///   iconData: Icons.nights_stay,
  /// )
  /// ```
  ///
  /// Error Handling:
  /// - Time can be null to handle calculation failures
  /// - UI components should provide fallbacks for null times
  /// - PrayerEnum must be valid for proper functionality
  const PrayerListItemData({
    required this.name,
    this.time,
    required this.prayerEnum,
    required this.iconData,
  });

  // ==================== COMPUTED PROPERTIES ====================

  /// Indicates whether this prayer time is available
  ///
  /// This convenience property provides a clean API for UI conditional rendering,
  /// allowing widgets to show different states based on time availability.
  ///
  /// Design Decision: Computed property instead of storing a boolean to maintain
  /// single source of truth with the time field and avoid synchronization issues.
  ///
  /// Returns: true if time is not null, false otherwise
  ///
  /// Usage: Commonly used in UI to show placeholders or disable interactions
  /// when prayer times cannot be calculated (e.g., location unavailable).
  bool get hasTime => time != null;

  /// Indicates whether this prayer time has passed
  ///
  /// Used for UI styling decisions such as graying out past prayers or
  /// showing completion indicators. Compares against current system time.
  ///
  /// Design Decision: Real-time comparison ensures accuracy even if the
  /// object is held in memory for extended periods.
  ///
  /// Returns: true if time is in the past, false if future or null
  ///
  /// Edge Cases:
  /// - Returns false for null time (graceful degradation)
  /// - Uses DateTime.now() for current time reference
  bool get isPast {
    if (time == null) return false;
    return DateTime.now().isAfter(time!);
  }

  /// Indicates whether this prayer time is upcoming
  ///
  /// Used for highlighting the next prayer in the UI or showing countdown timers.
  /// Provides the complement to isPast for complete temporal state coverage.
  ///
  /// Design Decision: Separate property from isPast for clarity and to avoid
  /// double computation in UI components that need both states.
  ///
  /// Returns: true if time is in the future, false if past or null
  ///
  /// Usage: Critical for prayer tracking features and UI highlighting
  bool get isUpcoming {
    if (time == null) return false;
    return DateTime.now().isBefore(time!);
  }

  /// Gets the time formatted for display according to the specified time format
  ///
  /// This method formats the prayer time using the provided TimeFormat preference,
  /// supporting both 12-hour (AM/PM) and 24-hour formats. The formatting uses
  /// the intl package's DateFormat with locale-aware patterns.
  ///
  /// Design Decision: Implemented as a method rather than a getter to allow
  /// flexible time formatting without storing format preference in the data model,
  /// maintaining the class's lightweight nature and separation of concerns.
  ///
  /// Parameters:
  /// - [timeFormat]: The user's preferred time display format
  ///
  /// Returns: Formatted time string or placeholder if time is null
  ///
  /// Example:
  /// ```dart
  /// final formatted = prayerData.formattedTime(TimeFormat.twelveHour);
  /// // Returns "05:30 AM" for 12-hour format
  /// ```
  ///
  /// Localization: Uses the default locale for AM/PM markers in 12-hour format
  String formattedTime(TimeFormat timeFormat) {
    if (time == null) return '--:--';

    // Use intl DateFormat for proper localization and formatting
    final formatter = DateFormat(
      timeFormat == TimeFormat.twentyFourHour ? 'HH:mm' : 'hh:mm a',
    );

    return formatter.format(time!);
  }

  /// Gets the relative time description
  ///
  /// Provides user-friendly time descriptions like "in 2 hours" or "passed 30 min ago".
  /// Uses smart formatting to show the most relevant time unit (hours/minutes).
  ///
  /// Design Decision: Human-readable format improves UX over raw time differences.
  /// Handles both past and future times with appropriate language.
  ///
  /// Returns: Human-readable relative time or empty string if time is null
  ///
  /// Formatting Rules:
  /// - Past: "{duration}h ago" or "{duration}m ago"
  /// - Future: "in {duration}h" or "in {duration}m"
  /// - Immediate: "Just now" or "Soon"
  /// - Null time: Empty string
  ///
  /// Localization Note: Currently English-only; consider i18n for multi-language support
  String get relativeTime {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = time!.difference(now);

    if (difference.isNegative) {
      // Prayer has passed - show how long ago
      final pastDuration = now.difference(time!);
      if (pastDuration.inHours > 0) {
        return '${pastDuration.inHours}h ago';
      } else if (pastDuration.inMinutes > 0) {
        return '${pastDuration.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } else {
      // Prayer is upcoming - show time until
      if (difference.inHours > 0) {
        return 'in ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'in ${difference.inMinutes}m';
      } else {
        return 'Soon';
      }
    }
  }

  // ==================== FACTORY METHODS ====================

  /// Creates PrayerListItemData from a PrayerTime object
  ///
  /// This factory method bridges the gap between the core prayer calculation
  /// model (PrayerTime) and the UI data model (PrayerListItemData). It handles
  /// the conversion logic and provides a clean API for UI components.
  ///
  /// Design Decision: Factory method encapsulates conversion logic and provides
  /// type safety. Requires localized names to be passed externally, maintaining
  /// separation between data and localization concerns.
  ///
  /// Parameters:
  /// - [prayerTime]: PrayerTime object from PrayerTimesModel calculation
  /// - [localizedNames]: Map of prayer enum to localized display names
  ///
  /// Returns: PrayerListItemData with converted data and proper localization
  ///
  /// Conversion Logic:
  /// - Maps prayer name strings to PrayerNotification enums
  /// - Applies localized names from the provided map
  /// - Preserves time and icon data from PrayerTime
  ///
  /// Example:
  /// ```dart
  /// final prayerData = PrayerListItemData.fromPrayerTime(
  ///   prayerTime,
  ///   localizedNames: {
  ///     PrayerNotification.fajr: 'Fajr',
  ///     PrayerNotification.dhuhr: 'Dhuhr',
  ///     // ... other mappings
  ///   },
  /// );
  /// ```
  ///
  /// Error Handling:
  /// - Unknown prayer names fallback to Fajr enum
  /// - Localized names must be provided (no defaults)
  ///   localizedNames: {
  ///     PrayerNotification.fajr: 'Fajr',
  ///     PrayerNotification.dhuhr: 'Dhuhr',
  ///     // ... other mappings
  ///   },
  /// );
  /// ```
  factory PrayerListItemData.fromPrayerTime(
    PrayerTime prayerTime, {
    required Map<PrayerNotification, String> localizedNames,
  }) {
    // Map prayer names to notification enums
    final prayerEnum = _mapPrayerNameToEnum(prayerTime.name);

    return PrayerListItemData(
      name: localizedNames[prayerEnum] ?? prayerTime.name,
      time: prayerTime.time,
      prayerEnum: prayerEnum,
      iconData: prayerTime.iconData,
    );
  }

  /// Creates a list of PrayerListItemData from prayer times
  ///
  /// Batch factory method for converting all prayer times for a day
  /// into UI-ready data objects.
  ///
  /// Parameters:
  /// - [prayerTimes]: List of PrayerTime objects
  /// - [localizedNames]: Map of prayer enum to localized names
  ///
  /// Returns: List of PrayerListItemData objects
  static List<PrayerListItemData> fromPrayerTimesList(
    List<PrayerTime> prayerTimes, {
    required Map<PrayerNotification, String> localizedNames,
  }) {
    return prayerTimes.map((prayerTime) {
      return PrayerListItemData.fromPrayerTime(
        prayerTime,
        localizedNames: localizedNames,
      );
    }).toList();
  }

  // ==================== PRIVATE HELPERS ====================

  /// Maps prayer name strings to PrayerNotification enums
  ///
  /// This internal utility method converts the string-based prayer names from
  /// the PrayerTimesModel into the strongly-typed PrayerNotification enums
  /// used throughout the application for settings and notifications.
  ///
  /// Design Decision: Case-insensitive matching provides robustness against
  /// variations in prayer name formatting. Fallback to Fajr ensures the app
  /// continues functioning even with unknown prayer names.
  ///
  /// Parameters:
  /// - [prayerName]: String name of the prayer from PrayerTimesModel
  ///
  /// Returns: Corresponding PrayerNotification enum
  ///
  /// Mapping:
  /// - 'fajr' -> PrayerNotification.fajr
  /// - 'sunrise' -> PrayerNotification.sunrise
  /// - 'dhuhr' -> PrayerNotification.dhuhr
  /// - 'asr' -> PrayerNotification.asr
  /// - 'maghrib' -> PrayerNotification.maghrib
  /// - 'isha' -> PrayerNotification.isha
  /// - unknown -> PrayerNotification.fajr (fallback)
  ///
  /// Error Handling: Graceful degradation with Fajr fallback for unknown names
  static PrayerNotification _mapPrayerNameToEnum(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return PrayerNotification.fajr;
      case 'sunrise':
        return PrayerNotification.sunrise;
      case 'dhuhr':
        return PrayerNotification.dhuhr;
      case 'asr':
        return PrayerNotification.asr;
      case 'maghrib':
        return PrayerNotification.maghrib;
      case 'isha':
        return PrayerNotification.isha;
      default:
        // Fallback for unknown prayer names - ensures app stability
        return PrayerNotification.fajr;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Creates a copy with updated time
  ///
  /// This method provides immutable updates for prayer times, essential for
  /// reactive UI frameworks like Flutter where object identity matters for
  /// efficient rebuilding.
  ///
  /// Design Decision: CopyWith pattern maintains immutability while providing
  /// convenient updates. Separate methods for each field allow targeted updates
  /// without affecting other properties.
  ///
  /// Parameters:
  /// - [time]: New prayer time (nullable for error states)
  ///
  /// Returns: New PrayerListItemData with updated time, preserving other fields
  ///
  /// Usage: Called when prayer times are recalculated due to location changes
  /// or time zone updates, allowing UI to update without full object recreation.
  PrayerListItemData withTime(DateTime? time) {
    return PrayerListItemData(
      name: this.name,
      time: time,
      prayerEnum: this.prayerEnum,
      iconData: this.iconData,
    );
  }

  /// Creates a copy with updated name
  ///
  /// Supports dynamic language switching by allowing name updates without
  /// affecting other prayer data. Maintains immutability for consistent state.
  ///
  /// Design Decision: Separate method for name updates enables efficient
  /// localization changes without rebuilding the entire prayer data structure.
  ///
  /// Parameters:
  /// - [name]: New localized prayer name
  ///
  /// Returns: New PrayerListItemData with updated name
  ///
  /// Usage: Called during app language changes to update display names
  /// while preserving times, enums, and icons.
  PrayerListItemData withName(String name) {
    return PrayerListItemData(
      name: name,
      time: this.time,
      prayerEnum: this.prayerEnum,
      iconData: this.iconData,
    );
  }

  /// Returns a string representation of the prayer data
  ///
  /// Useful for debugging and logging. Includes key identifying fields
  /// while excluding iconData for brevity.
  ///
  /// Design Decision: Excludes iconData as it's not typically relevant
  /// for debugging prayer data, keeping output focused on core properties.
  @override
  String toString() {
    return 'PrayerListItemData(name: $name, time: $time, prayerEnum: $prayerEnum)';
  }

  /// Compares this PrayerListItemData with another object for equality
  ///
  /// Essential for Flutter's widget diffing and state management. Two prayer
  /// items are considered equal if they have the same name, time, and prayer enum.
  ///
  /// Design Decision: Excludes iconData from equality as it's derived from
  /// prayerEnum and doesn't affect the core prayer data identity.
  ///
  /// Note: Time comparison uses DateTime equality, which includes all components
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PrayerListItemData &&
        other.name == name &&
        other.time == time &&
        other.prayerEnum == prayerEnum;
  }

  /// Returns a hash code for this PrayerListItemData
  ///
  /// Required when overriding == operator. Used by collections like HashSet
  /// and HashMap for efficient lookups.
  ///
  /// Design Decision: Uses XOR combination of hashCodes for the same fields
  /// used in equality comparison, ensuring consistency between == and hashCode.
  @override
  int get hashCode {
    return name.hashCode ^ time.hashCode ^ prayerEnum.hashCode;
  }
}
