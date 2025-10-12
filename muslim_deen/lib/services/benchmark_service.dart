import 'dart:async';
import 'dart:math' as math;

import 'package:muslim_deen/service_locator.dart';

import 'package:muslim_deen/services/logger_service.dart';

/// Benchmark result data class
class BenchmarkResult {
  final String name;
  final String category;
  final Duration duration;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int iterations;
  final Duration averageTime;
  final Duration minTime;
  final Duration maxTime;
  final double standardDeviation;

  BenchmarkResult({
    required this.name,
    required this.category,
    required this.duration,
    required this.metadata,
    required this.timestamp,
    required this.iterations,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.standardDeviation,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'duration': duration.inMicroseconds,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'iterations': iterations,
      'averageTime': averageTime.inMicroseconds,
      'minTime': minTime.inMicroseconds,
      'maxTime': maxTime.inMicroseconds,
      'standardDeviation': standardDeviation,
    };
  }

  /// Create from JSON
  factory BenchmarkResult.fromJson(Map<String, dynamic> json) {
    return BenchmarkResult(
      name: json['name'] as String,
      category: json['category'] as String,
      duration: Duration(microseconds: json['duration'] as int),
      metadata: json['metadata'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      iterations: json['iterations'] as int,
      averageTime: Duration(microseconds: json['averageTime'] as int),
      minTime: Duration(microseconds: json['minTime'] as int),
      maxTime: Duration(microseconds: json['maxTime'] as int),
      standardDeviation: json['standardDeviation'] as double,
    );
  }
}

/// Benchmark comparison data
class BenchmarkComparison {
  final String name;
  final BenchmarkResult baseline;
  final BenchmarkResult current;
  final double improvementPercentage;
  final bool isRegression;

  BenchmarkComparison({
    required this.name,
    required this.baseline,
    required this.current,
    required this.improvementPercentage,
    required this.isRegression,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'baseline': baseline.toJson(),
      'current': current.toJson(),
      'improvementPercentage': improvementPercentage,
      'isRegression': isRegression,
    };
  }
}

/// Performance benchmark service for measuring and comparing performance
class BenchmarkService {
  final LoggerService _logger = locator<LoggerService>();

  // Benchmark storage
  final Map<String, BenchmarkResult> _benchmarks = {};
  final Map<String, List<BenchmarkResult>> _benchmarkHistory = {};
  final Map<String, BenchmarkResult> _baselines = {};

  // Benchmark configuration
  static const int _defaultIterations = 10;
  static const int _maxHistorySize = 50;
  static const double _regressionThreshold = 10.0; // 10% slower than baseline

  // Benchmark state

  bool _isRunning = false;

  Timer? _reportingTimer;
  static const Duration _reportingInterval = Duration(hours: 6);

  /// Initialize the benchmark service
  void initialize() {
    _logger.info('BenchmarkService initialized');
    _startPeriodicReporting();
  }

  /// Start periodic reporting of benchmark results
  void _startPeriodicReporting() {
    _reportingTimer?.cancel();
    _reportingTimer = Timer.periodic(_reportingInterval, (_) {
      _generateBenchmarkReport();
    });
  }

