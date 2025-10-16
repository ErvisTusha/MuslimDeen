/// Advanced prayer state management with periodic updates and granular selectors
///
/// This file implements a comprehensive prayer state management system that provides
/// real-time prayer tracking, automatic updates, and granular state selectors for
/// optimal UI performance. It includes both prayer time tracking and completion
/// status management.
///
/// Architecture Notes:
/// - Uses Notifier pattern for complex state management with controlled mutations
/// - Implements periodic updates with adaptive intervals
/// - Provides granular selectors to prevent unnecessary widget rebuilds
/// - Includes comprehensive error handling and logging
/// - Separates concerns between prayer times and completion tracking

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';

/// Immutable state class for prayer-related data
///
/// This class encapsulates all prayer-related state including current/next prayers,
/// timing information, loading states, and error handling. It's designed to be
/// immutable and provides equality checking for efficient state comparisons.
///
/// State Properties:
/// - currentPrayer: Name of the currently active prayer
/// - nextPrayer: Name of the next upcoming prayer
/// - nextPrayerTime: DateTime when the next prayer begins
/// - lastUpdateTime: When the state was last updated
/// - isLoading: Whether prayer data is being calculated
/// - error: Any error that occurred during state updates
/// - prayerTimes: Map of all prayer times for the day
///
/// Performance Considerations:
/// - Implements proper equality operators to prevent unnecessary rebuilds
/// - Uses immutable state pattern for predictability
/// - Provides copyWith method for efficient state updates
/// - Includes toString for debugging purposes
class PrayerState {
  final String currentPrayer;
  final String nextPrayer;
  final DateTime? nextPrayerTime;
  final DateTime? lastUpdateTime;
  final bool isLoading;
  final String? error;
  final Map<String, DateTime?> prayerTimes;

  const PrayerState({
    required this.currentPrayer,
    required this.nextPrayer,
    this.nextPrayerTime,
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
    this.prayerTimes = const {},
  });

  /// Creates a new PrayerState with updated values
  ///
  /// This method enables immutable state updates by creating a new state
  /// instance with only the specified properties changed. It's the primary
  /// way to update state in the notifier.
  ///
  /// Parameters:
  /// - currentPrayer: New current prayer name (optional)
  /// - nextPrayer: New next prayer name (optional)
  /// - nextPrayerTime: New next prayer time (optional)
  /// - lastUpdateTime: New last update timestamp (optional)
  /// - isLoading: New loading state (optional)
  /// - error: New error message (optional)
  /// - prayerTimes: New prayer times map (optional)
  ///
  /// Returns: New PrayerState instance with updated values
  PrayerState copyWith({
    String? currentPrayer,
    String? nextPrayer,
    DateTime? nextPrayerTime,
    DateTime? lastUpdateTime,
    bool? isLoading,
    String? error,
    Map<String, DateTime?>? prayerTimes,
  }) {
    return PrayerState(
      currentPrayer: currentPrayer ?? this.currentPrayer,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      prayerTimes: prayerTimes ?? this.prayerTimes,
    );
  }

  /// Equality operator for state comparison
  ///
  /// Implements deep equality checking to determine if two PrayerState
  /// instances are equivalent. This is crucial for Riverpod's optimization
  /// to prevent unnecessary widget rebuilds.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerState &&
        other.currentPrayer == currentPrayer &&
        other.nextPrayer == nextPrayer &&
        other.nextPrayerTime == nextPrayerTime &&
        other.lastUpdateTime == lastUpdateTime &&
        other.isLoading == isLoading &&
        other.error == error &&
        mapEquals(other.prayerTimes, prayerTimes);
  }

  /// Hash code for state comparison
  ///
  /// Generates a consistent hash code based on all state properties.
  /// Used in conjunction with the equality operator for state comparisons.
  @override
  int get hashCode {
    return Object.hash(
      currentPrayer,
      nextPrayer,
      nextPrayerTime,
      lastUpdateTime,
      isLoading,
      error,
      prayerTimes,
    );
  }

  /// String representation for debugging
  ///
  /// Provides a human-readable representation of the state,
  /// useful for logging and debugging purposes.
  @override
  String toString() {
    return 'PrayerState(currentPrayer: $currentPrayer, nextPrayer: $nextPrayer, nextPrayerTime: $nextPrayerTime, isLoading: $isLoading, error: $error)';
  }
}

