import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:flutter/scheduler.dart';

import 'package:flutter/widgets.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Performance monitoring service for tracking widget build times, frame rates,
/// and other performance metrics in the MuslimDeen app.
class PerformanceMonitoringService {
  final LoggerService _logger = locator<LoggerService>();

  // Frame rate monitoring
  Timer? _frameRateTimer;
  double _currentFrameRate = 0.0;
  double _averageFrameRate = 0.0;
  final List<double> _frameRateHistory = [];
  int _framesInCurrentSecond = 0;
  int _lastSecondTimestamp = 0;

  // Widget build time tracking
  final Map<String, List<int>> _widgetBuildTimes = {};
  final Map<String, int> _widgetBuildCounts = {};
  final Queue<Map<String, dynamic>> _recentBuilds = Queue();
  static const int _maxRecentBuilds = 100;

  // Performance metrics
  final Map<String, dynamic> _performanceMetrics = {};

  // Settings
  bool _isMonitoringEnabled = false;
  bool _isFrameRateMonitoringEnabled = false;
  bool _isWidgetBuildTrackingEnabled = false;

  /// Initialize performance monitoring with specified settings
  void initialize({
    bool enableMonitoring = kDebugMode,
    bool enableFrameRateMonitoring = kDebugMode,
    bool enableWidgetBuildTracking = kDebugMode,
  }) {
    _isMonitoringEnabled = enableMonitoring;
    _isFrameRateMonitoringEnabled = enableFrameRateMonitoring;
    _isWidgetBuildTrackingEnabled = enableWidgetBuildTracking;

    if (_isMonitoringEnabled) {
      _logger.info('Performance monitoring service initialized');

      if (_isFrameRateMonitoringEnabled) {
        _startFrameRateMonitoring();
      }
    }
  }

