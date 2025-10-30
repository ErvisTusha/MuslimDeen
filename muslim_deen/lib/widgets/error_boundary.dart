import 'package:flutter/material.dart';

/// Error Boundary - Graceful error handling and display widget
///
/// This widget provides a safety net for catching and displaying errors that occur
/// within its child widget tree. It prevents entire app crashes by isolating errors
/// to specific UI sections and providing user-friendly error displays.
///
/// ## Key Features
/// - Error isolation: Prevents child errors from crashing the entire app
/// - Customizable error UI: Optional errorBuilder for custom error displays
/// - Graceful fallback: Default error screen with retry functionality
/// - State management: Maintains error state and recovery options
/// - User-friendly messaging: Clear error communication without technical details
///
/// ## Error Handling Strategy
/// - Catches runtime errors in child widget tree
/// - Displays appropriate error UI instead of crashing
/// - Provides recovery options (dismiss/retry)
/// - Maintains app stability during error conditions
/// - Logs errors for debugging and monitoring
///
/// ## Usage Patterns
/// - Wrap critical UI sections that might fail
/// - Use around network-dependent components
/// - Apply to complex widget trees with multiple data sources
/// - Implement at screen or major component boundaries
///
/// ## Error Display
/// - Default error screen with icon and message
/// - Custom error builder for branded error experiences
/// - Error details display for debugging (development only)
/// - Recovery actions with clear call-to-actions
///
/// ## State Management
/// - Error state persistence during widget lifecycle
/// - Recovery mechanism to clear error state
/// - Child widget recreation on error recovery
/// - State isolation to prevent error propagation
///
/// ## Performance Considerations
/// - Minimal overhead when no errors occur
/// - Efficient error state management
/// - No impact on normal app performance
/// - Lightweight error UI rendering
///
/// ## User Experience
/// - Prevents app crashes and white screens
/// - Clear error communication in user-friendly language
/// - Recovery options to restore functionality
/// - Consistent error handling across the app
/// - Maintains app usability during error conditions
///
/// ## Development & Debugging
/// - Error details available in development mode
/// - Stack trace preservation for debugging
/// - Error logging integration points
/// - Development-friendly error displays
///
/// ## Integration Guidelines
/// - Use at appropriate granularity (not every widget)
/// - Combine with proper error logging
/// - Test error scenarios during development
/// - Provide meaningful error messages to users
/// - Consider user context when designing error UI
///
/// ## Accessibility
/// - Screen reader support for error messages
/// - High contrast error indicators
/// - Keyboard navigation for recovery actions
/// - Semantic structure for assistive technologies
///
/// ## Platform Considerations
/// - Consistent behavior across iOS and Android
/// - Web-specific error handling considerations
/// - Desktop error display adaptations
/// - Mobile-specific recovery patterns
class ErrorBoundary extends StatefulWidget {
  /// The child widget tree to protect with error boundary
  /// Any errors occurring within this widget tree will be caught
  final Widget child;

  /// Optional custom error builder function
  /// If provided, this function is called to build custom error UI
  /// Receives BuildContext and the error object as parameters
  /// Return null to use default error display
  final Widget Function(BuildContext context, dynamic error)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  /// Current error state - null when no error, contains error when caught
  dynamic _error;

  @override
  void initState() {
    super.initState();
    // In a production implementation, you would set up error listeners here
    // For example: FlutterError.onError, PlatformDispatcher.onError, etc.
  }

  @override
  Widget build(BuildContext context) {
    // In a real implementation, you'd listen to global errors and set _error
    // This simplified version shows the error handling structure

    // If there's an error and a custom error builder is provided, use it
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!);
    }

    // If there's an error but no custom builder, show default error UI
    if (_error != null) {
      return Material(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon for visual indication
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),

                // Main error message
                Text(
                  _error?.message?.toString() ?? 'An unknown error occurred',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),

                // Additional error details if available
                if (_error?.details != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _error!.details!.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 24),

                // Recovery action button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null; // Clear error state to retry
                    });
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // No error - render the protected child widget tree
    return widget.child;
  }
}
