import 'package:flutter/material.dart';

import 'package:muslim_deen/models/app_settings.dart' show PrayerNotification;
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
/// 
/// Key responsibilities:
/// - Provide prayer name and time for display
/// - Supply appropriate icons for visual identification
/// - Maintain prayer type reference for notifications and settings
/// - Support efficient list rendering with minimal object creation
/// 
/// Usage patterns:
/// - Created by UI components from PrayerTimesModel data
/// - Used in ListView/GridView builders for prayer time displays
/// - Passed to prayer item widgets for consistent rendering
/// - Referenced by notification systems for prayer-specific alerts
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
  /// Parameters:
  /// - [name]: Display name of the prayer (required)
  /// - [time]: Actual prayer time (nullable for error handling)
  /// - [prayerEnum]: Prayer notification enum (required for settings integration)
  /// - [iconData]: Material Design icon (required for visual identification)
  /// 
  /// Example:
  /// ```dart
  /// PrayerListItemData(
  ///   name: 'Fajr',
  ///   time: DateTime(2023, 1, 1, 5, 30),
  ///   prayerEnum: PrayerNotification.fajr,
  ///   iconData: Icons.nights_stay,
  /// )
  /// ```
  /// 
  /// Notes:
  /// - Name should be localized before passing to constructor
  /// - Time can be null to handle calculation failures gracefully
  /// - PrayerEnum must match the prayer type for proper functionality
  /// - Icon should be chosen consistently across the application
  const PrayerListItemData({
    required this.name,
    this.time,
    required this.prayerEnum,
    required this.iconData,
  });

  // ==================== COMPUTED PROPERTIES ====================
  
  /// Indicates whether this prayer time is available
  /// Convenience property for UI conditional rendering
  /// 
  /// Returns: true if time is not null, false otherwise
  bool get hasTime => time != null;
  
  /// Indicates whether this prayer time has passed
  /// Used for UI styling (e.g., graying out past prayers)
  /// 
  /// Returns: true if time is in the past, false if future or null
  bool get isPast {
    if (time == null) return false;
    return DateTime.now().isAfter(time!);
  }
  
  /// Indicates whether this prayer time is upcoming
  /// Used for highlighting the next prayer in the UI
  /// 
  /// Returns: true if time is in the future, false if past or null
  bool get isUpcoming {
    if (time == null) return false;
    return DateTime.now().isBefore(time!);
  }
  
  /// Gets the time formatted for display
  /// Should be used with app's time format settings
  /// 
  /// Returns: formatted time string or placeholder if time is null
  String get formattedTime {
    if (time == null) return '--:--';
    // TODO: Apply app's time format settings (12/24 hour)
    return '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}';
  }
  
  /// Gets the relative time description
  /// Provides user-friendly descriptions like "in 2 hours" or "passed"
  /// 
  /// Returns: Human-readable relative time or empty string if time is null
  String get relativeTime {
    if (time == null) return '';
    
    final now = DateTime.now();
    final difference = time!.difference(now);
    
    if (difference.isNegative) {
      // Prayer has passed
      final pastDuration = now.difference(time!);
      if (pastDuration.inHours > 0) {
        return '${pastDuration.inHours}h ago';
      } else if (pastDuration.inMinutes > 0) {
        return '${pastDuration.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } else {
      // Prayer is upcoming
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
  /// Convenience factory for converting prayer time calculation results
  /// into UI-ready data objects.
  /// 
  /// Parameters:
  /// - [prayerTime]: PrayerTime object from PrayerTimesModel
  /// - [localizedNames]: Map of prayer enum to localized names
  /// 
  /// Returns: PrayerListItemData with converted data
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
  /// Internal helper for converting string-based prayer names
  /// back to their enum representation for settings integration.
  /// 
  /// Parameters:
  /// - [prayerName]: String name of the prayer
  /// 
  /// Returns: Corresponding PrayerNotification enum
  /// 
  /// Notes:
  /// - Uses case-insensitive matching
  /// - Fallback to Fajr for unknown names (graceful degradation)
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
        // Fallback for unknown prayer names
        return PrayerNotification.fajr;
    }
  }

  // ==================== UTILITY METHODS ====================
  
  /// Creates a copy with updated time
  /// 
  /// Useful for updating prayer times without recreating the entire object
  /// when only the time changes (e.g., after recalculation).
  /// 
  /// Parameters:
  /// - [time]: New prayer time (nullable)
  /// 
  /// Returns: New PrayerListItemData with updated time
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
  /// Useful for language changes without recreating the entire object.
  /// 
  /// Parameters:
  /// - [name]: New localized prayer name
  /// 
  /// Returns: New PrayerListItemData with updated name
  PrayerListItemData withName(String name) {
    return PrayerListItemData(
      name: name,
      time: this.time,
      prayerEnum: this.prayerEnum,
      iconData: this.iconData,
    );
  }

  @override
  String toString() {
    return 'PrayerListItemData(name: $name, time: $time, prayerEnum: $prayerEnum)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerListItemData &&
        other.name == name &&
        other.time == time &&
        other.prayerEnum == prayerEnum;
  }

  @override
  int get hashCode {
    return name.hashCode ^ time.hashCode ^ prayerEnum.hashCode;
  }
}