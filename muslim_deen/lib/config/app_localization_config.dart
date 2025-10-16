import 'package:flutter/material.dart';

/// Configuration class for app localization settings
/// 
/// This class provides centralized configuration for app localization,
/// including supported locales, text direction settings, and formatting
/// utilities. It ensures consistent localization behavior across
/// the entire application.
/// 
/// Features:
/// - Centralized locale configuration
/// - Support for right-to-left (RTL) languages
/// - Localized numeric formatting for Arabic and Persian
/// - Display name handling for supported languages
/// - Extension methods for convenient locale access
/// 
/// Usage:
/// ```dart
/// // Get supported locales
/// final locales = AppLocalizationConfig.supportedLocales;
/// 
/// // Check if locale is RTL
/// final isRTL = AppLocalizationConfig.isRTLLanguage(locale);
/// 
/// // Format numbers for locale
/// final formatted = AppLocalizationConfig.formatNumber(123, locale);
/// 
/// // Use extension methods
/// final displayName = locale.displayName;
/// final isRTLLang = locale.isRTL;
/// ```
/// 
/// Design Patterns:
/// - Configuration: Centralizes localization settings
/// - Utility: Provides helper methods for localization
/// - Extension Methods: Enhances Locale class with additional functionality
/// - Static Factory: Provides consistent access to configuration
/// 
/// Performance:
/// - Static methods for efficient access
/// - Optimized string formatting
/// - Minimal object creation
/// 
/// Platform Support:
/// - Full support for Android and iOS
/// - Proper handling of RTL languages on both platforms
/// - Native numeric formatting where supported
class AppLocalizationConfig {
  /// Supported locales for the application
  /// 
  /// This list defines all languages that the application supports.
  /// Each locale includes both language code and country code
  /// to ensure proper localization and formatting.
  /// 
  /// Supported Languages:
  /// - English (US): Default language for the app
  /// - Arabic (SA): Right-to-left language with Arabic numerals
  /// - Urdu (PK): Right-to-left language with Arabic numerals
  /// - Persian/Farsi (IR): Right-to-left language with Persian numerals
  /// - Turkish (TR): Left-to-right language
  /// - Indonesian (ID): Left-to-right language
  /// - Malay (MY): Left-to-right language
  /// - French (FR): Left-to-right language
  /// 
  /// Note:
  /// - Arabic, Urdu, and Persian are RTL languages
  /// - Arabic and Persian use localized numerals
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English - United States
    Locale('ar', 'SA'), // Arabic - Saudi Arabia
    Locale('ur', 'PK'), // Urdu - Pakistan
    Locale('fa', 'IR'), // Persian/Farsi - Iran
    Locale('tr', 'TR'), // Turkish - Turkey
    Locale('id', 'ID'), // Indonesian - Indonesia
    Locale('ms', 'MY'), // Malay - Malaysia
    Locale('fr', 'FR'), // French - France
  ];

  /// Get text direction based on locale
  /// 
  /// Determines the appropriate text direction for a given locale.
  /// This is essential for proper rendering of RTL languages.
  /// 
  /// Parameters:
  /// - [locale]: The locale to determine text direction for
  /// 
  /// Algorithm:
  /// 1. Check if language code is in RTL language list
  /// 2. Return TextDirection.rtl for RTL languages
  /// 3. Return TextDirection.ltr for all other languages
  /// 
  /// RTL Languages:
  /// - Arabic (ar)
  /// - Urdu (ur)
  /// - Persian (fa)
  /// 
  /// Performance:
  /// - O(1) lookup with simple switch statement
  /// - No object creation for direction determination
  /// 
  /// Returns:
  /// - TextDirection.rtl for RTL languages, TextDirection.ltr otherwise
  static TextDirection getTextDirection(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
      case 'ur':
      case 'fa':
        return TextDirection.rtl;
      default:
        return TextDirection.ltr;
    }
  }

  /// Check if locale is RTL (right-to-left)
  /// 
  /// Convenience method to check if a locale uses right-to-left
  /// text direction. This is useful for conditional UI rendering.
  /// 
  /// Parameters:
  /// - [locale]: The locale to check
  /// 
  /// Algorithm:
  /// 1. Get text direction for the locale
  /// 2. Return true if direction is RTL, false otherwise
  /// 
  /// Performance:
  /// - Direct comparison with getTextDirection result
  /// - No duplicate logic
  /// 
  /// Returns:
  /// - true if the locale is RTL, false otherwise
  static bool isRTLLanguage(Locale locale) {
    return getTextDirection(locale) == TextDirection.rtl;
  }

  /// Get display name for language
  /// 
  /// Returns the human-readable display name for a locale in its
  /// native language. This is useful for language selection UIs.
  /// 
  /// Parameters:
  /// - [locale]: The locale to get the display name for
  /// 
  /// Algorithm:
  /// 1. Match language code to native language name
  /// 2. Return appropriate name or fallback
  /// 
  /// Performance:
  /// - O(1) lookup with switch statement
  /// - No external dependencies
  /// 
  /// Returns:
  /// - Native language name if supported, uppercase language code otherwise
  static String getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'ur':
        return 'اردو';
      case 'fa':
        return 'فارسی';
      case 'tr':
        return 'Türkçe';
      case 'id':
        return 'Bahasa Indonesia';
      case 'ms':
        return 'Bahasa Melayu';
      case 'fr':
        return 'Français';
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  /// Get localized numeric format
  /// 
  /// Formats numbers according to the conventions of the specified
  /// locale. This includes using localized numerals for Arabic
  /// and Persian scripts.
  /// 
  /// Parameters:
  /// - [number]: The number to format
  /// - [locale]: The locale to format for
  /// 
  /// Algorithm:
  /// 1. Convert number to string
  /// 2. For Arabic, replace with Arabic-Indic digits
  /// 3. For Persian, replace with Persian digits
  /// 4. For other locales, return standard digits
  /// 
  /// Digit Mappings:
  /// - Arabic-Indic: ٠-٩ (Unicode 0x0660-0x0669)
  /// - Persian: ۰-۹ (Unicode 0x06F0-0x06F9)
  /// 
  /// Performance:
  /// - Efficient character replacement with regex
  /// - No external dependencies
  /// - Cached digit mappings
  /// 
  /// Returns:
  /// - Locally formatted number string
  static String formatNumber(int number, Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        // Use Arabic-Indic digits for Arabic
        return number.toString().replaceAllMapped(
          RegExp(r'[0-9]'),
          (match) => String.fromCharCode(int.parse(match.group(0)!) + 0x0660),
        );
      case 'fa':
        // Use Persian digits for Persian
        return number.toString().replaceAllMapped(
          RegExp(r'[0-9]'),
          (match) => String.fromCharCode(int.parse(match.group(0)!) + 0x06F0),
        );
      default:
        return number.toString();
    }
  }
}

