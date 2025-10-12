
import 'package:flutter_test/flutter_test.dart';

import 'package:muslim_deen/services/production_monitoring_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Production monitoring tests for verifying event tracking and reporting
void main() {
  group('Production Monitoring Tests', () {
    late ProductionMonitoringService monitoringService;
    late LoggerService loggerService;

    setUpAll(() async {
      // Initialize service locator
      await setupLocator(testing: true);
    });

    setUp(() {
      monitoringService = locator<ProductionMonitoringService>();
      loggerService = locator<LoggerService>();
    });

    tearDown(() async {
      await monitoringService.dispose();
    });

    test('Production monitoring service initialization', () async {
      // Initialize with custom config
      const config = MonitoringConfig(
        enabled: true,
        endpoint: 'https://test.example.com/events',
        apiKey: 'test-api-key',
        reportingInterval: Duration(minutes: 1),
        batchSize: 10,
        samplingRate: 1.0,
      );
      
      await monitoringService.initialize(
        config: config,
        userId: 'test-user',
        sessionId: 'test-session',
      );
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify initialization
      expect(stats['enabled'], equals(true));
      expect(stats['sessionId'], equals('test-session'));
      expect(stats['userId'], equals('test-user'));
      expect(stats['pendingEvents'], equals(1)); // Startup event
      
      // Log verification
      loggerService.info('Production monitoring initialization test completed', data: stats);
    });

    test('Event logging and tracking', () async {
      // Initialize with test config
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(seconds: 30), // Longer interval for testing
        batchSize: 5,
        samplingRate: 1.0,
      );
      
      await monitoringService.initialize(config: config);
      
      // Log different types of events
      monitoringService.logInfo('Test info event', data: {'key': 'value'});
      monitoringService.logWarning('Test warning event', data: {'warning': 'test'});
      monitoringService.logError('Test error event', error: 'Test error', data: {'error': 'test'});
      monitoringService.logUserAction('Test action', data: {'action': 'test'});
      monitoringService.logPerformanceMetrics();
      monitoringService.logMemoryUsage();
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify events were logged
      expect(stats['pendingEvents'], greaterThan(1)); // At least startup + test events
      
      // Log verification
      loggerService.info('Event logging test completed', data: stats);
    });

    test('Event sampling and filtering', () async {
      // Initialize with low sampling rate
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(seconds: 30),
        batchSize: 5,
        samplingRate: 0.5, // 50% sampling rate
      );
      
      await monitoringService.initialize(config: config);
      
      // Log many events to test sampling
      for (int i = 0; i < 20; i++) {
        monitoringService.logInfo('Sampled event $i');
      }
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify sampling worked (approximately half of events should be logged)
      expect(stats['pendingEvents'], lessThan(20)); // Less than all events
      
      // Log verification
      loggerService.info('Event sampling test completed', data: {
        'totalEvents': 20,
        'loggedEvents': stats['pendingEvents'],
        'samplingRate': config.samplingRate,
      });
    });

    test('User action filtering', () async {
      // Initialize with user actions disabled
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(seconds: 30),
        batchSize: 5,
        samplingRate: 1.0,
        includeUserActions: false, // User actions disabled
      );
      
      await monitoringService.initialize(config: config);
      
      // Log different types of events
      monitoringService.logInfo('Test info event');
      monitoringService.logUserAction('Test user action'); // Should be filtered
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify user action was filtered
      expect(stats['pendingEvents'], equals(2)); // Startup + info event only
      
      // Log verification
      loggerService.info('User action filtering test completed', data: stats);
    });

    test('Monitoring configuration update', () async {
      // Initialize with initial config
      const initialConfig = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(minutes: 1),
        batchSize: 10,
        samplingRate: 1.0,
      );
      
      await monitoringService.initialize(config: initialConfig);
      
      // Update configuration
      const newConfig = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(minutes: 2),
        batchSize: 20,
        samplingRate: 0.8,
      );
      
      monitoringService.updateConfig(newConfig);
      
      // Log an event to verify config update was logged
      monitoringService.logInfo('Test event after config update');
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify config update was logged
      expect(stats['pendingEvents'], greaterThan(2)); // Startup + config update + test event
      
      // Log verification
      loggerService.info('Configuration update test completed', data: stats);
    });

    test('User ID management', () async {
      // Initialize without user ID
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(seconds: 30),
        batchSize: 5,
      );
      
      await monitoringService.initialize(config: config);
      
      // Set user ID
      monitoringService.setUserId('new-test-user');
      
      // Log an event to verify user ID set was logged
      monitoringService.logInfo('Test event after setting user ID');
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify user ID set was logged
      expect(stats['pendingEvents'], greaterThan(2)); // Startup + user ID set + test event
      
      // Log verification
      loggerService.info('User ID management test completed', data: stats);
    });

    test('Monitoring report generation', () async {
      // Initialize with test config
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(seconds: 30),
        batchSize: 5,
      );
      
      await monitoringService.initialize(config: config);
      
      // Log various events
      monitoringService.logInfo('Test info event 1');
      monitoringService.logInfo('Test info event 2');
      monitoringService.logWarning('Test warning event');
      monitoringService.logError('Test error event', error: 'Test error');
      
      // Generate monitoring report
      final report = monitoringService.generateMonitoringReport();
      
      // Verify report structure
      expect(report['sessionId'], isNotNull);
      expect(report['period'], equals('7 days'));
      expect(report['totalEvents'], greaterThan(0));
      expect(report['eventCounts'], isNotNull);
      expect(report['healthScore'], isNotNull);
      expect(report['statistics'], isNotNull);
      
      // Log verification
      loggerService.info('Monitoring report generation test completed', data: report);
    });

    test('Event flushing', () async {
      // Initialize with small batch size
      const config = MonitoringConfig(
        enabled: true,
        reportingInterval: Duration(minutes: 10), // Long interval
        batchSize: 2, // Small batch size
      );
      
      await monitoringService.initialize(config: config);
      
      // Log events to fill batch
      monitoringService.logInfo('Test event 1');
      monitoringService.logInfo('Test event 2');
      monitoringService.logInfo('Test event 3');
      
      // Get monitoring statistics before flush
      final statsBefore = monitoringService.getMonitoringStatistics();
      expect(statsBefore['pendingEvents'], greaterThan(0));
      
      // Flush events
      await monitoringService.flushEvents();
      
      // Get monitoring statistics after flush
      final statsAfter = monitoringService.getMonitoringStatistics();
      
      // In a real implementation, events would be sent to the server
      // For testing, we just verify the method runs without error
      expect(statsAfter['isReporting'], isFalse);
      
      // Log verification
      loggerService.info('Event flushing test completed', data: {
        'statsBefore': statsBefore,
        'statsAfter': statsAfter,
      });
    });

    test('Disabled monitoring service', () async {
      // Initialize with monitoring disabled
      const config = MonitoringConfig(
        enabled: false,
        reportingInterval: Duration(seconds: 30),
        batchSize: 5,
      );
      
      await monitoringService.initialize(config: config);
      
      // Log events
      monitoringService.logInfo('Test event');
      monitoringService.logError('Test error', error: 'Test error');
      
      // Get monitoring statistics
      final stats = monitoringService.getMonitoringStatistics();
      
      // Verify events were not logged (only startup event)
      expect(stats['enabled'], isFalse);
      expect(stats['pendingEvents'], equals(1)); // Only startup event
      
      // Log verification
      loggerService.info('Disabled monitoring service test completed', data: stats);
    });
  });
}