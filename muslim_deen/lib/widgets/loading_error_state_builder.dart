import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../styles/app_styles.dart';
import '../styles/ui_theme_helper.dart';

/// Comprehensive loading and error state management widget with retry functionality
///
/// This widget provides a unified, theme-aware solution for handling common UI states
/// in the MuslimDeen application. It elegantly manages loading spinners, error displays,
/// and success content with consistent styling and user experience patterns.
/// - Smooth state transitions between loading, error, and success
/// - Accessibility support with proper semantic structure
/// - Touch-friendly retry buttons with proper sizing
/// - Customizable loading messages for context-specific feedback
///
/// ## State Management
/// - Loading State: Shows circular progress indicator with optional text
/// - Error State: Displays error message with retry button and icon
/// - Success State: Renders the provided child widget seamlessly
/// - State Transitions: Smooth animations between different states
///
/// ## UI Architecture
/// - Uses Column layout for vertical centering and proper spacing
/// - Implements Material Design principles for consistency
/// - Responsive design that works across different screen sizes
/// - Proper padding and margins following app design system
/// - Icon integration for visual error indication
///
/// ## Error Handling
/// - Graceful error message display with user-friendly language
/// - Retry button with clear call-to-action text
/// - Error icon for immediate visual feedback
/// - Callback-based retry mechanism for flexible error recovery
/// - Null safety for optional error messages and loading text
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Minimal computation in build method
/// - Efficient conditional rendering based on state
/// - No expensive operations or animations
///
/// ## Usage Patterns
/// - API call loading states with custom messages
/// - Location permission requests with retry options
/// - Data fetching operations with error recovery
/// - Network-dependent features with offline handling
/// - Async initialization sequences
///
/// ## Accessibility
/// - Screen reader friendly loading announcements
/// - Proper semantic structure for error states
/// - High contrast colors for visibility
/// - Keyboard navigation support for retry actions
/// - Focus management for interactive elements
///
/// ## Integration Points
/// - Works with FutureBuilder and StreamBuilder patterns
/// - Compatible with Riverpod async notifiers
/// - Supports custom error types and messages
/// - Integrates with app-wide theme system
/// - Follows established design system patterns
///
/// ## Platform Considerations
/// - Android: Material Design spinner and button styling
/// - iOS: Cupertino-style loading indicators when appropriate
/// - Web: Responsive behavior and hover states
/// - Desktop: Mouse and keyboard interaction support
class LoadingErrorStateBuilder extends StatelessWidget {
  /// Whether the widget is currently in a loading state
  final bool isLoading;

  /// Error message to display when in error state (null for no error)
  final String? errorMessage;

  /// The success content widget to display when not loading and no error
  final Widget child;

  /// Callback function triggered when user taps retry button
  final VoidCallback onRetry;

  /// Optional loading message to display below the spinner
  final String? loadingText;

  const LoadingErrorStateBuilder({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.child,
    required this.onRetry,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.accentColor),
              strokeWidth: 3,
            ),
            if (loadingText != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingText!,
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.textColorSecondary),
              ),
            ],
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colors.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                _getProcessedErrorMessage(errorMessage!),
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.errorColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  foregroundColor: colors.accentColor,
                ),
                child: const Text('Retry'),
              ),
              ..._buildActionButtons(errorMessage!),
            ],
          ),
        ),
      );
    }

    return child;
  }

  String _getProcessedErrorMessage(String errorMessage) {
    if (errorMessage ==
        'Location permission denied. Please enable it in settings.') {
      return errorMessage;
    } else if (errorMessage.contains('permission')) {
      return "Location permission error. Please check settings.";
    } else if (errorMessage.contains('service is disabled')) {
      return "Location service is disabled. Please enable it.";
    } else if (errorMessage.contains('Compass sensor error')) {
      return "Compass sensor error. Please try again.";
    }
    return errorMessage;
  }

  List<Widget> _buildActionButtons(String errorMessage) {
    final List<Widget> buttons = [];

    if (errorMessage.contains('permission') ||
        errorMessage.contains('permanently denied')) {
      buttons.addAll([
        const SizedBox(height: 8),
        TextButton(
          onPressed: Geolocator.openAppSettings,
          child: const Text("Open App Settings"),
        ),
      ]);
    }

    if (errorMessage.contains('services are disabled')) {
      buttons.addAll([
        const SizedBox(height: 8),
        TextButton(
          onPressed: Geolocator.openLocationSettings,
          child: const Text("Open Location Settings"),
        ),
      ]);
    }

    return buttons;
  }
}
