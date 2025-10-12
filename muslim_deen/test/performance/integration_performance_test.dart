import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Integration performance tests for end-to-end performance validation
void main() {
  group('Integration Performance Tests', () {
    late ProviderContainer container;
    late DatabaseService databaseService;
    late PrayerService prayerService;
    late CacheService cacheService;
    late PerformanceMonitoringService performanceService;
    late LoggerService loggerService;

    setUpAll(() async {
      await setupLocator(testing: true);
    });

    setUp(() async {
      container = ProviderContainer();
      databaseService = locator<DatabaseService>();
      prayerService = locator<PrayerService>();
      cacheService = locator<CacheService>();
      performanceService = locator<PerformanceMonitoringService>();
      loggerService = locator<LoggerService>();

      // Initialize services
      await databaseService.init();

      performanceService.initialize(
        enableMonitoring: true,
        enableFrameRateMonitoring: true,
        enableWidgetBuildTracking: true,
      );
    });

    tearDown(() async {
      container.dispose();
      performanceService.resetMetrics();
      await databaseService.close();
    });

    test('End-to-end prayer times calculation performance', () async {
      const int testIterations = 50;
      final List<Duration> calculationTimes = [];

      // Test location
      final DateTime testDate = DateTime.now();

      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();

        // Calculate prayer times
        final prayerTimes = await prayerService.calculatePrayerTimesForDate(
          testDate,
          null,
        );

        stopwatch.stop();
        calculationTimes.add(stopwatch.elapsed);

        // Verify we got valid prayer times
        expect(prayerTimes, isNotNull);
        // PrayerTimes object doesn't have a length property, but we can check if it has valid times
        expect(prayerTimes.fajr, isNotNull);
      }

      // Calculate performance metrics
      final avgCalculationTime = _calculateAverageTime(calculationTimes);
      final maxCalculationTime = _calculateMaxTime(calculationTimes);

      loggerService.info(
        'Prayer Times Calculation Performance',
        data: {
          'iterations': testIterations,
          'avgCalculationTime': '${avgCalculationTime.inMilliseconds}ms',
          'maxCalculationTime': '${maxCalculationTime.inMilliseconds}ms',
          'location': 'New York',
          'date': testDate.toIso8601String(),
        },
      );

      // Performance assertions
      expect(
        avgCalculationTime.inMilliseconds,
        lessThan(100),
        reason: 'Average calculation time should be under 100ms',
      );
      expect(
        maxCalculationTime.inMilliseconds,
        lessThan(200),
        reason: 'Max calculation time should be under 200ms',
      );
    });

    test('Database and cache integration performance', () async {
      const int testIterations = 100;
      final List<Duration> dbOperations = [];
      final List<Duration> cacheOperations = [];
      final List<Duration> integratedOperations = [];

      for (int i = 0; i < testIterations; i++) {
        final testKey = 'integration_test_$i';
        final testValue = 'integration_value_$i';

        // Test database operation
        final dbStopwatch = Stopwatch()..start();
        await databaseService.saveSettings(testKey, testValue);
        final dbResult = await databaseService.getSettings(testKey);
        dbStopwatch.stop();
        dbOperations.add(dbStopwatch.elapsed);

        // Test cache operation
        final cacheStopwatch = Stopwatch()..start();
        await cacheService.saveData(testKey, testValue);
        final cacheResult = cacheService.getData(testKey);
        cacheStopwatch.stop();
        cacheOperations.add(cacheStopwatch.elapsed);

        // Test integrated operation (read from cache first, fallback to DB)
        final integratedStopwatch = Stopwatch()..start();

        // Try cache first
        var result = cacheService.getData(testKey);
        if (result == null) {
          // Fallback to database
          result = await databaseService.getSettings(testKey);
          if (result != null) {
            // Store in cache for next time
            await cacheService.saveData(testKey, result);
          }
        }

        integratedStopwatch.stop();
        integratedOperations.add(integratedStopwatch.elapsed);

        // Verify results
        expect(dbResult, equals(testValue));
        expect(cacheResult, equals(testValue));
        expect(result, equals(testValue));
      }

      // Calculate performance metrics
      final avgDbTime = _calculateAverageTime(dbOperations);
      final avgCacheTime = _calculateAverageTime(cacheOperations);
      final avgIntegratedTime = _calculateAverageTime(integratedOperations);

      loggerService.info(
        'Database and Cache Integration Performance',
        data: {
          'iterations': testIterations,
          'avgDbTime': '${avgDbTime.inMicroseconds}μs',
          'avgCacheTime': '${avgCacheTime.inMicroseconds}μs',
          'avgIntegratedTime': '${avgIntegratedTime.inMicroseconds}μs',
          'cacheSpeedup':
              '${(avgDbTime.inMicroseconds / avgCacheTime.inMicroseconds).toStringAsFixed(2)}x',
          'integratedSpeedup':
              '${(avgDbTime.inMicroseconds / avgIntegratedTime.inMicroseconds).toStringAsFixed(2)}x',
        },
      );

      // Performance assertions
      expect(
        avgCacheTime.inMicroseconds,
        lessThan(avgDbTime.inMicroseconds),
        reason: 'Cache should be faster than database',
      );
      expect(
        avgIntegratedTime.inMicroseconds,
        lessThan(avgDbTime.inMicroseconds),
        reason: 'Integrated operation should be faster than database alone',
      );
    });

    test('Prayer history data flow performance', () async {
      const int testDays = 365; // One year of data
      final List<Duration> saveTimes = [];
      final List<Duration> readTimes = [];
      final List<Duration> batchReadTimes = [];

      // Generate test data
      final Map<String, String> prayerHistoryData = {};
      final now = DateTime.now();

      for (int i = 0; i < testDays; i++) {
        final date =
            now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        final completedPrayers = List.generate(
          5,
          (index) => index % 2 == 0 ? '1' : '0',
        ).join('');
        prayerHistoryData[date] = completedPrayers;
      }

      // Test individual save operations
      for (final entry in prayerHistoryData.entries) {
        final stopwatch = Stopwatch()..start();
        await databaseService.savePrayerHistory(entry.key, entry.value);
        stopwatch.stop();
        saveTimes.add(stopwatch.elapsed);
      }

      // Test individual read operations
      for (final entry in prayerHistoryData.entries) {
        final stopwatch = Stopwatch()..start();
        await databaseService.getPrayerHistory(entry.key);
        stopwatch.stop();
        readTimes.add(stopwatch.elapsed);
      }

      // Test batch read operation
      final batchStopwatch = Stopwatch()..start();
      await databaseService.getPrayerHistoryBatch(
        prayerHistoryData.keys.toList(),
      );
      batchStopwatch.stop();
      batchReadTimes.add(batchStopwatch.elapsed);

      // Calculate performance metrics
      final avgSaveTime = _calculateAverageTime(saveTimes);
      final avgReadTime = _calculateAverageTime(readTimes);
      final avgBatchReadTime = _calculateAverageTime(batchReadTimes);

      loggerService.info(
        'Prayer History Data Flow Performance',
        data: {
          'testDays': testDays,
          'avgSaveTime': '${avgSaveTime.inMicroseconds}μs',
          'avgReadTime': '${avgReadTime.inMicroseconds}μs',
          'avgBatchReadTime': '${avgBatchReadTime.inMilliseconds}ms',
          'batchReadRate':
              '${(testDays / avgBatchReadTime.inMilliseconds * 1000).toStringAsFixed(0)} records/sec',
          'batchSpeedup':
              '${(avgReadTime.inMicroseconds * testDays / avgBatchReadTime.inMicroseconds).toStringAsFixed(2)}x',
        },
      );

      // Performance assertions
      expect(
        avgSaveTime.inMilliseconds,
        lessThan(10),
        reason: 'Individual save should be under 10ms',
      );
      expect(
        avgReadTime.inMilliseconds,
        lessThan(5),
        reason: 'Individual read should be under 5ms',
      );
      expect(
        avgBatchReadTime.inMilliseconds,
        lessThan(100),
        reason: 'Batch read should be under 100ms',
      );
    });

    test('Memory usage during extended operations', () async {
      const int operationCount = 1000;

      // Get initial memory metrics
      final initialMemory = await performanceService.getMemoryUsage();

      // Perform extended operations
      for (int i = 0; i < operationCount; i++) {
        // Mix of different operations
        switch (i % 4) {
          case 0:
            await databaseService.saveSettings('memory_test_$i', 'value_$i');
            break;
          case 1:
            await databaseService.getSettings('memory_test_${i ~/ 2}');
            break;
          case 2:
            await cacheService.saveData('cache_test_$i', 'cache_value_$i');
            break;
          case 3:
            cacheService.getData('cache_test_${i ~/ 2}');
            break;
        }

        // Periodically check memory usage
        if (i % 100 == 0) {
          final currentMemory = await performanceService.getMemoryUsage();
          loggerService.debug(
            'Memory usage at iteration $i',
            data: currentMemory,
          );
        }
      }

      // Get final memory metrics
      final finalMemory = await performanceService.getMemoryUsage();

      loggerService.info(
        'Extended Operations Memory Usage',
        data: {
          'operationCount': operationCount,
          'initialMemory': initialMemory,
          'finalMemory': finalMemory,
        },
      );

      // Check for memory leaks
      if (initialMemory['usedMemory'] != null &&
          finalMemory['usedMemory'] != null) {
        final memoryGrowth =
            finalMemory['usedMemory'] - initialMemory['usedMemory'];
        final growthPercentage =
            (memoryGrowth / initialMemory['usedMemory'] * 100);

        loggerService.info(
          'Memory Growth Analysis',
          data: {
            'memoryGrowth': memoryGrowth,
            'growthPercentage': '${growthPercentage.toStringAsFixed(2)}%',
          },
        );

        // Memory growth should be reasonable for the operations performed
        expect(
          growthPercentage,
          lessThan(200),
          reason: 'Memory growth should be under 200% for extended operations',
        );
      }
    });

    test('Concurrent operations performance', () async {
      const int concurrentOperations = 50;
      final List<Duration> operationTimes = [];

      // Create a list of concurrent operations
      final futures = <Future<void>>[];

      for (int i = 0; i < concurrentOperations; i++) {
        futures.add(_performConcurrentOperation(i, operationTimes));
      }

      // Execute all operations concurrently
      final stopwatch = Stopwatch()..start();
      await Future.wait(futures);
      stopwatch.stop();

      // Calculate performance metrics
      final totalConcurrentTime = stopwatch.elapsed;
      final avgOperationTime = _calculateAverageTime(operationTimes);
      final maxOperationTime = _calculateMaxTime(operationTimes);

      loggerService.info(
        'Concurrent Operations Performance',
        data: {
          'concurrentOperations': concurrentOperations,
          'totalConcurrentTime': '${totalConcurrentTime.inMilliseconds}ms',
          'avgOperationTime': '${avgOperationTime.inMicroseconds}μs',
          'maxOperationTime': '${maxOperationTime.inMicroseconds}μs',
          'concurrentEfficiency':
              '${(concurrentOperations * avgOperationTime.inMicroseconds / totalConcurrentTime.inMicroseconds * 100).toStringAsFixed(2)}%',
        },
      );

      // Performance assertions
      expect(
        totalConcurrentTime.inMilliseconds,
        lessThan(1000),
        reason: 'Concurrent operations should complete within 1 second',
      );
      expect(
        avgOperationTime.inMilliseconds,
        lessThan(100),
        reason: 'Average operation time should be under 100ms',
      );
    });

    test('Performance regression detection', () async {
      // Define performance budgets
      const int maxDbOperationTime = 10; // ms
      const int maxCacheOperationTime = 5; // ms
      const int maxPrayerCalculationTime = 100; // ms

      bool regressionDetected = false;
      final List<String> regressionMessages = [];

      // Test database performance
      final dbStopwatch = Stopwatch()..start();
      await databaseService.saveSettings('regression_test', 'regression_value');
      await databaseService.getSettings('regression_test');
      dbStopwatch.stop();

      if (dbStopwatch.elapsed.inMilliseconds > maxDbOperationTime) {
        regressionDetected = true;
        regressionMessages.add(
          'Database operation exceeded budget: ${dbStopwatch.elapsed.inMilliseconds}ms > ${maxDbOperationTime}ms',
        );
      }

      // Test cache performance
      final cacheStopwatch = Stopwatch()..start();
      await cacheService.saveData('regression_test', 'regression_value');
      cacheService.getData('regression_test');
      cacheStopwatch.stop();

      if (cacheStopwatch.elapsed.inMilliseconds > maxCacheOperationTime) {
        regressionDetected = true;
        regressionMessages.add(
          'Cache operation exceeded budget: ${cacheStopwatch.elapsed.inMilliseconds}ms > ${maxCacheOperationTime}ms',
        );
      }

      // Test prayer calculation performance
      final prayerStopwatch = Stopwatch()..start();
      await prayerService.calculatePrayerTimesForDate(DateTime.now(), null);
      prayerStopwatch.stop();

      if (prayerStopwatch.elapsed.inMilliseconds > maxPrayerCalculationTime) {
        regressionDetected = true;
        regressionMessages.add(
          'Prayer calculation exceeded budget: ${prayerStopwatch.elapsed.inMilliseconds}ms > ${maxPrayerCalculationTime}ms',
        );
      }

      // Log regression test results
      loggerService.info(
        'Performance Regression Test Results',
        data: {
          'regressionDetected': regressionDetected,
          'regressionMessages': regressionMessages,
          'dbOperationTime': '${dbStopwatch.elapsed.inMilliseconds}ms',
          'cacheOperationTime': '${cacheStopwatch.elapsed.inMilliseconds}ms',
          'prayerCalculationTime':
              '${prayerStopwatch.elapsed.inMilliseconds}ms',
        },
      );

      // Fail test if regressions detected
      if (regressionDetected) {
        fail(
          'Performance regressions detected:\n${regressionMessages.join('\n')}',
        );
      }
    });
  });
}

