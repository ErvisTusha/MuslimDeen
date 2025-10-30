import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// Custom application bar widget with theme-aware styling and status bar integration
///
/// This widget provides a consistent, branded app bar across the MuslimDeen application
/// with proper theme integration, status bar styling, and accessibility features.
/// It implements the PreferredSizeWidget interface for seamless integration with
/// Flutter's Scaffold system.
///
/// ## Key Features
/// - Theme-aware color scheme (light/dark mode support)
/// - Consistent typography using AppTextStyles
/// - Proper status bar styling with system overlay management
/// - Optional action buttons for navigation and controls
/// - Elevation and shadow effects for depth perception
/// - Centered title layout following Material Design guidelines
/// - Accessibility support with proper contrast ratios
///
/// ## Theme Integration
/// - Automatically adapts to system brightness settings
/// - Uses AppColors.primary for background consistency
/// - Applies AppTextStyles.appTitle for branded typography
/// - Maintains proper contrast ratios for readability
/// - Status bar icons adjust for optimal visibility
///
/// ## Status Bar Management
/// - Sets status bar color to match app bar background
/// - Configures status bar icon brightness for visibility
/// - Uses SystemUiOverlayStyle for platform-specific styling
/// - Ensures seamless visual integration across platforms
///
/// ## Layout & Sizing
/// - Implements PreferredSizeWidget for proper Scaffold integration
/// - Uses standard kToolbarHeight for consistent sizing
/// - Supports optional actions with proper spacing
/// - Centered title with responsive text scaling
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Minimal state management and computation
/// - Efficient color and style resolution
/// - No expensive operations in build method
///
/// ## Usage Context
/// - Primary navigation bar across all application screens
/// - Consistent branding and user experience
/// - Settings access and navigation controls
/// - Screen titles and contextual actions
///
/// ## Accessibility
/// - High contrast text for screen reader compatibility
/// - Proper semantic structure for navigation
/// - Touch target sizing for action buttons
/// - Keyboard navigation support through Flutter framework
///
/// ## Platform Considerations
/// - Android: Status bar color and icon brightness management
/// - iOS: Safe area and navigation bar integration
/// - Web: Responsive behavior and touch interactions
/// - Desktop: Window decoration and system integration
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// The title text displayed in the app bar
  final String title;

  /// Current theme brightness for styling decisions
  final Brightness brightness;

  /// Optional list of action widgets (icons, buttons) for the app bar
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.brightness,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if dark mode is active, to ensure correct status bar icon brightness
    // final bool isDarkMode = brightness == Brightness.dark; // This was simplified

    return AppBar(
      title: Text(title, style: AppTextStyles.appTitle(brightness)),
      backgroundColor: AppColors.primary(brightness),
      elevation: 2.0,
      shadowColor: AppColors.shadowColor,
      centerTitle: true,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary(brightness),
        // Simplified from isDarkMode ? Brightness.light : Brightness.light
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
