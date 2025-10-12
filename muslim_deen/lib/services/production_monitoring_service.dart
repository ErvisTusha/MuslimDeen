import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/performance_monitoring_service.dart';
import 'package:muslim_deen/services/benchmark_service.dart';
import 'package:muslim_deen/services/scalability_test_service.dart';

/// Production monitoring event type
enum MonitoringEventType {
  startup,
  shutdown,
  error,
  warning,
  info,
  performance,
  memory,
  crash,
  userAction,
}

/// Production monitoring event
class MonitoringEvent {
  final MonitoringEventType type;
  final String message;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  MonitoringEvent({
    required this.type,
    required this.message,
    required this.data,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'sessionId': sessionId,
    };
  }

  /// Create from JSON
  factory MonitoringEvent.fromJson(Map<String, dynamic> json) {
    return MonitoringEvent(
      type: MonitoringEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MonitoringEventType.info,
      ),
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }
}

/// Monitoring configuration
class MonitoringConfig {
  final bool enabled;
  final String endpoint;
  final String apiKey;
  final Duration reportingInterval;
  final int batchSize;
  final bool reportOnCrash;
  final bool includeDeviceInfo;
  final bool includeUserActions;
  final double samplingRate;

  const MonitoringConfig({
    this.enabled = true,
    this.endpoint = 'https://api.monitoring.example.com/events',
    this.apiKey = '',
    this.reportingInterval = const Duration(minutes: 5),
    this.batchSize = 50,
    this.reportOnCrash = true,
    this.includeDeviceInfo = true,
    this.includeUserActions = false,
    this.samplingRate = 1.0,
  });
}

/// Production monitoring service for tracking app performance in production
class ProductionMonitoringService {
  final LoggerService _logger = locator<LoggerService>();
  final PerformanceMonitoringService _performanceService = locator<PerformanceMonitoringService>();
  final BenchmarkService _benchmarkService = locator<BenchmarkService>();
  final ScalabilityTestService _scalabilityService = locator<ScalabilityTestService>();
  
  // Configuration
  MonitoringConfig _config = const MonitoringConfig();
  
  // Event storage
  final List<MonitoringEvent> _pendingEvents = [];
  final List<MonitoringEvent> _reportedEvents = [];
  
  // Monitoring state
  bool _isInitialized = false;
  bool _isReporting = false;
  String? _sessionId;
  String? _userId;
  Timer? _reportingTimer;
  
  // Device info
  Map<String, dynamic>? _deviceInfo;

  /// Initialize the production monitoring service
  Future<void> initialize({
    MonitoringConfig? config,
    String? userId,
    String? sessionId,
  }) async {
    if (_isInitialized) return;
    
    _config = config ?? _config;
    _userId = userId;
    _sessionId = sessionId ?? _generateSessionId();
    
    if (_config.includeDeviceInfo) {
      _deviceInfo = await _collectDeviceInfo();
    }
    
    // Set up error handling
    if (_config.reportOnCrash) {
      _setupErrorHandling();
    }
    
    // Start periodic reporting
    if (_config.enabled) {
      _startPeriodicReporting();
    }
    
    // Log startup event
    logEvent(
      MonitoringEventType.startup,
      'Production monitoring initialized',
      data: {
        'config': {
          'enabled': _config.enabled,
          'reportingInterval': _config.reportingInterval.inMinutes,
          'batchSize': _config.batchSize,
          'samplingRate': _config.samplingRate,
        },
        'deviceInfo': _deviceInfo,
      },
    );
    
    _isInitialized = true;
    _logger.info('ProductionMonitoringService initialized', data: {
      'sessionId': _sessionId,
      'userId': _userId,
      'enabled': _config.enabled,
    });
  }

