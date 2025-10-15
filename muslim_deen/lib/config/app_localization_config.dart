import 'package:flutter/material.dart';

class AppLocalizationConfig {
  // Supported locales for the application
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

  // Get text direction based on locale
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

  // Check if locale is RTL (right-to-left)
  static bool isRTLLanguage(Locale locale) {
    return getTextDirection(locale) == TextDirection.rtl;
  }

  // Get display name for language
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

  // Get localized numeric format
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

// Extension methods for easier localization access
extension LocaleExtensions on Locale {
  String get displayName => AppLocalizationConfig.getLanguageDisplayName(this);
  bool get isRTL => AppLocalizationConfig.isRTLLanguage(this);
  TextDirection get textDirection =>
      AppLocalizationConfig.getTextDirection(this);
  String formatNumber(int number) =>
      AppLocalizationConfig.formatNumber(number, this);
}
