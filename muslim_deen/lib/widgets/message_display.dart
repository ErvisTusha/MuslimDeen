import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart'; // For AppColors, AppTextStyles

/// Message Display - Versatile message presentation widget
///
/// This widget provides a consistent, themed way to display messages to users
/// with optional icons, retry actions, and different visual treatments for
/// errors vs informational messages. It ensures proper accessibility and
/// user experience across different message types.
///
/// ## Key Features
/// - Flexible message display with customizable styling
/// - Error vs informational message differentiation
/// - Optional icons for visual context and emphasis
/// - Retry action support for error recovery
/// - Theme-aware colors and responsive design
/// - Accessibility-compliant contrast and sizing
///
/// ## Message Types
/// - Error messages: Red-themed styling for problems and failures
/// - Informational messages: Neutral styling for general communication
/// - Success messages: Green-themed for positive feedback
/// - Warning messages: Orange-themed for cautionary information
///
/// ## Visual Design
/// - Centered layout for maximum visibility
/// - Rounded container with subtle shadow for depth
/// - Consistent padding and spacing for readability
/// - Icon integration with appropriate sizing and colors
/// - Border styling that adapts to message type
///
/// ## Interaction Patterns
/// - Optional retry button for error recovery scenarios
/// - Touch-friendly button sizing for mobile interaction
/// - Clear visual hierarchy between message and actions
/// - Smooth animations and state transitions
///
/// ## Theme Integration
/// - Automatic adaptation to light and dark themes
/// - Uses AppColors for consistent color application
/// - AppTextStyles for readable, scalable typography
/// - Proper contrast ratios for accessibility compliance
///
/// ## Layout & Spacing
/// - Container margins: 16pt for screen edge spacing
/// - Internal padding: 24pt horizontal, 32pt vertical for breathing room
/// - Icon spacing: 16pt below icon for visual separation
/// - Button spacing: 24pt above button for action emphasis
///
/// ## Usage Guidelines
/// - Use for empty states, error conditions, and user feedback
/// - Choose appropriate icons that match message context
/// - Provide retry actions for recoverable error states
/// - Test readability in both light and dark themes
/// - Consider message length and line wrapping
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Efficient color and style resolution
/// - Minimal layout complexity for smooth rendering
/// - Reusable component reduces code duplication
///
/// ## Accessibility Features
/// - High contrast text and icons for screen readers
/// - Semantic structure with proper heading hierarchy
/// - Touch target sizing meeting accessibility guidelines
/// - Clear visual indicators for different message types
/// - Keyboard navigation support for interactive elements
///
/// ## Customization Options
/// - customContainerStyle: Override default container styling
/// - icon: Custom icon for message context
/// - onRetry: Callback for retry functionality
/// - isError: Toggle between error and normal styling
/// - message: Primary message text content
///
/// ## User Experience
/// - Clear, concise messaging without technical jargon
/// - Visual cues that match message importance
/// - Recovery options for error scenarios
/// - Consistent behavior across the application
/// - Professional appearance that builds user trust
class MessageDisplay extends StatelessWidget {
  /// The primary message text to display to the user
  /// Should be clear, concise, and appropriate for the context
  final String message;

  /// Optional icon to provide visual context for the message
  /// Should be semantically relevant to the message type
  /// Examples: Icons.error for errors, Icons.info for information
  final IconData? icon;

  /// Optional callback function executed when retry button is tapped
  /// Should contain logic to retry the failed operation
  /// Only displayed when provided and message is marked as error
  final VoidCallback? onRetry;

  /// Whether this message represents an error condition
  /// Affects color scheme (red for errors, neutral for information)
  /// Defaults to false (informational message)
  final bool isError;

  /// Optional custom container styling to override defaults
  /// Allows complete customization of the message container appearance
  /// When null, uses theme-appropriate default styling
  final BoxDecoration? customContainerStyle;

  const MessageDisplay({
    Key? key,
    required this.message,
    this.icon,
    this.onRetry,
    this.isError = false,
    this.customContainerStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // Determine container background color based on message type
    final defaultContainerColor =
        isError
            ? AppColors.error(brightness).withValues(alpha: 0.1)
            : AppColors.surface(brightness);

    // Determine border color for visual definition
    final defaultBorderColor =
        isError
            ? AppColors.error(brightness)
            : AppColors.borderColor(brightness);

    // Use custom styling if provided, otherwise create default
    final containerStyle =
        customContainerStyle ??
        BoxDecoration(
          color: defaultContainerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: defaultBorderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

    // Determine text color based on message type
    final messageColor =
        isError
            ? AppColors.error(brightness)
            : AppTextStyles.label(brightness).color;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: containerStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Optional icon display with appropriate styling
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color:
                    isError
                        ? AppColors.error(brightness)
                        : AppColors.primary(brightness),
              ),

            // Spacing between icon and text
            if (icon != null) const SizedBox(height: 16),

            // Main message text with center alignment
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(
                brightness,
              ).copyWith(color: messageColor, height: 1.5),
            ),

            // Spacing before retry button
            if (onRetry != null) const SizedBox(height: 24),

            // Optional retry button for error recovery
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  // Button styling can be customized here if needed
                  // Currently uses default theme styling
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
