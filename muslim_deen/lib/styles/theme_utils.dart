import 'package:flutter/material.dart';

/// Utility class to provide theme helpers and reduce code duplication
class ThemeUtils {
  /// Gets the current brightness from the provided context
  static Brightness getBrightness(BuildContext context) {
    return Theme.of(context).brightness;
  }

  /// Gets the current theme from the provided context
  static ThemeData getTheme(BuildContext context) {
    return Theme.of(context);
  }

  /// Helper to check if the theme is dark
  static bool isDark(BuildContext context) {
    return getBrightness(context) == Brightness.dark;
  }

  /// Helper to check if the theme is light
  static bool isLight(BuildContext context) {
    return getBrightness(context) == Brightness.light;
  }

  /// Gets appropriate text color based on theme brightness
  static Color getTextColor(BuildContext context, {bool isSecondary = false}) {
    final brightness = getBrightness(context);
    if (isSecondary) {
      return brightness == Brightness.dark
          ? Colors.grey.shade400
          : Colors.grey.shade600;
    }
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  /// Gets appropriate surface color based on theme brightness
  static Color getSurfaceColor(BuildContext context) {
    final brightness = getBrightness(context);
    return brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : Colors.white;
  }

  /// Gets appropriate divider color based on theme brightness
  static Color getDividerColor(BuildContext context) {
    final brightness = getBrightness(context);
    return brightness == Brightness.dark
        ? const Color(0xFF3A3A3A)
        : Colors.grey.shade300;
  }

  /// Creates a standard snackbar with consistent styling
  static SnackBar createSnackBar({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor ?? Colors.red,
      duration: duration,
      action: action,
      behavior: SnackBarBehavior.floating,
    );
  }

  /// Shows a snackbar with the given message
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      createSnackBar(
        context: context,
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }
}
