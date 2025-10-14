import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';

/// Utility class for common container styling patterns
class CommonContainerStyles {
  /// Creates a standard card decoration with consistent styling
  static BoxDecoration cardDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 100 : 150),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor
              .withAlpha(colors.isDarkMode ? 20 : 30),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Creates a standard info panel decoration
  static BoxDecoration infoPanelDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor
              .withAlpha(colors.isDarkMode ? 20 : 30),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Creates a standard circular container decoration
  static BoxDecoration circularDecoration(
    UIColors colors, {
    bool isAligned = false,
  }) {
    return BoxDecoration(
      color: colors.contentSurface,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor
              .withAlpha(colors.isDarkMode ? 30 : 50),
          blurRadius: 8,
          spreadRadius: 1,
          offset: const Offset(0, 3),
        ),
      ],
      border:
          isAligned
              ? Border.all(color: colors.accentColor, width: 3)
              : Border.all(
                color: colors.borderColor.withAlpha(
                  colors.isDarkMode ? 100 : 150,
                ),
                width: 1,
              ),
    );
  }

  /// Creates a standard divider with consistent styling
  static Widget divider(UIColors colors) {
    return Container(
      height: 30,
      width: 1,
      color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
    );
  }

  /// Creates a standard icon container decoration
  static BoxDecoration iconContainerDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.accentColor.withAlpha(30),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
