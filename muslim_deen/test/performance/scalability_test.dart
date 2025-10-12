import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/scalability_test_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Scalability tests for measuring performance under load
void main() {
  group('Scalability Tests', () {
    late DatabaseService databaseService;
    late ScalabilityTestService scalabilityService;
    late LoggerService loggerService;

    setUpAll(() async {
      // Initialize FFI
      sqfliteFfiInit();
      // Set factory
      databaseFactory = databaseFactoryFfi;

      // Initialize service locator
      await setupLocator(testing: true);
    });

    setUp(() async {
      databaseService = locator<DatabaseService>();
      scalabilityService = locator<ScalabilityTestService>();
      loggerService = locator<LoggerService>();

      // Initialize services
      await databaseService.init();
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('Database scalability test', () async {
      // Run database scalability test
      final result = await scalabilityService.runTest('database_scalability');

      // Verify test completed
      expect(result.name, equals('database_scalability'));
      expect(result.metrics, isNotNull);
      expect(result.warnings, isNotNull);
      expect(result.errors, isNotNull);

      // Log detailed results
      loggerService.info(
        'Database Scalability Test Results',
        data: {
          'passedThresholds': result.passedThresholds,
          'warnings': result.warnings,
          'errors': result.errors,
          'metrics': result.metrics,
        },
      );

      // Verify key metrics are present
      expect(result.metrics.containsKey('maxMemoryUsageMB'), isTrue);
      expect(result.metrics.containsKey('avgOperationTimeMs'), isTrue);
      expect(result.metrics.containsKey('minThroughputOpsPerSec'), isTrue);

      // Performance assertions (may need adjustment based on test environment)
      expect(
        result.metrics['maxMemoryUsageMB'] as double,
        lessThan(100.0),
        reason: 'Max memory usage should be under 100MB',
      );
      expect(
        result.metrics['avgOperationTimeMs'] as double,
        lessThan(50.0),
        reason: 'Average operation time should be under 50ms',
      );
      expect(
        result.metrics['minThroughputOpsPerSec'] as double,
        greaterThan(100.0),
        reason: 'Minimum throughput should be over 100 ops/sec',
      );
    });

    test('UI rendering scalability test', () async {
      // Run UI rendering scalability test
      final result = await scalabilityService.runTest(
        'ui_rendering_scalability',
      );

      // Verify test completed
      expect(result.name, equals('ui_rendering_scalability'));
      expect(result.metrics, isNotNull);
      expect(result.warnings, isNotNull);
      expect(result.errors, isNotNull);

      // Log detailed results
      loggerService.info(
        'UI Rendering Scalability Test Results',
        data: {
          'passedThresholds': result.passedThresholds,
          'warnings': result.warnings,
          'errors': result.errors,
          'metrics': result.metrics,
        },
      );

      // Verify key metrics are present
      expect(result.metrics.containsKey('maxFrameTimeMs'), isTrue);
      expect(result.metrics.containsKey('avgFrameTimeMs'), isTrue);
      expect(result.metrics.containsKey('minThroughputFps'), isTrue);

      // Performance assertions
      expect(
        result.metrics['maxFrameTimeMs'] as double,
        lessThan(33.33),
        reason: 'Max frame time should be under 33.33ms (30 FPS)',
      );
      expect(
        result.metrics['minThroughputFps'] as double,
        greaterThan(30.0),
        reason: 'Minimum throughput should be over 30 FPS',
      );
    });

    test('Concurrent operations scalability test', () async {
      // Run concurrent operations scalability test
      final result = await scalabilityService.runTest(
        'concurrent_operations_scalability',
      );

      // Verify test completed
      expect(result.name, equals('concurrent_operations_scalability'));
      expect(result.metrics, isNotNull);
      expect(result.warnings, isNotNull);
      expect(result.errors, isNotNull);

      // Log detailed results
      loggerService.info(
        'Concurrent Operations Scalability Test Results',
        data: {
          'passedThresholds': result.passedThresholds,
          'warnings': result.warnings,
          'errors': result.errors,
          'metrics': result.metrics,
        },
      );

      // Verify key metrics are present
      expect(result.metrics.containsKey('maxResponseTimeMs'), isTrue);
      expect(result.metrics.containsKey('maxErrorRatePercent'), isTrue);
      expect(result.metrics.containsKey('minThroughputOpsPerSec'), isTrue);

      // Performance assertions
      expect(
        result.metrics['maxResponseTimeMs'] as double,
        lessThan(5000.0),
        reason: 'Max response time should be under 5 seconds',
      );
      expect(
        result.metrics['maxErrorRatePercent'] as double,
        lessThan(5.0),
        reason: 'Max error rate should be under 5%',
      );
      expect(
        result.metrics['minThroughputOpsPerSec'] as double,
        greaterThan(50.0),
        reason: 'Minimum throughput should be over 50 ops/sec',
      );
    });

    test('Memory stress test', () async {
      // Run memory stress test
      final result = await scalabilityService.runTest('memory_stress_test');

      // Verify test completed
      expect(result.name, equals('memory_stress_test'));
      expect(result.metrics, isNotNull);
      expect(result.warnings, isNotNull);
      expect(result.errors, isNotNull);

      // Log detailed results
      loggerService.info(
        'Memory Stress Test Results',
        data: {
          'passedThresholds': result.passedThresholds,
          'warnings': result.warnings,
          'errors': result.errors,
          'metrics': result.metrics,
        },
      );

      // Verify key metrics are present
      expect(result.metrics.containsKey('maxMemoryUsageMB'), isTrue);
      expect(result.metrics.containsKey('maxMemoryLeakMB'), isTrue);
      expect(result.metrics.containsKey('maxGcTimeMs'), isTrue);

      // Performance assertions
      expect(
        result.metrics['maxMemoryUsageMB'] as double,
        lessThan(300.0),
        reason: 'Max memory usage should be under 300MB',
      );
      expect(
        result.metrics['maxMemoryLeakMB'] as double,
        lessThan(20.0),
        reason: 'Max memory leak should be under 20MB',
      );
      expect(
        result.metrics['maxGcTimeMs'] as double,
        lessThan(100.0),
        reason: 'Max GC time should be under 100ms',
      );
    });

    test('Custom scalability test configuration', () async {
      // Create custom test configuration
      final customConfig = ScalabilityTestConfig(
        name: 'custom_database_test',
        description: 'Custom database test with smaller parameters',
        parameters: {
          'startRecords': 10,
          'maxRecords': 100,
          'incrementStep': 10,
          'operationsPerRecord': 2,
        },
        thresholds: {
          'maxMemoryGrowthMB': 10.0,
          'maxAvgOperationTimeMs': 5.0,
          'minThroughputOpsPerSec': 200.0,
        },
        timeout: const Duration(minutes: 2),
      );

      // Register custom test
      scalabilityService.registerTestConfig(customConfig);

      // Verify test config was registered
      final retrievedConfig = scalabilityService.getTestConfig(
        'custom_database_test',
      );
      expect(retrievedConfig, isNotNull);
      expect(retrievedConfig!.name, equals('custom_database_test'));
      expect(retrievedConfig.parameters['maxRecords'], equals(100));
      expect(retrievedConfig.thresholds['maxMemoryGrowthMB'], equals(10.0));

      // Run custom test
      final result = await scalabilityService.runTestWithConfig(customConfig);

      // Verify test completed
      expect(result.name, equals('custom_database_test'));
      expect(result.metrics, isNotNull);
      expect(result.warnings, isNotNull);
      expect(result.errors, isNotNull);

      // Log detailed results
      loggerService.info(
        'Custom Scalability Test Results',
        data: {
          'passedThresholds': result.passedThresholds,
          'warnings': result.warnings,
          'errors': result.errors,
          'metrics': result.metrics,
        },
      );

      // Performance assertions based on custom thresholds
      expect(
        result.metrics['maxMemoryUsageMB'] as double,
        lessThan(50.0),
        reason: 'Max memory usage should be under 50MB for custom test',
      );
    });

    test('Comprehensive scalability report', () async {
      // Run all default tests
      await scalabilityService.runTest('database_scalability');
      await scalabilityService.runTest('ui_rendering_scalability');
      await scalabilityService.runTest('concurrent_operations_scalability');
      await scalabilityService.runTest('memory_stress_test');

      // Generate comprehensive report
      final report = scalabilityService.generateScalabilityReport();

      // Verify report structure
      expect(report['totalTests'], equals(4));
      expect(report['passedTests'] + report['failedTests'], equals(4));
      expect(report['testResults'], isNotNull);
      expect(report['summary'], isNotNull);

      // Verify categories
      final categories =
          report['summary']['categories'] as Map<String, dynamic>;
      expect(categories['Database'], greaterThan(0));
      expect(categories['UI'], greaterThan(0));
      expect(categories['Concurrency'], greaterThan(0));
      expect(categories['Memory'], greaterThan(0));

      // Log comprehensive report
      loggerService.info('Comprehensive Scalability Report', data: report);

      // Verify test results are in report
      final testResults = report['testResults'] as Map<String, dynamic>;
      expect(testResults.containsKey('database_scalability'), isTrue);
      expect(testResults.containsKey('ui_rendering_scalability'), isTrue);
      expect(
        testResults.containsKey('concurrent_operations_scalability'),
        isTrue,
      );
      expect(testResults.containsKey('memory_stress_test'), isTrue);
    });

    test('Scalability test result retrieval', () async {
      // Run a test
      await scalabilityService.runTest('database_scalability');

      // Retrieve test result
      final result = scalabilityService.getTestResult('database_scalability');
      expect(result, isNotNull);
      expect(result!.name, equals('database_scalability'));
      expect(result.metrics, isNotNull);

      // Retrieve all test results
      final allResults = scalabilityService.getAllTestResults();
      expect(allResults, isNotNull);
      expect(allResults.containsKey('database_scalability'), isTrue);

      // Get all test configurations
      final allConfigs = scalabilityService.getAllTestConfigs();
      expect(allConfigs.length, greaterThan(4)); // At least 4 default tests

      // Log retrieval test results
      loggerService.info(
        'Scalability Test Retrieval Results',
        data: {
          'resultCount': allResults.length,
          'configCount': allConfigs.length,
          'resultName': result.name,
        },
      );
    });
  });
}
