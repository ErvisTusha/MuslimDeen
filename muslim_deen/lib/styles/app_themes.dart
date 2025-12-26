import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

class AppThemes {
  static ThemeData buildLightTheme() {
    const brightness = Brightness.light;
    return ThemeData.light().copyWith(
      primaryColor: AppColors.primary(brightness),
      scaffoldBackgroundColor: AppColors.background(brightness),
      colorScheme: ColorScheme.light(
        primary: AppColors.primary(brightness),
        secondary: AppColors.accentGreen,
        surface: AppColors.surface(brightness),
        error: AppColors.error(brightness),
        onPrimary: AppColors.textPrimary(brightness),
        onSecondary: AppColors.textPrimary(brightness),
        onSurface: AppColors.textPrimary(brightness),
        onError: AppColors.textPrimary(brightness),
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface(brightness),
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.textPrimary(brightness)),
        toolbarTextStyle: AppTextStyles.appTitle(brightness),
        titleTextStyle: AppTextStyles.appTitle(brightness),
      ),
      cardColor: AppColors.surface(brightness),
      dividerColor: AppColors.divider,
      iconTheme: IconThemeData(color: AppColors.iconInactive),
      primaryIconTheme: IconThemeData(color: AppColors.accentGreen),
      textTheme: _buildTextTheme(brightness),
      switchTheme: _buildSwitchTheme(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface(brightness),
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.iconInactive,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textPrimary(brightness),
      ),
    );
  }

  static ThemeData buildDarkTheme() {
    const brightness = Brightness.dark;
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary(brightness),
      scaffoldBackgroundColor: AppColors.background(brightness),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary(brightness),
        secondary: AppColors.accentGreen,
        surface: AppColors.surface(brightness),
        error: AppColors.error(brightness),
        onPrimary: AppColors.textPrimary(brightness),
        onSecondary: AppColors.textPrimary(brightness),
        onSurface: AppColors.textPrimary(brightness),
        onError: AppColors.textPrimary(brightness),
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface(brightness),
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.textPrimary(brightness)),
        toolbarTextStyle:
            TextTheme(
              titleLarge: AppTextStyles.appTitle(brightness),
            ).bodyMedium,
        titleTextStyle:
            TextTheme(
              titleLarge: AppTextStyles.appTitle(brightness),
            ).titleLarge,
      ),
      cardColor: AppColors.surface(brightness),
      dividerColor: AppColors.divider,
      iconTheme: IconThemeData(color: AppColors.iconInactive),
      primaryIconTheme: IconThemeData(color: AppColors.accentGreen),
      textTheme: _buildTextTheme(brightness),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.accentGreen,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.textPrimary(brightness),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accentGreen),
      ),
      switchTheme: _buildSwitchTheme(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface(brightness),
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.iconInactive,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textPrimary(brightness),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    return TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      displayMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      displaySmall: TextStyle(color: AppColors.textPrimary(brightness)),
      headlineMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      headlineSmall: TextStyle(color: AppColors.textPrimary(brightness)),
      titleLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      bodyLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      bodyMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      bodySmall: TextStyle(color: AppColors.textSecondary(brightness)),
      labelLarge: const TextStyle(color: AppColors.accentGreen),
    );
  }

  static SwitchThemeData _buildSwitchTheme(Brightness brightness) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentGreen;
        }
        return AppColors.accentGray;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.switchTrackActive;
        }
        return AppColors.accentGray.withAlpha(50);
      }),
    );
  }
}