  /// Run a benchmark with the specified function
  Future<BenchmarkResult> runBenchmark(
    String name,
    String category,
    Future<void> Function() operation, {
    int iterations = _defaultIterations,
    Map<String, dynamic>? metadata,
    bool saveAsBaseline = false,
  }) async {
    if (_isRunning) {
      throw StateError('Another benchmark is already running');
    }

    _isRunning = true;

    _logger.info(
      'Starting benchmark',
      data: {'name': name, 'category': category, 'iterations': iterations},
    );

    final List<Duration> runTimes = [];
    final Stopwatch stopwatch = Stopwatch();

    try {
      // Warm-up run
      await operation();

      // Actual benchmark runs
      for (int i = 0; i < iterations; i++) {
        stopwatch.reset();
        stopwatch.start();

        await operation();

        stopwatch.stop();
        runTimes.add(stopwatch.elapsed);

        // Log progress for long benchmarks
        if (iterations > 10 && i % (iterations ~/ 10) == 0) {
          _logger.debug(
            'Benchmark progress',
            data: {
              'name': name,
              'iteration': i + 1,
              'total': iterations,
              'currentTime': '${stopwatch.elapsed.inMilliseconds}ms',
            },
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Benchmark failed',
        error: e,
        stackTrace: stackTrace,
        data: {'name': name},
      );
      rethrow;
    } finally {
      _isRunning = false;
    }

    // Calculate statistics
    final totalDuration = runTimes.reduce((a, b) => a + b);
    final averageTime = Duration(
      microseconds: totalDuration.inMicroseconds ~/ runTimes.length,
    );
    final minTime = runTimes.reduce((a, b) => a < b ? a : b);
    final maxTime = runTimes.reduce((a, b) => a > b ? a : b);

    // Calculate standard deviation
    final mean = averageTime.inMicroseconds.toDouble();
    final variance =
        runTimes
            .map((d) => math.pow(d.inMicroseconds - mean, 2))
            .reduce((a, b) => a + b) /
        runTimes.length;
    final standardDeviation = math.sqrt(variance);

    // Create benchmark result
    final result = BenchmarkResult(
      name: name,
      category: category,
      duration: totalDuration,
      metadata: metadata ?? {},
      timestamp: DateTime.now(),
      iterations: iterations,
      averageTime: averageTime,
      minTime: minTime,
      maxTime: maxTime,
      standardDeviation: standardDeviation,
    );

    // Store benchmark
    _storeBenchmark(result);

    // Save as baseline if requested
    if (saveAsBaseline) {
      _baselines[name] = result;
      _logger.info('Benchmark saved as baseline', data: {'name': name});
    }

    // Check for regression
    _checkForRegression(result);

    _logger.info(
      'Benchmark completed',
      data: {
        'name': name,
        'averageTime': '${averageTime.inMicroseconds}μs',
        'minTime': '${minTime.inMicroseconds}μs',
        'maxTime': '${maxTime.inMicroseconds}μs',
        'standardDeviation': standardDeviation.toStringAsFixed(2),
      },
    );

    return result;
  }

  /// Store benchmark result
  void _storeBenchmark(BenchmarkResult result) {
    _benchmarks[result.name] = result;

    // Add to history
    _benchmarkHistory.putIfAbsent(result.name, () => []);
    _benchmarkHistory[result.name]!.add(result);

    // Limit history size
    if (_benchmarkHistory[result.name]!.length > _maxHistorySize) {
      _benchmarkHistory[result.name]!.removeAt(0);
    }
  }

  /// Check for performance regression
  void _checkForRegression(BenchmarkResult result) {
    if (!_baselines.containsKey(result.name)) {
      return;
    }

    final baseline = _baselines[result.name]!;
    final improvementPercentage = _calculateImprovementPercentage(
      baseline,
      result,
    );
    final isRegression = improvementPercentage < -_regressionThreshold;

    if (isRegression) {
      _logger.warning(
        'Performance regression detected',
        data: {
          'name': result.name,
          'baselineTime': '${baseline.averageTime.inMicroseconds}μs',
          'currentTime': '${result.averageTime.inMicroseconds}μs',
          'regressionPercentage':
              '${improvementPercentage.toStringAsFixed(2)}%',
        },
      );
    }
  }

  /// Calculate improvement percentage between two benchmarks
  double _calculateImprovementPercentage(
    BenchmarkResult baseline,
    BenchmarkResult current,
  ) {
    if (baseline.averageTime.inMicroseconds == 0) {
      return 0.0;
    }

    final improvement =
        baseline.averageTime.inMicroseconds -
        current.averageTime.inMicroseconds;
    return (improvement / baseline.averageTime.inMicroseconds) * 100;
  }

  /// Compare current benchmark with baseline
  BenchmarkComparison? compareWithBaseline(String name) {
    if (!_benchmarks.containsKey(name) || !_baselines.containsKey(name)) {
      return null;
    }

    final current = _benchmarks[name]!;
    final baseline = _baselines[name]!;
    final improvementPercentage = _calculateImprovementPercentage(
      baseline,
      current,
    );

    return BenchmarkComparison(
      name: name,
      baseline: baseline,
      current: current,
      improvementPercentage: improvementPercentage,
      isRegression: improvementPercentage < -_regressionThreshold,
    );
  }

  /// Get all benchmarks
  Map<String, BenchmarkResult> getAllBenchmarks() {
    return Map.unmodifiable(_benchmarks);
  }

  /// Get benchmarks by category
  Map<String, BenchmarkResult> getBenchmarksByCategory(String category) {
    return Map.fromEntries(
      _benchmarks.entries.where((entry) => entry.value.category == category),
    );
  }

  /// Get benchmark history
  List<BenchmarkResult> getBenchmarkHistory(String name) {
    return List.unmodifiable(_benchmarkHistory[name] ?? []);
  }

  /// Get all baselines
  Map<String, BenchmarkResult> getAllBaselines() {
    return Map.unmodifiable(_baselines);
  }

  /// Set benchmark as baseline
  void setBaseline(String name) {
    if (!_benchmarks.containsKey(name)) {
      throw ArgumentError('Benchmark not found: $name');
    }

    _baselines[name] = _benchmarks[name]!;
    _logger.info('Benchmark set as baseline', data: {'name': name});
  }

  /// Generate benchmark report
  Map<String, dynamic> generateBenchmarkReport() {
    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'totalBenchmarks': _benchmarks.length,
      'categories': <String, int>{},
      'benchmarks': <String, dynamic>{},
      'regressions': <String, dynamic>{},
      'improvements': <String, dynamic>{},
    };

    // Count benchmarks by category
    for (final benchmark in _benchmarks.values) {
      report['categories'][benchmark.category] =
          (report['categories'][benchmark.category] ?? 0) + 1;
    }

    // Add benchmark details
    for (final entry in _benchmarks.entries) {
      final name = entry.key;
      final benchmark = entry.value;

      report['benchmarks'][name] = {
        'category': benchmark.category,
        'averageTime': benchmark.averageTime.inMicroseconds,
        'minTime': benchmark.minTime.inMicroseconds,
        'maxTime': benchmark.maxTime.inMicroseconds,
        'standardDeviation': benchmark.standardDeviation,
        'iterations': benchmark.iterations,
        'timestamp': benchmark.timestamp.toIso8601String(),
      };

      // Check for regression or improvement
      final comparison = compareWithBaseline(name);
      if (comparison != null) {
        if (comparison.isRegression) {
          report['regressions'][name] = {
            'baselineTime': comparison.baseline.averageTime.inMicroseconds,
            'currentTime': comparison.current.averageTime.inMicroseconds,
            'regressionPercentage': comparison.improvementPercentage.abs(),
          };
        } else if (comparison.improvementPercentage > _regressionThreshold) {
          report['improvements'][name] = {
            'baselineTime': comparison.baseline.averageTime.inMicroseconds,
            'currentTime': comparison.current.averageTime.inMicroseconds,
            'improvementPercentage': comparison.improvementPercentage,
          };
        }
      }
    }

    return report;
  }

  /// Generate and log benchmark report
  void _generateBenchmarkReport() {
    final report = generateBenchmarkReport();

    _logger.info(
      'Benchmark Report Generated',
      data: {
        'totalBenchmarks': report['totalBenchmarks'],
        'categories': report['categories'],
        'regressions': report['regressions'].length,
        'improvements': report['improvements'].length,
      },
    );

    // Log regressions separately for visibility
    if ((report['regressions'] as Map).isNotEmpty) {
      _logger.warning('Performance Regressions', data: report['regressions']);
    }
  }

  /// Export benchmarks to JSON
  String exportBenchmarksToJson() {
    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'benchmarks': _benchmarks.map((k, v) => MapEntry(k, v.toJson())),
      'baselines': _baselines.map((k, v) => MapEntry(k, v.toJson())),
      'benchmarkHistory': _benchmarkHistory.map(
        (k, v) => MapEntry(k, v.map((e) => e.toJson())),
      ),
    };

    return _encodeJson(exportData);
  }

