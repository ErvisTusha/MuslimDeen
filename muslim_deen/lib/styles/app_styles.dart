import 'package:flutter/material.dart';

/// Comprehensive styling system for the MuslimDeen application
///
/// This file defines the complete visual design language for the MuslimDeen app,
/// including colors, typography, spacing, and component styles. It provides a
/// centralized, theme-aware styling system that ensures consistency across all
/// UI components while supporting both light and dark modes.
///
/// ## Design Philosophy
/// - Islamic-inspired color palette with green as primary accent
/// - Accessibility-first approach with proper contrast ratios
/// - Theme-aware design supporting system light/dark preferences
/// - Consistent spacing and typography scales
/// - Performance-optimized style definitions
///
/// ## Color System
/// - Primary colors: Islamic green tones for branding and actions
/// - Semantic colors: Clear meaning for success, warning, error states
/// - Theme variants: Separate palettes for light and dark modes
/// - Accessibility: WCAG compliant contrast ratios
/// - Cultural sensitivity: Colors chosen to be appropriate for Islamic context
///
/// ## Typography Scale
/// - Hierarchical text styles for different content types
/// - Responsive sizing for different screen densities
/// - Readability optimized for Islamic text content
/// - Consistent line heights and letter spacing
///
/// ## Component Styles
/// - Predefined styles for common UI patterns
/// - Consistent spacing and sizing
/// - Theme-aware property resolution
/// - Performance optimized with const constructors
///
/// ## Usage Guidelines
/// - Always use theme-aware getters instead of direct color values
/// - Prefer predefined text styles over custom styling
/// - Use semantic color names for maintainability
/// - Test all styles in both light and dark themes
///
/// ## Performance Considerations
/// - All color values are const for compile-time optimization
/// - Style methods are lightweight and cacheable
/// - Minimal computation in style resolution
/// - Efficient theme switching with precomputed values
///
/// ## Maintenance
/// - Colors should be updated in design system coordination
/// - Typography changes affect entire app readability
/// - Test accessibility compliance after style changes
/// - Document color usage intentions for future changes