  /// Start monitoring frame rates
  void _startFrameRateMonitoring() {
    if (_frameRateTimer?.isActive == true) {
      _frameRateTimer?.cancel();
    }

    _frameRateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateFrameRate();
    });

    // Listen to frame callbacks
    SchedulerBinding.instance.addTimingsCallback(_onFrameCallback);

    _logger.debug('Frame rate monitoring started');
  }

  /// Handle frame callbacks to count frames
  void _onFrameCallback(List<FrameTiming> timings) {
    if (!_isFrameRateMonitoringEnabled) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final currentSecond = (now / 1000).floor();

    if (_lastSecondTimestamp != currentSecond) {
      _lastSecondTimestamp = currentSecond;
      _currentFrameRate = _framesInCurrentSecond.toDouble();

      // Update frame rate history
      _frameRateHistory.add(_currentFrameRate);
      if (_frameRateHistory.length > 60) {
        // Keep last 60 seconds
        _frameRateHistory.removeAt(0);
      }

      // Calculate average frame rate
      if (_frameRateHistory.isNotEmpty) {
        _averageFrameRate =
            _frameRateHistory.reduce((a, b) => a + b) /
            _frameRateHistory.length;
      }

      _framesInCurrentSecond = 0;

      // Log low frame rates
      if (_currentFrameRate < 30 && _currentFrameRate > 0) {
        _logger.warning(
          'Low frame rate detected',
          data: {'frameRate': _currentFrameRate},
        );
      }
    }

    _framesInCurrentSecond++;
  }

  /// Calculate frame rate metrics
  void _calculateFrameRate() {
    // Additional frame rate calculations can be done here
    _performanceMetrics['lastFrameRate'] = _currentFrameRate;
    _performanceMetrics['averageFrameRate'] = _averageFrameRate;
    _performanceMetrics['frameRateHistoryLength'] = _frameRateHistory.length;
  }

  /// Start tracking widget build time
  String startWidgetBuildTracking(String widgetName) {
    if (!_isWidgetBuildTrackingEnabled) {
      return '';
    }

    final trackingId = '${widgetName}_${DateTime.now().millisecondsSinceEpoch}';
    final startTime = DateTime.now().microsecondsSinceEpoch;

    // Store the start time
    _recentBuilds.add({
      'id': trackingId,
      'widgetName': widgetName,
      'startTime': startTime,
      'endTime': null,
      'duration': null,
    });

    // Limit the size of recent builds
    while (_recentBuilds.length > _maxRecentBuilds) {
      _recentBuilds.removeFirst();
    }

    return trackingId;
  }

  /// End tracking widget build time
  void endWidgetBuildTracking(String trackingId) {
    if (!_isWidgetBuildTrackingEnabled || trackingId.isEmpty) {
      return;
    }

    final endTime = DateTime.now().microsecondsSinceEpoch;

    // Find the build entry
    for (final build in _recentBuilds) {
      if (build['id'] == trackingId) {
        build['endTime'] = endTime;
        build['duration'] = endTime - (build['startTime'] as int);

        final widgetName = build['widgetName'] as String;
        final duration = build['duration'] as int;

        // Update widget statistics
        _widgetBuildTimes.putIfAbsent(widgetName, () => []);
        _widgetBuildTimes[widgetName]!.add(duration);

        // Keep only last 50 build times for each widget
        if (_widgetBuildTimes[widgetName]!.length > 50) {
          _widgetBuildTimes[widgetName]!.removeAt(0);
        }

        _widgetBuildCounts[widgetName] =
            (_widgetBuildCounts[widgetName] ?? 0) + 1;

        // Log slow builds
        if (duration > 16000) {
          // > 16ms (60 FPS threshold)
          _logger.warning(
            'Slow widget build detected',
            data: {
              'widgetName': widgetName,
              'duration': duration,
              'durationMs': duration / 1000,
            },
          );
        }

        break;
      }
    }
  }

  /// Get widget build statistics
  Map<String, dynamic> getWidgetStats(String widgetName) {
    final buildTimes = _widgetBuildTimes[widgetName];
    if (buildTimes == null || buildTimes.isEmpty) {
      return {
        'widgetName': widgetName,
        'buildCount': 0,
        'averageBuildTime': 0,
        'maxBuildTime': 0,
        'minBuildTime': 0,
      };
    }

    final averageBuildTime =
        buildTimes.reduce((a, b) => a + b) / buildTimes.length;
    final maxBuildTime = buildTimes.reduce((a, b) => a > b ? a : b);
    final minBuildTime = buildTimes.reduce((a, b) => a < b ? a : b);

    return {
      'widgetName': widgetName,
      'buildCount': _widgetBuildCounts[widgetName] ?? 0,
      'averageBuildTime': averageBuildTime,
      'averageBuildTimeMs': averageBuildTime / 1000,
      'maxBuildTime': maxBuildTime,
      'maxBuildTimeMs': maxBuildTime / 1000,
      'minBuildTime': minBuildTime,
      'minBuildTimeMs': minBuildTime / 1000,
      'recentBuildTimes': buildTimes.take(10).toList(),
    };
  }

  /// Get all widget statistics
  Map<String, dynamic> getAllWidgetStats() {
    final allStats = <String, dynamic>{};

    for (final widgetName in _widgetBuildTimes.keys) {
      allStats[widgetName] = getWidgetStats(widgetName);
    }

    return allStats;
  }

  /// Get current performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return Map<String, dynamic>.from(_performanceMetrics);
  }

  /// Get frame rate metrics
  Map<String, dynamic> getFrameRateMetrics() {
    return {
      'currentFrameRate': _currentFrameRate,
      'averageFrameRate': _averageFrameRate,
      'frameRateHistory': List<double>.from(_frameRateHistory),
      'historyLength': _frameRateHistory.length,
    };
  }

  /// Get memory usage information
  Future<Map<String, dynamic>> getMemoryUsage() async {
    try {
      // This is a simplified memory tracking
      // In a real implementation, you might use more sophisticated memory tracking
      final info = await MemoryPerformance.getMemoryInfo();

      return {
        'totalMemory': info['totalMemory'],
        'usedMemory': info['usedMemory'],
        'freeMemory': info['freeMemory'],
        'memoryUsagePercentage': info['memoryUsagePercentage'],
      };
    } catch (e) {
      _logger.warning(
        'Failed to get memory usage',
        data: {'error': e.toString()},
      );
      return {'error': 'Failed to get memory usage', 'message': e.toString()};
    }
  }

  /// Reset all performance metrics
  void resetMetrics() {
    _frameRateHistory.clear();
    _widgetBuildTimes.clear();
    _widgetBuildCounts.clear();
    _recentBuilds.clear();
    _performanceMetrics.clear();
    _currentFrameRate = 0.0;
    _averageFrameRate = 0.0;

    _logger.info('Performance metrics reset');
  }

  /// Enable or disable performance monitoring
  void setMonitoringEnabled(bool enabled) {
    _isMonitoringEnabled = enabled;

    if (!enabled) {
      _frameRateTimer?.cancel();
      SchedulerBinding.instance.removeTimingsCallback(_onFrameCallback);
    } else if (_isFrameRateMonitoringEnabled) {
      _startFrameRateMonitoring();
    }

    _logger.info('Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable or disable frame rate monitoring
  void setFrameRateMonitoringEnabled(bool enabled) {
    _isFrameRateMonitoringEnabled = enabled;

    if (enabled && _isMonitoringEnabled) {
      _startFrameRateMonitoring();
    } else {
      _frameRateTimer?.cancel();
      SchedulerBinding.instance.removeTimingsCallback(_onFrameCallback);
    }

    _logger.info('Frame rate monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Enable or disable widget build tracking
  void setWidgetBuildTrackingEnabled(bool enabled) {
    _isWidgetBuildTrackingEnabled = enabled;
    _logger.info('Widget build tracking ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Dispose of resources
  void dispose() {
    _frameRateTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_onFrameCallback);
    resetMetrics();

    _logger.info('Performance monitoring service disposed');
  }
}

/// Helper class for memory performance tracking
class MemoryPerformance {
  static Future<Map<String, dynamic>> getMemoryInfo() async {
    // This is a placeholder implementation
    // In a real app, you might use platform-specific APIs to get detailed memory info
    try {
      // Simulate memory information
      final totalMemory = 1024 * 1024 * 1024; // 1GB in bytes
      final usedMemory = (totalMemory * 0.6).round(); // 60% usage
      final freeMemory = totalMemory - usedMemory;

      return {
        'totalMemory': totalMemory,
        'usedMemory': usedMemory,
        'freeMemory': freeMemory,
        'memoryUsagePercentage': (usedMemory / totalMemory * 100).round(),
      };
    } catch (e) {
      return {'error': 'Failed to get memory info', 'message': e.toString()};
    }
  }
}

/// Widget performance tracker mixin for easy integration
mixin WidgetPerformanceTracker<T extends StatefulWidget> on State<T> {
  String? _trackingId;
  late final String _widgetName;

  @override
  void initState() {
    super.initState();
    _widgetName = widget.runtimeType.toString();
    _startTracking();
  }

  void _startTracking() {
    final performanceService = locator<PerformanceMonitoringService>();
    _trackingId = performanceService.startWidgetBuildTracking(_widgetName);
  }

  @override
  void dispose() {
    _endTracking();
    super.dispose();
  }

  void _endTracking() {
    if (_trackingId != null) {
      final performanceService = locator<PerformanceMonitoringService>();
      performanceService.endWidgetBuildTracking(_trackingId!);
      _trackingId = null;
    }
  }

  /// Call this method at the beginning of your build method
  void trackBuildStart() {
    _startTracking();
  }

  /// Call this method at the end of your build method
  void trackBuildEnd() {
    _endTracking();
  }
}
