import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';

/// Performance overlay widget for displaying performance metrics during development
class PerformanceOverlay extends ConsumerStatefulWidget {
  final bool enabled;
  final Widget child;
  final Alignment alignment;
  final double width;
  final double height;

  const PerformanceOverlay({
    super.key,
    this.enabled = kDebugMode,
    required this.child,
    this.alignment = Alignment.topRight,
    this.width = 300,
    this.height = 200,
  });

  @override
  ConsumerState<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends ConsumerState<PerformanceOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeInAnimation;
  bool _isVisible = false;
  Timer? _updateTimer;

  // Performance metrics
  double _currentFrameRate = 0.0;
  double _averageFrameRate = 0.0;
  Map<String, dynamic> _widgetStats = {};
  Map<String, dynamic> _memoryStats = {};

  final PerformanceMonitoringService _performanceService =
      locator<PerformanceMonitoringService>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.enabled) {
      _startMetricsUpdate();
    }
  }

  @override
  void didUpdateWidget(PerformanceOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startMetricsUpdate();
      } else {
        _stopMetricsUpdate();
      }
    }
  }

  void _startMetricsUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _updateMetrics();
      }
    });
  }

  void _stopMetricsUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  Future<void> _updateMetrics() async {
    try {
      final frameRateMetrics = _performanceService.getFrameRateMetrics();
      final allWidgetStats = _performanceService.getAllWidgetStats();
      final memoryStats = await _performanceService.getMemoryUsage();

      setState(() {
        _currentFrameRate =
            (frameRateMetrics['currentFrameRate'] as double?) ?? 0.0;
        _averageFrameRate =
            (frameRateMetrics['averageFrameRate'] as double?) ?? 0.0;
        _widgetStats = allWidgetStats;
        _memoryStats = memoryStats;
      });
    } catch (e) {
      // Silently handle errors in metrics update
    }
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
      if (_isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Color _getFrameRateColor(double frameRate) {
    if (frameRate >= 55) return Colors.green;
    if (frameRate >= 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPerformanceMetrics() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _performanceService.resetMetrics,
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleVisibility,
                      child: const Icon(
                        Icons.close,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Frame rate metrics
                  Row(
                    children: [
                      const Text(
                        'FPS: ',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _currentFrameRate.toStringAsFixed(1),
                        style: TextStyle(
                          color: _getFrameRateColor(_currentFrameRate),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' (',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        _averageFrameRate.toStringAsFixed(1),
                        style: TextStyle(
                          color: _getFrameRateColor(_averageFrameRate),
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        ' avg)',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Memory usage
                  if (_memoryStats['memoryUsagePercentage'] != null)
                    Row(
                      children: [
                        const Text(
                          'Memory: ',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${_memoryStats['memoryUsagePercentage']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Widget statistics
                  if (_widgetStats.isNotEmpty) ...[
                    const Text(
                      'Widget Stats:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              _widgetStats.entries.take(5).map((entry) {
                                final widgetName = entry.key;
                                final stats =
                                    entry.value as Map<String, dynamic>;
                                final avgTime =
                                    (stats['averageBuildTimeMs'] as double?) ??
                                    0.0;
                                final buildCount =
                                    (stats['buildCount'] as int?) ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widgetName.length > 15
                                              ? '${widgetName.substring(0, 15)}...'
                                              : widgetName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${avgTime.toStringAsFixed(1)}ms ($buildCount)',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,

        // Toggle button
        Positioned(
          top: 50,
          right: 10,
          child: GestureDetector(
            onTap: _toggleVisibility,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.speed,
                color: _getFrameRateColor(_currentFrameRate),
                size: 20,
              ),
            ),
          ),
        ),

        // Performance overlay
        if (_isVisible)
          Positioned(
            top: 80,
            right: 10,
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: _buildPerformanceMetrics(),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _stopMetricsUpdate();
    _animationController.dispose();
    super.dispose();
  }
}

/// Simple performance monitor for showing basic metrics in a more compact form
class CompactPerformanceMonitor extends ConsumerWidget {
  final Widget child;

  const CompactPerformanceMonitor({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return child;
    }

    final performanceService = locator<PerformanceMonitoringService>();
    final frameRateMetrics = performanceService.getFrameRateMetrics();
    final currentFrameRate = frameRateMetrics['currentFrameRate'] ?? 0.0;

    Color getFrameRateColor(double frameRate) {
      if (frameRate >= 55) return Colors.green;
      if (frameRate >= 30) return Colors.orange;
      return Colors.red;
    }

    return Stack(
      children: [
        child,

        // FPS indicator
        Positioned(
          top: 50,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currentFrameRate.toStringAsFixed(0)} FPS',
              style: TextStyle(
                color: getFrameRateColor(currentFrameRate as double),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Performance metrics collector for automated testing
class PerformanceMetricsCollector {
  final PerformanceMonitoringService _performanceService =
      locator<PerformanceMonitoringService>();

  final Map<String, List<double>> _metricsHistory = {};

  /// Collect current performance metrics
  Map<String, dynamic> collectMetrics() {
    final frameRateMetrics = _performanceService.getFrameRateMetrics();
    final allWidgetStats = _performanceService.getAllWidgetStats();
    final performanceMetrics = _performanceService.getPerformanceMetrics();

    final metrics = {
      'timestamp': DateTime.now().toIso8601String(),
      'frameRate': frameRateMetrics,
      'widgetStats': allWidgetStats,
      'performanceMetrics': performanceMetrics,
    };

    // Store in history
    final currentFrameRate = frameRateMetrics['currentFrameRate'] ?? 0.0;
    _metricsHistory
        .putIfAbsent('frameRate', () => [])
        .add(currentFrameRate as double);

    // Keep only last 100 entries
    if (_metricsHistory['frameRate']!.length > 100) {
      _metricsHistory['frameRate']!.removeAt(0);
    }

    return metrics;
  }

  /// Get performance summary for testing
  Map<String, dynamic> getPerformanceSummary() {
    final frameRateHistory = _metricsHistory['frameRate'] ?? [];

    if (frameRateHistory.isEmpty) {
      return {
        'averageFrameRate': 0.0,
        'minFrameRate': 0.0,
        'maxFrameRate': 0.0,
        'frameDrops': 0,
        'totalSamples': 0,
      };
    }

    final averageFrameRate =
        frameRateHistory.reduce((a, b) => a + b) / frameRateHistory.length;
    final minFrameRate = frameRateHistory.reduce((a, b) => a < b ? a : b);
    final maxFrameRate = frameRateHistory.reduce((a, b) => a > b ? a : b);
    final frameDrops = frameRateHistory.where((fps) => fps < 30).length;

    return {
      'averageFrameRate': averageFrameRate,
      'minFrameRate': minFrameRate,
      'maxFrameRate': maxFrameRate,
      'frameDrops': frameDrops,
      'frameDropPercentage':
          (frameDrops / frameRateHistory.length * 100).round(),
      'totalSamples': frameRateHistory.length,
    };
  }

  /// Reset metrics history
  void reset() {
    _metricsHistory.clear();
  }
}
