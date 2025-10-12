import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';

/// Optimized provider for prayer state with granular selectors
class OptimizedPrayerStateNotifier extends Notifier<OptimizedPrayerState> {
  late final PrayerService _prayerService;
  late final LoggerService _logger;
  late final PerformanceMonitoringService _performanceService;
  Timer? _updateTimer;
  Timer? _debounceTimer;

  // Cache for performance optimization
  String _cachedCurrentPrayer = '';
  String _cachedNextPrayer = '';
  DateTime? _cachedNextPrayerTime;
  DateTime? _lastStateUpdate;

  @override
  OptimizedPrayerState build() {
    _prayerService = locator<PrayerService>();
    _logger = locator<LoggerService>();
    _performanceService = locator<PerformanceMonitoringService>();

    // Start with empty state
    return const OptimizedPrayerState(
      currentPrayer: '',
      nextPrayer: '',
      nextPrayerTime: null,
      isLoading: false,
    );
  }

  /// Initialize prayer state with settings
  Future<void> initialize(AppSettings settings) async {
    final trackingId = _performanceService.startWidgetBuildTracking(
      'OptimizedPrayerInit',
    );

    try {
      state = state.copyWith(isLoading: true);
      await _updatePrayerState(settings);
      _startOptimizedUpdates(settings);

      _logger.info('Optimized prayer state initialized');
    } catch (e, s) {
      _logger.error(
        'Failed to initialize optimized prayer state',
        error: e,
        stackTrace: s,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _performanceService.endWidgetBuildTracking(trackingId);
    }
  }

  /// Update prayer state with smart caching
  Future<void> _updatePrayerState(AppSettings settings) async {
    final trackingId = _performanceService.startWidgetBuildTracking(
      'PrayerStateUpdate',
    );

    try {
      final currentPrayer = _prayerService.getCurrentPrayer();
      final nextPrayer = _prayerService.getNextPrayer();
      final nextPrayerTime = await _prayerService.getNextPrayerTime();

      // Only update state if values actually changed
      final bool hasChanged =
          _cachedCurrentPrayer != currentPrayer ||
          _cachedNextPrayer != nextPrayer ||
          _cachedNextPrayerTime != nextPrayerTime;

      if (hasChanged) {
        _cachedCurrentPrayer = currentPrayer;
        _cachedNextPrayer = nextPrayer;
        _cachedNextPrayerTime = nextPrayerTime;
        _lastStateUpdate = DateTime.now();

        state = OptimizedPrayerState(
          currentPrayer: currentPrayer,
          nextPrayer: nextPrayer,
          nextPrayerTime: nextPrayerTime,
          lastUpdateTime: _lastStateUpdate,
          isLoading: false,
        );

        _logger.debug(
          'Prayer state updated',
          data: {
            'currentPrayer': currentPrayer,
            'nextPrayer': nextPrayer,
            'nextPrayerTime': nextPrayerTime?.toIso8601String(),
          },
        );
      }
    } catch (e, s) {
      _logger.error('Failed to update prayer state', error: e, stackTrace: s);
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _performanceService.endWidgetBuildTracking(trackingId);
    }
  }

  /// Start optimized periodic updates with adaptive intervals
  void _startOptimizedUpdates(AppSettings settings) {
    _updateTimer?.cancel();

    // Adaptive interval: check more frequently around prayer times
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!state.isLoading) {
        await _debouncedUpdate(settings);
      }
    });
  }

  /// Debounced update to prevent excessive rebuilds
  Future<void> _debouncedUpdate(AppSettings settings) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 5), () async {
      await _updatePrayerState(settings);
    });
  }

  /// Refresh prayer state immediately
  Future<void> refresh(AppSettings settings) async {
    _debounceTimer?.cancel();
    await _updatePrayerState(settings);
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  void dispose() {
    _updateTimer?.cancel();
    _debounceTimer?.cancel();
  }
}

/// Optimized prayer state with better performance characteristics
@immutable
class OptimizedPrayerState {
  final String currentPrayer;
  final String nextPrayer;
  final DateTime? nextPrayerTime;
  final DateTime? lastUpdateTime;
  final bool isLoading;
  final String? error;

  const OptimizedPrayerState({
    required this.currentPrayer,
    required this.nextPrayer,
    this.nextPrayerTime,
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
  });

