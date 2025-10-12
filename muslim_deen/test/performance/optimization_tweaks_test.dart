
import 'package:flutter_test/flutter_test.dart';

import 'package:muslim_deen/services/optimization_tweaks_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/service_locator.dart';

/// Optimization tweaks tests for verifying performance optimizations
void main() {
  group('Optimization Tweaks Tests', () {
    late OptimizationTweaksService optimizationService;
    late LoggerService loggerService;

    setUpAll(() async {
      // Initialize service locator
      await setupLocator(testing: true);
    });

    setUp(() {
      optimizationService = locator<OptimizationTweaksService>();
      loggerService = locator<LoggerService>();
    });

    tearDown(() async {
      optimizationService.dispose();
    });

    test('Optimization tweaks service initialization', () {
      // Service should be initialized in setUp
      final allTweaks = optimizationService.getAllTweaks();
      
      // Verify default tweaks are registered
      expect(allTweaks.length, greaterThan(0));
      
      // Verify categories are represented
      final categories = allTweaks.map((tweak) => tweak.category).toSet();
      expect(categories.contains('memory'), isTrue);
      expect(categories.contains('cpu'), isTrue);
      expect(categories.contains('rendering'), isTrue);
      expect(categories.contains('cache'), isTrue);
      
      // Log verification
      loggerService.info('Optimization tweaks initialization test completed', data: {
        'totalTweaks': allTweaks.length,
        'categories': categories.toList(),
      });
    });

    test('Memory optimization tweaks', () async {
      // Get memory tweaks
      final memoryTweaks = optimizationService.getTweaksByCategory('memory');
      expect(memoryTweaks.length, greaterThan(0));
      
      // Apply memory leak detection tweak
      final result = await optimizationService.applyTweak('memory_leak_detection');
      
      // Verify result
      expect(result.name, equals('memory_leak_detection'));
      expect(result.category, equals('memory'));
      expect(result.applied, isTrue);
      expect(result.beforeMetrics, isNotNull);
      expect(result.afterMetrics, isNotNull);
      
      // Log verification
      loggerService.info('Memory optimization tweak test completed', data: {
        'tweakName': result.name,
        'applied': result.applied,
        'improvement': result.improvement,
      });
    });

    test('Rendering optimization tweaks', () async {
      // Get rendering tweaks
      final renderingTweaks = optimizationService.getTweaksByCategory('rendering');
      expect(renderingTweaks.length, greaterThan(0));
      
      // Apply widget rebuild optimization tweak
      final result = await optimizationService.applyTweak('widget_rebuild_optimization');
      
      // Verify result
      expect(result.name, equals('widget_rebuild_optimization'));
      expect(result.category, equals('rendering'));
      expect(result.applied, isTrue);
      expect(result.beforeMetrics, isNotNull);
      expect(result.afterMetrics, isNotNull);
      
      // Log verification
      loggerService.info('Rendering optimization tweak test completed', data: {
        'tweakName': result.name,
        'applied': result.applied,
        'improvement': result.improvement,
      });
    });

    test('Cache optimization tweaks', () async {
      // Get cache tweaks
      final cacheTweaks = optimizationService.getTweaksByCategory('cache');
      expect(cacheTweaks.length, greaterThan(0));
      
      // Apply cache hit rate optimization tweak
      final result = await optimizationService.applyTweak('cache_hit_rate_optimization');
      
      // Verify result
      expect(result.name, equals('cache_hit_rate_optimization'));
      expect(result.category, equals('cache'));
      expect(result.applied, isTrue);
      expect(result.beforeMetrics, isNotNull);
      expect(result.afterMetrics, isNotNull);
      
      // Log verification
      loggerService.info('Cache optimization tweak test completed', data: {
        'tweakName': result.name,
        'applied': result.applied,
        'improvement': result.improvement,
      });
    });

    test('Multiple optimization tweaks', () async {
      // Apply multiple tweaks
      final tweakNames = [
        'memory_leak_detection',
        'widget_rebuild_optimization',
        'cache_hit_rate_optimization',
      ];
      
      final results = await optimizationService.applyTweaks(tweakNames);
      
      // Verify results
      expect(results.length, equals(3));
      
      for (final result in results) {
        expect(result.applied, isTrue);
        expect(tweakNames.contains(result.name), isTrue);
      }
      
      // Log verification
      loggerService.info('Multiple optimization tweaks test completed', data: {
        'appliedCount': results.length,
        'tweakNames': tweakNames,
        'results': results.map((r) => {'name': r.name, 'applied': r.applied}).toList(),
      });
    });

    test('All enabled optimization tweaks', () async {
      // Apply all enabled tweaks
      final results = await optimizationService.applyAllTweaks();
      
      // Verify results
      expect(results.length, greaterThan(0));
      
      // Check that all results are for enabled tweaks
      final allTweaks = optimizationService.getAllTweaks();
      final enabledTweaks = allTweaks.where((tweak) => tweak.enabled).toList();
      
      expect(results.length, equals(enabledTweaks.length));
      
      // Log verification
      loggerService.info('All enabled optimization tweaks test completed', data: {
        'totalTweaks': allTweaks.length,
        'enabledTweaks': enabledTweaks.length,
        'appliedCount': results.length,
      });
    });

    test('Tweak enable/disable functionality', () {
      // Get all tweaks
      final allTweaks = optimizationService.getAllTweaks();
      expect(allTweaks.length, greaterThan(0));
      
      // Select a tweak to disable
      final tweakToDisable = allTweaks.first;
      expect(tweakToDisable.enabled, isTrue);
      
      // Disable the tweak
      optimizationService.setTweakEnabled(tweakToDisable.name, false);
      
      // Verify tweak is disabled
      final updatedTweaks = optimizationService.getAllTweaks();
      final disabledTweak = updatedTweaks.firstWhere((tweak) => tweak.name == tweakToDisable.name);
      expect(disabledTweak.enabled, isFalse);
      
      // Try to apply the disabled tweak
      final futureResult = optimizationService.applyTweak(tweakToDisable.name);
      
      // Verify the result indicates the tweak is disabled
      futureResult.then((result) {
        expect(result.applied, isFalse);
        expect(result.error, contains('disabled'));
      });
      
      // Re-enable the tweak
      optimizationService.setTweakEnabled(tweakToDisable.name, true);
      
      // Verify tweak is re-enabled
      final reEnabledTweaks = optimizationService.getAllTweaks();
      final reEnabledTweak = reEnabledTweaks.firstWhere((tweak) => tweak.name == tweakToDisable.name);
      expect(reEnabledTweak.enabled, isTrue);
      
      // Log verification
      loggerService.info('Tweak enable/disable functionality test completed', data: {
        'tweakName': tweakToDisable.name,
        'originalState': true,
        'disabledState': false,
        'reEnabledState': true,
      });
    });

    test('Optimization report generation', () async {
      // Apply some tweaks first
      await optimizationService.applyTweak('memory_leak_detection');
      await optimizationService.applyTweak('widget_rebuild_optimization');
      
      // Generate optimization report
      final report = optimizationService.generateOptimizationReport();
      
      // Verify report structure
      expect(report['timestamp'], isNotNull);
      expect(report['totalTweaks'], greaterThan(0));
      expect(report['enabledTweaks'], greaterThan(0));
      expect(report['appliedTweaks'], greaterThan(0));
      expect(report['successfulTweaks'], greaterThan(0));
      expect(report['categories'], isNotNull);
      expect(report['results'], isNotNull);
      expect(report['summary'], isNotNull);
      
      // Log verification
      loggerService.info('Optimization report generation test completed', data: report);
    });

    test('Custom optimization tweak registration', () {
      // Get initial tweak count
      final initialTweaks = optimizationService.getAllTweaks();
      final initialCount = initialTweaks.length;
      
      // Register a custom tweak
      final customTweak = OptimizationTweak(
        name: 'custom_test_tweak',
        category: 'test',
        description: 'A custom test tweak',
        priority: 5,
      );
      
      optimizationService.registerTweak(customTweak);
      
      // Verify tweak was registered
      final updatedTweaks = optimizationService.getAllTweaks();
      expect(updatedTweaks.length, equals(initialCount + 1));
      
      // Find the custom tweak
      final registeredTweak = updatedTweaks.firstWhere(
        (tweak) => tweak.name == 'custom_test_tweak',
      );
      expect(registeredTweak.category, equals('test'));
      expect(registeredTweak.description, equals('A custom test tweak'));
      expect(registeredTweak.priority, equals(5));
      
      // Log verification
      loggerService.info('Custom optimization tweak registration test completed', data: {
        'initialCount': initialCount,
        'finalCount': updatedTweaks.length,
        'customTweak': {
          'name': customTweak.name,
          'category': customTweak.category,
          'priority': customTweak.priority,
        },
      });
    });

    test('Optimization results retrieval', () async {
      // Apply a tweak
      const tweakName = 'memory_leak_detection';
      await optimizationService.applyTweak(tweakName);
      
      // Get all results
      final allResults = optimizationService.getAllResults();
      expect(allResults.length, greaterThan(0));
      
      // Get results by category
      final memoryResults = optimizationService.getResultsByCategory('memory');
      expect(memoryResults.length, greaterThan(0));
      
      // Get result by name
      final specificResult = optimizationService.getResult(tweakName);
      expect(specificResult, isNotNull);
      expect(specificResult!.name, equals(tweakName));
      
      // Log verification
      loggerService.info('Optimization results retrieval test completed', data: {
        'allResultsCount': allResults.length,
        'memoryResultsCount': memoryResults.length,
        'specificResultName': specificResult.name,
      });
    });

    test('Error handling for unknown tweaks', () async {
      // Try to apply an unknown tweak
      try {
        await optimizationService.applyTweak('unknown_tweak');
        fail('Expected ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
        expect(e.toString(), contains('Tweak not found'));
      }
      
      // Log verification
      loggerService.info('Error handling for unknown tweaks test completed');
    });
  });
}