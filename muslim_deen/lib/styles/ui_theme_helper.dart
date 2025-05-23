import 'package:flutter/material.dart';
import 'app_styles.dart';

/// Utility class to standardize color setup across views
class UIThemeHelper {
  static UIColors getThemeColors(Brightness brightness) {
    final bool isDarkMode = brightness == Brightness.dark;
    return UIColors(
      brightness: brightness,
      isDarkMode: isDarkMode,
      contentSurface:
          isDarkMode
              ? const Color(0xFF2C2C2C)
              : AppColors.background(brightness),
      accentColor: AppColors.accentGreen(brightness),
      errorColor: AppColors.error(brightness),
      textColorPrimary: AppColors.textPrimary(brightness),
      textColorSecondary: AppColors.textSecondary(brightness),
      borderColor: AppColors.borderColor(brightness),
      iconInactive: AppColors.iconInactive(brightness),
    );
  }
}

/// Data class to hold commonly used colors
class UIColors {
  final Brightness brightness;
  final bool isDarkMode;
  final Color contentSurface;
  final Color accentColor;
  final Color errorColor;
  final Color textColorPrimary;
  final Color textColorSecondary;
  final Color borderColor;
  final Color iconInactive;

  const UIColors({
    required this.brightness,
    required this.isDarkMode,
    required this.contentSurface,
    required this.accentColor,
    required this.errorColor,
    required this.textColorPrimary,
    required this.textColorSecondary,
    required this.borderColor,
    required this.iconInactive,
  });
}

/// Data class for prayer-specific colors used in prayer lists
class PrayerItemColors {
  final Color currentPrayerBg;
  final Color currentPrayerBorder;
  final Color currentPrayerText;

  const PrayerItemColors({
    required this.currentPrayerBg,
    required this.currentPrayerBorder,
    required this.currentPrayerText,
  });
}

/// Data class for Tesbih-specific colors
class TesbihColors {
  final Color contentSurface;
  final Color counterCircleBg;
  final Color dhikrArabicText;
  final Color counterProgress;
  final Color counterCountText;
  final Color toggleCardBg;

  const TesbihColors({
    required this.contentSurface,
    required this.counterCircleBg,
    required this.dhikrArabicText,
    required this.counterProgress,
    required this.counterCountText,
    required this.toggleCardBg,
  });
}
