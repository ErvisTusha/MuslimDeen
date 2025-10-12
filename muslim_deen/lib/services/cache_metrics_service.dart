import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// Service for tracking and reporting cache performance metrics
class CacheMetricsService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();

  static const String _metricsPrefix = 'cache_metrics_';
  static const String _hitRateKey = '${_metricsPrefix}hit_rate';
  static const String _totalHitsKey = '${_metricsPrefix}total_hits';
  static const String _totalMissesKey = '${_metricsPrefix}total_misses';
  static const String _cacheSizeKey = '${_metricsPrefix}cache_size';
  static const String _operationsKey = '${_metricsPrefix}operations';
  static const String _lastReportKey = '${_metricsPrefix}last_report';

  // In-memory metrics for faster access
  double _currentHitRate = 0.0;
  int _totalHits = 0;
  int _totalMisses = 0;
  int _currentCacheSize = 0;
  final List<Map<String, dynamic>> _recentOperations = [];

  // Maximum number of recent operations to keep in memory
  static const int _maxRecentOperations = 100;

  CacheMetricsService(this._prefs) {
    _loadMetrics();
  }

  /// Load metrics from persistent storage
  void _loadMetrics() {
    try {
      _currentHitRate = _prefs.getDouble(_hitRateKey) ?? 0.0;
      _totalHits = _prefs.getInt(_totalHitsKey) ?? 0;
      _totalMisses = _prefs.getInt(_totalMissesKey) ?? 0;
      _currentCacheSize = _prefs.getInt(_cacheSizeKey) ?? 0;

      final operationsJson = _prefs.getString(_operationsKey);
      if (operationsJson != null) {
        final operationsList = jsonDecode(operationsJson) as List;
        _recentOperations.clear();
        for (final operation in operationsList.take(_maxRecentOperations)) {
          _recentOperations.add(operation as Map<String, dynamic>);
        }
      }

      _logger.debug('Cache metrics loaded from storage');
    } catch (e, s) {
      _logger.error('Error loading cache metrics', error: e, stackTrace: s);
      // Reset metrics on error
      _resetMetrics();
    }
  }

  /// Save metrics to persistent storage
  Future<void> _saveMetrics() async {
    try {
      await _prefs.setDouble(_hitRateKey, _currentHitRate);
      await _prefs.setInt(_totalHitsKey, _totalHits);
      await _prefs.setInt(_totalMissesKey, _totalMisses);
      await _prefs.setInt(_cacheSizeKey, _currentCacheSize);

      // Only save recent operations to avoid excessive storage
      final recentOpsToSave =
          _recentOperations.take(_maxRecentOperations).toList();
      await _prefs.setString(_operationsKey, jsonEncode(recentOpsToSave));
      await _prefs.setString(_lastReportKey, DateTime.now().toIso8601String());

      _logger.debug('Cache metrics saved to storage');
    } catch (e, s) {
      _logger.error('Error saving cache metrics', error: e, stackTrace: s);
    }
  }

  /// Record a cache hit
  void recordHit(String cacheKey, String operationType) {
    _totalHits++;
    _updateHitRate();
    _recordOperation('hit', cacheKey, operationType);
    _logger.debug(
      'Cache hit recorded',
      data: {'key': cacheKey, 'type': operationType},
    );
  }

  /// Record a cache miss
  void recordMiss(String cacheKey, String operationType) {
    _totalMisses++;
    _updateHitRate();
    _recordOperation('miss', cacheKey, operationType);
    _logger.debug(
      'Cache miss recorded',
      data: {'key': cacheKey, 'type': operationType},
    );
  }

  /// Record cache size change
  void recordCacheSize(int size) {
    _currentCacheSize = size;
    _logger.debug('Cache size updated', data: {'size': size});
  }

  /// Record a cache operation
  void _recordOperation(String result, String cacheKey, String operationType) {
    final operation = {
      'timestamp': DateTime.now().toIso8601String(),
      'result': result,
      'key': cacheKey,
      'type': operationType,
    };

    _recentOperations.add(operation);

    // Keep only the most recent operations
    if (_recentOperations.length > _maxRecentOperations) {
      _recentOperations.removeAt(0);
    }
  }

  /// Update hit rate calculation
  void _updateHitRate() {
    final totalOperations = _totalHits + _totalMisses;
    if (totalOperations > 0) {
      _currentHitRate = _totalHits / totalOperations;
    } else {
      _currentHitRate = 0.0;
    }
  }

  /// Get current hit rate
  double get hitRate => _currentHitRate;

  /// Get total hits
  int get totalHits => _totalHits;

  /// Get total misses
  int get totalMisses => _totalMisses;

  /// Get current cache size
  int get cacheSize => _currentCacheSize;

  /// Get recent operations
  List<Map<String, dynamic>> get recentOperations =>
      List.unmodifiable(_recentOperations);

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return {
      'hitRate': _currentHitRate,
      'totalHits': _totalHits,
      'totalMisses': _totalMisses,
      'totalOperations': _totalHits + _totalMisses,
      'cacheSize': _currentCacheSize,
      'lastReport': _prefs.getString(_lastReportKey),
      'recentOperationCount': _recentOperations.length,
    };
  }

  /// Get detailed performance report
  Map<String, dynamic> getDetailedReport() {
    final operationTypeStats = <String, Map<String, int>>{};

    // Analyze recent operations by type
    for (final operation in _recentOperations) {
      final type = operation['type'] as String;
      final result = operation['result'] as String;

      if (!operationTypeStats.containsKey(type)) {
        operationTypeStats[type] = {'hits': 0, 'misses': 0};
      }

      if (result == 'hit') {
        operationTypeStats[type]!['hits'] =
            (operationTypeStats[type]!['hits'] ?? 0) + 1;
      } else {
        operationTypeStats[type]!['misses'] =
            (operationTypeStats[type]!['misses'] ?? 0) + 1;
      }
    }

    // Calculate hit rates by operation type
    final hitRatesByType = <String, double>{};
    for (final entry in operationTypeStats.entries) {
      final type = entry.key;
      final stats = entry.value;
      final total = (stats['hits'] ?? 0) + (stats['misses'] ?? 0);
      if (total > 0) {
        hitRatesByType[type] = (stats['hits'] ?? 0) / total;
      }
    }

    return {
      ...getPerformanceSummary(),
      'operationTypeStats': operationTypeStats,
      'hitRatesByType': hitRatesByType,
      'recommendations': _generateRecommendations(),
    };
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    if (_currentHitRate < 0.7) {
      recommendations.add(
        'Cache hit rate is below 70%. Consider increasing cache duration or reviewing cache key generation.',
      );
    }

    if (_currentCacheSize > 500) {
      recommendations.add(
        'Cache size is large. Consider implementing more aggressive cleanup or compression.',
      );
    }

    // Check for patterns in recent operations
    final missPatterns =
        _recentOperations
            .where((op) => op['result'] == 'miss')
            .map((op) => op['type'] as String)
            .toList();

    if (missPatterns.isNotEmpty) {
      final missFrequency = <String, int>{};
      for (final type in missPatterns) {
        missFrequency[type] = (missFrequency[type] ?? 0) + 1;
      }

      final mostMissedType =
          missFrequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      recommendations.add(
        'Consider optimizing cache for $mostMissedType operations (highest miss rate).',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Cache performance is optimal. No immediate actions required.',
      );
    }

    return recommendations;
  }

  /// Reset all metrics
  void _resetMetrics() {
    _currentHitRate = 0.0;
    _totalHits = 0;
    _totalMisses = 0;
    _currentCacheSize = 0;
    _recentOperations.clear();
    _logger.info('Cache metrics reset');
  }

  /// Save current metrics and reset
  Future<void> saveAndReset() async {
    await _saveMetrics();
    _resetMetrics();
  }

  /// Persist metrics to storage
  Future<void> persistMetrics() async {
    await _saveMetrics();
  }

  /// Log performance summary
  void logPerformanceSummary() {
    final summary = getPerformanceSummary();
    _logger.info('Cache Performance Summary', data: summary);
  }

  /// Log detailed report
  void logDetailedReport() {
    final report = getDetailedReport();
    _logger.info('Cache Performance Report', data: report);
  }
}
