import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/cache_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/benchmark_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Benchmark tests for measuring and comparing performance
void main() {
  group('Benchmark Tests', () {
    late DatabaseService databaseService;
    late CacheService cacheService;
    late PrayerService prayerService;
    late BenchmarkService benchmarkService;
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
      cacheService = locator<CacheService>();
      prayerService = locator<PrayerService>();
      benchmarkService = locator<BenchmarkService>();
      loggerService = locator<LoggerService>();

      // Initialize services
      await databaseService.init();
    });

    tearDown(() async {
      benchmarkService.clearAllBenchmarks();
      await databaseService.close();
    });

    test('Database CRUD operations benchmark', () async {
      const int iterations = 100;

      // Benchmark database save operations
      final saveResult = await benchmarkService.runBenchmark(
        'database_save',
        'database',
        () async {
          for (int i = 0; i < iterations; i++) {
            await databaseService.saveSettings(
              'benchmark_key_$i',
              'benchmark_value_$i',
            );
          }
        },
        iterations: 5,
        metadata: {'iterations': iterations, 'operation': 'save'},
        saveAsBaseline: true,
      );

      // Benchmark database read operations
      final readResult = await benchmarkService.runBenchmark(
        'database_read',
        'database',
        () async {
          for (int i = 0; i < iterations; i++) {
            await databaseService.getSettings('benchmark_key_$i');
          }
        },
        iterations: 5,
        metadata: {'iterations': iterations, 'operation': 'read'},
      );

      // Benchmark database batch operations
      final batchResult = await benchmarkService.runBenchmark(
        'database_batch',
        'database',
        () async {
          final batch = <String, String>{};
          for (int i = 0; i < iterations; i++) {
            batch['batch_key_$i'] = 'batch_value_$i';
          }

          for (final entry in batch.entries) {
            await databaseService.saveSettings(entry.key, entry.value);
          }
        },
        iterations: 5,
        metadata: {'iterations': iterations, 'operation': 'batch'},
      );

      // Verify results
      expect(saveResult.iterations, equals(5));
      expect(readResult.iterations, equals(5));
      expect(batchResult.iterations, equals(5));

      // Log benchmark results
      loggerService.info(
        'Database Benchmark Results',
        data: {
          'save': {
            'average': '${saveResult.averageTime.inMicroseconds}μs',
            'min': '${saveResult.minTime.inMicroseconds}μs',
            'max': '${saveResult.maxTime.inMicroseconds}μs',
            'stdDev': saveResult.standardDeviation.toStringAsFixed(2),
          },
          'read': {
            'average': '${readResult.averageTime.inMicroseconds}μs',
            'min': '${readResult.minTime.inMicroseconds}μs',
            'max': '${readResult.maxTime.inMicroseconds}μs',
            'stdDev': readResult.standardDeviation.toStringAsFixed(2),
          },
          'batch': {
            'average': '${batchResult.averageTime.inMicroseconds}μs',
            'min': '${batchResult.minTime.inMicroseconds}μs',
            'max': '${batchResult.maxTime.inMicroseconds}μs',
            'stdDev': batchResult.standardDeviation.toStringAsFixed(2),
          },
        },
      );

      // Performance assertions
      expect(
        saveResult.averageTime.inMilliseconds,
        lessThan(50),
        reason: 'Database save should be under 50ms',
      );
      expect(
        readResult.averageTime.inMilliseconds,
        lessThan(20),
        reason: 'Database read should be under 20ms',
      );
      expect(
        batchResult.averageTime.inMilliseconds,
        lessThan(100),
        reason: 'Database batch should be under 100ms',
      );
    });

    test('Cache operations benchmark', () async {
      const int iterations = 200;

      // Benchmark cache set operations
      final setResult = await benchmarkService.runBenchmark(
        'cache_set',
        'cache',
        () async {
          for (int i = 0; i < iterations; i++) {
            await cacheService.saveData('cache_key_$i', 'cache_value_$i');
          }
        },
        iterations: 5,
        metadata: {'iterations': iterations, 'operation': 'set'},
        saveAsBaseline: true,
      );

      // Benchmark cache get operations
      final getResult = await benchmarkService.runBenchmark(
        'cache_get',
        'cache',
        () async {
          for (int i = 0; i < iterations; i++) {
            cacheService.getData('cache_key_$i');
          }
        },
        iterations: 5,
        metadata: {'iterations': iterations, 'operation': 'get'},
      );

      // Verify results
      expect(setResult.iterations, equals(5));
      expect(getResult.iterations, equals(5));

      // Log benchmark results
      loggerService.info(
        'Cache Benchmark Results',
        data: {
          'set': {
            'average': '${setResult.averageTime.inMicroseconds}μs',
            'min': '${setResult.minTime.inMicroseconds}μs',
            'max': '${setResult.maxTime.inMicroseconds}μs',
            'stdDev': setResult.standardDeviation.toStringAsFixed(2),
          },
          'get': {
            'average': '${getResult.averageTime.inMicroseconds}μs',
            'min': '${getResult.minTime.inMicroseconds}μs',
            'max': '${getResult.maxTime.inMicroseconds}μs',
            'stdDev': getResult.standardDeviation.toStringAsFixed(2),
          },
        },
      );

      // Performance assertions
      expect(
        setResult.averageTime.inMicroseconds,
        lessThan(200),
        reason: 'Cache set should be under 200μs',
      );
      expect(
        getResult.averageTime.inMicroseconds,
        lessThan(100),
        reason: 'Cache get should be under 100μs',
      );
    });

    test('Prayer calculation benchmark', () async {
      const int iterations = 10;

      // Benchmark prayer calculation
      final calcResult = await benchmarkService.runBenchmark(
        'prayer_calculation',
        'calculation',
        () async {
          for (int i = 0; i < iterations; i++) {
            await prayerService.calculatePrayerTimesForDate(
              DateTime.now().add(Duration(days: i)),
              null,
            );
          }
        },
        iterations: 3,
        metadata: {'iterations': iterations, 'operation': 'prayer_calculation'},
        saveAsBaseline: true,
      );

      // Verify results
      expect(calcResult.iterations, equals(3));

      // Log benchmark results
      loggerService.info(
        'Prayer Calculation Benchmark Results',
        data: {
          'calculation': {
            'average': '${calcResult.averageTime.inMilliseconds}ms',
            'min': '${calcResult.minTime.inMilliseconds}ms',
            'max': '${calcResult.maxTime.inMilliseconds}ms',
            'stdDev': calcResult.standardDeviation.toStringAsFixed(2),
          },
        },
      );

      // Performance assertions
      expect(
        calcResult.averageTime.inMilliseconds,
        lessThan(500),
        reason: 'Prayer calculation should be under 500ms',
      );
    });

    test('Benchmark comparison and regression detection', () async {
      const int iterations = 50;

      // Run initial benchmark (baseline)
      await benchmarkService.runBenchmark(
        'comparison_test',
        'regression',
        () async {
          for (int i = 0; i < iterations; i++) {
            await databaseService.saveSettings(
              'comparison_key_$i',
              'comparison_value_$i',
            );
          }
        },
        iterations: 3,
        metadata: {'iterations': iterations, 'version': 'baseline'},
        saveAsBaseline: true,
      );

      // Run improved benchmark
      await benchmarkService.runBenchmark(
        'comparison_test',
        'regression',
        () async {
          for (int i = 0; i < iterations; i++) {
            await databaseService.saveSettings(
              'comparison_key_$i',
              'comparison_value_$i',
            );
          }
        },
        iterations: 3,
        metadata: {'iterations': iterations, 'version': 'improved'},
      );

      // Compare with baseline
      final comparison = benchmarkService.compareWithBaseline(
        'comparison_test',
      );
      expect(comparison, isNotNull);
      expect(comparison!.name, equals('comparison_test'));

      // Log comparison results
      loggerService.info(
        'Benchmark Comparison Results',
        data: {
          'baselineTime': '${comparison.baseline.averageTime.inMicroseconds}μs',
          'currentTime': '${comparison.current.averageTime.inMicroseconds}μs',
          'improvementPercentage':
              '${comparison.improvementPercentage.toStringAsFixed(2)}%',
          'isRegression': comparison.isRegression,
        },
      );

      // Verify baseline was saved
      final baselines = benchmarkService.getAllBaselines();
      expect(baselines.containsKey('comparison_test'), isTrue);
    });

    test('Benchmark statistics and reporting', () async {
      // Run multiple benchmarks
      await benchmarkService.runBenchmark(
        'stats_test_1',
        'statistics',
        () async {
          for (int i = 0; i < 10; i++) {
            await databaseService.saveSettings(
              'stats_key_$i',
              'stats_value_$i',
            );
          }
        },
        iterations: 3,
        metadata: {'test': 'statistics'},
      );

      await benchmarkService.runBenchmark(
        'stats_test_2',
        'statistics',
        () async {
          for (int i = 0; i < 20; i++) {
            await databaseService.saveSettings(
              'stats_key_2_$i',
              'stats_value_2_$i',
            );
          }
        },
        iterations: 3,
        metadata: {'test': 'statistics'},
      );

      // Get benchmark statistics
      final stats = benchmarkService.getBenchmarkStatistics();
      expect(stats['totalBenchmarks'], equals(2));
      expect(stats['categories']['statistics'], equals(2));
      expect(stats['fastestBenchmark'], isNotNull);
      expect(stats['slowestBenchmark'], isNotNull);

      // Generate benchmark report
      final report = benchmarkService.generateBenchmarkReport();
      expect(report['totalBenchmarks'], equals(2));
      expect(report['benchmarks'], isNotNull);
      expect(report['categories'], isNotNull);

      // Log statistics and report
      loggerService.info('Benchmark Statistics', data: stats);
      loggerService.info('Benchmark Report', data: report);
    });

    test('Benchmark history tracking', () async {
      // Run same benchmark multiple times
      for (int i = 0; i < 3; i++) {
        await benchmarkService.runBenchmark(
          'history_test',
          'history',
          () async {
            for (int j = 0; j < 10; j++) {
              await databaseService.saveSettings(
                'history_key_${i}_$j',
                'history_value_${i}_$j',
              );
            }
          },
          iterations: 2,
          metadata: {'run': i + 1},
        );
      }

      // Get benchmark history
      final history = benchmarkService.getBenchmarkHistory('history_test');
      expect(history.length, equals(3));

      // Verify timestamps are in order
      for (int i = 1; i < history.length; i++) {
        expect(history[i].timestamp.isAfter(history[i - 1].timestamp), isTrue);
      }

      // Log history
      loggerService.info(
        'Benchmark History',
        data: {
          'name': 'history_test',
          'entries': history.length,
          'firstRun': history.first.timestamp.toIso8601String(),
          'lastRun': history.last.timestamp.toIso8601String(),
        },
      );
    });
  });
}
