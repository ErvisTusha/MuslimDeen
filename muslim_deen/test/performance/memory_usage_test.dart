import 'package:flutter_test/flutter_test.dart';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Memory usage tests for the application
void main() {
  group('Memory Usage Tests', () {
    late DatabaseService databaseService;
    late CacheService cacheService;
    late PerformanceMonitoringService performanceService;
    late LoggerService loggerService;

    setUpAll(() async {
      await setupLocator(testing: true);
    });

    setUp(() async {
      databaseService = locator<DatabaseService>();
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
      performanceService.resetMetrics();
      await databaseService.close();
    });

    test('Database memory usage with large datasets', () async {
      const int datasetSize = 1000;

      // Get initial memory usage
      final initialMemory = await performanceService.getMemoryUsage();

      // Generate and save large dataset
      for (int i = 0; i < datasetSize; i++) {
        final date =
            DateTime.now()
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')[0];
        await databaseService.savePrayerHistory(
          date,
          '11111',
        ); // All prayers completed

        // Add tasbih history
        await databaseService.saveTasbihHistory(date, 'SubhanAllah', 33);
        await databaseService.saveTasbihHistory(date, 'Alhamdulillah', 33);
        await databaseService.saveTasbihHistory(date, 'AllahuAkbar', 34);
      }

      // Get memory usage after data insertion
      final afterInsertionMemory = await performanceService.getMemoryUsage();

      // Read all data back
      for (int i = 0; i < datasetSize; i++) {
        final date =
            DateTime.now()
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')[0];
        await databaseService.getPrayerHistory(date);
        await databaseService.getTasbihHistory(date);
      }

      // Get memory usage after data reading
      final afterReadingMemory = await performanceService.getMemoryUsage();

      // Clean up data
      for (int i = 0; i < datasetSize; i++) {
        final date =
            DateTime.now()
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')[0];
        await databaseService.removeData('prayer_history_$date');
        await databaseService.removeData('tasbih_history_${date}_SubhanAllah');
        await databaseService.removeData(
          'tasbih_history_${date}_Alhamdulillah',
        );
        await databaseService.removeData('tasbih_history_${date}_AllahuAkbar');
      }

      // Get final memory usage
      final finalMemory = await performanceService.getMemoryUsage();

      // Calculate memory metrics
      final memoryAfterInsertion = afterInsertionMemory['usedMemory'] ?? 0;
      final memoryAfterReading = afterReadingMemory['usedMemory'] ?? 0;
      final finalMemoryUsage = finalMemory['usedMemory'] ?? 0;
      final initialMemoryUsage = initialMemory['usedMemory'] ?? 0;

      final insertionGrowth = memoryAfterInsertion - initialMemoryUsage;
      final readingGrowth = memoryAfterReading - memoryAfterInsertion;
      final finalGrowth = finalMemoryUsage - initialMemoryUsage;

      loggerService.info(
        'Database Memory Usage Test Results',
        data: {
          'datasetSize': datasetSize,
          'initialMemory': initialMemoryUsage,
          'memoryAfterInsertion': memoryAfterInsertion,
          'memoryAfterReading': memoryAfterReading,
          'finalMemory': finalMemoryUsage,
          'insertionGrowth': insertionGrowth,
          'readingGrowth': readingGrowth,
          'finalGrowth': finalGrowth,
          'memoryPerRecord': insertionGrowth / datasetSize,
        },
      );

      // Memory assertions
      expect(
        insertionGrowth,
        lessThan(100 * 1024 * 1024),
        reason: 'Memory growth should be under 100MB for 1000 records',
      );
      expect(
        finalGrowth,
        lessThan(((insertionGrowth as int) * 0.2).toInt()),
        reason: 'Memory should be properly cleaned up',
      );
    });

    test('Cache memory usage with large datasets', () async {
      const int cacheSize = 500;

      // Get initial memory usage
      final initialMemory = await performanceService.getMemoryUsage();

      // Fill cache with large data
      for (int i = 0; i < cacheSize; i++) {
        final key = 'cache_test_$i';
        final value = List.generate(
          100,
          (index) => 'Large data string $index for $key',
        ).join(',');
        await cacheService.setCache(key, value);
      }

      // Get memory usage after caching
      final afterCachingMemory = await performanceService.getMemoryUsage();

      // Read all cached data
      for (int i = 0; i < cacheSize; i++) {
        final key = 'cache_test_$i';
        cacheService.getCache<String>(key);
      }

      // Get memory usage after reading
      final afterReadingMemory = await performanceService.getMemoryUsage();

      // Clear cache
      await cacheService.clearAllCache();

      // Get final memory usage
      final finalMemory = await performanceService.getMemoryUsage();

      // Calculate memory metrics
      final memoryAfterCaching = afterCachingMemory['usedMemory'] ?? 0;
      final memoryAfterReading = afterReadingMemory['usedMemory'] ?? 0;
      final finalMemoryUsage = finalMemory['usedMemory'] ?? 0;
      final initialMemoryUsage = initialMemory['usedMemory'] ?? 0;

      final cachingGrowth = memoryAfterCaching - initialMemoryUsage;
      final readingGrowth = memoryAfterReading - memoryAfterCaching;
      final finalGrowth = finalMemoryUsage - initialMemoryUsage;

      loggerService.info(
        'Cache Memory Usage Test Results',
        data: {
          'cacheSize': cacheSize,
          'initialMemory': initialMemoryUsage,
          'memoryAfterCaching': memoryAfterCaching,
          'memoryAfterReading': memoryAfterReading,
          'finalMemory': finalMemoryUsage,
          'cachingGrowth': cachingGrowth,
          'readingGrowth': readingGrowth,
          'finalGrowth': finalGrowth,
          'memoryPerCacheEntry': cachingGrowth / cacheSize,
        },
      );

      // Memory assertions
      expect(
        cachingGrowth,
        lessThan(50 * 1024 * 1024),
        reason: 'Memory growth should be under 50MB for 500 cache entries',
      );
      expect(
        finalGrowth,
        lessThan(((cachingGrowth as int) * 0.1).toInt()),
        reason: 'Cache should be properly cleared',
      );
    });

    test('Memory usage during concurrent operations', () async {
      const int concurrentOperations = 50;

      // Get initial memory usage
      final initialMemory = await performanceService.getMemoryUsage();

      // Create concurrent operations
      final futures = <Future<void>>[];

      for (int i = 0; i < concurrentOperations; i++) {
        futures.add(_performMemoryIntensiveOperation(i));
      }

      // Execute all operations concurrently
      await Future.wait(futures);

      // Get memory usage after operations
      final afterOperationsMemory = await performanceService.getMemoryUsage();

      // Force garbage collection simulation
      await Future<void>.delayed(const Duration(seconds: 1));

      // Get final memory usage
      final finalMemory = await performanceService.getMemoryUsage();

      // Calculate memory metrics
      final memoryAfterOperations = afterOperationsMemory['usedMemory'] ?? 0;
      final finalMemoryUsage = finalMemory['usedMemory'] ?? 0;
      final initialMemoryUsage = initialMemory['usedMemory'] ?? 0;

      final operationsGrowth = memoryAfterOperations - initialMemoryUsage;
      final finalGrowth = finalMemoryUsage - initialMemoryUsage;

      loggerService.info(
        'Concurrent Operations Memory Usage Test Results',
        data: {
          'concurrentOperations': concurrentOperations,
          'initialMemory': initialMemoryUsage,
          'memoryAfterOperations': memoryAfterOperations,
          'finalMemory': finalMemoryUsage,
          'operationsGrowth': operationsGrowth,
          'finalGrowth': finalGrowth,
        },
      );

      // Memory assertions
      expect(
        operationsGrowth,
        lessThan(50 * 1024 * 1024),
        reason: 'Memory growth should be under 50MB for concurrent operations',
      );
      expect(
        finalGrowth,
        lessThan(((operationsGrowth as int) * 0.3).toInt()),
        reason: 'Memory should be recovered after operations',
      );
    });

    test('Memory leak detection for long-running operations', () async {
      const int iterations = 100;
      final List<int> memorySnapshots = [];

      // Get initial memory usage
      final initialMemory = await performanceService.getMemoryUsage();
      memorySnapshots.add((initialMemory['usedMemory'] ?? 0) as int);

      // Perform operations in iterations
      for (int i = 0; i < iterations; i++) {
        // Create and use temporary data
        final tempData = List.generate(
          50,
          (index) => 'Temporary data $index for iteration $i',
        );

        // Save to database
        for (int j = 0; j < tempData.length; j++) {
          await databaseService.saveSettings('temp_${i}_$j', tempData[j]);
        }

        // Read from database
        for (int j = 0; j < tempData.length; j++) {
          await databaseService.getSettings('temp_${i}_$j');
        }

        // Clean up
        for (int j = 0; j < tempData.length; j++) {
          await databaseService.removeData('temp_${i}_$j');
        }

        // Take memory snapshot every 10 iterations
        if (i % 10 == 0) {
          final currentMemory = await performanceService.getMemoryUsage();
          memorySnapshots.add((currentMemory['usedMemory'] ?? 0) as int);
        }
      }

      // Get final memory usage
      final finalMemory = await performanceService.getMemoryUsage();
      memorySnapshots.add((finalMemory['usedMemory'] ?? 0) as int);

      // Calculate memory growth trend
      final initialMemoryUsage = memorySnapshots.first;
      final finalMemoryUsage = memorySnapshots.last;
      final totalGrowth = finalMemoryUsage - initialMemoryUsage;

      // Check for memory leaks (memory should not continuously grow)
      bool memoryLeakDetected = false;
      for (int i = 1; i < memorySnapshots.length; i++) {
        final growth = memorySnapshots[i] - memorySnapshots[i - 1];
        if (growth > 10 * 1024 * 1024) {
          // More than 10MB growth between snapshots
          memoryLeakDetected = true;
          break;
        }
      }

      loggerService.info(
        'Memory Leak Detection Test Results',
        data: {
          'iterations': iterations,
          'initialMemory': initialMemoryUsage,
          'finalMemory': finalMemoryUsage,
          'totalGrowth': totalGrowth,
          'memorySnapshots': memorySnapshots,
          'memoryLeakDetected': memoryLeakDetected,
        },
      );

      // Memory assertions
      expect(
        memoryLeakDetected,
        isFalse,
        reason: 'No memory leaks should be detected',
      );
      expect(
        totalGrowth,
        lessThan(20 * 1024 * 1024),
        reason: 'Total memory growth should be under 20MB',
      );
    });

    test('Memory usage optimization with cache invalidation', () async {
      const int cacheSize = 200;

      // Get initial memory usage
      final initialMemory = await performanceService.getMemoryUsage();

      // Fill cache with data
      for (int i = 0; i < cacheSize; i++) {
        final key = 'optimization_test_$i';
        final value = List.generate(
          50,
          (index) => 'Optimization test data $index for $key',
        ).join(',');
        await cacheService.setCache(key, value);
      }

      // Get memory usage after caching
      final afterCachingMemory = await performanceService.getMemoryUsage();

      // Access only a subset of cache entries (to test LRU behavior)
      for (int i = 0; i < cacheSize ~/ 2; i++) {
        final key = 'optimization_test_$i';
        cacheService.getCache<String>(key);
      }

      // Get memory usage after partial access
      final afterAccessMemory = await performanceService.getMemoryUsage();

      // Force cache cleanup
      await cacheService.forceCleanup();

      // Get memory usage after cleanup
      final afterCleanupMemory = await performanceService.getMemoryUsage();

      // Calculate memory metrics
      final memoryAfterCaching = (afterCachingMemory['usedMemory'] ?? 0) as int;
      final memoryAfterAccess = (afterAccessMemory['usedMemory'] ?? 0) as int;
      final memoryAfterCleanup = (afterCleanupMemory['usedMemory'] ?? 0) as int;
      final initialMemoryUsage = (initialMemory['usedMemory'] ?? 0) as int;

      final cachingGrowth = memoryAfterCaching - initialMemoryUsage;
      final accessGrowth = memoryAfterAccess - memoryAfterCaching;
      final cleanupGrowth = memoryAfterCleanup - memoryAfterCaching;

      loggerService.info(
        'Memory Optimization Test Results',
        data: {
          'cacheSize': cacheSize,
          'initialMemory': initialMemoryUsage,
          'memoryAfterCaching': memoryAfterCaching,
          'memoryAfterAccess': memoryAfterAccess,
          'memoryAfterCleanup': memoryAfterCleanup,
          'cachingGrowth': cachingGrowth,
          'accessGrowth': accessGrowth,
          'cleanupGrowth': cleanupGrowth,
          'optimizationRatio':
              (cleanupGrowth / cachingGrowth * 100).toStringAsFixed(2) + '%',
        },
      );

      // Memory assertions
      expect(
        cachingGrowth,
        greaterThan(0),
        reason: 'Memory should grow when caching data',
      );
      expect(
        cleanupGrowth,
        lessThan(cachingGrowth * 0.5),
        reason: 'Cache cleanup should free significant memory',
      );
    });
  });
}

/// Perform a memory-intensive operation for testing
Future<void> _performMemoryIntensiveOperation(int operationId) async {
  // Create temporary data
  final tempData = List.generate(
    100,
    (index) => 'Memory intensive data $index for operation $operationId',
  );

  // Use database service
  for (int i = 0; i < tempData.length; i++) {
    await locator<DatabaseService>().saveSettings(
      'mem_test_${operationId}_$i',
      tempData[i],
    );
  }

  // Read data back
  for (int i = 0; i < tempData.length; i++) {
    await locator<DatabaseService>().getSettings('mem_test_${operationId}_$i');
  }

  // Clean up
  for (int i = 0; i < tempData.length; i++) {
    await locator<DatabaseService>().removeData('mem_test_${operationId}_$i');
  }
}
