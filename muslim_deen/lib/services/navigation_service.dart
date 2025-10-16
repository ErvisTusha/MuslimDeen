import 'package:flutter/material.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Centralized navigation service for consistent routing throughout the app
/// 
/// This service provides a centralized approach to navigation management,
/// ensuring consistent behavior across the entire application. It implements
/// the singleton pattern to maintain a single navigation state and provides
/// comprehensive logging for debugging and analytics.
/// 
/// Features:
/// - Centralized navigation management with singleton pattern
/// - Comprehensive logging of all navigation events
/// - Support for all common navigation scenarios (push, replace, pop)
/// - Error handling and graceful degradation
/// - Navigation state inspection and validation
/// - Route name tracking for analytics
/// 
/// Usage:
/// ```dart
/// final navigationService = NavigationService();
/// 
/// // Navigate to a new screen
/// await navigationService.navigateTo(const HomeView());
/// 
/// // Replace current screen
/// await navigationService.navigateAndReplace(const SettingsView());
/// 
/// // Go back to previous screen
/// navigationService.goBack();
/// ```
/// 
/// Design Patterns:
/// - Singleton: Ensures single navigation state across the app
/// - Service: Provides navigation functionality as a service
/// - Facade: Simplifies Flutter's navigation complexity
/// - Observer: Logs all navigation events for debugging
/// 
/// Performance Considerations:
/// - Minimal overhead over direct navigation
/// - Efficient context management
/// - Early validation to prevent unnecessary operations
/// - Singleton pattern prevents duplicate instances
/// 
/// Error Handling:
/// - Graceful handling of missing context
/// - Detailed error logging with stack traces
/// - Safe navigation that won't crash the app
/// - Validation of navigation state before operations
/// 
/// Dependencies:
/// - LoggerService: For centralized logging of navigation events
/// - Flutter's Navigator: Underlying navigation implementation
class NavigationService {
  static NavigationService? _instance;
  final LoggerService _logger = LoggerService();

  /// Singleton factory constructor
  /// 
  /// Ensures only one instance of NavigationService exists throughout
  /// the application. This maintains consistent navigation state
  /// and prevents multiple navigation contexts.
  /// 
  /// Returns:
  /// - The singleton instance of NavigationService
  factory NavigationService() {
    _instance ??= NavigationService._internal();
    return _instance!;
  }

  /// Internal constructor for singleton pattern
  /// 
  /// Private constructor to prevent direct instantiation.
  /// Initializes the navigator key for context management.
  NavigationService._internal();