/// Notifier for managing prayer state with periodic updates
///
/// This class implements the business logic for prayer state management,
/// including initialization, periodic updates, and error handling. It uses
/// a timer-based approach to keep prayer times current throughout the day.
///
/// Architecture Pattern: Notifier (Riverpod)
///
/// Key Features:
/// - Automatic periodic updates every minute
/// - Error handling with graceful degradation
/// - Performance optimization by checking state changes
/// - Comprehensive logging for debugging
/// - Manual refresh capability
///
/// Dependencies:
/// - PrayerService: For prayer calculations and current/next prayer detection
/// - LoggerService: For comprehensive logging
/// - AppSettings: For prayer calculation parameters
///
/// Lifecycle:
/// 1. build(): Creates initial empty state
/// 2. initialize(): Sets up periodic updates and loads initial data
/// 3. Periodic updates: Runs every minute to keep state current
/// 4. dispose(): Cleans up timer resources
class PrayerStateNotifier extends riverpod.Notifier<PrayerState> {
  final PrayerService _prayerService;
  final LoggerService _logger;
  Timer? _updateTimer;

  /// Constructor with dependency injection
  ///
  /// Parameters:
  /// - prayerService: Service for prayer calculations
  /// - loggerService: Service for logging operations
  PrayerStateNotifier({
    required PrayerService prayerService,
    required LoggerService loggerService,
  }) : _prayerService = prayerService,
       _logger = loggerService;

  /// Builds the initial prayer state
  ///
  /// Called by Riverpod when the provider is first created. Returns
  /// an empty state that will be populated by the initialize method.
  ///
  /// Returns: Initial PrayerState with empty prayer names
  @override
  PrayerState build() {
    return const PrayerState(currentPrayer: '', nextPrayer: '');
  }

  /// Initialize prayer state with settings and start periodic updates
  ///
  /// This method should be called after the provider is created to
  /// initialize the state with actual prayer data and start the
  /// automatic update mechanism.
  ///
  /// Parameters:
  /// - settings: Application settings for prayer calculations
  ///
  /// Side Effects:
  /// - Updates state with current prayer information
  /// - Starts periodic timer for automatic updates
  /// - Logs initialization status
  /// - Handles and logs any initialization errors
  Future<void> initialize(AppSettings settings) async {
    try {
      // Set loading state and clear any previous errors
      state = state.copyWith(isLoading: true, error: null);

      // Load initial prayer data
      await _updatePrayerState(settings);

      // Start periodic updates to keep prayer times current
      _startPeriodicUpdates(settings);

      _logger.info('Prayer state initialized');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize prayer state',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Update prayer state with current data
  ///
  /// Public method to manually trigger a state update. This can be
  /// called by UI components or other services when a refresh is needed.
  ///
  /// Parameters:
  /// - settings: Current application settings
  ///
  /// Error Handling:
  /// - Catches and logs any errors during update
  /// - Updates state with error information
  Future<void> updatePrayerState(AppSettings settings) async {
    try {
      await _updatePrayerState(settings);
    } catch (e, s) {
      _logger.error(
        'Failed to update prayer state',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      state = state.copyWith(error: e.toString());
    }
  }

  /// Internal method to update prayer state
  Future<void> _updatePrayerState(AppSettings settings) async {
    // Get current prayer information
    final currentPrayer = _prayerService.getCurrentPrayer();
    final nextPrayer = _prayerService.getNextPrayer();
    final nextPrayerTime = await _prayerService.getNextPrayerTime();

    // Get all prayer times
    final prayerTimes = await _prayerService.calculatePrayerTimesForToday(
      settings,
    );
    final prayerTimesMap = <String, DateTime?>{};

    prayerTimesMap['fajr'] = prayerTimes.fajr;
    prayerTimesMap['sunrise'] = prayerTimes.sunrise;
    prayerTimesMap['dhuhr'] = prayerTimes.dhuhr;
    prayerTimesMap['asr'] = prayerTimes.asr;
    prayerTimesMap['maghrib'] = prayerTimes.maghrib;
    prayerTimesMap['isha'] = prayerTimes.isha;

    // Check if state actually changed
    final newState = PrayerState(
      currentPrayer: currentPrayer,
      nextPrayer: nextPrayer,
      nextPrayerTime: nextPrayerTime,
      lastUpdateTime: DateTime.now(),
      isLoading: false,
      error: null,
      prayerTimes: prayerTimesMap,
    );

    if (state != newState) {
      state = newState;
      _logger.debug(
        'Prayer state updated',
        data: {
          'currentPrayer': currentPrayer,
          'nextPrayer': nextPrayer,
          'nextPrayerTime': nextPrayerTime?.toIso8601String(),
        },
      );
    }
  }

  /// Start periodic updates with adaptive intervals
  void _startPeriodicUpdates(AppSettings settings) {
    _updateTimer?.cancel();

    // Adaptive interval based on time to next prayer
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!state.isLoading) {
        await updatePrayerState(settings);
      }
    });
  }

