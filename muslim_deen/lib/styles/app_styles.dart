import 'package:flutter/material.dart';

/// App Styles - Global styling system for MuslimDeen
/// Provides consistent theming across the application
class AppColors {
  // Brightness-based color definitions
  
  // Light theme colors
  static const Color primaryLight = Color(0xFF2E604C);
  static const Color backgroundLight = Color(0xFFF5F6F8);
  static const Color surfaceLight = Color(0xFFF5F6F8);
  static const Color errorLight = Color(0xFFE53935);
  static const Color surfaceVariantLight = Color(0xFFE8F5E8);
  
  // Dark theme colors
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color errorDark = Color(0xFFCF6679);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // Semantic colors
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentBlue = Color(0xFF2193F3);
  static const Color accentGray = Color(0xFF757575);
  static const Color switchTrackActive = Color(0xFF4CAF50);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xB0BEC7);

  // Text color getters
  static Color textPrimary(Brightness brightness) => 
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;
  static Color textSecondary(Brightness brightness) => 
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;

  // Utility colors
  static Color primary(Brightness brightness) => 
      brightness == Brightness.dark ? primaryDark : primaryLight;
  static Color background(Brightness brightness) => 
      brightness == Brightness.dark ? backgroundDark : backgroundLight;
  static Color surface(Brightness brightness) => 
      brightness == Brightness.dark ? surfaceDark : surfaceLight;
  static Color error(Brightness brightness) => 
      brightness == Brightness.dark ? errorDark : errorLight;
  static Color surfaceVariant(Brightness brightness) => 
      brightness == Brightness.dark ? surfaceVariantDark : surfaceVariantLight;
  
  // Convenience methods
  static Color getScaffoldBackground(Brightness brightness) => background(brightness);
  static Color borderColor(Brightness brightness) => divider;
  
  // Element colors
  static const Color iconInactive = Color(0xFF9E9E9E);
  static const Color iconActivePrimary = Color(0xFF2E604C);
  static const Color iconActiveSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x33000000);
}

class AppTextStyles {
  // Generic text styles
  static TextStyle headlineLarge(Brightness brightness) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle headlineMedium(Brightness brightness) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle headlineSmall(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle titleLarge(Brightness brightness) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle titleMedium(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle titleSmall(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle titleTiny(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  // Body text styles
  static TextStyle bodyLarge(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle bodyMedium(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle bodySmall(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle bodyTiny(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  // Label text styles
  static TextStyle labelLarge(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle labelMedium(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle labelSmall(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  // Specialized styles
  static TextStyle appTitle(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
  );

  static TextStyle prayerTime(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle prayerName(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle subtitle(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle caption(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
  );

  // Button text styles
  static TextStyle buttonLarge(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle buttonMedium(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle buttonSmall(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  // Convenience methods for views
  static TextStyle sectionTitle(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle dateSecondary(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
  );

  static TextStyle label(Brightness brightness) => labelLarge(brightness);
  
  static TextStyle date(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle locationCity(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle locationCountry(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle currentPrayer(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle nextPrayer(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
  );
  
  static TextStyle countdownTimer(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.accentGreen,
    fontFamily: 'Roboto',
  );
}

class AppLayout {
  // Spacing constants
  static const double spacingTiny = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // Padding constants
  static const EdgeInsets paddingTiny = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);
  
  // Specific padding
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(horizontal: 0, vertical: 8.0);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(horizontal: 0, vertical: 16.0);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(horizontal: 0, vertical: 24.0);
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: 8.0, vertical: 0);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 16.0, vertical: 0);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: 24.0, vertical: 0);

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusOversized = 20.0; 
  static const double radiusGiant = 32.0;

  // Elevation
  static const double elevationTiny = 1.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationExtraLarge = 12.0;
}

/// App Container Styles
class AppContainers {
  static BoxDecoration createCardDecoration({
    required Color? color,
    BorderRadius? borderRadius,
    bool shadow = false,
    Color? shadowColor,
    double? elevation,
    Border? border,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(AppLayout.radiusMedium),
      boxShadow: shadow && elevation != null ? [
        BoxShadow(
          color: shadowColor ?? AppColors.shadowColor,
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ] : [],
      border: border,
      gradient: gradient,
    );
  }

  static BoxDecoration createContainerDecoration({
    Color? color,
    BorderRadius? borderRadius,
    bool shadow = false,
    Color? shadowColor,
    double? elevation,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      boxShadow: shadow && (elevation != null) ? [
        BoxShadow(
          color: shadowColor ?? AppColors.shadowColor,
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ] : [],
      border: border,
    );
  }
}