  /// Import benchmarks from JSON
  bool importBenchmarksFromJson(String jsonData) {
    try {
      final importData = _decodeJson(jsonData) as Map<String, dynamic>;

      // Import benchmarks
      final benchmarksData = importData['benchmarks'] as Map<String, dynamic>;
      for (final entry in benchmarksData.entries) {
        _benchmarks[entry.key] = BenchmarkResult.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      // Import baselines
      final baselinesData = importData['baselines'] as Map<String, dynamic>;
      for (final entry in baselinesData.entries) {
        _baselines[entry.key] = BenchmarkResult.fromJson(
          entry.value as Map<String, dynamic>,
        );
      }

      // Import history
      final historyData =
          importData['benchmarkHistory'] as Map<String, dynamic>;
      for (final entry in historyData.entries) {
        final historyList =
            (entry.value as List<dynamic>)
                .map((e) => BenchmarkResult.fromJson(e as Map<String, dynamic>))
                .toList();
        _benchmarkHistory[entry.key] = historyList;
      }

      _logger.info(
        'Benchmarks imported successfully',
        data: {
          'benchmarksCount': _benchmarks.length,
          'baselinesCount': _baselines.length,
        },
      );

      return true;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to import benchmarks',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clear all benchmarks
  void clearAllBenchmarks() {
    _benchmarks.clear();
    _benchmarkHistory.clear();
    _logger.info('All benchmarks cleared');
  }

  /// Clear benchmark history
  void clearBenchmarkHistory(String name) {
    _benchmarkHistory.remove(name);
    _logger.info('Benchmark history cleared', data: {'name': name});
  }

  /// Get benchmark statistics
  Map<String, dynamic> getBenchmarkStatistics() {
    if (_benchmarks.isEmpty) {
      return {
        'totalBenchmarks': 0,
        'categories': <String, dynamic>{},
        'averageTime': 0,
        'fastestBenchmark': null,
        'slowestBenchmark': null,
      };
    }

    // Calculate statistics
    final allTimes =
        _benchmarks.values.map((b) => b.averageTime.inMicroseconds).toList();
    final averageTime = allTimes.reduce((a, b) => a + b) / allTimes.length;

    final fastestBenchmark = _benchmarks.values.reduce(
      (a, b) =>
          a.averageTime.inMicroseconds < b.averageTime.inMicroseconds ? a : b,
    );
    final slowestBenchmark = _benchmarks.values.reduce(
      (a, b) =>
          a.averageTime.inMicroseconds > b.averageTime.inMicroseconds ? a : b,
    );

    // Count by category
    final categories = <String, int>{};
    for (final benchmark in _benchmarks.values) {
      categories[benchmark.category] =
          (categories[benchmark.category] ?? 0) + 1;
    }

    return {
      'totalBenchmarks': _benchmarks.length,
      'categories': categories,
      'averageTime': averageTime.round(),
      'fastestBenchmark': {
        'name': fastestBenchmark.name,
        'category': fastestBenchmark.category,
        'time': fastestBenchmark.averageTime.inMicroseconds,
      },
      'slowestBenchmark': {
        'name': slowestBenchmark.name,
        'category': slowestBenchmark.category,
        'time': slowestBenchmark.averageTime.inMicroseconds,
      },
    };
  }

  /// Dispose of resources
  void dispose() {
    _reportingTimer?.cancel();
    _reportingTimer = null;
    _logger.info('BenchmarkService disposed');
  }

  /// Simple JSON encoder (to avoid dependency on dart:convert)
  String _encodeJson(Map<String, dynamic> data) {
    // In a real implementation, you would use dart:convert.jsonEncode
    // This is a simplified placeholder
    return data.toString();
  }

  /// Simple JSON decoder (to avoid dependency on dart:convert)
  dynamic _decodeJson(String jsonData) {
    // In a real implementation, you would use dart:convert.jsonDecode
    // This is a simplified placeholder
    return <String, dynamic>{};
  }
}
