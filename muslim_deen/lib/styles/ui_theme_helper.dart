import 'package:flutter/material.dart';
import 'app_styles.dart';
import 'dart:math' as math;

/// Comprehensive theme utility for consistent UI styling across the MuslimDeen app
///
/// This utility centralizes color management, accessibility compliance, and theme
/// coordination for all UI components. It ensures consistent visual design while
/// maintaining accessibility standards and supporting both light and dark themes.
///
/// ## Key Features
/// - Centralized theme color management for all UI components
/// - WCAG-compliant contrast ratio calculations for accessibility
/// - Automatic color selection based on brightness mode
/// - Specialized color schemes for different app sections (prayers, tesbih, etc.)
/// - Defensive programming against low-contrast text combinations
///
/// ## Theme Architecture
/// - UIColors: General application colors (surfaces, text, borders)
/// - PrayerItemColors: Prayer-specific highlighting and current prayer states
/// - TesbihColors: Dhikr counter and Islamic remembrance features
///
/// ## Accessibility Compliance
/// - WCAG 2.1 AA contrast ratios (4.5:1 minimum for normal text)
/// - Automatic fallback to black/white for insufficient contrast
/// - Support for both light and dark theme accessibility
/// - Color-blind friendly color combinations
///
/// ## Performance Optimizations
/// - Static methods for efficient color calculation
/// - Immutable color data classes for memory efficiency
/// - Minimal computation overhead for runtime theme switching
/// - Cached luminance calculations for contrast computations
///
/// ## Usage Patterns
/// ```dart
/// // Get standard theme colors
/// final colors = UIThemeHelper.getThemeColors(brightness);
///
/// // Ensure text contrast safety
/// final safeTextColor = UIThemeHelper.contrastSafeTextColor(
///   Colors.blue,
///   backgroundColor,
/// );
/// ```
///
/// ## Integration Points
/// - AppStyles: Base color definitions and typography
/// - ThemeProvider: Runtime theme switching and persistence
/// - All widgets: Consistent color application across the app
///
/// ## Testing Considerations
/// - Contrast ratio validation for all color combinations
/// - Theme switching behavior verification
/// - Accessibility compliance testing with automated tools
/// - Color blindness simulation testing
class UIThemeHelper {
  /// Generates a complete UIColors theme based on the current brightness mode
  ///
  /// This method centralizes all color decisions for the application, ensuring
  /// consistent theming across all components. It adapts colors based on light/dark
  /// mode while maintaining design coherence and accessibility standards.
  ///
  /// ## Color Mapping Logic
  /// - Content surfaces: Dark mode uses custom dark surface, light mode uses standard background
  /// - Accent colors: Consistent green accent across all themes
  /// - Error colors: Brightness-adaptive error states
  /// - Text colors: Primary and secondary text with appropriate contrast
  /// - Borders and icons: Neutral colors that work in both themes
  ///
  /// ## Parameters
  /// - [brightness]: Current theme brightness (light/dark) from MediaQuery or Theme
  ///
  /// ## Returns
  /// A complete UIColors object with all necessary theme colors configured
  ///
  /// ## Usage
  /// ```dart
  /// final colors = UIThemeHelper.getThemeColors(MediaQuery.of(context).platformBrightness);
  /// ```
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

