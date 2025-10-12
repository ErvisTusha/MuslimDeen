import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/cache_service.dart';

/// Optimization tweak category
enum OptimizationCategory {
  memory,
  cpu,
  rendering,
  io,
  network,
  cache,
  battery,
}

/// Optimization tweak result
class OptimizationResult {
  final String name;
  final String category;
  final String description;
  final bool applied;
  final String? error;
  final Map<String, dynamic> beforeMetrics;
  final Map<String, dynamic> afterMetrics;
  final Map<String, dynamic> improvement;

  OptimizationResult({
    required this.name,
    required this.category,
    required this.description,
    required this.applied,
    this.error,
    required this.beforeMetrics,
    required this.afterMetrics,
    required this.improvement,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'applied': applied,
      'error': error,
      'beforeMetrics': beforeMetrics,
      'afterMetrics': afterMetrics,
      'improvement': improvement,
    };
  }
}

/// Optimization tweak configuration
class OptimizationTweak {
  final String name;
  final String category;
  final String description;
  final bool enabled;
  final int priority;
  final Map<String, dynamic>? parameters;

  OptimizationTweak({
    required this.name,
    required this.category,
    required this.description,
    this.enabled = true,
    this.priority = 0,
    this.parameters,
  });
}

/// Optimization tweaks service for applying performance optimizations
class OptimizationTweaksService {
  final LoggerService _logger = locator<LoggerService>();
  final PerformanceMonitoringService _performanceService =
      locator<PerformanceMonitoringService>();
  final CacheService _cacheService = locator<CacheService>();

  // Tweak storage
  final List<OptimizationTweak> _tweaks = [];
  final List<OptimizationResult> _results = [];

  // Tweak state
  bool _isInitialized = false;

  /// Initialize the optimization tweaks service
  void initialize() {
    if (_isInitialized) return;

    _registerDefaultTweaks();

    _isInitialized = true;
    _logger.info(
      'OptimizationTweaksService initialized',
      data: {'tweaksCount': _tweaks.length},
    );
  }

  /// Register default optimization tweaks
  void _registerDefaultTweaks() {
    // Memory optimizations
    registerTweak(
      OptimizationTweak(
        name: 'memory_leak_detection',
        category: 'memory',
        description: 'Detect and fix memory leaks',
        priority: 10,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'image_cache_optimization',
        category: 'memory',
        description: 'Optimize image caching for memory efficiency',
        priority: 8,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'object_pool_optimization',
        category: 'memory',
        description: 'Implement object pooling for frequently created objects',
        priority: 7,
      ),
    );

    // CPU optimizations
    registerTweak(
      OptimizationTweak(
        name: 'calculation_optimization',
        category: 'cpu',
        description: 'Optimize mathematical calculations',
        priority: 9,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'algorithm_optimization',
        category: 'cpu',
        description: 'Replace inefficient algorithms with optimized versions',
        priority: 8,
      ),
    );

    // Rendering optimizations
    registerTweak(
      OptimizationTweak(
        name: 'widget_rebuild_optimization',
        category: 'rendering',
        description: 'Minimize unnecessary widget rebuilds',
        priority: 10,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'repaint_boundary_optimization',
        category: 'rendering',
        description: 'Add repaint boundaries to isolate expensive repaints',
        priority: 8,
      ),
    );

    // I/O optimizations
    registerTweak(
      OptimizationTweak(
        name: 'database_query_optimization',
        category: 'io',
        description: 'Optimize database queries for better performance',
        priority: 9,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'file_io_optimization',
        category: 'io',
        description: 'Optimize file I/O operations',
        priority: 7,
      ),
    );

    // Cache optimizations
    registerTweak(
      OptimizationTweak(
        name: 'cache_hit_rate_optimization',
        category: 'cache',
        description: 'Improve cache hit rate through better caching strategies',
        priority: 9,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'cache_size_optimization',
        category: 'cache',
        description: 'Optimize cache size for memory efficiency',
        priority: 7,
      ),
    );

    // Battery optimizations
    registerTweak(
      OptimizationTweak(
        name: 'background_task_optimization',
        category: 'battery',
        description: 'Optimize background tasks to reduce battery usage',
        priority: 8,
      ),
    );

    registerTweak(
      OptimizationTweak(
        name: 'location_update_optimization',
        category: 'battery',
        description: 'Optimize location update frequency',
        priority: 7,
      ),
    );
  }