/// App Colors - Centralized color system with theme support
///
/// This class defines the complete color palette for the MuslimDeen application,
/// providing theme-aware color resolution for consistent visual design across
/// light and dark modes. All colors are chosen to be culturally appropriate
/// and accessible.
///
/// ## Color Categories
/// - Primary: Main brand colors (Islamic green tones)
/// - Background/Surface: Base canvas colors for different UI layers
/// - Semantic: Colors with specific meanings (accent, error, etc.)
/// - Text: Typography colors with proper contrast ratios
/// - Utility: Helper colors for specific use cases
///
/// ## Theme Support
/// - Automatic switching between light and dark variants
/// - Brightness-based color resolution
/// - Consistent color relationships across themes
/// - Accessibility-compliant contrast ratios
///
/// ## Islamic Design Considerations
/// - Green as primary color (represents Islam, nature, growth)
/// - Calming, spiritual color palette
/// - Appropriate for religious application context
/// - Culturally sensitive color choices
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  /// Light Theme Colors
  /// These colors are optimized for light backgrounds and provide
  /// excellent readability and accessibility compliance.

  /// Primary color for light theme - Islamic green
  /// Used for primary buttons, active states, and brand elements
  /// Represents growth, nature, and Islamic spirituality
  static const Color primaryLight = Color(0xFF2E604C);

  /// Background color for light theme - clean, minimal
  /// Provides a neutral canvas for content while maintaining readability
  static const Color backgroundLight = Color(0xFFF5F6F8);

  /// Surface color for light theme - slightly elevated
  /// Used for cards, dialogs, and elevated surfaces
  static const Color surfaceLight = Color(0xFFF5F6F8);

  /// Error color for light theme - accessible red
  /// Used for error states, validation messages, and destructive actions
  static const Color errorLight = Color(0xFFE53935);

  /// Surface variant for light theme - subtle green tint
  /// Used for special states like Ramadan highlights or success indicators
  static const Color surfaceVariantLight = Color(0xFFE8F5E8);

  /// Dark Theme Colors
  /// These colors are optimized for dark backgrounds and provide
  /// excellent readability while being easy on the eyes.

  /// Primary color for dark theme - deeper Islamic green
  /// Maintains brand consistency while being appropriate for dark backgrounds
  static const Color primaryDark = Color(0xFF1B5E20);

  /// Background color for dark theme - true black with slight warmth
  /// Provides deep contrast while being comfortable for extended use
  static const Color backgroundDark = Color(0xFF121212);

  /// Surface color for dark theme - elevated dark surface
  /// Used for cards and dialogs in dark mode
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Error color for dark theme - softer red for dark backgrounds
  /// Maintains accessibility while being appropriate for dark themes
  static const Color errorDark = Color(0xFFCF6679);

  /// Surface variant for dark theme - subtle dark green tint
  /// Used for special states in dark mode
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  /// Accent Colors
  /// These colors provide additional visual variety while maintaining
  /// the Islamic and spiritual theme of the application.

  /// Accent green - vibrant green for highlights and success states
  /// Used for positive actions, completed tasks, and celebratory elements
  static const Color accentGreen = Color(0xFF4CAF50);

  /// Accent orange - warm orange for attention and warnings
  /// Used for notifications, reminders, and non-critical alerts
  static const Color accentOrange = Color(0xFFFF9800);

  /// Accent blue - calming blue for informational content
  /// Used for links, secondary actions, and informational elements
  static const Color accentBlue = Color(0xFF2193F3);

  /// Accent gray - neutral gray for disabled states and subtle elements
  /// Used for disabled buttons, placeholders, and secondary information
  static const Color accentGray = Color(0xFF757575);

  /// Switch Track Active - green for active switch states
  /// Specifically designed for switch components to indicate active state
  static const Color switchTrackActive = Color(0xFF4CAF50);

  /// Text Colors
  /// Typography colors with proper contrast ratios for accessibility.
  /// These ensure readability across all theme variants.

  /// Primary text color for light theme - high contrast black
  /// Used for headings, important text, and primary content
  static const Color textPrimaryLight = Color(0xFF212121);

  /// Secondary text color for light theme - medium contrast gray
  /// Used for subtitles, descriptions, and less important information
  static const Color textSecondaryLight = Color(0xFF757575);

  /// Primary text color for dark theme - pure white
  /// Provides maximum contrast on dark backgrounds
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Secondary text color for dark theme - soft white with transparency
  /// Maintains readability while being subtle on dark backgrounds
  static const Color textSecondaryDark = Color(0xB0BEC7);

  /// Element Colors
  /// Additional colors for specific UI elements and states.

  /// Inactive icon color - subtle gray for disabled or inactive states
  /// Used for icons that are not currently active or available
  static const Color iconInactive = Color(0xFF9E9E9E);

  /// Active primary icon color - Islamic green for primary active states
  /// Used for icons in active primary states (navigation, selections)
  static const Color iconActivePrimary = Color(0xFF2E604C);

  /// Active secondary icon color - medium gray for secondary active states
  /// Used for icons in secondary active states
  static const Color iconActiveSecondary = Color(0xFF757575);

  /// Divider color - subtle gray for separating content sections
  /// Used for borders, dividers, and subtle separators
  static const Color divider = Color(0xFFE0E0E0);

  /// Shadow color - semi-transparent black for depth effects
  /// Used for creating shadow effects with appropriate opacity
  static const Color shadowColor = Color(0x33000000);

  /// Theme-Aware Color Getters
  /// These methods automatically return the appropriate color based on
  /// the current theme brightness, ensuring consistent appearance.

  /// Returns primary color based on theme brightness
  /// - Light theme: Islamic green for brand consistency
  /// - Dark theme: Deeper green for dark background compatibility
  static Color primary(Brightness brightness) =>
      brightness == Brightness.light ? primaryLight : primaryDark;

  /// Returns background color based on theme brightness
  /// - Light theme: Clean, minimal background
  /// - Dark theme: Deep, comfortable dark background
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? backgroundLight : backgroundDark;

  /// Returns surface color based on theme brightness
  /// - Light theme: Slightly elevated surface
  /// - Dark theme: Elevated dark surface for cards and dialogs
  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? surfaceLight : surfaceDark;

  /// Returns error color based on theme brightness
  /// - Light theme: Standard accessible red
  /// - Dark theme: Softer red appropriate for dark backgrounds
  static Color error(Brightness brightness) =>
      brightness == Brightness.light ? errorLight : errorDark;

  /// Returns surface variant color based on theme brightness
  /// - Light theme: Subtle green tint for special states
  /// - Dark theme: Subtle dark green tint for special states
  static Color surfaceVariant(Brightness brightness) =>
      brightness == Brightness.light ? surfaceVariantLight : surfaceVariantDark;

  /// Returns primary text color based on theme brightness
  /// - Light theme: High contrast black
  /// - Dark theme: Pure white for maximum readability
  static Color textPrimary(Brightness brightness) =>
      brightness == Brightness.light ? textPrimaryLight : textPrimaryDark;

  /// Returns secondary text color based on theme brightness
  /// - Light theme: Medium contrast gray
  /// - Dark theme: Soft white with transparency
  static Color textSecondary(Brightness brightness) =>
      brightness == Brightness.light ? textSecondaryLight : textSecondaryDark;

  /// Convenience Methods
  /// Helper methods for common color usage patterns.

  /// Returns scaffold background color (same as background)
  /// Convenience method for getting the main app background color
  static Color getScaffoldBackground(Brightness brightness) =>
      background(brightness);

  /// Returns border color based on theme
  /// Uses divider color for consistent border styling
  static Color borderColor(Brightness brightness) => divider;
}

