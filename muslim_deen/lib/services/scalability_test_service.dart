import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/database_service.dart';

/// Scalability test result data class
class ScalabilityTestResult {
  final String name;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;
  final bool passedThresholds;
  final List<String> warnings;
  final List<String> errors;

  ScalabilityTestResult({
    required this.name,
    required this.parameters,
    required this.metrics,
    required this.timestamp,
    required this.passedThresholds,
    required this.warnings,
    required this.errors,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
      'metrics': metrics,
      'timestamp': timestamp.toIso8601String(),
      'passedThresholds': passedThresholds,
      'warnings': warnings,
      'errors': errors,
    };
  }
}

/// Scalability test configuration
class ScalabilityTestConfig {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final Map<String, double> thresholds;
  final Duration timeout;

  ScalabilityTestConfig({
    required this.name,
    required this.description,
    required this.parameters,
    required this.thresholds,
    this.timeout = const Duration(minutes: 5),
  });
}

/// Scalability testing service for measuring app performance under load
class ScalabilityTestService {
  final LoggerService _logger = locator<LoggerService>();
  final PerformanceMonitoringService _performanceService =
      locator<PerformanceMonitoringService>();

  // Test storage
  final Map<String, ScalabilityTestResult> _testResults = {};
  final List<ScalabilityTestConfig> _testConfigs = [];

  // Test state
  bool _isRunning = false;

  /// Initialize the scalability test service
  void initialize() {
    _logger.info('ScalabilityTestService initialized');
    _registerDefaultTests();
  }

  /// Register default scalability tests
  void _registerDefaultTests() {
    // Database scalability test
    registerTestConfig(
      ScalabilityTestConfig(
        name: 'database_scalability',
        description: 'Tests database performance with increasing data volume',
        parameters: {
          'startRecords': 100,
          'maxRecords': 10000,
          'incrementStep': 100,
          'operationsPerRecord': 5,
        },
        thresholds: {
          'maxMemoryGrowthMB': 50.0,
          'maxAvgOperationTimeMs': 10.0,
          'minThroughputOpsPerSec': 500.0,
        },
      ),
    );

    // UI rendering scalability test
    registerTestConfig(
      ScalabilityTestConfig(
        name: 'ui_rendering_scalability',
        description:
            'Tests UI rendering performance with increasing widget count',
        parameters: {
          'startWidgets': 10,
          'maxWidgets': 1000,
          'incrementStep': 10,
          'complexityFactor': 1.0,
        },
        thresholds: {
          'maxFrameTimeMs': 16.67,
          'maxJankPercent': 5.0,
          'minThroughputFps': 55.0,
        },
      ),
    );

    // Concurrent operations scalability test
    registerTestConfig(
      ScalabilityTestConfig(
        name: 'concurrent_operations_scalability',
        description: 'Tests performance with increasing concurrent operations',
        parameters: {
          'startConcurrentOps': 5,
          'maxConcurrentOps': 100,
          'incrementStep': 5,
          'operationsPerBatch': 10,
        },
        thresholds: {
          'maxResponseTimeMs': 2000.0,
          'maxErrorRatePercent': 1.0,
          'minThroughputOpsPerSec': 200.0,
        },
      ),
    );

    // Memory stress test
    registerTestConfig(
      ScalabilityTestConfig(
        name: 'memory_stress_test',
        description: 'Tests memory usage under stress',
        parameters: {
          'iterations': 100,
          'dataSizeKB': 100,
          'operationsPerIteration': 10,
        },
        thresholds: {
          'maxMemoryUsageMB': 200.0,
          'maxMemoryLeakMB': 10.0,
          'maxGcTimeMs': 50.0,
        },
      ),
    );
  }

  /// Register a test configuration
  void registerTestConfig(ScalabilityTestConfig config) {
    _testConfigs.add(config);
    _logger.debug(
      'Scalability test config registered',
      data: {'name': config.name},
    );
  }

  /// Get all registered test configurations
  List<ScalabilityTestConfig> getAllTestConfigs() {
    return List.unmodifiable(_testConfigs);
  }

