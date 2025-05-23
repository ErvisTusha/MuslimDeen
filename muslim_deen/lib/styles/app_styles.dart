import 'package:flutter/material.dart';

/// Core color palette
class AppColors {
  // Light Theme Colors
  static const Color _primaryLight = Colors.green;
  static const Color _primaryLightVariant = Color(0xFFEBF3EC);
  static const Color _backgroundLight = Colors.white;
  static const Color _textPrimaryLight = Colors.black87;
  static const Color _textSecondaryLight = Colors.grey;
  static const Color _dividerLight = Color(0xFFE0E0E0);
  static final Color _shadowColorLight = Colors.black.withAlpha(13);
  static final Color _borderColorLight = Colors.grey.shade200;
  static final Color _iconInactiveLight = Colors.grey.shade600;
  static final Color _switchTrackActiveLight = _primaryLight.withAlpha(77);
  static const Color _errorLight = Colors.red;

  // Dark Theme Colors
  // Dark Theme Colors - Revised: Black/White primary, Green/Gray accent
  static const Color _primaryDark = Color(
    0xFF000000,
  ); // Black for primary elements (matching screenshot)
  static const Color _primaryDarkVariant = Color(
    0xFF000000,
  ); // Black for variants or main background
  static const Color _backgroundDark = Color(0xFF000000);
  static const Color _surfaceDark = Color(
    0xFF1A1A1A,
  ); // Very dark gray for elevated surfaces (cards, dialogs)
  static const Color _textPrimaryDark = Colors.white; // White for primary text
  static final Color _textSecondaryDark =
      Colors.grey.shade400; // #BDBDBD (Light grey for secondary text)
  static const Color _accentGreenDark = Color(
    0xFF66BB6A,
  ); // Green accent (formerly _primaryDark)
  static final Color _accentGrayDark =
      Colors.grey.shade700; // #616161 (Gray accent / borders)
  static const Color _dividerDark = Color(
    0xFF3A3A3A,
  ); // Slightly lighter divider
  static final Color _shadowColorDark = Colors.black.withAlpha(
    30,
  ); // Slightly more pronounced shadow
  static final Color _borderColorDark =
      _accentGrayDark; // Use accent gray for borders
  static final Color _iconInactiveDark = Colors.grey.shade500; // #9E9E9E
  static final Color _switchTrackActiveDark = _accentGreenDark.withAlpha(
    100,
  ); // Green accent for switch track
  static const Color _errorDark = Color(
    0xFFCF6679,
  ); // Material Design dark theme error color

  static Color primary(Brightness brightness) =>
      brightness == Brightness.light ? _primaryLight : _primaryDark;
  static Color primaryVariant(Brightness brightness) =>
      brightness == Brightness.light
          ? _primaryLightVariant
          : _primaryDarkVariant; // Renamed from primaryLight to primaryVariant for clarity
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? _backgroundLight : _backgroundDark;
  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? _backgroundLight : _surfaceDark;
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.light ? _textPrimaryLight : _textPrimaryDark;
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.light ? _textSecondaryLight : _textSecondaryDark;
  static Color accentGreen(Brightness brightness) =>
      brightness == Brightness.light
          ? _primaryLight
          : _accentGreenDark; // Green is accent in dark, primary in light
  static Color accentGray(Brightness brightness) =>
      brightness == Brightness.light
          ? _textSecondaryLight
          : _accentGrayDark; // Gray is accent/secondary
  static Color divider(Brightness brightness) =>
      brightness == Brightness.light ? _dividerLight : _dividerDark;
  static Color shadowColor(Brightness brightness) =>
      brightness == Brightness.light ? _shadowColorLight : _shadowColorDark;
  static Color borderColor(Brightness brightness) =>
      brightness == Brightness.light ? _borderColorLight : _borderColorDark;
  static Color iconInactive(Brightness brightness) =>
      brightness == Brightness.light ? _iconInactiveLight : _iconInactiveDark;
  static Color switchTrackActive(Brightness brightness) =>
      brightness == Brightness.light
          ? _switchTrackActiveLight
          : _switchTrackActiveDark;
  static Color error(Brightness brightness) =>
      brightness == Brightness.light ? _errorLight : _errorDark;

  static Color getScaffoldBackground(Brightness brightness) {
    return brightness == Brightness.dark ? _surfaceDark : _backgroundLight;
  }
}

/// Text styles used throughout the app
class AppTextStyles {
  static TextStyle appTitle(Brightness brightness) => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white, // Always white for better visibility in both modes
  );

  static TextStyle date(Brightness brightness) => const TextStyle(
    // Assuming date color doesn't change with theme or is handled by context
    fontSize: 14,
    fontWeight: FontWeight.w500,
    // color: AppColors.textPrimary(brightness), // Uncomment if date color should adapt
  );

  static TextStyle dateSecondary(Brightness brightness) =>
      TextStyle(fontSize: 14, color: AppColors.textSecondary(brightness));

  static TextStyle prayerName(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
  );

  static TextStyle prayerNameCurrent(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.accentGreen(
      brightness,
    ), // Use green accent for current prayer name
  );

  static TextStyle sectionTitle(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
  );

  static TextStyle currentPrayer(Brightness brightness) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.accentGreen(
      brightness,
    ), // Use green accent for current prayer highlight
  );

  static TextStyle nextPrayer(Brightness brightness) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
  );

  static TextStyle countdownTimer(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary(brightness),
  );

  static TextStyle label(Brightness brightness) =>
      TextStyle(fontSize: 14, color: AppColors.textSecondary(brightness));

  static TextStyle prayerTime(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
  );

  static TextStyle snackBarText(Brightness brightness) => TextStyle(
    // Snackbar usually has its own theming
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color:
        brightness == Brightness.light
            ? Colors.white
            : Colors
                .black, // Example: dark text on light snackbar, light text on dark snackbar
  );

  static TextStyle prayerTimeCurrent(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.accentGreen(
      brightness,
    ), // Use green accent for current prayer time
  );
}
