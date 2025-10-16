/// Service providers for dependency injection in the MuslimDeen application
///
/// This file contains Riverpod providers that expose application services
/// throughout the dependency graph. It bridges the service locator pattern
/// with Riverpod's reactive state management, allowing services to be
/// both injectable and observable.
///
/// Architecture Pattern: Service Locator + Riverpod Provider Bridge
///
/// Why This Approach:
/// - Combines the flexibility of service location with Riverpod's reactivity
/// - Enables easy testing through provider overriding
/// - Provides singleton behavior for services
/// - Allows for lazy initialization of services
/// - Maintains separation of concerns between service creation and usage
///
/// Service Lifecycle:
/// - Services are created on first access through the service locator
/// - Provider ensures services remain singletons throughout the app
/// - Services are initialized with their required dependencies
/// - Proper cleanup is handled by individual services
///
/// Testing Considerations:
/// - All providers can be overridden in tests using ProviderScope
/// - Mock services can be injected for isolated unit testing
/// - Service locator can be replaced with test doubles

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/services/dhikr_reminder_service.dart';
import 'package:muslim_deen/services/audio_player_service.dart';

/// Provider for the LoggerService instance
///
/// Exposes the centralized logging service throughout the application.
/// This service handles all logging operations with different log levels
/// and output formatting based on the build configuration.
///
/// Provider Type: Provider<LoggerService>
///
/// Service Responsibilities:
/// - Centralized logging with different levels (debug, info, warning, error)
/// - Conditional output formatting (simple in debug, pretty in special sessions)
/// - Performance monitoring and log aggregation
/// - Error tracking and crash reporting integration
///
/// Usage Example:
/// ```dart
/// final logger = ref.read(loggerServiceProvider);
/// logger.info('User action completed');
/// ```
///
/// Testing Override:
/// ```dart
/// ProviderScope(
///   overrides: [
///     loggerServiceProvider.overrideWithValue(MockLoggerService()),
///   ],
///   child: MyApp(),
/// );
/// ```
final loggerServiceProvider = Provider<LoggerService>(
  (ref) => locator<LoggerService>(),
);

/// Provider for the PrayerService instance
///
/// Exposes the core prayer calculation and management service.
/// This service handles all prayer-related calculations including
/// prayer times, current/next prayer detection, and offset calculations.
///
/// Provider Type: Provider<PrayerService>
///
/// Service Responsibilities:
/// - Prayer times calculation based on location and settings
/// - Current prayer detection
/// - Next prayer time calculation
/// - Prayer offset handling for custom adjustments
/// - Islamic calendar integration
///
/// Dependencies:
/// - LocationService (for geographical coordinates)
/// - Settings (for calculation methods and parameters)
/// - LoggerService (for operation logging)
///
/// Performance Considerations:
/// - Implements caching for prayer calculations
/// - Uses optimized algorithms for time-based calculations
/// - Handles edge cases for extreme latitudes and time zones
final prayerServiceProvider = Provider<PrayerService>(
  (ref) => locator<PrayerService>(),
);

/// Provider for the StorageService instance
///
/// Exposes the persistent storage service for application data.
/// This service handles all local data persistence including
/// user preferences, cached data, and application state.
///
/// Provider Type: Provider<StorageService>
///
/// Service Responsibilities:
/// - Persistent key-value storage for user preferences
/// - JSON serialization/deserialization for complex objects
/// - Secure storage for sensitive data
/// - Cache management with TTL support
/// - Storage quota monitoring and cleanup
///
/// Data Types Stored:
/// - User settings and preferences
/// - Cached prayer times
/// - Application state
/// - User-generated content (prayer history, etc.)
///
/// Error Handling:
/// - Graceful degradation when storage is unavailable
/// - Automatic data recovery from corrupted storage
/// - Backup and restore functionality
final storageServiceProvider = Provider<StorageService>(
  (ref) => locator<StorageService>(),
);

/// Provider for the NotificationService instance
///
/// Exposes the notification management service for prayer reminders
/// and application alerts. This service handles all aspects of
/// notification scheduling, permission management, and delivery.
///
/// Provider Type: Provider<NotificationService>
///
/// Service Responsibilities:
/// - Prayer notification scheduling and management
/// - Permission handling and status monitoring
/// - Custom notification sounds and vibration patterns
/// - Notification grouping and stacking
/// - Background notification processing
///
/// Platform Integration:
/// - iOS: Uses UNUserNotificationCenter for local notifications
/// - Android: Uses NotificationManagerCompat with channel management
/// - Handles platform-specific notification behaviors
///
/// Performance Features:
/// - Batch notification updates to reduce system load
/// - Intelligent notification timing based on prayer schedules
/// - Adaptive notification behavior based on user engagement
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => locator<NotificationService>(),
);

/// Provider for the DatabaseService instance
///
/// Exposes the local database service for structured data storage.
/// This service manages the SQLite database used for storing
/// user data, prayer history, and application analytics.
///
/// Provider Type: Provider<DatabaseService>
///
/// Service Responsibilities:
/// - SQLite database management and operations
/// - Schema migrations and versioning
/// - Transaction management for data consistency
/// - Query optimization and indexing
/// - Data backup and synchronization
///
/// Data Tables Managed:
/// - Prayer history and completion records
/// - User preferences and settings
/// - Application analytics and usage metrics
/// - Cached external data for offline support
///
/// Performance Optimizations:
/// - Connection pooling for concurrent access
/// - Prepared statement caching
/// - Lazy loading for large datasets
/// - Automatic vacuuming and maintenance
final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => locator<DatabaseService>(),
);

/// Provider for the DhikrReminderService instance
///
/// Exposes the dhikr (remembrance) reminder service for spiritual
/// notifications and religious prompts. This service manages
/// customizable spiritual reminders throughout the day.
///
/// Provider Type: Provider<DhikrReminderService>
///
/// Service Responsibilities:
/// - Scheduled dhikr reminders throughout the day
/// - Customizable reminder intervals and content
/// - Integration with prayer times for contextual reminders
/// - Spiritual progress tracking
/// - Islamic content management
///
/// Features:
/// - Configurable reminder frequencies (hourly, daily, custom)
/// - Different dhikr categories and content types
/// - Intelligent timing based on Islamic prayer schedule
/// - Progress tracking and streak maintenance
///
/// Integration Points:
/// - NotificationService for alert delivery
/// - StorageService for preference persistence
/// - PrayerService for contextual timing
final dhikrReminderServiceProvider = Provider<DhikrReminderService>(
  (ref) => locator<DhikrReminderService>(),
);

/// Provider for the AudioPlayerService instance
///
/// Exposes the audio playback service for adhan (call to prayer),
/// religious audio content, and application sounds. This service
/// manages all audio playback with proper lifecycle handling.
///
/// Provider Type: Provider<AudioPlayerService>
///
/// Service Responsibilities:
/// - Adhan audio playback for prayer notifications
/// - Religious audio content management
/// - Application sound effects and feedback
/// - Audio session management with system integration
/// - Background playback handling
///
/// Audio Features:
/// - Multiple adhan audio options (Makkah, Madinah, etc.)
/// - Custom audio file support
/// - Volume normalization and crossfading
/// - Audio focus management with other apps
/// - Bluetooth and audio routing support
///
/// Platform Integration:
/// - iOS: Uses AVAudioSession for proper system integration
/// - Android: Uses AudioManager with focus handling
/// - Handles platform-specific audio behaviors
final audioPlayerServiceProvider = Provider<AudioPlayerService>(
  (ref) => locator<AudioPlayerService>(),
);