/// App Text Styles - Comprehensive typography system
///
/// This class provides a complete typography scale for the MuslimDeen application,
/// with theme-aware text styles that ensure consistent readability and visual
/// hierarchy across all UI components.
///
/// ## Typography Hierarchy
/// - Headlines: Large, bold text for major section headers
/// - Titles: Medium-sized text for component headers and important labels
/// - Body: Standard text for content and descriptions
/// - Labels: Small text for buttons, form labels, and metadata
/// - Specialized: Custom styles for specific Islamic/prayer contexts
///
/// ## Design Principles
/// - Consistent font family (Roboto) for clean, readable text
/// - Proper contrast ratios for accessibility compliance
/// - Responsive sizing for different screen densities
/// - Theme-aware color resolution
/// - Optimized for Islamic text content (Arabic/Persian support ready)
///
/// ## Usage Guidelines
/// - Use semantic style names (headlineLarge, bodyMedium, etc.)
/// - Always pass brightness parameter for theme-aware colors
/// - Prefer predefined styles over custom TextStyle creation
/// - Test readability in both light and dark themes
///
/// ## Performance Considerations
/// - Styles are created on-demand to avoid unnecessary memory usage
/// - Font family is consistent to leverage system font caching
/// - Color resolution is lightweight and efficient
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  /// Headline Styles
  /// Large, bold text styles for major headings and section titles.

  /// Largest headline - 32pt bold
  /// Used for main app titles and major section headers
  static TextStyle headlineLarge(Brightness brightness) => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.2,
  );

  /// Medium headline - 28pt bold
  /// Used for subsection headers and important titles
  static TextStyle headlineMedium(Brightness brightness) => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.2,
  );

  /// Small headline - 24pt bold
  /// Used for card headers and secondary section titles
  static TextStyle headlineSmall(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.25,
  );

  /// Title Styles
  /// Medium-sized text for component headers and important labels.

  /// Large title - 22pt semibold
  /// Used for dialog titles and major component headers
  static TextStyle titleLarge(Brightness brightness) => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.3,
  );

  /// Medium title - 20pt semibold
  /// Used for card titles and section headers
  static TextStyle titleMedium(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.3,
  );

  /// Small title - 18pt semibold
  /// Used for subsection titles and important labels
  static TextStyle titleSmall(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.35,
  );

  /// Tiny title - 16pt semibold
  /// Used for small headers and emphasized labels
  static TextStyle titleTiny(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Body Text Styles
  /// Standard text styles for content and descriptions.

  /// Large body text - 20pt regular
  /// Used for primary content and readable text blocks
  static TextStyle bodyLarge(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Medium body text - 18pt regular
  /// Used for standard content and descriptions
  static TextStyle bodyMedium(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.45,
  );

  /// Small body text - 16pt regular
  /// Used for secondary content and detailed descriptions
  static TextStyle bodySmall(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.5,
  );

  /// Tiny body text - 14pt regular
  /// Used for captions and fine print
  static TextStyle bodyTiny(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.5,
  );

  /// Label Styles
  /// Small text styles for buttons, form labels, and metadata.

  /// Large label - 16pt medium
  /// Used for button text and important form labels
  static TextStyle labelLarge(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Medium label - 14pt medium
  /// Used for standard form labels and secondary buttons
  static TextStyle labelMedium(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.45,
  );

  /// Small label - 12pt medium
  /// Used for small buttons and metadata labels
  static TextStyle labelSmall(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.5,
  );

  /// Specialized Styles
  /// Custom styles designed for specific Islamic and prayer-related contexts.

  /// App title style - 24pt bold with letter spacing
  /// Used for the main application title and branding
  static TextStyle appTitle(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// Prayer time display - 18pt bold
  /// Used for displaying prayer times in a prominent, readable format
  static TextStyle prayerTime(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.3,
  );

  /// Prayer name display - 16pt semibold
  /// Used for prayer names (Fajr, Dhuhr, Asr, Maghrib, Isha)
  static TextStyle prayerName(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Subtitle style - 16pt medium with secondary color
  /// Used for subtitles and secondary information
  static TextStyle subtitle(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Caption style - 12pt regular with secondary color
  /// Used for captions, disclaimers, and tertiary information
  static TextStyle caption(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
    height: 1.5,
  );

  /// Button Text Styles
  /// Specialized styles for button text with appropriate sizing.

  /// Large button text - 16pt semibold
  /// Used for primary action buttons
  static TextStyle buttonLarge(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Medium button text - 14pt semibold
  /// Used for secondary action buttons
  static TextStyle buttonMedium(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.45,
  );

  /// Small button text - 12pt semibold
  /// Used for small action buttons and links
  static TextStyle buttonSmall(Brightness brightness) => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.5,
  );

  /// View-Specific Styles
  /// Convenience styles optimized for specific view components.

  /// Section title - 18pt bold
  /// Used for section headers in views and components
  static TextStyle sectionTitle(Brightness brightness) => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.3,
  );

  /// Date display - 16pt regular
  /// Used for displaying dates in a readable format
  static TextStyle date(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Secondary date display - 14pt regular with secondary color
  /// Used for secondary date information and timestamps
  static TextStyle dateSecondary(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
    height: 1.45,
  );

  /// Location city display - 16pt semibold
  /// Used for displaying city names in location information
  static TextStyle locationCity(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Location country display - 14pt regular with secondary color
  /// Used for displaying country names in location information
  static TextStyle locationCountry(Brightness brightness) => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
    height: 1.45,
  );

  /// Current prayer display - 20pt bold
  /// Used for highlighting the currently active prayer
  static TextStyle currentPrayer(Brightness brightness) => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary(brightness),
    fontFamily: 'Roboto',
    height: 1.25,
  );

  /// Next prayer display - 16pt semibold with secondary color
  /// Used for showing the upcoming prayer information
  static TextStyle nextPrayer(Brightness brightness) => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary(brightness),
    fontFamily: 'Roboto',
    height: 1.4,
  );

  /// Countdown timer display - 24pt bold with accent green
  /// Used for prayer countdown timers with special green coloring
  static TextStyle countdownTimer(Brightness brightness) => TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.accentGreen,
    fontFamily: 'Roboto',
    height: 1.2,
  );

  /// Legacy Aliases
  /// Backward compatibility aliases for existing code.

  /// Alias for labelLarge - maintained for backward compatibility
  static TextStyle label(Brightness brightness) => labelLarge(brightness);
}

/// App Layout Constants - Spacing, padding, and sizing system
///
/// This class defines the complete spacing and layout system for the MuslimDeen
/// application, providing consistent dimensions across all UI components.
///
/// ## Spacing Scale
/// - Tiny: 4pt - Small gaps and micro-interactions
/// - Small: 8pt - Component internal spacing
/// - Medium: 16pt - Standard component spacing
/// - Large: 24pt - Section spacing
/// - X-Large: 32pt - Major section breaks
/// - XX-Large: 48pt - Page-level spacing
///
/// ## Design Principles
/// - Consistent 4pt grid system for alignment
/// - Proportional scaling for different screen sizes
/// - Accessibility-compliant touch targets (minimum 44pt)
/// - Islamic design harmony with balanced proportions
///
/// ## Usage Guidelines
/// - Use predefined constants instead of magic numbers
/// - Combine spacing constants for complex layouts
/// - Test layouts on multiple screen sizes
/// - Consider touch accessibility for interactive elements
class AppLayout {
  // Private constructor to prevent instantiation
  AppLayout._();

  /// Spacing Constants
  /// Standardized spacing values following a 4pt grid system.

  /// Tiny spacing - 4pt
  /// Used for micro-gaps between very small elements
  static const double spacingTiny = 4.0;

  /// Small spacing - 8pt
  /// Used for internal component spacing and small gaps
  static const double spacingSmall = 8.0;

  /// Medium spacing - 16pt
  /// Standard spacing for component separation and padding
  static const double spacingMedium = 16.0;

  /// Large spacing - 24pt
  /// Used for section breaks and major component separation
  static const double spacingLarge = 24.0;

  /// Extra large spacing - 32pt
  /// Used for major section breaks and layout divisions
  static const double spacingXLarge = 32.0;

  /// Extra extra large spacing - 48pt
  /// Used for page-level spacing and major content breaks
  static const double spacingXXLarge = 48.0;

  /// Padding Constants
  /// Predefined EdgeInsets for consistent padding application.

  /// Tiny padding - 4pt all around
  /// Used for minimal padding on small elements
  static const EdgeInsets paddingTiny = EdgeInsets.all(4.0);

  /// Small padding - 8pt all around
  /// Used for internal component padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);

  /// Medium padding - 16pt all around
  /// Standard padding for most components
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);

  /// Large padding - 24pt all around
  /// Used for spacious component padding
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);

  /// Directional Padding
  /// Specialized padding for specific layout needs.

  /// Small vertical padding - 8pt top/bottom, 0pt sides
  /// Used for vertical spacing without horizontal padding
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(
    horizontal: 0,
    vertical: 8.0,
  );

  /// Medium vertical padding - 16pt top/bottom, 0pt sides
  /// Used for standard vertical spacing
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(
    horizontal: 0,
    vertical: 16.0,
  );

  /// Large vertical padding - 24pt top/bottom, 0pt sides
  /// Used for major vertical spacing
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(
    horizontal: 0,
    vertical: 24.0,
  );

  /// Small horizontal padding - 8pt left/right, 0pt top/bottom
  /// Used for horizontal spacing without vertical padding
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 0,
  );

  /// Medium horizontal padding - 16pt left/right, 0pt top/bottom
  /// Used for standard horizontal spacing
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 0,
  );

  /// Large horizontal padding - 24pt left/right, 0pt top/bottom
  /// Used for major horizontal spacing
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 0,
  );

  /// Border Radius Constants
  /// Standardized border radius values for consistent corner styling.

  /// Small border radius - 8pt
  /// Used for subtle rounding on small elements
  static const double radiusSmall = 8.0;

  /// Medium border radius - 12pt
  /// Standard border radius for most components
  static const double radiusMedium = 12.0;

  /// Large border radius - 16pt
  /// Used for larger components and cards
  static const double radiusLarge = 16.0;

  /// Oversized border radius - 20pt
  /// Used for special components requiring more rounding
  static const double radiusOversized = 20.0;

  /// Giant border radius - 32pt
  /// Used for very large rounded elements
  static const double radiusGiant = 32.0;

  /// Elevation Constants
  /// Standardized elevation values for shadow effects.

  /// Tiny elevation - 1pt
  /// Subtle shadow for minimal depth
  static const double elevationTiny = 1.0;

  /// Small elevation - 2pt
  /// Light shadow for slight elevation
  static const double elevationSmall = 2.0;

  /// Medium elevation - 4pt
  /// Standard elevation for cards and elevated surfaces
  static const double elevationMedium = 4.0;

  /// Large elevation - 8pt
  /// Strong elevation for prominent elements
  static const double elevationLarge = 8.0;

  /// Extra large elevation - 12pt
  /// Maximum elevation for modal dialogs and overlays
  static const double elevationExtraLarge = 12.0;
}