  OptimizedPrayerState copyWith({
    String? currentPrayer,
    String? nextPrayer,
    DateTime? nextPrayerTime,
    DateTime? lastUpdateTime,
    bool? isLoading,
    String? error,
  }) {
    return OptimizedPrayerState(
      currentPrayer: currentPrayer ?? this.currentPrayer,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      nextPrayerTime: nextPrayerTime ?? this.nextPrayerTime,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimizedPrayerState &&
        other.currentPrayer == currentPrayer &&
        other.nextPrayer == nextPrayer &&
        other.nextPrayerTime == nextPrayerTime &&
        other.lastUpdateTime == lastUpdateTime &&
        other.isLoading == isLoading &&
        other.error == error;
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
    );
  }
}

/// Provider for optimized prayer state
final optimizedPrayerStateProvider =
    NotifierProvider<OptimizedPrayerStateNotifier, OptimizedPrayerState>(
      OptimizedPrayerStateNotifier.new,
    );

/// Granular selectors for optimized performance
final currentPrayerSelectorProvider = Provider<String>((ref) {
  return ref.watch(
    optimizedPrayerStateProvider.select((state) => state.currentPrayer),
  );
});

final nextPrayerSelectorProvider = Provider<String>((ref) {
  return ref.watch(
    optimizedPrayerStateProvider.select((state) => state.nextPrayer),
  );
});

final nextPrayerTimeSelectorProvider = Provider<DateTime?>((ref) {
  return ref.watch(
    optimizedPrayerStateProvider.select((state) => state.nextPrayerTime),
  );
});

final prayerLoadingSelectorProvider = Provider<bool>((ref) {
  return ref.watch(
    optimizedPrayerStateProvider.select((state) => state.isLoading),
  );
});

final prayerErrorSelectorProvider = Provider<String?>((ref) {
  return ref.watch(optimizedPrayerStateProvider.select((state) => state.error));
});

/// Optimized prayer completion state notifier
class OptimizedPrayerCompletionNotifier
    extends Notifier<OptimizedPrayerCompletionState> {
  late final PrayerHistoryService _prayerHistoryService;
  late final LoggerService _logger;
  late final PerformanceMonitoringService _performanceService;

  // Cache for prayer completion status
  final Map<String, bool> _completionCache = {};
  DateTime? _lastCacheUpdate;

  @override
  OptimizedPrayerCompletionState build() {
    _prayerHistoryService = locator<PrayerHistoryService>();
    _logger = locator<LoggerService>();
    _performanceService = locator<PerformanceMonitoringService>();

    return const OptimizedPrayerCompletionState(
      completedPrayers: {},
      isLoading: false,
    );
  }

  /// Load prayer completion status with caching
  Future<void> loadCompletionStatus() async {
    final trackingId = _performanceService.startWidgetBuildTracking(
      'LoadPrayerCompletion',
    );

    try {
      state = state.copyWith(isLoading: true);

      // Check if cache is still valid (5 minutes)
      final now = DateTime.now();
      if (_lastCacheUpdate != null &&
          now.difference(_lastCacheUpdate!).inMinutes < 5) {
        state = state.copyWith(
          completedPrayers: Map<String, bool>.from(_completionCache),
          isLoading: false,
        );
        return;
      }

      // Load fresh data
      final completedPrayers = <String, bool>{};
      for (final prayerName in [
        'fajr',
        'sunrise',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
      ]) {
        final isCompleted = await _prayerHistoryService.isPrayerCompletedToday(
          prayerName,
        );
        completedPrayers[prayerName] = isCompleted;
      }

      // Update cache
      _completionCache.clear();
      _completionCache.addAll(completedPrayers);
      _lastCacheUpdate = now;

      state = state.copyWith(
        completedPrayers: completedPrayers,
        isLoading: false,
      );

      _logger.debug('Prayer completion status loaded');
    } catch (e, s) {
      _logger.error(
        'Failed to load prayer completion status',
        error: e,
        stackTrace: s,
      );
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _performanceService.endWidgetBuildTracking(trackingId);
    }
  }

  /// Update completion status for a specific prayer
  Future<void> updatePrayerCompletion(
    String prayerName,
    bool isCompleted,
  ) async {
    final trackingId = _performanceService.startWidgetBuildTracking(
      'UpdatePrayerCompletion',
    );

    try {
      if (isCompleted) {
        await _prayerHistoryService.markPrayerCompleted(prayerName);
      } else {
        await _prayerHistoryService.unmarkPrayerCompleted(prayerName);
      }

      // Update cache and state
      _completionCache[prayerName] = isCompleted;
      final newCompletedPrayers = Map<String, bool>.from(
        state.completedPrayers,
      );
      newCompletedPrayers[prayerName] = isCompleted;

      state = state.copyWith(completedPrayers: newCompletedPrayers);

      _logger.debug(
        'Prayer completion updated',
        data: {'prayerName': prayerName, 'isCompleted': isCompleted},
      );
    } catch (e, s) {
      _logger.error(
        'Failed to update prayer completion',
        error: e,
        stackTrace: s,
      );
      state = state.copyWith(error: e.toString());
    } finally {
      _performanceService.endWidgetBuildTracking(trackingId);
    }
  }

  /// Clear completion cache
  void clearCache() {
    _completionCache.clear();
    _lastCacheUpdate = null;
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }
}