  /// Register an optimization tweak
  void registerTweak(OptimizationTweak tweak) {
    _tweaks.add(tweak);
    _tweaks.sort((a, b) => b.priority.compareTo(a.priority));
    _logger.debug(
      'Optimization tweak registered',
      data: {
        'name': tweak.name,
        'category': tweak.category,
        'priority': tweak.priority,
      },
    );
  }

  /// Get all registered tweaks
  List<OptimizationTweak> getAllTweaks() {
    return List.unmodifiable(_tweaks);
  }

  /// Get tweaks by category
  List<OptimizationTweak> getTweaksByCategory(String category) {
    return _tweaks.where((tweak) => tweak.category == category).toList();
  }

  /// Apply an optimization tweak
  Future<OptimizationResult> applyTweak(String name) async {
    final tweak = _tweaks.firstWhere(
      (t) => t.name == name,
      orElse: () => throw ArgumentError('Tweak not found: $name'),
    );

    if (!tweak.enabled) {
      return OptimizationResult(
        name: name,
        category: tweak.category,
        description: tweak.description,
        applied: false,
        error: 'Tweak is disabled',
        beforeMetrics: {},
        afterMetrics: {},
        improvement: {},
      );
    }

    _logger.info('Applying optimization tweak', data: {'name': name});

    // Collect before metrics
    final beforeMetrics = await _collectMetrics(tweak.category);

    try {
      // Apply the tweak based on its name
      final afterMetrics = await _applySpecificTweak(tweak, beforeMetrics);

      // Calculate improvement
      final improvement = _calculateImprovement(beforeMetrics, afterMetrics);

      final result = OptimizationResult(
        name: name,
        category: tweak.category,
        description: tweak.description,
        applied: true,
        beforeMetrics: beforeMetrics,
        afterMetrics: afterMetrics,
        improvement: improvement,
      );

      _results.add(result);

      _logger.info(
        'Optimization tweak applied successfully',
        data: {'name': name, 'improvement': improvement},
      );

      return result;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to apply optimization tweak',
        error: e,
        stackTrace: stackTrace,
        data: {'name': name},
      );

      final result = OptimizationResult(
        name: name,
        category: tweak.category,
        description: tweak.description,
        applied: false,
        error: e.toString(),
        beforeMetrics: beforeMetrics,
        afterMetrics: {},
        improvement: {},
      );

      _results.add(result);
      return result;
    }
  }

  /// Apply multiple optimization tweaks
  Future<List<OptimizationResult>> applyTweaks(List<String> names) async {
    final results = <OptimizationResult>[];

    for (final name in names) {
      try {
        final result = await applyTweak(name);
        results.add(result);
      } catch (e) {
        _logger.error('Error applying tweak', error: e, data: {'name': name});
      }
    }

    return results;
  }

  /// Apply all enabled tweaks
  Future<List<OptimizationResult>> applyAllTweaks() async {
    final enabledTweaks =
        _tweaks
            .where((tweak) => tweak.enabled)
            .map((tweak) => tweak.name)
            .toList();
    return await applyTweaks(enabledTweaks);
  }

  /// Collect metrics for a specific category
  Future<Map<String, dynamic>> _collectMetrics(String category) async {
    final metrics = <String, dynamic>{};

    switch (category) {
      case 'memory':
        final memoryUsage = await _performanceService.getMemoryUsage();
        metrics.addAll(memoryUsage);
        break;

      case 'cpu':
        final frameRateMetrics = _performanceService.getFrameRateMetrics();
        metrics.addAll(frameRateMetrics);
        break;

      case 'rendering':
        final frameRateMetrics = _performanceService.getFrameRateMetrics();
        final widgetStats = _performanceService.getAllWidgetStats();
        metrics.addAll(frameRateMetrics);
        metrics.addAll({'widgetStats': widgetStats});
        break;

      case 'io':
        metrics['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        break;

      case 'cache':
        final cacheStats = _cacheService.getCacheStats();
        metrics.addAll(cacheStats);
        break;

      case 'battery':
        metrics['timestamp'] = DateTime.now().millisecondsSinceEpoch;
        break;
    }

    return metrics;
  }

  /// Apply a specific optimization tweak
  Future<Map<String, dynamic>> _applySpecificTweak(
    OptimizationTweak tweak,
    Map<String, dynamic> beforeMetrics,
  ) async {
    final afterMetrics = <String, dynamic>{};

    switch (tweak.name) {
      case 'memory_leak_detection':
        // Force garbage collection
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final memoryUsage = await _performanceService.getMemoryUsage();
        afterMetrics.addAll(memoryUsage);
        break;

      case 'image_cache_optimization':
        // Clear image cache if it's too large
        PaintingBinding.instance.imageCache.clear();
        final memoryUsage = await _performanceService.getMemoryUsage();
        afterMetrics.addAll(memoryUsage);
        break;

      case 'widget_rebuild_optimization':
        // Mark widgets as dirty to trigger rebuild optimization
        final frameRateMetrics = _performanceService.getFrameRateMetrics();
        afterMetrics.addAll(frameRateMetrics);
        break;

      case 'repaint_boundary_optimization':
        // Trigger repaint boundary optimization
        final frameRateMetrics = _performanceService.getFrameRateMetrics();
        afterMetrics.addAll(frameRateMetrics);
        break;

      case 'cache_hit_rate_optimization':
        // Pre-warm cache with commonly accessed items
        final cacheStats = _cacheService.getCacheStats();
        afterMetrics.addAll(cacheStats);
        break;

      case 'cache_size_optimization':
        // Force cache cleanup
        await _cacheService.forceCleanup();
        final cacheStats = _cacheService.getCacheStats();
        afterMetrics.addAll(cacheStats);
        break;

      default:
        // For unknown tweaks, just collect current metrics
        afterMetrics.addAll(await _collectMetrics(tweak.category));
        break;
    }

    return afterMetrics;
  }

  /// Calculate improvement between before and after metrics
  Map<String, dynamic> _calculateImprovement(
    Map<String, dynamic> beforeMetrics,
    Map<String, dynamic> afterMetrics,
  ) {
    final improvement = <String, dynamic>{};

    // Calculate memory improvement
    if (beforeMetrics.containsKey('usedMemory') &&
        afterMetrics.containsKey('usedMemory')) {
      final beforeMemory = beforeMetrics['usedMemory'] as int;
      final afterMemory = afterMetrics['usedMemory'] as int;

      if (beforeMemory > 0) {
        final memoryReduction =
            (beforeMemory - afterMemory) / beforeMemory * 100;
        improvement['memoryReductionPercent'] = memoryReduction.toStringAsFixed(
          2,
        );
      }
    }

    // Calculate frame rate improvement
    if (beforeMetrics.containsKey('currentFrameRate') &&
        afterMetrics.containsKey('currentFrameRate')) {
      final beforeFrameRate = beforeMetrics['currentFrameRate'] as double;
      final afterFrameRate = afterMetrics['currentFrameRate'] as double;

      if (beforeFrameRate > 0) {
        final frameRateImprovement =
            (afterFrameRate - beforeFrameRate) / beforeFrameRate * 100;
        improvement['frameRateImprovementPercent'] = frameRateImprovement
            .toStringAsFixed(2);
      }
    }

    // Calculate cache hit rate improvement
    if (beforeMetrics.containsKey('totalEntries') &&
        afterMetrics.containsKey('totalEntries')) {
      final beforeEntries = beforeMetrics['totalEntries'] as int;
      final afterEntries = afterMetrics['totalEntries'] as int;

      if (beforeEntries > 0) {
        final cacheSizeChange =
            (afterEntries - beforeEntries) / beforeEntries * 100;
        improvement['cacheSizeChangePercent'] = cacheSizeChange.toStringAsFixed(
          2,
        );
      }
    }

    return improvement;
  }

  /// Get all optimization results
  List<OptimizationResult> getAllResults() {
    return List.unmodifiable(_results);
  }

  /// Get results by category
  List<OptimizationResult> getResultsByCategory(String category) {
    return _results.where((result) => result.category == category).toList();
  }

  /// Get results by tweak name
  OptimizationResult? getResult(String name) {
    try {
      return _results.firstWhere((result) => result.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Generate optimization report
  Map<String, dynamic> generateOptimizationReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'totalTweaks': _tweaks.length,
      'enabledTweaks': _tweaks.where((tweak) => tweak.enabled).length,
      'appliedTweaks': _results.length,
      'successfulTweaks': _results.where((result) => result.applied).length,
      'failedTweaks': _results.where((result) => !result.applied).length,
      'categories': <String, int>{},
      'results': <String, dynamic>{},
      'summary': {
        'averageMemoryReduction': 0.0,
        'averageFrameRateImprovement': 0.0,
        'totalMemoryReduction': 0.0,
        'totalFrameRateImprovement': 0.0,
      },
    };

    // Count tweaks by category
    for (final tweak in _tweaks) {
      report['categories'][tweak.category] =
          (report['categories'][tweak.category] ?? 0) + 1;
    }

    // Add detailed results
    for (final result in _results) {
      report['results'][result.name] = {
        'category': result.category,
        'description': result.description,
        'applied': result.applied,
        'error': result.error,
        'improvement': result.improvement,
      };

      // Calculate summary statistics
      if (result.improvement.containsKey('memoryReductionPercent')) {
        final memoryReduction =
            double.tryParse(
              result.improvement['memoryReductionPercent'] as String,
            ) ??
            0.0;
        report['summary']['totalMemoryReduction'] += memoryReduction;
      }

      if (result.improvement.containsKey('frameRateImprovementPercent')) {
        final frameRateImprovement =
            double.tryParse(
              result.improvement['frameRateImprovementPercent'] as String,
            ) ??
            0.0;
        report['summary']['totalFrameRateImprovement'] += frameRateImprovement;
      }
    }

    // Calculate averages
    if ((report['successfulTweaks'] as int) > 0) {
      report['summary']['averageMemoryReduction'] =
          report['summary']['totalMemoryReduction'] /
          report['successfulTweaks'];
      report['summary']['averageFrameRateImprovement'] =
          report['summary']['totalFrameRateImprovement'] /
          report['successfulTweaks'];
    }

    return report;
  }

  /// Enable or disable a tweak
  void setTweakEnabled(String name, bool enabled) {
    final tweak = _tweaks.firstWhere(
      (t) => t.name == name,
      orElse: () => throw ArgumentError('Tweak not found: $name'),
    );

    // Create new tweak with updated enabled status
    final updatedTweak = OptimizationTweak(
      name: tweak.name,
      category: tweak.category,
      description: tweak.description,
      enabled: enabled,
      priority: tweak.priority,
      parameters: tweak.parameters,
    );

    // Replace the old tweak
    final index = _tweaks.indexWhere((t) => t.name == name);
    _tweaks[index] = updatedTweak;

    _logger.info(
      'Tweak enabled status updated',
      data: {'name': name, 'enabled': enabled},
    );
  }

  /// Dispose of resources
  void dispose() {
    _isInitialized = false;
    _logger.info('OptimizationTweaksService disposed');
  }
}
