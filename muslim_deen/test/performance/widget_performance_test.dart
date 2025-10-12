import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import 'package:muslim_deen/widgets/optimized_prayer_list_item.dart';

import 'package:muslim_deen/widgets/optimized_prayer_times_section.dart';

import 'package:muslim_deen/widgets/performance_overlay.dart' as custom;

import 'package:muslim_deen/services/performance_monitoring_service.dart';

import 'package:muslim_deen/services/logger_service.dart';

import 'package:muslim_deen/models/prayer_display_info_data.dart';

import 'package:muslim_deen/models/app_settings.dart';

import 'package:muslim_deen/styles/ui_theme_helper.dart';

import 'package:muslim_deen/service_locator.dart';

/// Performance tests for UI widgets
void main() {
  group('Widget Performance Tests', () {
    late ProviderContainer container;
    late PerformanceMonitoringService performanceService;
    late LoggerService loggerService;

    setUpAll(() async {
      await setupLocator(testing: true);
    });

    setUp(() {
      container = ProviderContainer();
      performanceService = locator<PerformanceMonitoringService>();
      loggerService = locator<LoggerService>();
      performanceService.initialize(
        enableMonitoring: true,
        enableFrameRateMonitoring: true,
        enableWidgetBuildTracking: true,
      );
    });

    tearDown(() {
      container.dispose();
      performanceService.resetMetrics();
    });

    testWidgets('OptimizedPrayerListItem build performance', (tester) async {
      const int testIterations = 50;
      final List<Duration> buildTimes = [];

      // Create test prayer info
      final prayerInfo = PrayerDisplayInfoData(
        name: 'Fajr',
        time: DateTime.now().add(const Duration(hours: 1)),
        prayerEnum: PrayerNotification.fajr,
        iconData: Icons.wb_sunny,
      );

      // Create theme colors
      final colors = UIThemeHelper.getThemeColors(Brightness.light);
      final prayerColors = PrayerItemColors(
        currentPrayerBg: colors.accentColor.withAlpha(30),
        currentPrayerBorder: colors.accentColor,
        currentPrayerText: colors.accentColor,
      );

      // Create time formatter
      final timeFormatter = DateFormat.jm();

      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedPrayerListItem(
                  prayerInfo: prayerInfo,
                  timeFormatter: timeFormatter,
                  isCurrent:
                      i % 5 == 0, // Make every 5th item the current prayer
                  brightness: Brightness.light,
                  contentSurfaceColor: colors.contentSurface,
                  currentPrayerItemBgColor: prayerColors.currentPrayerBg,
                  currentPrayerItemBorderColor:
                      prayerColors.currentPrayerBorder,
                  currentPrayerItemTextColor: prayerColors.currentPrayerText,
                  onRefresh: () {},
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();
        buildTimes.add(stopwatch.elapsed);

        // Clear the widget tree for next iteration
        await tester.pumpWidget(Container());
      }

      // Calculate performance metrics
      final avgBuildTime = _calculateAverageTime(buildTimes);
      final maxBuildTime = _calculateMaxTime(buildTimes);
      final minBuildTime = _calculateMinTime(buildTimes);

      loggerService.info(
        'OptimizedPrayerListItem Performance Results',
        data: {
          'iterations': testIterations,
          'avgBuildTime': '${avgBuildTime.inMicroseconds}μs',
          'maxBuildTime': '${maxBuildTime.inMicroseconds}μs',
          'minBuildTime': '${minBuildTime.inMicroseconds}μs',
        },
      );

      // Performance assertions
      expect(
        avgBuildTime.inMilliseconds,
        lessThan(50),
        reason: 'Average build time should be under 50ms',
      );
      expect(
        maxBuildTime.inMilliseconds,
        lessThan(100),
        reason: 'Max build time should be under 100ms',
      );
    });

    testWidgets('OptimizedPrayerTimesSection build performance', (
      tester,
    ) async {
      const int testIterations = 20;
      final List<Duration> buildTimes = [];

      // Create theme colors
      final colors = UIThemeHelper.getThemeColors(Brightness.light);
      final prayerColors = PrayerItemColors(
        currentPrayerBg: colors.accentColor.withAlpha(30),
        currentPrayerBorder: colors.accentColor,
        currentPrayerText: colors.accentColor,
      );

      // Create prayer order
      final prayerOrder = PrayerNotification.values;

      // Create time formatter
      final timeFormatter = DateFormat.jm();

      // Create prayer info builder
      PrayerDisplayInfoData getPrayerDisplayInfo(
        PrayerNotification prayerEnum,
      ) {
        return PrayerDisplayInfoData(
          name: prayerEnum.name,
          time: DateTime.now().add(Duration(hours: prayerEnum.index + 1)),
          prayerEnum: prayerEnum,
          iconData: _getPrayerIcon(prayerEnum),
        );
      }

      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedPrayerTimesSection(
                  isLoading: false,
                  prayerOrder: prayerOrder,
                  colors: colors,
                  currentPrayerBg: prayerColors.currentPrayerBg,
                  currentPrayerBorder: prayerColors.currentPrayerBorder,
                  currentPrayerText: prayerColors.currentPrayerText,
                  currentPrayerEnum: PrayerNotification.fajr,
                  timeFormatter: timeFormatter,
                  onRefresh: () {},
                  scrollController: ScrollController(),
                  getPrayerDisplayInfo: getPrayerDisplayInfo,
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();
        buildTimes.add(stopwatch.elapsed);

        // Clear the widget tree for next iteration
        await tester.pumpWidget(Container());
      }

      // Calculate performance metrics
      final avgBuildTime = _calculateAverageTime(buildTimes);
      final maxBuildTime = _calculateMaxTime(buildTimes);

      loggerService.info(
        'OptimizedPrayerTimesSection Performance Results',
        data: {
          'iterations': testIterations,
          'avgBuildTime': '${avgBuildTime.inMilliseconds}ms',
          'maxBuildTime': '${maxBuildTime.inMilliseconds}ms',
        },
      );

      // Performance assertions (PrayerTimesSection is more complex)
      expect(
        avgBuildTime.inMilliseconds,
        lessThan(150),
        reason: 'Average build time should be under 150ms',
      );
      expect(
        maxBuildTime.inMilliseconds,
        lessThan(300),
        reason: 'Max build time should be under 300ms',
      );
    });

    testWidgets('Performance overlay impact test', (tester) async {
      const int testIterations = 30;
      final List<Duration> buildTimesWithOverlay = [];
      final List<Duration> buildTimesWithoutOverlay = [];

      // Create a simple widget to test overlay impact
      Widget createTestWidget({bool withOverlay = false}) {
        final testWidget = Container(
          width: 200,
          height: 100,
          color: Colors.blue,
          child: const Center(child: Text('Test Widget')),
        );

        if (withOverlay) {
          return Stack(
            children: [
              testWidget,
              custom.PerformanceOverlay(enabled: true, child: testWidget),
            ],
          );
        }

        return testWidget;
      }

      // Test without overlay
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: createTestWidget(withOverlay: false)),
            ),
          ),
        );

        stopwatch.stop();
        buildTimesWithoutOverlay.add(stopwatch.elapsed);

        await tester.pumpWidget(Container());
      }

      // Test with overlay
      for (int i = 0; i < testIterations; i++) {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(body: createTestWidget(withOverlay: true)),
            ),
          ),
        );

        stopwatch.stop();
        buildTimesWithOverlay.add(stopwatch.elapsed);

        await tester.pumpWidget(Container());
      }

      // Calculate performance metrics
      final avgTimeWithoutOverlay = _calculateAverageTime(
        buildTimesWithoutOverlay,
      );
      final avgTimeWithOverlay = _calculateAverageTime(buildTimesWithOverlay);
      final overhead =
          avgTimeWithOverlay.inMicroseconds -
          avgTimeWithoutOverlay.inMicroseconds;
      final overheadPercentage =
          avgTimeWithoutOverlay.inMicroseconds > 0
              ? (overhead / avgTimeWithoutOverlay.inMicroseconds * 100)
              : 0.0;

      loggerService.info(
        'Performance Overlay Impact Results',
        data: {
          'iterations': testIterations,
          'avgTimeWithoutOverlay': '${avgTimeWithoutOverlay.inMicroseconds}μs',
          'avgTimeWithOverlay': '${avgTimeWithOverlay.inMicroseconds}μs',
          'overhead': '${overhead}μs',
          'overheadPercentage': '${overheadPercentage.toStringAsFixed(2)}%',
        },
      );

      // Performance assertions - overlay should have minimal impact
      expect(
        overheadPercentage,
        lessThan(50),
        reason: 'Performance overlay overhead should be under 50%',
      );
    });

    testWidgets('Widget rebuild performance test', (tester) async {
      const int rebuildCount = 50;
      final List<Duration> rebuildTimes = [];

      // Create test prayer info
      final prayerInfo = PrayerDisplayInfoData(
        name: 'Fajr',
        time: DateTime.now().add(const Duration(hours: 1)),
        prayerEnum: PrayerNotification.fajr,
        iconData: Icons.wb_sunny,
      );

      // Create theme colors
      final colors = UIThemeHelper.getThemeColors(Brightness.light);
      final prayerColors = PrayerItemColors(
        currentPrayerBg: colors.accentColor.withAlpha(30),
        currentPrayerBorder: colors.accentColor,
        currentPrayerText: colors.accentColor,
      );

      // Create time formatter
      final timeFormatter = DateFormat.jm();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: OptimizedPrayerListItem(
                prayerInfo: prayerInfo,
                timeFormatter: timeFormatter,
                isCurrent: true,
                brightness: Brightness.light,
                contentSurfaceColor: colors.contentSurface,
                currentPrayerItemBgColor: prayerColors.currentPrayerBg,
                currentPrayerItemBorderColor: prayerColors.currentPrayerBorder,
                currentPrayerItemTextColor: prayerColors.currentPrayerText,
                onRefresh: () {},
              ),
            ),
          ),
        ),
      );

      // Test rebuild performance
      for (int i = 0; i < rebuildCount; i++) {
        final stopwatch = Stopwatch()..start();

        // Trigger a rebuild by updating the widget
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedPrayerListItem(
                  prayerInfo: prayerInfo,
                  timeFormatter: timeFormatter,
                  isCurrent:
                      true, // Keep consistent to avoid rebuilds due to this parameter
                  brightness: Brightness.light,
                  contentSurfaceColor: colors.contentSurface,
                  currentPrayerItemBgColor: prayerColors.currentPrayerBg,
                  currentPrayerItemBorderColor:
                      prayerColors.currentPrayerBorder,
                  currentPrayerItemTextColor: prayerColors.currentPrayerText,
                  onRefresh: () {},
                ),
              ),
            ),
          ),
        );

        stopwatch.stop();
        rebuildTimes.add(stopwatch.elapsed);
      }

      // Calculate performance metrics
      final avgRebuildTime = _calculateAverageTime(rebuildTimes);
      final maxRebuildTime = _calculateMaxTime(rebuildTimes);

      loggerService.info(
        'Widget Rebuild Performance Results',
        data: {
          'rebuildCount': rebuildCount,
          'avgRebuildTime': '${avgRebuildTime.inMicroseconds}μs',
          'maxRebuildTime': '${maxRebuildTime.inMicroseconds}μs',
        },
      );

      // Performance assertions
      expect(
        avgRebuildTime.inMilliseconds,
        lessThan(10),
        reason: 'Average rebuild time should be under 10ms',
      );
      expect(
        maxRebuildTime.inMilliseconds,
        lessThan(20),
        reason: 'Max rebuild time should be under 20ms',
      );
    });

    testWidgets('Memory usage during widget operations', (tester) async {
      const int operationCount = 100;

      // Get initial memory metrics
      final initialMemory = await performanceService.getMemoryUsage();

      // Create theme colors
      final colors = UIThemeHelper.getThemeColors(Brightness.light);
      final prayerColors = PrayerItemColors(
        currentPrayerBg: colors.accentColor.withAlpha(30),
        currentPrayerBorder: colors.accentColor,
        currentPrayerText: colors.accentColor,
      );

      // Create time formatter
      final timeFormatter = DateFormat.jm();

      // Perform intensive widget operations
      for (int i = 0; i < operationCount; i++) {
        final prayerInfo = PrayerDisplayInfoData(
          name:
              PrayerNotification
                  .values[i % PrayerNotification.values.length]
                  .name,
          time: DateTime.now().add(Duration(hours: i % 24)),
          prayerEnum:
              PrayerNotification.values[i % PrayerNotification.values.length],
          iconData: _getPrayerIcon(
            PrayerNotification.values[i % PrayerNotification.values.length],
          ),
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: OptimizedPrayerListItem(
                  prayerInfo: prayerInfo,
                  timeFormatter: timeFormatter,
                  isCurrent: i % 10 == 0,
                  brightness: i % 2 == 0 ? Brightness.light : Brightness.dark,
                  contentSurfaceColor: colors.contentSurface,
                  currentPrayerItemBgColor: prayerColors.currentPrayerBg,
                  currentPrayerItemBorderColor:
                      prayerColors.currentPrayerBorder,
                  currentPrayerItemTextColor: prayerColors.currentPrayerText,
                  onRefresh: () {},
                ),
              ),
            ),
          ),
        );

        // Occasionally trigger garbage collection simulation
        if (i % 20 == 0) {
          await tester.pumpWidget(Container());
        }
      }

      // Get final memory metrics
      final finalMemory = await performanceService.getMemoryUsage();

      loggerService.info(
        'Memory Usage Test Results',
        data: {
          'operationCount': operationCount,
          'initialMemory': initialMemory,
          'finalMemory': finalMemory,
        },
      );

      // Check for memory leaks (simplified check)
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

        // Memory growth should be reasonable
        expect(
          growthPercentage,
          lessThan(100),
          reason: 'Memory growth should be under 100%',
        );
      }
    });

    testWidgets('Frame rate performance during complex UI operations', (
      tester,
    ) async {
      // Start frame rate monitoring
      performanceService.setFrameRateMonitoringEnabled(true);

      // Create a complex UI scenario with ListView
      final colors = UIThemeHelper.getThemeColors(Brightness.light);
      final prayerColors = PrayerItemColors(
        currentPrayerBg: colors.accentColor.withAlpha(30),
        currentPrayerBorder: colors.accentColor,
        currentPrayerText: colors.accentColor,
      );

      final timeFormatter = DateFormat.jm();

      PrayerDisplayInfoData getPrayerDisplayInfo(
        PrayerNotification prayerEnum,
      ) {
        return PrayerDisplayInfoData(
          name: prayerEnum.name,
          time: DateTime.now().add(Duration(hours: prayerEnum.index + 1)),
          prayerEnum: prayerEnum,
          iconData: _getPrayerIcon(prayerEnum),
        );
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) {
                  final prayerEnum =
                      PrayerNotification.values[index %
                          PrayerNotification.values.length];
                  final prayerInfo = getPrayerDisplayInfo(prayerEnum);
                  final isCurrent = index % 10 == 0;

                  return Container(
                    margin: const EdgeInsets.all(4),
                    child: OptimizedPrayerListItem(
                      prayerInfo: prayerInfo,
                      timeFormatter: timeFormatter,
                      isCurrent: isCurrent,
                      brightness: Brightness.light,
                      contentSurfaceColor: colors.contentSurface,
                      currentPrayerItemBgColor: prayerColors.currentPrayerBg,
                      currentPrayerItemBorderColor:
                          prayerColors.currentPrayerBorder,
                      currentPrayerItemTextColor:
                          prayerColors.currentPrayerText,
                      onRefresh: () {},
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Simulate scrolling
      for (int i = 0; i < 10; i++) {
        await tester.fling(find.byType(ListView), const Offset(0, -300), 1000);
        await tester.pumpAndSettle();
      }

      // Get frame rate metrics after scrolling
      final frameRateMetrics = performanceService.getFrameRateMetrics();

      loggerService.info(
        'Frame Rate Performance Results',
        data: {
          'scrollOperations': 10,
          'currentFrameRate': frameRateMetrics['currentFrameRate'],
          'averageFrameRate': frameRateMetrics['averageFrameRate'],
          'historyLength': frameRateMetrics['historyLength'],
        },
      );

      // Performance assertions - basic check that we have frame rate data
      expect(
        frameRateMetrics['averageFrameRate'],
        greaterThan(0),
        reason: 'Should have positive frame rate',
      );
    });
  });
}

/// Get appropriate icon for each prayer
IconData _getPrayerIcon(PrayerNotification prayer) {
  switch (prayer) {
    case PrayerNotification.fajr:
      return Icons.wb_sunny;
    case PrayerNotification.sunrise:
      return Icons.wb_twilight;
    case PrayerNotification.dhuhr:
      return Icons.wb_sunny_outlined;
    case PrayerNotification.asr:
      return Icons.access_time;
    case PrayerNotification.maghrib:
      return Icons.nights_stay;
    case PrayerNotification.isha:
      return Icons.bedtime;
  }
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

/// Calculate minimum time from a list of durations
Duration _calculateMinTime(List<Duration> durations) {
  if (durations.isEmpty) return Duration.zero;

  return durations.reduce((a, b) => a < b ? a : b);
}