/// Perform a concurrent operation for testing
Future<void> _performConcurrentOperation(
  int operationId,
  List<Duration> operationTimes,
) async {
  final stopwatch = Stopwatch()..start();

  // Mix of different operations
  switch (operationId % 3) {
    case 0:
      // Database operation
      await locator<DatabaseService>().saveSettings(
        'concurrent_$operationId',
        'value_$operationId',
      );
      await locator<DatabaseService>().getSettings('concurrent_$operationId');
      break;
    case 1:
      // Cache operation
      await locator<CacheService>().saveData(
        'concurrent_cache_$operationId',
        'cache_value_$operationId',
      );
      locator<CacheService>().getData('concurrent_cache_$operationId');
      break;
    case 2:
      // Prayer calculation
      // For prayer service, we need to use calculatePrayerTimesForDate
      // but it uses the device location, so we'll just test calculation performance
      await locator<PrayerService>().calculatePrayerTimesForDate(
        DateTime.now().add(Duration(days: operationId % 30)),
        null,
      );
      break;
  }

  stopwatch.stop();
  operationTimes.add(stopwatch.elapsed);
}

/// Calculate average time from a list of durations
Duration _calculateAverageTime(List<Duration> durations) {
  if (durations.isEmpty) return Duration.zero;

  final totalMicroseconds = durations
      .map((d) => d.inMicroseconds)
      .reduce((a, b) => a + b);

  return Duration(microseconds: totalMicroseconds ~/ durations.length);
}

/// Calculate maximum time from a list of durations
Duration _calculateMaxTime(List<Duration> durations) {
  if (durations.isEmpty) return Duration.zero;

  return durations.reduce((a, b) => a > b ? a : b);
}