/// App Container Styles - Predefined container decorations
///
/// This class provides factory methods for creating consistent container
/// decorations with proper theming, shadows, and styling for the MuslimDeen app.
///
/// ## Design Principles
/// - Consistent shadow and elevation system
/// - Theme-aware color resolution
/// - Flexible customization options
/// - Performance optimized with const values where possible
///
/// ## Usage Guidelines
/// - Use factory methods instead of creating BoxDecoration directly
/// - Always provide required color parameter for theme awareness
/// - Customize optional parameters as needed for specific use cases
/// - Test shadow effects in both light and dark themes
class AppContainers {
  // Private constructor to prevent instantiation
  AppContainers._();

  /// Creates a card-style decoration with optional shadow and customization
  ///
  /// Parameters:
  /// - color: Required background color (theme-aware)
  /// - borderRadius: Optional corner radius (defaults to medium)
  /// - shadow: Whether to apply shadow effect
  /// - shadowColor: Custom shadow color (defaults to theme shadow)
  /// - elevation: Shadow intensity (affects blur and offset)
  /// - border: Optional border styling
  /// - gradient: Optional gradient background
  ///
  /// Returns a BoxDecoration configured for card-like appearance
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
      borderRadius:
          borderRadius ?? BorderRadius.circular(AppLayout.radiusMedium),
      boxShadow:
          shadow && elevation != null
              ? [
                BoxShadow(
                  color: shadowColor ?? AppColors.shadowColor,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
              : [],
      border: border,
      gradient: gradient,
    );
  }

  /// Creates a general-purpose container decoration
  ///
  /// Parameters:
  /// - color: Optional background color
  /// - borderRadius: Optional corner radius
  /// - shadow: Whether to apply shadow effect
  /// - shadowColor: Custom shadow color
  /// - elevation: Shadow intensity
  /// - border: Optional border styling
  ///
  /// Returns a BoxDecoration for general container styling
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
      boxShadow:
          shadow && (elevation != null)
              ? [
                BoxShadow(
                  color: shadowColor ?? AppColors.shadowColor,
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
              : [],
      border: border,
    );
  }
}