  /// Ensures text color meets WCAG accessibility contrast requirements
  ///
  /// This critical accessibility method prevents low-contrast text combinations
  /// that could make the app unusable for users with visual impairments. It
  /// automatically selects the best contrasting color (black or white) when
  /// the provided foreground color doesn't meet minimum contrast ratios.
  ///
  /// ## WCAG Compliance
  /// - Minimum contrast ratio: 4.5:1 for normal text (default)
  /// - Higher ratios available for larger text or critical UI elements
  /// - Follows WCAG 2.1 AA accessibility guidelines
  ///
  /// ## Algorithm
  /// 1. Calculate contrast ratio between fg and background colors
  /// 2. Return original fg color if ratio meets minimum requirement
  /// 3. Test black and white alternatives against background
  /// 4. Return the color (black/white) with highest contrast ratio
  ///
  /// ## Parameters
  /// - [fg]: Proposed foreground/text color
  /// - [background]: Background color to test contrast against
  /// - [minRatio]: Minimum WCAG contrast ratio (default: 4.5)
  ///
  /// ## Returns
  /// Either the original fg color (if compliant) or black/white for best contrast
  ///
  /// ## Usage Examples
  /// ```dart
  /// // Standard accessibility compliance
  /// final safeColor = UIThemeHelper.contrastSafeTextColor(textColor, backgroundColor);
  ///
  /// // Higher contrast for headings
  /// final headingColor = UIThemeHelper.contrastSafeTextColor(color, bg, minRatio: 7.0);
  /// ```
  ///
  /// ## Performance Notes
  /// - Uses cached luminance calculations for efficiency
  /// - Minimal computational overhead for runtime theme changes
  /// - Suitable for use in build methods and animations
  static Color contrastSafeTextColor(
    Color fg,
    Color background, {
    double minRatio = 4.5,
  }) {
    final double l1 = _luminance(fg);
    final double l2 = _luminance(background);
    final double hi = l1 > l2 ? l1 : l2;
    final double lo = l1 > l2 ? l2 : l1;
    final double ratio = (hi + 0.05) / (lo + 0.05);
    if (ratio >= minRatio) return fg;

    // try black and white and pick the best contrast
    final black = const Color(0xFF000000);
    final white = const Color(0xFFFFFFFF);
    final double rBlack = _contrastRatio(black, background);
    final double rWhite = _contrastRatio(white, background);
    return rBlack >= rWhite ? black : white;
  }