  /// Refresh prayer state immediately
  Future<void> refresh(AppSettings settings) async {
    await updatePrayerState(settings);
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for prayer state
final prayerStateProvider =
    riverpod.NotifierProvider<PrayerStateNotifier, PrayerState>(() {
      return PrayerStateNotifier(
        prayerService: locator<PrayerService>(),
        loggerService: locator<LoggerService>(),
      );
    });

/// Selectors for specific prayer state properties
final currentPrayerProvider = Provider<String>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.currentPrayer));
});

final nextPrayerProvider = Provider<String>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.nextPrayer));
});

final nextPrayerTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.nextPrayerTime));
});

final prayerTimesProvider = Provider<Map<String, DateTime?>>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.prayerTimes));
});

final prayerLoadingProvider = Provider<bool>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.isLoading));
});

final prayerErrorProvider = Provider<String?>((ref) {
  return ref.watch(prayerStateProvider.select((state) => state.error));
});

/// State class for prayer completion tracking
@immutable
class PrayerCompletionState {
  final Map<String, bool> completedPrayers;
  final DateTime? lastUpdateTime;
  final bool isLoading;
  final String? error;

  const PrayerCompletionState({
    this.completedPrayers = const {},
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
  });

  PrayerCompletionState copyWith({
    Map<String, bool>? completedPrayers,
    DateTime? lastUpdateTime,
    bool? isLoading,
    String? error,
  }) {
    return PrayerCompletionState(
      completedPrayers: completedPrayers ?? this.completedPrayers,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrayerCompletionState &&
        mapEquals(other.completedPrayers, completedPrayers) &&
        other.lastUpdateTime == lastUpdateTime &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      mapEquals(completedPrayers, const {}),
      lastUpdateTime,
      isLoading,
      error,
    );
  }
}

/// Provider for prayer completion state
class PrayerCompletionNotifier
    extends riverpod.Notifier<PrayerCompletionState> {
  final LoggerService _logger;

  PrayerCompletionNotifier({required LoggerService loggerService})
    : _logger = loggerService;

  @override
  PrayerCompletionState build() {
    return const PrayerCompletionState();
  }

  /// Update completion status for a specific prayer
  Future<void> updatePrayerCompletion(
    String prayerName,
    bool isCompleted,
  ) async {
    try {
      final newCompletedPrayers = Map<String, bool>.from(
        state.completedPrayers,
      );
      newCompletedPrayers[prayerName] = isCompleted;

      state = state.copyWith(
        completedPrayers: newCompletedPrayers,
        lastUpdateTime: DateTime.now(),
      );

      _logger.debug(
        'Prayer completion updated',
        data: {'prayerName': prayerName, 'isCompleted': isCompleted},
      );
    } catch (e, s) {
      _logger.error(
        'Failed to update prayer completion',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear all completion data
  void clearCompletionData() {
    state = const PrayerCompletionState();
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Provider for prayer completion state
final prayerCompletionProvider =
    riverpod.NotifierProvider<PrayerCompletionNotifier, PrayerCompletionState>(
      () {
        final loggerService = locator<LoggerService>();

        return PrayerCompletionNotifier(loggerService: loggerService);
      },
    );

/// Selector for specific prayer completion status
final prayerCompletionStatusProvider = Provider.family<bool, String>((
  ref,
  prayerName,
) {
  return ref.watch(
    prayerCompletionProvider.select(
      (state) => state.completedPrayers[prayerName] ?? false,
    ),
  );
});
