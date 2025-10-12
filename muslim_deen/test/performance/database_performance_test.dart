import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Performance tests for database operations
void main() {
  group('Database Performance Tests', () {
    late DatabaseService databaseService;
    late LoggerService loggerService;

    setUpAll(() async {
      // Initialize FFI
      sqfliteFfiInit();
      // Set factory
      databaseFactory = databaseFactoryFfi;

      // Initialize service locator
      await setupLocator(testing: true);
      loggerService = locator<LoggerService>();
    });

    setUp(() async {
      databaseService = DatabaseService();
      await databaseService.init();
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('Settings CRUD operations performance', () async {
      const int testIterations = 1000;
      final List<Duration> saveTimes = [];
      final List<Duration> readTimes = [];
      final List<Duration> updateTimes = [];
      final List<Duration> deleteTimes = [];

      // Test save operations
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();
        await databaseService.saveSettings('test_key_$i', 'test_value_$i');
        stopwatch.stop();
        saveTimes.add(stopwatch.elapsed);
      }

      // Test read operations
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();
        await databaseService.getSettings('test_key_$i');
        stopwatch.stop();
        readTimes.add(stopwatch.elapsed);
      }

      // Test update operations
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();
        await databaseService.saveSettings('test_key_$i', 'updated_value_$i');
        stopwatch.stop();
        updateTimes.add(stopwatch.elapsed);
      }

      // Test delete operations
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();
        await databaseService.removeData('test_key_$i');
        stopwatch.stop();
        deleteTimes.add(stopwatch.elapsed);
      }

      // Calculate and verify performance metrics
      final avgSaveTime = _calculateAverageTime(saveTimes);
      final avgReadTime = _calculateAverageTime(readTimes);
      final avgUpdateTime = _calculateAverageTime(updateTimes);
      final avgDeleteTime = _calculateAverageTime(deleteTimes);

      loggerService.info(
        'Settings CRUD Performance Results',
        data: {
          'iterations': testIterations,
          'avgSaveTime': '${avgSaveTime.inMicroseconds}μs',
          'avgReadTime': '${avgReadTime.inMicroseconds}μs',
          'avgUpdateTime': '${avgUpdateTime.inMicroseconds}μs',
          'avgDeleteTime': '${avgDeleteTime.inMicroseconds}μs',
        },
      );

      // Performance assertions (adjust thresholds based on requirements)
      expect(
        avgSaveTime.inMilliseconds,
        lessThan(10),
        reason: 'Save operations should be under 10ms',
      );
      expect(
        avgReadTime.inMilliseconds,
        lessThan(5),
        reason: 'Read operations should be under 5ms',
      );
      expect(
        avgUpdateTime.inMilliseconds,
        lessThan(10),
        reason: 'Update operations should be under 10ms',
      );
      expect(
        avgDeleteTime.inMilliseconds,
        lessThan(5),
        reason: 'Delete operations should be under 5ms',
      );
    });

    test('Prayer history batch operations performance', () async {
      const int batchSize = 365; // One year of data
      final Map<String, String> prayerData = {};
      final List<Duration> batchInsertTimes = [];
      final List<Duration> batchReadTimes = [];

      // Generate test data
      final now = DateTime.now();
      for (int i = 0; i < batchSize; i++) {
        final date =
            now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
        prayerData[date] =
            'Fajr,Dhuhr,Asr,Maghrib,Isha'; // All prayers completed
      }

      // Test batch insert
      final stopwatch = Stopwatch()..start();
      await databaseService.batchInsertPrayerHistory(prayerData);
      stopwatch.stop();
      batchInsertTimes.add(stopwatch.elapsed);

      // Test batch read
      final dates = prayerData.keys.toList();
      stopwatch.reset();
      stopwatch.start();
      await databaseService.getPrayerHistoryBatch(dates);
      stopwatch.stop();
      batchReadTimes.add(stopwatch.elapsed);

      // Performance metrics
      final avgBatchInsertTime = _calculateAverageTime(batchInsertTimes);
      final avgBatchReadTime = _calculateAverageTime(batchReadTimes);

      loggerService.info(
        'Prayer History Batch Performance',
        data: {
          'batchSize': batchSize,
          'avgBatchInsertTime': '${avgBatchInsertTime.inMilliseconds}ms',
          'avgBatchReadTime': '${avgBatchReadTime.inMilliseconds}ms',
          'insertRate':
              '${(batchSize / avgBatchInsertTime.inMilliseconds * 1000).toStringAsFixed(0)} records/sec',
          'readRate':
              '${(batchSize / avgBatchReadTime.inMilliseconds * 1000).toStringAsFixed(0)} records/sec',
        },
      );

      // Performance assertions
      expect(
        avgBatchInsertTime.inMilliseconds,
        lessThan(100),
        reason: 'Batch insert should be under 100ms',
      );
      expect(
        avgBatchReadTime.inMilliseconds,
        lessThan(50),
        reason: 'Batch read should be under 50ms',
      );
    });

    test('Tasbih history operations performance', () async {
      const int testIterations = 1000;
      final List<Duration> saveTimes = [];
      final List<Duration> readTimes = [];
      final List<Duration> batchReadTimes = [];

      // Test individual save operations
      for (int i = 0; i < testIterations; i++) {
        final date =
            DateTime.now()
                .subtract(Duration(days: i % 365))
                .toIso8601String()
                .split('T')[0];
        final dhikrTypes = [
          'SubhanAllah',
          'Alhamdulillah',
          'AllahuAkbar',
          'Astaghfirullah',
        ];
        final dhikrType = dhikrTypes[i % dhikrTypes.length];
        final count = Random().nextInt(100);

        final stopwatch = Stopwatch()..start();
        await databaseService.saveTasbihHistory(date, dhikrType, count);
        stopwatch.stop();
        saveTimes.add(stopwatch.elapsed);
      }

      // Test individual read operations
      for (int i = 0; i < testIterations; i++) {
        final date =
            DateTime.now()
                .subtract(Duration(days: i % 365))
                .toIso8601String()
                .split('T')[0];
        final stopwatch = Stopwatch()..start();
        await databaseService.getTasbihHistory(date);
        stopwatch.stop();
        readTimes.add(stopwatch.elapsed);
      }

      // Test batch read operations
      final dates = List.generate(
        365,
        (i) =>
            DateTime.now()
                .subtract(Duration(days: i))
                .toIso8601String()
                .split('T')[0],
      );
      final stopwatch = Stopwatch()..start();
      await databaseService.getTasbihHistoryBatch(dates);
      stopwatch.stop();
      batchReadTimes.add(stopwatch.elapsed);

      // Calculate performance metrics
      final avgSaveTime = _calculateAverageTime(saveTimes);
      final avgReadTime = _calculateAverageTime(readTimes);
      final avgBatchReadTime = _calculateAverageTime(batchReadTimes);

      loggerService.info(
        'Tasbih History Performance Results',
        data: {
          'iterations': testIterations,
          'avgSaveTime': '${avgSaveTime.inMicroseconds}μs',
          'avgReadTime': '${avgReadTime.inMicroseconds}μs',
          'avgBatchReadTime': '${avgBatchReadTime.inMilliseconds}ms',
          'batchSize': dates.length,
        },
      );

      // Performance assertions
      expect(
        avgSaveTime.inMilliseconds,
        lessThan(10),
        reason: 'Tasbih save should be under 10ms',
      );
      expect(
        avgReadTime.inMilliseconds,
        lessThan(5),
        reason: 'Tasbih read should be under 5ms',
      );
      expect(
        avgBatchReadTime.inMilliseconds,
        lessThan(50),
        reason: 'Tasbih batch read should be under 50ms',
      );
    });

    test('Database transaction performance', () async {
      const int transactionSize = 100;
      final List<Duration> transactionTimes = [];

      for (int i = 0; i < 10; i++) {
        // Run 10 transactions
        final stopwatch = Stopwatch()..start();

        await databaseService.transaction((txn) async {
          for (int j = 0; j < transactionSize; j++) {
            await txn.insert('settings', {
              'key': 'tx_test_${i}_$j',
              'value': 'tx_value_${i}_$j',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        });

        stopwatch.stop();
        transactionTimes.add(stopwatch.elapsed);
      }

      final avgTransactionTime = _calculateAverageTime(transactionTimes);
      final operationsPerSecond =
          (transactionSize / avgTransactionTime.inMilliseconds * 1000);

      loggerService.info(
        'Transaction Performance Results',
        data: {
          'transactionSize': transactionSize,
          'avgTransactionTime': '${avgTransactionTime.inMilliseconds}ms',
          'operationsPerSecond': operationsPerSecond.toStringAsFixed(0),
        },
      );

      // Performance assertions
      expect(
        avgTransactionTime.inMilliseconds,
        lessThan(200),
        reason: 'Transaction should be under 200ms',
      );
      expect(
        operationsPerSecond,
        greaterThan(500),
        reason: 'Should handle at least 500 operations/sec',
      );
    });

    test('Database connection health and metrics', () async {
      // Test connection health
      expect(
        databaseService.isHealthy,
        isTrue,
        reason: 'Database should be healthy',
      );

      // Test connection status
      final status = databaseService.getConnectionStatus();
      expect(status['initialized'], isTrue);
      expect(status['healthy'], isTrue);
      expect(status['activeConnections'], greaterThan(0));

      // Test performance metrics
      final metrics = databaseService.getMetrics();
      expect(metrics, isA<List<DatabaseMetrics>>());

      // Test average query time
      final avgQueryTime = databaseService.getAverageQueryTime();
      expect(avgQueryTime.inMilliseconds, greaterThanOrEqualTo(0));

      loggerService.info(
        'Database Health Metrics',
        data: {
          'connectionStatus': status,
          'metricsCount': metrics.length,
          'avgQueryTime': '${avgQueryTime.inMicroseconds}μs',
        },
      );
    });

    test('Large dataset performance test', () async {
      const int largeDatasetSize = 10000;
      final List<Duration> insertTimes = [];
      final List<Duration> queryTimes = [];

      // Insert large dataset
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < largeDatasetSize; i++) {
        final insertStopwatch = Stopwatch()..start();
        await databaseService.saveSettings('large_test_$i', 'large_value_$i');
        insertStopwatch.stop();
        insertTimes.add(insertStopwatch.elapsed);
      }
      stopwatch.stop();

      // Query performance with large dataset
      for (int i = 0; i < 100; i++) {
        // Sample 100 queries
        final randomIndex = Random().nextInt(largeDatasetSize);
        final queryStopwatch = Stopwatch()..start();
        await databaseService.getSettings('large_test_$randomIndex');
        queryStopwatch.stop();
        queryTimes.add(queryStopwatch.elapsed);
      }

      // Calculate metrics
      final avgInsertTime = _calculateAverageTime(insertTimes);
      final avgQueryTime = _calculateAverageTime(queryTimes);
      final totalInsertTime = stopwatch.elapsed;
      final insertRate =
          largeDatasetSize / totalInsertTime.inMilliseconds * 1000;

      loggerService.info(
        'Large Dataset Performance Results',
        data: {
          'datasetSize': largeDatasetSize,
          'totalInsertTime': '${totalInsertTime.inMilliseconds}ms',
          'avgInsertTime': '${avgInsertTime.inMicroseconds}μs',
          'avgQueryTime': '${avgQueryTime.inMicroseconds}μs',
          'insertRate': '${insertRate.toStringAsFixed(0)} records/sec',
        },
      );

      // Performance assertions for large dataset
      expect(
        avgInsertTime.inMilliseconds,
        lessThan(5),
        reason:
            'Individual inserts should be under 5ms even with large dataset',
      );
      expect(
        avgQueryTime.inMilliseconds,
        lessThan(2),
        reason: 'Queries should be under 2ms with large dataset',
      );
      expect(
        insertRate,
        greaterThan(1000),
        reason: 'Should maintain at least 1000 inserts/sec',
      );
    });

    test('Memory usage during database operations', () async {
      const int memoryTestIterations = 5000;

      // Get initial memory usage (simplified)
      final initialMetrics = await databaseService.getMetrics();

      // Perform intensive database operations
      for (int i = 0; i < memoryTestIterations; i++) {
        await databaseService.saveSettings('memory_test_$i', 'memory_value_$i');
        await databaseService.getSettings(
          'memory_test_${i ~/ 2}',
        ); // Read half of them
      }

      // Get final memory usage
      final finalMetrics = await databaseService.getMetrics();

      // Check if metrics history is properly managed
      expect(
        finalMetrics.length,
        lessThanOrEqualTo(100),
        reason: 'Metrics history should be limited',
      );

      loggerService.info(
        'Memory Usage Test Results',
        data: {
          'iterations': memoryTestIterations,
          'initialMetricsCount': initialMetrics.length,
          'finalMetricsCount': finalMetrics.length,
          'metricsGrowth': finalMetrics.length - initialMetrics.length,
        },
      );

      // Clean up test data
      for (int i = 0; i < memoryTestIterations; i++) {
        await databaseService.removeData('memory_test_$i');
      }
    });
  });
}

/// Calculate average time from a list of durations
Duration _calculateAverageTime(List<Duration> durations) {
  if (durations.isEmpty) return Duration.zero;

  final totalMicroseconds = durations
      .map((d) => d.inMicroseconds)
      .reduce((a, b) => a + b);

  return Duration(microseconds: totalMicroseconds ~/ durations.length);
}