  /// Generate a unique session ID
  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(10000);
    return 'session_${timestamp}_$random';
  }

  /// Collect device information
  Future<Map<String, dynamic>> _collectDeviceInfo() async {
    final deviceInfo = <String, dynamic>{
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'isDebug': kDebugMode,
      'isProfileMode': kProfileMode,
      'isReleaseMode': kReleaseMode,
    };
    
    if (Platform.isAndroid || Platform.isIOS) {
      // Add mobile-specific info
      deviceInfo['isMobile'] = true;
    } else {
      deviceInfo['isMobile'] = false;
    }
    
    return deviceInfo;
  }

  /// Set up error handling for crash reporting
  void _setupErrorHandling() {
    // In a real implementation, you would set up error handlers
    // for platform-specific crash reporting
    
    if (kDebugMode) {
      return; // Don't set up crash reporting in debug mode
    }
    
    // Example for Flutter web and desktop
    FlutterError.onError = (FlutterErrorDetails details) {
      logEvent(
        MonitoringEventType.crash,
        'Flutter error occurred',
        data: {
          'error': details.toString(),
          'stack': details.stack?.toString(),
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
    };
  }

  /// Start periodic reporting
  void _startPeriodicReporting() {
    _reportingTimer?.cancel();
    _reportingTimer = Timer.periodic(_config.reportingInterval, (_) {
      _reportPendingEvents();
    });
  }

  /// Log a monitoring event
  void logEvent(
    MonitoringEventType type,
    String message, {
    Map<String, dynamic>? data,
    String? userId,
    String? sessionId,
  }) {
    if (!_config.enabled) return;
    
    // Apply sampling rate
    if (math.Random().nextDouble() > _config.samplingRate) {
      return;
    }
    
    // Filter user action events if not enabled
    if (type == MonitoringEventType.userAction && !_config.includeUserActions) {
      return;
    }
    
    final event = MonitoringEvent(
      type: type,
      message: message,
      data: data ?? {},
      timestamp: DateTime.now(),
      userId: userId ?? _userId,
      sessionId: sessionId ?? _sessionId,
    );
    
    _pendingEvents.add(event);
    
    // Report immediately for critical events
    if (_isCriticalEvent(type)) {
      _reportPendingEvents();
    }
    
    // Limit pending events queue
    if (_pendingEvents.length > _config.batchSize * 2) {
      _pendingEvents.removeRange(0, _pendingEvents.length - _config.batchSize * 2);
      _logger.warning('Pending events queue exceeded limit, oldest events discarded');
    }
  }

  /// Check if an event type is critical and should be reported immediately
  bool _isCriticalEvent(MonitoringEventType type) {
    return type == MonitoringEventType.crash || type == MonitoringEventType.error;
  }

  /// Report pending events to the monitoring endpoint
  Future<void> _reportPendingEvents() async {
    if (_pendingEvents.isEmpty || _isReporting) {
      return;
    }
    
    _isReporting = true;
    
    try {
      // Get a batch of events to report
      final eventsToReport = _pendingEvents.take(_config.batchSize).toList();
      
      // Create report payload
      final payload = {
        'events': eventsToReport.map((e) => e.toJson()).toList(),
        'deviceInfo': _deviceInfo,
        'appInfo': {
          'sessionId': _sessionId,
          'userId': _userId,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Send to monitoring endpoint
      final response = await http.post(
        Uri.parse(_config.endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config.apiKey}',
          'User-Agent': 'MuslimDeen/1.0',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Successfully reported events
        _reportedEvents.addAll(eventsToReport);
        _pendingEvents.removeRange(0, eventsToReport.length);
        
        _logger.debug('Events reported successfully', data: {
          'count': eventsToReport.length,
          'statusCode': response.statusCode,
        });
      } else {
        // Failed to report events
        _logger.warning('Failed to report events', data: {
          'statusCode': response.statusCode,
          'body': response.body,
          'count': eventsToReport.length,
        });
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error reporting monitoring events',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isReporting = false;
    }
  }

  /// Log user action
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    logEvent(
      MonitoringEventType.userAction,
      'User action: $action',
      data: <String, dynamic>{
        'action': action,
        ...(data ?? {}),
      },
    );
  }

  /// Log error
  void logError(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    logEvent(
      MonitoringEventType.error,
      message,
      data: <String, dynamic>{
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
        ...(data ?? {}),
      },
    );
  }

  /// Log warning
  void logWarning(String message, {Map<String, dynamic>? data}) {
    logEvent(
      MonitoringEventType.warning,
      message,
      data: data ?? {},
    );
  }

  /// Log info
  void logInfo(String message, {Map<String, dynamic>? data}) {
    logEvent(
      MonitoringEventType.info,
      message,
      data: data ?? {},
    );
  }

  /// Log performance metrics
  void logPerformanceMetrics() {
    final frameRateMetrics = _performanceService.getFrameRateMetrics();
    final allWidgetStats = _performanceService.getAllWidgetStats();
    final benchmarkStats = _benchmarkService.getBenchmarkStatistics();
    final scalabilityResults = _scalabilityService.getAllTestResults();
    
    logEvent(
      MonitoringEventType.performance,
      'Performance metrics collected',
      data: <String, dynamic>{
        'frameRate': frameRateMetrics,
        'widgetStats': allWidgetStats,
        'benchmarkStats': benchmarkStats,
        'scalabilityResults': scalabilityResults.map((k, v) => MapEntry(k, v.toJson())),
      },
    );
  }

  /// Log memory usage
  void logMemoryUsage() async {
    final memoryUsage = await _performanceService.getMemoryUsage();
    
    logEvent(
      MonitoringEventType.memory,
      'Memory usage collected',
      data: memoryUsage,
    );
  }

  /// Force report all pending events
  Future<void> flushEvents() async {
    if (_pendingEvents.isNotEmpty) {
      await _reportPendingEvents();
    }
  }

  /// Get monitoring statistics
  Map<String, dynamic> getMonitoringStatistics() {
    return {
      'enabled': _config.enabled,
      'sessionId': _sessionId,
      'userId': _userId,
      'pendingEvents': _pendingEvents.length,
      'reportedEvents': _reportedEvents.length,
      'isReporting': _isReporting,
      'lastReportTime': _reportedEvents.isNotEmpty
          ? _reportedEvents.last.timestamp.toIso8601String()
          : null,
      'config': {
        'reportingInterval': _config.reportingInterval.inMinutes,
        'batchSize': _config.batchSize,
        'samplingRate': _config.samplingRate,
      },
    };
  }

  /// Generate monitoring report
  Map<String, dynamic> generateMonitoringReport() {
    final now = DateTime.now();
    final recentEvents = _reportedEvents.where(
      (e) => now.difference(e.timestamp).inDays <= 7,
    ).toList();
    
    // Count events by type
    final eventCounts = <MonitoringEventType, int>{};
    for (final event in recentEvents) {
      eventCounts[event.type] = (eventCounts[event.type] ?? 0) + 1;
    }
    
    // Count errors and warnings
    final errorCount = eventCounts[MonitoringEventType.error] ?? 0;
    final warningCount = eventCounts[MonitoringEventType.warning] ?? 0;
    final crashCount = eventCounts[MonitoringEventType.crash] ?? 0;
    
    return {
      'timestamp': now.toIso8601String(),
      'sessionId': _sessionId,
      'userId': _userId,
      'period': '7 days',
      'totalEvents': recentEvents.length,
      'eventCounts': eventCounts.map((k, v) => MapEntry(k.name, v)),
      'errorCount': errorCount,
      'warningCount': warningCount,
      'crashCount': crashCount,
      'healthScore': _calculateHealthScore(errorCount, warningCount, crashCount),
      'statistics': getMonitoringStatistics(),
    };
  }

  /// Calculate health score based on events
  double _calculateHealthScore(int errorCount, int warningCount, int crashCount) {
    // Start with perfect score
    double score = 100.0;
    
    // Deduct points for errors
    score -= errorCount * 5.0;
    
    // Deduct points for warnings
    score -= warningCount * 1.0;
    
    // Deduct points for crashes
    score -= crashCount * 20.0;
    
    // Ensure score is between 0 and 100
    return math.max(0.0, math.min(100.0, score));
  }

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;
    logEvent(
      MonitoringEventType.info,
      'User ID set',
      data: {'userId': userId},
    );
  }

  /// Update configuration
  void updateConfig(MonitoringConfig config) {
    final oldConfig = _config;
    _config = config;
    
    // Restart periodic reporting if interval changed
    if (oldConfig.reportingInterval != config.reportingInterval && config.enabled) {
      _startPeriodicReporting();
    }
    
    logEvent(
      MonitoringEventType.info,
      'Monitoring configuration updated',
      data: {
        'oldConfig': {
          'enabled': oldConfig.enabled,
          'reportingInterval': oldConfig.reportingInterval.inMinutes,
          'batchSize': oldConfig.batchSize,
          'samplingRate': oldConfig.samplingRate,
        },
        'newConfig': {
          'enabled': config.enabled,
          'reportingInterval': config.reportingInterval.inMinutes,
          'batchSize': config.batchSize,
          'samplingRate': config.samplingRate,
        },
      },
    );
  }

  /// Dispose of resources
  Future<void> dispose() async {
    // Log shutdown event
    logEvent(
      MonitoringEventType.shutdown,
      'Production monitoring shutting down',
      data: {
        'pendingEvents': _pendingEvents.length,
        'reportedEvents': _reportedEvents.length,
      },
    );
    
    // Report any pending events
    await flushEvents();
    
    // Cancel timers
    _reportingTimer?.cancel();
    _reportingTimer = null;
    
    _isInitialized = false;
    _logger.info('ProductionMonitoringService disposed');
  }
}