/// Extension methods for easier localization access
/// 
/// These extension methods enhance the Locale class with additional
/// functionality provided by AppLocalizationConfig. They make
/// localization-related operations more convenient and readable.
/// 
/// Usage:
/// ```dart
/// final locale = Locale('ar', 'SA');
/// final displayName = locale.displayName; // "العربية"
/// final isRTL = locale.isRTL; // true
/// final formatted = locale.formatNumber(123); // "١٢٣"
/// final direction = locale.textDirection; // TextDirection.rtl
/// ```
/// 
/// Design Patterns:
/// - Extension Methods: Enhance existing class functionality
/// - Delegation: Methods delegate to AppLocalizationConfig
/// - Convenience: Simplifies common localization operations
/// 
/// Performance:
/// - Direct delegation to static methods
/// - No additional overhead beyond static method calls
/// - Cached results where applicable
extension LocaleExtensions on Locale {
  /// Get display name for the locale
  /// 
  /// Convenience property to get the native language display
  /// name for this locale.
  /// 
  /// Returns:
  /// - Native language name if supported, fallback otherwise
  String get displayName => AppLocalizationConfig.getLanguageDisplayName(this);

  /// Check if the locale is RTL
  /// 
  /// Convenience property to check if this locale uses
  /// right-to-left text direction.
  /// 
  /// Returns:
  /// - true if the locale is RTL, false otherwise
  bool get isRTL => AppLocalizationConfig.isRTLLanguage(this);

  /// Get text direction for the locale
  /// 
  /// Convenience property to get the text direction for
  /// this locale.
  /// 
  /// Returns:
  /// - TextDirection.rtl for RTL languages, TextDirection.ltr otherwise
  TextDirection get textDirection =>
      AppLocalizationConfig.getTextDirection(this);

  /// Format a number for the locale
  /// 
  /// Convenience method to format a number according to the
  /// conventions of this locale.
  /// 
  /// Parameters:
  /// - [number]: The number to format
  /// 
  /// Returns:
  /// - Locally formatted number string
  String formatNumber(int number) =>
      AppLocalizationConfig.formatNumber(number, this);
}