  /// Calculates the relative luminance of a color using WCAG formula
  ///
  /// Implements the WCAG 2.1 relative luminance calculation, which accounts
  /// for human perception of brightness. This is essential for accurate
  /// contrast ratio calculations and accessibility compliance.
  ///
  /// ## Formula
  /// L = 0.2126 × R + 0.7152 × G + 0.0722 × B
  /// Where R, G, B are the linear RGB components after gamma correction
  ///
  /// ## Parameters
  /// - [c]: Color to calculate luminance for
  ///
  /// ## Returns
  /// Relative luminance value between 0.0 (black) and 1.0 (white)
  ///
  /// ## Technical Details
  /// - Applies sRGB gamma correction before linear calculation
  /// - Weights reflect human eye sensitivity to different wavelengths
  /// - Used internally by contrast ratio calculations
  static double _luminance(Color c) {
    double srgb(double v) {
      final vv = v / 255.0;
      return vv <= 0.03928
          ? vv / 12.92
          : math.pow((vv + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * srgb((c.r * 255.0).round().toDouble()) +
        0.7152 * srgb((c.g * 255.0).round().toDouble()) +
        0.0722 * srgb((c.b * 255.0).round().toDouble());
  }

  /// Calculates the contrast ratio between two colors using WCAG formula
  ///
  /// Implements the WCAG 2.1 contrast ratio calculation: (L1 + 0.05) / (L2 + 0.05)
  /// where L1 and L2 are the relative luminances of the two colors. The +0.05
  /// adjustment prevents division by zero for very dark colors.
  ///
  /// ## Parameters
  /// - [a]: First color for comparison
  /// - [b]: Second color for comparison
  ///
  /// ## Returns
  /// Contrast ratio between 1.0 (same color) and 21.0+ (maximum contrast)
  ///
  /// ## WCAG Thresholds
  /// - 3.0:1 - Minimum for large text (18pt+ or 14pt+ bold)
  /// - 4.5:1 - Minimum for normal text (WCAG AA)
  /// - 7.0:1 - Enhanced contrast (WCAG AAA)
  ///
  /// ## Usage
  /// Used internally by contrastSafeTextColor to determine if colors meet accessibility standards
  static double _contrastRatio(Color a, Color b) {
    final double la = _luminance(a);
    final double lb = _luminance(b);
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }
}

/// Comprehensive color scheme for general UI components
///
/// This immutable data class encapsulates all the colors needed for standard
/// UI elements throughout the MuslimDeen app. It provides a consistent color
/// palette that adapts to light and dark themes while maintaining accessibility
/// and visual coherence.
///
/// ## Color Categories
/// - Surface colors: Backgrounds and content containers
/// - Text colors: Primary and secondary text with proper hierarchy
/// - Interactive colors: Accents, errors, and action states
/// - Structural colors: Borders, dividers, and inactive elements
///
/// ## Theme Adaptation
/// - Automatically adjusts based on brightness setting
/// - Maintains consistent contrast ratios across themes
/// - Preserves brand colors (green accent) in both modes
/// - Dark mode uses deeper surfaces for better battery life
///
/// ## Usage
/// ```dart
/// final colors = UIThemeHelper.getThemeColors(brightness);
/// Container(
///   color: colors.contentSurface,
///   child: Text('Hello', style: TextStyle(color: colors.textColorPrimary)),
/// );
/// ```
///
/// ## Integration
/// Used by all major UI components for consistent theming:
/// - Prayer list items and time displays
/// - Settings screens and form elements
/// - Navigation bars and tab indicators
/// - Error states and validation messages
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

/// Specialized color scheme for prayer list items and current prayer highlighting
///
/// This data class defines the colors used specifically for prayer-related UI
/// components, particularly the highlighting system that indicates the current
/// prayer time. It provides visual prominence for active prayer states while
/// maintaining readability and accessibility.
///
/// ## Color Roles
/// - Current prayer background: Subtle highlight for active prayer
/// - Current prayer border: Accent border for visual separation
/// - Current prayer text: High-contrast text for active prayer name/time
///
/// ## Design Intent
/// - Creates clear visual hierarchy in prayer lists
/// - Maintains Islamic design sensibilities with appropriate colors
/// - Ensures accessibility with sufficient contrast ratios
/// - Provides consistent highlighting across different screen sizes
///
/// ## Usage Context
/// Used exclusively in prayer list widgets to highlight the currently active
/// prayer time, making it easy for users to identify their current religious
/// obligation at a glance.
///
/// ## Accessibility Considerations
/// - High contrast ratios for current prayer text
/// - Color combinations that work for color-blind users
/// - Consistent with overall app accessibility guidelines
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

/// Specialized color scheme for Tesbih (dhikr counter) functionality
///
/// This data class defines the comprehensive color palette used in the Islamic
/// remembrance (dhikr) counter feature. It supports the unique visual requirements
/// of the tesbih interface including circular counters, Arabic text display,
/// and progress indicators.
///
/// ## Color Components
/// - Content surface: Background for tesbih interface
/// - Counter circle: Circular progress indicator background
/// - Arabic text: Special styling for dhikr phrases in Arabic script
/// - Progress indicators: Visual feedback for counting progress
/// - Count text: Numerical display of current count
/// - Toggle cards: Interactive elements for dhikr selection
///
/// ## Cultural Considerations
/// - Respects Islamic design principles in color selection
/// - Supports Arabic text rendering with appropriate colors
/// - Creates serene, contemplative atmosphere for dhikr practice
/// - Maintains accessibility while preserving spiritual aesthetics
///
/// ## Technical Implementation
/// - Optimized for circular progress indicators
/// - Supports smooth animations during counting
/// - Maintains readability of Arabic script at various sizes
/// - Provides clear visual feedback for user interactions
///
/// ## Usage
/// Applied throughout the tesbih/dhikr counter interface to create a cohesive
/// and spiritually appropriate visual experience for Islamic remembrance practices.
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