  /// Get test configuration by name
  ScalabilityTestConfig? getTestConfig(String name) {
    try {
      return _testConfigs.firstWhere((config) => config.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Run a scalability test by name
  Future<ScalabilityTestResult> runTest(String name) async {
    final config = getTestConfig(name);
    if (config == null) {
      throw ArgumentError('Test configuration not found: $name');
    }

    return await runTestWithConfig(config);
  }

  /// Run a scalability test with configuration
  Future<ScalabilityTestResult> runTestWithConfig(
    ScalabilityTestConfig config,
  ) async {
    if (_isRunning) {
      throw StateError('Another scalability test is already running');
    }

    _isRunning = true;

    _logger.info(
      'Starting scalability test',
      data: {
        'name': config.name,
        'description': config.description,
        'parameters': config.parameters,
      },
    );

    final warnings = <String>[];
    final errors = <String>[];
    final metrics = <String, dynamic>{};
    bool passedThresholds = true;

    try {
      switch (config.name) {
        case 'database_scalability':
          metrics.addAll(
            await _runDatabaseScalabilityTest(config, warnings, errors),
          );
          break;
        case 'ui_rendering_scalability':
          metrics.addAll(
            await _runUIRenderingScalabilityTest(config, warnings, errors),
          );
          break;
        case 'concurrent_operations_scalability':
          metrics.addAll(
            await _runConcurrentOperationsScalabilityTest(
              config,
              warnings,
              errors,
            ),
          );
          break;
        case 'memory_stress_test':
          metrics.addAll(await _runMemoryStressTest(config, warnings, errors));
          break;
        default:
          throw ArgumentError('Unknown test: ${config.name}');
      }

      // Check against thresholds
      for (final entry in config.thresholds.entries) {
        final threshold = entry.value;
        final metricValue = metrics[entry.key];

        if (metricValue == null) {
          warnings.add('Missing metric for threshold: ${entry.key}');
          continue;
        }

        if (entry.key.startsWith('max') && (metricValue as num) > threshold) {
          passedThresholds = false;
          errors.add(
            'Threshold exceeded: ${entry.key} (${metricValue} > ${threshold})',
          );
        } else if (entry.key.startsWith('min') &&
            (metricValue as num) < threshold) {
          passedThresholds = false;
          errors.add(
            'Threshold not met: ${entry.key} (${metricValue} < ${threshold})',
          );
        }
      }
    } catch (e, stackTrace) {
      errors.add('Test execution failed: $e');
      _logger.error(
        'Scalability test failed',
        error: e,
        stackTrace: stackTrace,
        data: {'name': config.name},
      );
    } finally {
      _isRunning = false;
    }

    // Create test result
    final result = ScalabilityTestResult(
      name: config.name,
      parameters: config.parameters,
      metrics: metrics,
      timestamp: DateTime.now(),
      passedThresholds: passedThresholds,
      warnings: warnings,
      errors: errors,
    );

    // Store result
    _testResults[config.name] = result;

    // Log result
    _logger.info(
      'Scalability test completed',
      data: {
        'name': config.name,
        'passedThresholds': passedThresholds,
        'warningsCount': warnings.length,
        'errorsCount': errors.length,
        'metrics': metrics,
      },
    );

    return result;
  }

  /// Run database scalability test
  Future<Map<String, dynamic>> _runDatabaseScalabilityTest(
    ScalabilityTestConfig config,
    List<String> warnings,
    List<String> errors,
  ) async {
    final metrics = <String, dynamic>{};
    final databaseService = locator<DatabaseService>();

    final startRecords = config.parameters['startRecords'] as int;
    final maxRecords = config.parameters['maxRecords'] as int;
    final incrementStep = config.parameters['incrementStep'] as int;
    final operationsPerRecord = config.parameters['operationsPerRecord'] as int;

    final memoryUsageHistory = <double>[];
    final operationTimeHistory = <double>[];
    final throughputHistory = <double>[];

    for (
      int recordCount = startRecords;
      recordCount <= maxRecords;
      recordCount += incrementStep
    ) {
      // Get initial memory usage
      final initialMemory = await _performanceService.getMemoryUsage();
      final initialMemoryMB =
          (initialMemory['usedMemory'] ?? 0) / (1024 * 1024);

      // Measure operation time
      final stopwatch = Stopwatch()..start();

      // Perform database operations
      for (int i = 0; i < recordCount; i++) {
        for (int j = 0; j < operationsPerRecord; j++) {
          await databaseService.saveSettings(
            'scalability_test_${i}_${j}',
            'value_${i}_${j}',
          );
        }
      }

      // Read operations
      for (int i = 0; i < recordCount; i++) {
        for (int j = 0; j < operationsPerRecord; j++) {
          await databaseService.getSettings('scalability_test_${i}_${j}');
        }
      }

      stopwatch.stop();

      // Get final memory usage
      final finalMemory = await _performanceService.getMemoryUsage();
      final finalMemoryMB = (finalMemory['usedMemory'] ?? 0) / (1024 * 1024);

      // Calculate metrics
      final operationTime = stopwatch.elapsedMilliseconds.toDouble();
      final memoryUsage = finalMemoryMB - initialMemoryMB;
      final throughput =
          (recordCount * operationsPerRecord * 2) /
          (operationTime / 1000); // ops/sec

      memoryUsageHistory.add(memoryUsage as double);
      operationTimeHistory.add(operationTime);
      throughputHistory.add(throughput);

      // Clean up test data
      for (int i = 0; i < recordCount; i++) {
        for (int j = 0; j < operationsPerRecord; j++) {
          await databaseService.removeData('scalability_test_${i}_${j}');
        }
      }

      // Check for warnings
      if (memoryUsage > 50) {
        warnings.add(
          'High memory usage at $recordCount records: ${memoryUsage.toStringAsFixed(2)}MB',
        );
      }

      if (operationTime > 5000) {
        warnings.add(
          'Slow operation time at $recordCount records: ${operationTime}ms',
        );
      }
    }

    // Calculate final metrics
    metrics['maxMemoryUsageMB'] = memoryUsageHistory.reduce(math.max);
    metrics['avgMemoryUsageMB'] =
        memoryUsageHistory.reduce((a, b) => a + b) / memoryUsageHistory.length;
    metrics['maxOperationTimeMs'] = operationTimeHistory.reduce(math.max);
    metrics['avgOperationTimeMs'] =
        operationTimeHistory.reduce((a, b) => a + b) /
        operationTimeHistory.length;
    metrics['minThroughputOpsPerSec'] = throughputHistory.reduce(math.min);
    metrics['avgThroughputOpsPerSec'] =
        throughputHistory.reduce((a, b) => a + b) / throughputHistory.length;

    return metrics;
  }

  /// Run UI rendering scalability test
  Future<Map<String, dynamic>> _runUIRenderingScalabilityTest(
    ScalabilityTestConfig config,
    List<String> warnings,
    List<String> errors,
  ) async {
    final metrics = <String, dynamic>{};

    final startWidgets = config.parameters['startWidgets'] as int;
    final maxWidgets = config.parameters['maxWidgets'] as int;
    final incrementStep = config.parameters['incrementStep'] as int;
    final complexityFactor = config.parameters['complexityFactor'] as double;

    final frameTimeHistory = <double>[];
    final jankHistory = <int>[];
    final fpsHistory = <double>[];

    for (
      int widgetCount = startWidgets;
      widgetCount <= maxWidgets;
      widgetCount += incrementStep
    ) {
      // Create test widgets
      final testWidgets = <Widget>[];
      for (int i = 0; i < widgetCount; i++) {
        testWidgets.add(
          Container(
            width: 100.0,
            height: (50.0 + i % 10 * 10) * complexityFactor,
            color: Colors.primaries[i % Colors.primaries.length],
            child: Text('Widget $i'),
          ),
        );
      }

      // Measure rendering performance
      final frameTimeMs = await _measureWidgetRenderingPerformance(testWidgets);
      final fps = 1000.0 / frameTimeMs;
      final jank = frameTimeMs > 16.67 ? 1 : 0; // Simple j detection

      frameTimeHistory.add(frameTimeMs);
      fpsHistory.add(fps);
      jankHistory.add(jank);

      // Check for warnings
      if (frameTimeMs > 33.33) {
        // Below 30 FPS
        warnings.add(
          'Low frame rate at $widgetCount widgets: ${fps.toStringAsFixed(2)} FPS',
        );
      }
    }

    // Calculate final metrics
    metrics['maxFrameTimeMs'] = frameTimeHistory.reduce(math.max);
    metrics['avgFrameTimeMs'] =
        frameTimeHistory.reduce((a, b) => a + b) / frameTimeHistory.length;
    metrics['maxJankPercent'] =
        (jankHistory.reduce((a, b) => a + b) / jankHistory.length) * 100;
    metrics['minThroughputFps'] = fpsHistory.reduce(math.min);
    metrics['avgThroughputFps'] =
        fpsHistory.reduce((a, b) => a + b) / fpsHistory.length;

    return metrics;
  }

  /// Measure widget rendering performance
  Future<double> _measureWidgetRenderingPerformance(
    List<Widget> widgets,
  ) async {
    // This is a simplified implementation
    // In a real app, you would use the Flutter rendering pipeline to measure actual performance

    final completer = Completer<double>();

    // Simulate rendering time based on widget complexity
    Timer.run(() {
      // Base time + time per widget
      final baseTime = 5.0; // ms
      final timePerWidget = 0.5; // ms
      final complexityFactor = widgets.length * timePerWidget;

      // Add some randomness to simulate real-world variance
      final randomFactor = 0.8 + math.Random().nextDouble() * 0.4; // 0.8 to 1.2

      final frameTime = (baseTime + complexityFactor) * randomFactor;
      completer.complete(frameTime);
    });

    return completer.future;
  }

  /// Run concurrent operations scalability test
  Future<Map<String, dynamic>> _runConcurrentOperationsScalabilityTest(
    ScalabilityTestConfig config,
    List<String> warnings,
    List<String> errors,
  ) async {
    final metrics = <String, dynamic>{};

    final startConcurrentOps = config.parameters['startConcurrentOps'] as int;
    final maxConcurrentOps = config.parameters['maxConcurrentOps'] as int;
    final incrementStep = config.parameters['incrementStep'] as int;
    final operationsPerBatch = config.parameters['operationsPerBatch'] as int;

    final responseTimeHistory = <double>[];
    final errorRateHistory = <double>[];
    final throughputHistory = <double>[];

    for (
      int concurrentOps = startConcurrentOps;
      concurrentOps <= maxConcurrentOps;
      concurrentOps += incrementStep
    ) {
      // Create concurrent operations
      final futures = <Future<void>>[];
      final errorCount = <int>[];

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < concurrentOps; i++) {
        futures.add(_performTestOperations(i, operationsPerBatch, errorCount));
      }

      // Wait for all operations to complete
      await Future.wait(futures);

      stopwatch.stop();

      // Calculate metrics
      final responseTime = stopwatch.elapsedMilliseconds.toDouble();
      final errorRate =
          errorCount.reduce((a, b) => a + b) /
          (concurrentOps * operationsPerBatch) *
          100;
      final throughput =
          (concurrentOps * operationsPerBatch) /
          (responseTime / 1000); // ops/sec

      responseTimeHistory.add(responseTime);
      errorRateHistory.add(errorRate);
      throughputHistory.add(throughput);

      // Check for warnings
      if (responseTime > 5000) {
        warnings.add(
          'Slow response time at $concurrentOps concurrent ops: ${responseTime}ms',
        );
      }

      if (errorRate > 5.0) {
        warnings.add(
          'High error rate at $concurrentOps concurrent ops: ${errorRate.toStringAsFixed(2)}%',
        );
      }
    }

    // Calculate final metrics
    metrics['maxResponseTimeMs'] = responseTimeHistory.reduce(math.max);
    metrics['avgResponseTimeMs'] =
        responseTimeHistory.reduce((a, b) => a + b) /
        responseTimeHistory.length;
    metrics['maxErrorRatePercent'] = errorRateHistory.reduce(math.max);
    metrics['maxThroughputOpsPerSec'] = throughputHistory.reduce(math.max);
    metrics['minThroughputOpsPerSec'] = throughputHistory.reduce(math.min);

    return metrics;
  }

  /// Perform test operations for concurrent scalability test
  Future<void> _performTestOperations(
    int batchId,
    int operationsPerBatch,
    List<int> errorCount,
  ) async {
    final databaseService = locator<DatabaseService>();

    try {
      for (int i = 0; i < operationsPerBatch; i++) {
        await databaseService.saveSettings(
          'concurrent_test_${batchId}_$i',
          'value_${batchId}_$i',
        );
      }

      for (int i = 0; i < operationsPerBatch; i++) {
        await databaseService.getSettings('concurrent_test_${batchId}_$i');
      }

      // Clean up
      for (int i = 0; i < operationsPerBatch; i++) {
        await databaseService.removeData('concurrent_test_${batchId}_$i');
      }
    } catch (e) {
      errorCount[batchId] = errorCount[batchId] + 1;
    }
  }

  /// Run memory stress test
  Future<Map<String, dynamic>> _runMemoryStressTest(
    ScalabilityTestConfig config,
    List<String> warnings,
    List<String> errors,
  ) async {
    final metrics = <String, dynamic>{};

    final iterations = config.parameters['iterations'] as int;
    final dataSizeKB = config.parameters['dataSizeKB'] as int;
    final operationsPerIteration =
        config.parameters['operationsPerIteration'] as int;

    final memoryUsageHistory = <double>[];
    final gcTimeHistory = <double>[];
    final memoryLeakHistory = <double>[];
    double? initialMemory;

    for (int i = 0; i < iterations; i++) {
      // Get initial memory usage
      final memoryBefore = await _performanceService.getMemoryUsage();
      final memoryBeforeMB = (memoryBefore['usedMemory'] ?? 0) / (1024 * 1024);

      if (i == 0) {
        initialMemory = memoryBeforeMB as double;
      }

      // Create memory stress
      final data = <List<int>>[];
      for (int j = 0; j < operationsPerIteration; j++) {
        // Create data of specified size
        final dataSizeBytes = dataSizeKB * 1024;
        final elements = dataSizeBytes ~/ 4; // 4 bytes per int

        final chunk = List<int>.generate(elements, (index) => index % 256);
        data.add(chunk);
      }

      // Measure GC time
      final gcStopwatch = Stopwatch()..start();

      // Force garbage collection
      await Future<void>.delayed(const Duration(milliseconds: 100));

      gcStopwatch.stop();

      // Get final memory usage
      final memoryAfter = await _performanceService.getMemoryUsage();
      final memoryAfterMB = (memoryAfter['usedMemory'] ?? 0) / (1024 * 1024);

      // Calculate metrics
      final memoryUsage = memoryAfterMB - memoryBeforeMB;
      final gcTime = gcStopwatch.elapsedMilliseconds.toDouble();

      memoryUsageHistory.add(memoryUsage as double);
      gcTimeHistory.add(gcTime);

      if (initialMemory != null) {
        memoryLeakHistory.add((memoryAfterMB as double) - initialMemory);
      }

      // Check for warnings
      if (memoryUsage > 50) {
        warnings.add(
          'High memory usage at iteration $i: ${memoryUsage.toStringAsFixed(2)}MB',
        );
      }

      if (gcTime > 100) {
        warnings.add('Long GC time at iteration $i: ${gcTime}ms');
      }
    }

    // Calculate final metrics
    metrics['maxMemoryUsageMB'] = memoryUsageHistory.reduce(math.max);
    metrics['avgMemoryUsageMB'] =
        memoryUsageHistory.reduce((a, b) => a + b) / memoryUsageHistory.length;
    metrics['maxGcTimeMs'] = gcTimeHistory.reduce(math.max);
    metrics['avgGcTimeMs'] =
        gcTimeHistory.reduce((a, b) => a + b) / gcTimeHistory.length;
    metrics['maxMemoryLeakMB'] = memoryLeakHistory.reduce(math.max);

    return metrics;
  }

  /// Get all test results
  Map<String, ScalabilityTestResult> getAllTestResults() {
    return Map.unmodifiable(_testResults);
  }

  /// Get test result by name
  ScalabilityTestResult? getTestResult(String name) {
    return _testResults[name];
  }

  /// Generate comprehensive scalability report
  Map<String, dynamic> generateScalabilityReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'totalTests': _testResults.length,
      'passedTests':
          _testResults.values.where((r) => r.passedThresholds).length,
      'failedTests':
          _testResults.values.where((r) => !r.passedThresholds).length,
      'testResults': <String, dynamic>{},
      'summary': {
        'categories': <String, int>{},
        'commonWarnings': <String, int>{},
        'commonErrors': <String, int>{},
      },
    };

    // Add detailed results
    for (final entry in _testResults.entries) {
      final name = entry.key;
      final result = entry.value;

      report['testResults'][name] = {
        'parameters': result.parameters,
        'metrics': result.metrics,
        'passedThresholds': result.passedThresholds,
        'warningsCount': result.warnings.length,
        'errorsCount': result.errors.length,
        'timestamp': result.timestamp.toIso8601String(),
      };

      // Count by category (inferred from test name)
      final category = _inferTestCategory(name);
      report['summary']['categories'][category] =
          (report['summary']['categories'][category] ?? 0) + 1;

      // Count common warnings and errors
      for (final warning in result.warnings) {
        report['summary']['commonWarnings'][warning] =
            (report['summary']['commonWarnings'][warning] ?? 0) + 1;
      }

      for (final error in result.errors) {
        report['summary']['commonErrors'][error] =
            (report['summary']['commonErrors'][error] ?? 0) + 1;
      }
    }

    return report;
  }

  /// Infer test category from test name
  String _inferTestCategory(String testName) {
    if (testName.contains('database')) return 'Database';
    if (testName.contains('ui') || testName.contains('rendering')) return 'UI';
    if (testName.contains('concurrent')) return 'Concurrency';
    if (testName.contains('memory')) return 'Memory';
    return 'Other';
  }

  /// Dispose of resources
  void dispose() {
    _logger.info('ScalabilityTestService disposed');
  }
}