  /// Global navigator key for context access
  /// 
  /// This key provides access to the navigator's context from anywhere
  /// in the application, enabling navigation without requiring
  /// direct context references. It must be set in the MaterialApp's
  /// navigatorKey property.
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to a new screen and add it to the navigation stack
  /// 
  /// Pushes a new route onto the navigation stack, allowing users
  /// to return to the previous screen. This is the most common
  /// navigation method for moving between screens.
  /// 
  /// Parameters:
  /// - [page]: The widget to navigate to
  /// - [routeName]: Optional name for logging and analytics
  /// 
  /// Algorithm:
  /// 1. Validate that context is available
  /// 2. Log navigation event with route name
  /// 3. Execute navigation with error handling
  /// 4. Log any errors with full stack trace
  /// 
  /// Error Handling:
  /// - Returns null if navigation fails
  /// - Logs detailed error information
  /// - Handles cases where context is unavailable
  /// 
  /// Performance:
  /// - Uses MaterialPageRoute for standard Android/iOS transitions
  /// - Minimal overhead over direct navigation
  /// 
  /// Returns:
  /// - Future that completes with the navigation result, or null on error
  Future<T?> navigateTo<T>(Widget page, {String? routeName}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'Push',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.push<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  /// Navigate back to the previous screen
  /// 
  /// Pops the current route from the navigation stack, returning to
  /// the previous screen. This is the standard way to go back in
  /// the navigation hierarchy.
  /// 
  /// Parameters:
  /// - [result]: Optional result to return to the previous screen
  /// 
  /// Algorithm:
  /// 1. Validate context and navigation state
  /// 2. Check if pop is possible
  /// 3. Log navigation event
  /// 4. Execute pop operation
  /// 
  /// Error Handling:
  /// - Graceful handling when pop is not possible
  /// - Logs warnings for invalid navigation attempts
  /// - Safe operation that won't crash the app
  /// 
  /// Performance:
  /// - Direct call to Navigator.pop
  /// - No overhead beyond validation
  void goBack<T>([T? result]) {
    final context = navigatorKey.currentContext;
    if (context == null || !Navigator.canPop(context)) {
      _logger.warning('Cannot go back: No context or cannot pop');
      return;
    }

    _logger.logNavigation('Pop');
    Navigator.pop(context, result);
  }

  /// Navigate to a new screen and replace the current one
  /// 
  /// Replaces the current route with a new one, removing the current
  /// screen from the navigation stack. This is useful for screens
  /// that shouldn't be accessible via back navigation (e.g., login,
  /// splash screens, or after logout).
  /// 
  /// Parameters:
  /// - [page]: The widget to navigate to
  /// - [routeName]: Optional name for logging and analytics
  /// 
  /// Algorithm:
  /// 1. Validate context availability
  /// 2. Log navigation event
  /// 3. Execute replacement navigation
  /// 4. Handle any errors gracefully
  /// 
  /// Use Cases:
  /// - After successful login (replace login screen with home)
  /// - After logout (replace current screen with login)
  /// - Navigation flows where back navigation should be prevented
  /// 
  /// Performance:
  /// - Uses Navigator.pushReplacement for efficiency
  /// - Removes previous route from memory
  /// 
  /// Returns:
  /// - Future that completes with the navigation result, or null on error
  Future<T?> navigateAndReplace<T>(Widget page, {String? routeName}) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'Replace',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.pushReplacement<T, void>(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  /// Navigate to a new screen and clear the navigation stack
  /// 
  /// Pushes a new route and removes all previous routes until a
  /// predicate is satisfied. This is typically used to create a
  /// new navigation root, such as after login or when switching
  /// between major app sections.
  /// 
  /// Parameters:
  /// - [page]: The widget to navigate to
  /// - [routeName]: Optional name for logging and analytics
  /// - [predicate]: Function to determine when to stop removing routes
  /// 
  /// Algorithm:
  /// 1. Validate context availability
  /// 2. Log navigation event
  /// 3. Execute pushAndRemoveUntil operation
  /// 4. Use provided predicate or default (remove all)
  /// 
  /// Use Cases:
  /// - After successful login (clear all previous screens)
  /// - Switching between main app sections
  /// - Resetting navigation state
  /// 
  /// Performance:
  /// - Efficiently clears multiple routes at once
  /// - Creates new navigation stack root
  /// 
  /// Returns:
  /// - Future that completes with the navigation result, or null on error
  Future<T?> navigateAndRemoveUntil<T>(
    Widget page, {
    String? routeName,
    bool Function(Route<dynamic>)? predicate,
  }) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.error('Navigation failed: No context available');
      return null;
    }

    _logger.logNavigation(
      'PushAndRemoveUntil',
      routeName: routeName ?? page.runtimeType.toString(),
    );

    try {
      return await Navigator.pushAndRemoveUntil<T>(
        context,
        MaterialPageRoute(builder: (_) => page),
        predicate ?? (route) => false,
      );
    } catch (e, stackTrace) {
      _logger.error(
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
        data: {'route': routeName ?? page.runtimeType.toString()},
      );
      return null;
    }
  }

  /// Pop routes until a predicate is satisfied
  /// 
  /// Repeatedly pops routes from the navigation stack until the
  /// provided predicate returns true. This is useful for navigating
  /// back to a specific screen in the stack without knowing
  /// exactly how many screens to pop.
  /// 
  /// Parameters:
  /// - [predicate]: Function that determines when to stop popping
  /// 
  /// Algorithm:
  /// 1. Validate context availability
  /// 2. Log navigation event
  /// 3. Execute popUntil operation
  /// 4. Apply predicate to each route
  /// 
  /// Use Cases:
  /// - Navigate back to a specific tab root
  /// - Return to home screen from deep in navigation
  /// - Custom back navigation logic
  /// 
  /// Error Handling:
  /// - Safe operation with context validation
  /// - Logs warnings for invalid attempts
  void popUntil(bool Function(Route<dynamic>) predicate) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      _logger.warning('Cannot pop until: No context available');
      return;
    }

    _logger.logNavigation('PopUntil');
    Navigator.popUntil(context, predicate);
  }

  /// Check if navigation can pop
  /// 
  /// Determines whether the current navigation stack allows popping,
  /// which means there's at least one previous route available.
  /// This is useful for conditionally showing back buttons or
  /// preventing invalid navigation attempts.
  /// 
  /// Algorithm:
  /// 1. Check if context is available
  /// 2. Use Navigator.canPop to check stack state
  /// 3. Return boolean result
  /// 
  /// Performance:
  /// - Direct call to Navigator.canPop
  /// - Minimal overhead
  /// 
  /// Returns:
  /// - true if pop is possible, false otherwise
  bool canPop() {
    final context = navigatorKey.currentContext;
    if (context == null) return false;
    return Navigator.canPop(context);
  }
}