/// Central settings management notifier using mixin composition
///
/// This class implements the main settings state management using a modular
/// mixin-based architecture. It combines functionality from multiple mixins
/// to provide comprehensive settings management including persistence,
/// notifications, and prayer calculations.
///
/// Architecture Pattern: Notifier with Mixin Composition
///
/// Why Mixin Composition:
/// - Separates concerns into focused, reusable mixins
/// - Allows for modular testing of individual settings features
/// - Enables clean code organization by functionality
/// - Provides flexibility to add new settings features without modifying core
/// - Follows single responsibility principle for each mixin
///
/// Mixin Responsibilities:
/// - SettingsPersistenceMixin: Storage, loading, and saving of settings
/// - NotificationSchedulingMixin: Prayer notifications and permissions
/// - PrayerCalculationMixin: Prayer calculation parameters and methods
///
/// State Management:
/// - Uses Notifier<AppSettings> for mutable state with controlled access
/// - Implements both synchronous and asynchronous initialization patterns
/// - Provides graceful fallback to defaults when storage is unavailable
/// - Handles hot reload scenarios with proper state restoration
///
/// Initialization Strategy:
/// 1. Synchronous load for immediate UI responsiveness
/// 2. Asynchronous initialization for complete feature setup
/// 3. Permission listener setup for notification status updates

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/settings_notification_mixin.dart';
import 'package:muslim_deen/providers/settings_persistence_mixin.dart';
import 'package:muslim_deen/providers/settings_prayer_mixin.dart';

/// Main settings notifier with mixin-based architecture
///
/// This class serves as the central point for all settings-related operations
/// in the application. It combines three key mixins to provide comprehensive
/// settings management while maintaining clean separation of concerns.
///
/// Provider Type: NotifierProvider<SettingsNotifier, AppSettings>
///
/// State Flow:
/// 1. build(): Creates initial state from synchronous storage or defaults
/// 2. Async initialization completes full setup and persistence
/// 3. State changes trigger appropriate side effects through mixins
/// 4. Settings are automatically persisted when changed
///
/// Performance Considerations:
/// - Synchronous loading prevents UI delays on app start
/// - Debounced saving reduces storage I/O for rapid changes
/// - Permission listeners update state only when necessary
/// - Graceful handling of storage unavailability
///
/// Error Handling:
/// - Falls back to defaults if storage is corrupted or unavailable
/// - Logs errors without crashing the application
/// - Maintains functional app even with partial settings loss
class SettingsNotifier extends Notifier<AppSettings>
    with
        SettingsPersistenceMixin,
        NotificationSchedulingMixin,
        PrayerCalculationMixin {
  
  /// Builds the initial settings state
  ///
  /// Implements a two-phase initialization strategy:
  /// 1. Synchronous phase: Loads settings immediately if storage is ready
  /// 2. Asynchronous phase: Completes full initialization after provider build
  ///
  /// This approach ensures the UI is responsive immediately while still
  /// providing full functionality after async operations complete.
  ///
  /// Returns: AppSettings instance from storage or defaults
  @override
  AppSettings build() {
    // Phase 1: Synchronous loading for immediate UI responsiveness
    // This prevents UI delays on app startup by providing settings immediately
    final loadedSettings = loadSettingsSync();

    // Phase 2: Asynchronous initialization for complete feature setup
    // Scheduled to run after the provider is fully built to avoid blocking
    Future.microtask(() {
      initializeSettings();
      initializePermissionListener();
    });

    // Return loaded settings if available, otherwise use defaults
    // This ensures the app always has valid settings even if storage fails
    return loadedSettings ?? AppSettings.defaults;
  }

  /// Disposes resources and cleanup operations
  ///
  /// Called when the provider is no longer needed. Properly cleans up
  /// resources from mixins to prevent memory leaks and background operations.
  ///
  /// Cleanup Operations:
  /// - Disposes persistence resources (timers, streams)
  /// - Cancels notification permission listeners
  /// - Stops any ongoing background operations
  void dispose() {
    disposePersistence();
    disposeNotifications();
  }
}
