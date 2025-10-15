import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as riverpod;

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';

/// State class for prayer-related data
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

  @override
  String toString() {
    return 'PrayerState(currentPrayer: $currentPrayer, nextPrayer: $nextPrayer, nextPrayerTime: $nextPrayerTime, isLoading: $isLoading, error: $error)';
  }
}

/// Provider for prayer state management
class PrayerStateNotifier extends riverpod.Notifier<PrayerState> {
  final PrayerService _prayerService;
  final LoggerService _logger;
  Timer? _updateTimer;

  PrayerStateNotifier({
    required PrayerService prayerService,
    required LoggerService loggerService,
  }) : _prayerService = prayerService,
       _logger = loggerService;

  @override
  PrayerState build() {
    return const PrayerState(currentPrayer: '', nextPrayer: '');
  }

  /// Initialize prayer state
  Future<void> initialize(AppSettings settings) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _updatePrayerState(settings);

      // Start periodic updates
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
