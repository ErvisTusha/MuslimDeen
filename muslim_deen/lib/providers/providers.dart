/// Core providers for the MuslimDeen application
///
/// This file contains the fundamental providers that manage core application state,
/// including settings, fasting services, and Ramadan detection. These providers are
/// the foundation of the application's state management architecture using Riverpod.
///
/// Architecture Notes:
/// - Uses NotifierProvider for settings state management with mutable state
/// - Uses FutureProvider for async service initialization
/// - Leverages the service locator pattern for dependency injection
/// - Implements proper separation of concerns between UI and business logic

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/settings_notifier.dart';
import 'package:muslim_deen/service_locator.dart';
import '../services/fasting_service.dart';

/// Settings provider using NotifierProvider pattern
///
/// This provider manages the application's settings state using a NotifierProvider.
/// The SettingsNotifier handles state mutations and persistence through mixins.
///
/// Provider Type: NotifierProvider<SettingsNotifier, AppSettings>
///
/// Why NotifierProvider was chosen:
/// - Provides mutable state management with controlled mutations
/// - Allows complex state logic through the notifier pattern
/// - Integrates seamlessly with Riverpod's reactivity system
/// - Supports dependency injection for services used by the notifier
///
/// State Management:
/// - Initial state is loaded synchronously during build if storage is ready
/// - Asynchronous initialization is scheduled after provider creation
/// - State persists across app restarts through the persistence mixin
/// - Settings changes trigger appropriate side effects (notifications, recalculation)
///
/// Dependencies:
/// - SettingsNotifier (with mixins for persistence, notifications, and prayer calculations)
/// - StorageService (for persistence)
/// - NotificationService (for prayer notifications)
/// - Various other services for settings-specific operations
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Fasting service provider for async service initialization
///
/// This provider asynchronously initializes and provides the FastingService instance.
/// It uses the service locator pattern to resolve dependencies and handles the
/// asynchronous nature of service initialization.
///
/// Provider Type: FutureProvider<FastingService>
///
/// Why FutureProvider was chosen:
/// - Handles asynchronous service initialization gracefully
/// - Provides loading and error states automatically
/// - Ensures service is fully initialized before being used
/// - Integrates with Riverpod's async state management
///
/// State Lifecycle:
/// - Loading: Service is being initialized through the service locator
/// - Data: Service instance is ready for use
/// - Error: Initialization failed (handled by consumer widgets)
///
/// Dependencies:
/// - Service locator for dependency injection
/// - FastingService implementation
///
/// Usage Example:
/// ```dart
/// final fastingServiceAsync = ref.watch(fastingServiceProvider);
/// return fastingServiceAsync.when(
///   data: (service) => Text(service.getRamadanInfo()),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final fastingServiceProvider = FutureProvider<FastingService>((ref) async {
  return await locator.getAsync<FastingService>();
});

/// Ramadan detection provider
///
/// This provider determines whether the current date is within Ramadan by checking
/// the fasting service's Ramadan countdown information. It automatically updates
/// based on the current date and provides a boolean state for UI components.
///
/// Provider Type: FutureProvider<bool>
///
/// Why FutureProvider was chosen:
/// - Handles async Ramadan calculation which may involve complex date logic
/// - Provides loading state while Ramadan status is being determined
/// - Automatically handles errors in Ramadan detection
/// - Reacts to date changes through dependency on fasting service
///
/// State Logic:
/// - Watches the fastingServiceProvider for Ramadan calculation data
/// - Extracts the 'isRamadan' flag from the countdown information
/// - Returns true if current date is within Ramadan, false otherwise
///
/// Dependencies:
/// - fastingServiceProvider (for Ramadan calculation)
/// - FastingService.getRamadanCountdown() method
///
/// Usage Example:
/// ```dart
/// final isRamadanAsync = ref.watch(isRamadanProvider);
/// return isRamadanAsync.when(
///   data: (isRamadan) => isRamadan ? RamadhanBanner() : NormalBanner(),
///   loading: () => SizedBox(),
///   error: (error, stack) => Text('Error detecting Ramadan'),
/// );
/// ```
final isRamadanProvider = FutureProvider<bool>((ref) async {
  final fastingService = await ref.watch(fastingServiceProvider.future);
  final ramadanInfo = fastingService.getRamadanCountdown();
  return ramadanInfo['isRamadan'] == true;
});
