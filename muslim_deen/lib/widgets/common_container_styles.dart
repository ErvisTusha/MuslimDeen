import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';

/// Common Container Styles - Centralized styling utilities for UI containers
///
/// This utility class provides factory methods for creating consistent container
/// decorations throughout the MuslimDeen application. It ensures visual coherence
/// by standardizing shadows, borders, colors, and spacing across different UI components.
///
/// ## Design Philosophy
/// - Consistent visual language across all container elements
/// - Theme-aware styling with automatic light/dark mode adaptation
/// - Performance optimized with reusable decoration patterns
/// - Accessibility-compliant contrast and sizing
/// - Islamic design harmony with balanced proportions
///
/// ## Container Types
/// - Card decorations: Elevated surfaces for content display
/// - Info panels: Subtle containers for informational content
/// - Circular decorations: Rounded elements for special states
/// - Icon containers: Background styling for icon presentation
/// - Dividers: Consistent separation elements
///
/// ## Theme Integration
/// - Uses UIColors class for comprehensive theme support
/// - Automatic adaptation to brightness settings
/// - Consistent shadow and border application
/// - Alpha transparency adjustments for dark mode
///
/// ## Shadow System
/// - Subtle shadows for depth without visual clutter
/// - Different shadow intensities for different container types
/// - Theme-aware shadow opacity adjustments
/// - Performance optimized shadow calculations
///
/// ## Border System
/// - Consistent border radius values (8pt, 10pt, 12pt)
/// - Subtle border colors using theme border colors
/// - Alpha transparency for different emphasis levels
/// - Special borders for aligned/selected states
///
/// ## Usage Guidelines
/// - Use appropriate decoration method for each container type
/// - Always pass UIColors parameter for theme consistency
/// - Customize optional parameters when needed for specific use cases
/// - Test all containers in both light and dark themes
///
/// ## Performance Considerations
/// - Static methods for optimal performance
/// - Minimal object creation and computation
/// - Reusable BoxDecoration objects
/// - Efficient color and shadow resolution
///
/// ## Maintenance
/// - Update decoration patterns in coordination with design system
/// - Test visual consistency across all container implementations
/// - Ensure accessibility compliance with contrast ratios
/// - Document any new decoration patterns added
///
/// ## Integration with UIColors
/// This class works closely with the UIColors class to provide:
/// - Consistent color application across containers
/// - Theme-aware property resolution
/// - Proper contrast ratios for accessibility
/// - Unified visual design language
class CommonContainerStyles {
  // Private constructor to prevent instantiation
  CommonContainerStyles._();

  /// Creates a standard card decoration with consistent styling
  ///
  /// Used for elevated content containers that need visual prominence.
  /// Features rounded corners, subtle shadow, and theme-aware colors.
  ///
  /// Parameters:
  /// - colors: UIColors instance for theme-aware styling
  ///
  /// Returns a BoxDecoration configured for card-like appearance
  static BoxDecoration cardDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 100 : 150),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor.withAlpha(colors.isDarkMode ? 20 : 30),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Creates a standard info panel decoration
  ///
  /// Used for informational content that needs subtle elevation without
  /// being as prominent as cards. Features lighter shadows and borders.
  ///
  /// Parameters:
  /// - colors: UIColors instance for theme-aware styling
  ///
  /// Returns a BoxDecoration configured for info panel appearance
  static BoxDecoration infoPanelDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor.withAlpha(colors.isDarkMode ? 20 : 30),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Creates a standard circular container decoration
  ///
  /// Used for circular elements that need special visual treatment,
  /// such as aligned/selected states or prominent circular containers.
  ///
  /// Parameters:
  /// - colors: UIColors instance for theme-aware styling
  /// - isAligned: Whether this represents an aligned/selected state
  ///   (affects border color and width)
  ///
  /// Returns a BoxDecoration configured for circular appearance
  static BoxDecoration circularDecoration(
    UIColors colors, {
    bool isAligned = false,
  }) {
    return BoxDecoration(
      color: colors.contentSurface,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor.withAlpha(colors.isDarkMode ? 30 : 50),
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
  ///
  /// Used for vertical separation between UI elements. Provides a subtle
  /// visual divider that adapts to the current theme.
  ///
  /// Parameters:
  /// - colors: UIColors instance for theme-aware styling
  ///
  /// Returns a Container widget configured as a vertical divider
  static Widget divider(UIColors colors) {
    return Container(
      height: 30,
      width: 1,
      color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
    );
  }

  /// Creates a standard icon container decoration
  ///
  /// Used for background styling behind icons to provide visual context
  /// and improve icon visibility against various backgrounds.
  ///
  /// Parameters:
  /// - colors: UIColors instance for theme-aware styling
  ///
  /// Returns a BoxDecoration configured for icon container appearance
  static BoxDecoration iconContainerDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.accentColor.withAlpha(30),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
