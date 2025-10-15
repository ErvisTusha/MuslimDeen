import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'dart:math' as math;

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
      accentColor: AppColors.accentGreen,
      errorColor: AppColors.error(brightness),
      textColorPrimary: AppColors.textPrimary(brightness),
      textColorSecondary: AppColors.textSecondary(brightness),
      borderColor: AppColors.divider,
      iconInactive: AppColors.iconInactive,
    );
  }

  /// Returns a text color that meets the requested WCAG contrast ratio against
  /// the provided background. If `fg` already meets the ratio it is returned
  /// unchanged. Otherwise the function will pick black or white depending on
  /// which gives a higher contrast. This is a small defensive helper to avoid
  /// low-contrast text when themes or backgrounds change at runtime.
  static Color contrastSafeTextColor(Color fg, Color background,
      {double minRatio = 4.5}) {
    double l1 = _luminance(fg);
    double l2 = _luminance(background);
    double hi = l1 > l2 ? l1 : l2;
    double lo = l1 > l2 ? l2 : l1;
    double ratio = (hi + 0.05) / (lo + 0.05);
    if (ratio >= minRatio) return fg;

    // try black and white and pick the best contrast
    final black = const Color(0xFF000000);
    final white = const Color(0xFFFFFFFF);
    double rBlack = _contrastRatio(black, background);
    double rWhite = _contrastRatio(white, background);
    return rBlack >= rWhite ? black : white;
  }

  static double _luminance(Color c) {
    double srgb(double v) {
      var vv = v / 255.0;
      return vv <= 0.03928 ? vv / 12.92 : math.pow((vv + 0.055) / 1.055, 2.4).toDouble();
    }
    return 0.2126 * srgb(c.red.toDouble()) + 0.7152 * srgb(c.green.toDouble()) + 0.0722 * srgb(c.blue.toDouble());
  }

  static double _contrastRatio(Color a, Color b) {
    double la = _luminance(a);
    double lb = _luminance(b);
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
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