/// Optimized prayer completion state
@immutable
class OptimizedPrayerCompletionState {
  final Map<String, bool> completedPrayers;
  final DateTime? lastUpdateTime;
  final bool isLoading;
  final String? error;

  const OptimizedPrayerCompletionState({
    this.completedPrayers = const {},
    this.lastUpdateTime,
    this.isLoading = false,
    this.error,
  });

  OptimizedPrayerCompletionState copyWith({
    Map<String, bool>? completedPrayers,
    DateTime? lastUpdateTime,
    bool? isLoading,
    String? error,
  }) {
    return OptimizedPrayerCompletionState(
      completedPrayers: completedPrayers ?? this.completedPrayers,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OptimizedPrayerCompletionState &&
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

/// Provider for optimized prayer completion state
final optimizedPrayerCompletionProvider = NotifierProvider<
  OptimizedPrayerCompletionNotifier,
  OptimizedPrayerCompletionState
>(OptimizedPrayerCompletionNotifier.new);

/// Selector for specific prayer completion status
final prayerCompletionSelectorProvider = Provider.family<bool, String>((
  ref,
  prayerName,
) {
  return ref.watch(
    optimizedPrayerCompletionProvider.select(
      (state) => state.completedPrayers[prayerName] ?? false,
    ),
  );
});

/// Provider for UI-specific state optimizations
class UIStateNotifier extends Notifier<UIState> {
  @override
  UIState build() {
    return const UIState(
      isRefreshing: false,
      lastRefreshTime: null,
      selectedTabIndex: 0,
    );
  }

  /// Set refreshing state
  void setRefreshing(bool isRefreshing) {
    if (state.isRefreshing != isRefreshing) {
      state = state.copyWith(
        isRefreshing: isRefreshing,
        lastRefreshTime: isRefreshing ? null : DateTime.now(),
      );
    }
  }

  /// Update selected tab index
  void setSelectedTabIndex(int index) {
    if (state.selectedTabIndex != index) {
      state = state.copyWith(selectedTabIndex: index);
    }
  }

  /// Trigger refresh with timestamp
  void triggerRefresh() {
    state = state.copyWith(isRefreshing: true, lastRefreshTime: DateTime.now());
  }

  /// Complete refresh
  void completeRefresh() {
    state = state.copyWith(
      isRefreshing: false,
      lastRefreshTime: DateTime.now(),
    );
  }
}

/// UI state for optimized rebuilds
@immutable
class UIState {
  final bool isRefreshing;
  final DateTime? lastRefreshTime;
  final int selectedTabIndex;

  const UIState({
    required this.isRefreshing,
    this.lastRefreshTime,
    required this.selectedTabIndex,
  });

  UIState copyWith({
    bool? isRefreshing,
    DateTime? lastRefreshTime,
    int? selectedTabIndex,
  }) {
    return UIState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UIState &&
        other.isRefreshing == isRefreshing &&
        other.lastRefreshTime == lastRefreshTime &&
        other.selectedTabIndex == selectedTabIndex;
  }

  @override
  int get hashCode {
    return Object.hash(isRefreshing, lastRefreshTime, selectedTabIndex);
  }
}

/// Provider for UI state
final uiStateProvider = NotifierProvider<UIStateNotifier, UIState>(
  UIStateNotifier.new,
);

/// Selectors for UI state
final isRefreshingProvider = Provider<bool>((ref) {
  return ref.watch(uiStateProvider.select((state) => state.isRefreshing));
});

final lastRefreshTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(uiStateProvider.select((state) => state.lastRefreshTime));
});

final selectedTabIndexProvider = Provider<int>((ref) {
  return ref.watch(uiStateProvider.select((state) => state.selectedTabIndex));
});
