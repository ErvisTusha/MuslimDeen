import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/providers/optimized_providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/optimized_prayer_list_item.dart';

typedef PrayerInfoBuilder =
    PrayerDisplayInfoData Function(PrayerNotification prayerEnum);

/// Optimized prayer times section with performance improvements
class OptimizedPrayerTimesSection extends ConsumerStatefulWidget {
  final bool isLoading;
  final List<PrayerNotification> prayerOrder;
  final UIColors colors;
  final Color currentPrayerBg;
  final Color currentPrayerBorder;
  final Color currentPrayerText;
  final PrayerNotification? currentPrayerEnum;
  final DateFormat timeFormatter;
  final VoidCallback onRefresh;
  final ScrollController scrollController;
  final PrayerInfoBuilder getPrayerDisplayInfo;

  const OptimizedPrayerTimesSection({
    super.key,
    required this.isLoading,
    required this.prayerOrder,
    required this.colors,
    required this.currentPrayerBg,
    required this.currentPrayerBorder,
    required this.currentPrayerText,
    required this.currentPrayerEnum,
    required this.timeFormatter,
    required this.onRefresh,
    required this.scrollController,
    required this.getPrayerDisplayInfo,
  });

  @override
  ConsumerState<OptimizedPrayerTimesSection> createState() =>
      _OptimizedPrayerTimesSectionState();
}

class _OptimizedPrayerTimesSectionState
    extends ConsumerState<OptimizedPrayerTimesSection>
    with AutomaticKeepAliveClientMixin {
  // Memoized decoration
  BoxDecoration? _cachedDecoration;

  @override
  bool get wantKeepAlive => true;

  /// Memoized decoration builder
  BoxDecoration _buildPrayerListDecoration() {
    if (_cachedDecoration != null) {
      return _cachedDecoration!;
    }

    _cachedDecoration = BoxDecoration(
      color: widget.colors.contentSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: widget.colors.borderColor.withAlpha(
          widget.colors.isDarkMode ? 70 : 100,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor
              .withAlpha(widget.colors.isDarkMode ? 20 : 40),
          spreadRadius: 0,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );

    return _cachedDecoration!;
  }

  /// Optimized item builder with proper keys
  Widget _buildPrayerItem(BuildContext context, int index) {
    try {
      final prayerEnum = widget.prayerOrder[index];
      final prayerInfo = widget.getPrayerDisplayInfo(prayerEnum);
      final bool isCurrent =
          !widget.isLoading &&
          widget.currentPrayerEnum == prayerInfo.prayerEnum;

      // Use the optimized factory for creating prayer items
      return OptimizedPrayerListItemFactory.create(
        prayerInfo: prayerInfo,
        timeFormatter: widget.timeFormatter,
        isCurrent: isCurrent,
        brightness: widget.colors.brightness,
        contentSurfaceColor: widget.colors.contentSurface,
        currentPrayerItemBgColor: widget.currentPrayerBg,
        currentPrayerItemBorderColor: widget.currentPrayerBorder,
        currentPrayerItemTextColor: widget.currentPrayerText,
        onRefresh: widget.onRefresh,
      );
    } catch (e) {
      // Handle error gracefully
      return const SizedBox.shrink();
    }
  }

  /// Optimized separator builder
  Widget _buildSeparator(BuildContext context, int index) {
    return Divider(
      key: ValueKey('separator_$index'),
      color: widget.colors.borderColor.withAlpha(
        widget.colors.isDarkMode ? 70 : 100,
      ),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    try {
      // Use optimized provider for UI state
      final isRefreshing = ref.watch(isRefreshingProvider);

      return Expanded(
        child: Column(
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Prayer Times",
                  style: AppTextStyles.sectionTitle(
                    widget.colors.brightness,
                  ).copyWith(color: widget.colors.textColorPrimary),
                ),
              ),
            ),

            // Prayer list
            Expanded(
              child: Stack(
                children: [
                  // Main content
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: _buildPrayerListDecoration(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: ListView.separated(
                        controller: widget.scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: widget.prayerOrder.length,
                        // Note: itemExtent is not available in ListView.separated
                        // Performance optimization through item caching and proper keys
                        separatorBuilder: _buildSeparator,
                        itemBuilder: _buildPrayerItem,
                      ),
                    ),
                  ),

                  // Loading overlay
                  if (widget.isLoading || isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(50),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.colors.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Handle error gracefully
      return const SizedBox.shrink();
    }
  }

  @override
  void didUpdateWidget(OptimizedPrayerTimesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Invalidate cached decoration when colors change
    if (oldWidget.colors != widget.colors) {
      _cachedDecoration = null;
    }
  }
}

/// Optimized prayer times section with automatic refresh management
class AutoRefreshPrayerTimesSection extends ConsumerStatefulWidget {
  final List<PrayerNotification> prayerOrder;
  final UIColors colors;
  final Color currentPrayerBg;
  final Color currentPrayerBorder;
  final Color currentPrayerText;
  final PrayerNotification? currentPrayerEnum;
  final DateFormat timeFormatter;
  final PrayerInfoBuilder getPrayerDisplayInfo;

  const AutoRefreshPrayerTimesSection({
    super.key,
    required this.prayerOrder,
    required this.colors,
    required this.currentPrayerBg,
    required this.currentPrayerBorder,
    required this.currentPrayerText,
    required this.currentPrayerEnum,
    required this.timeFormatter,
    required this.getPrayerDisplayInfo,
  });

  @override
  ConsumerState<AutoRefreshPrayerTimesSection> createState() =>
      _AutoRefreshPrayerTimesSectionState();
}

class _AutoRefreshPrayerTimesSectionState
    extends ConsumerState<AutoRefreshPrayerTimesSection>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final LoggerService _logger = locator<LoggerService>();

  Timer? _autoRefreshTimer;
  DateTime? _lastRefreshTime;
  static const Duration _autoRefreshInterval = Duration(minutes: 5);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();

    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      _performAutoRefresh();
    });

    _logger.debug(
      'Auto refresh started with interval: ${_autoRefreshInterval.inMinutes} minutes',
    );
  }

  Future<void> _performAutoRefresh() async {
    try {
      // Only refresh if enough time has passed
      final now = DateTime.now();
      if (_lastRefreshTime != null &&
          now.difference(_lastRefreshTime!).inMinutes <
              _autoRefreshInterval.inMinutes) {
        return;
      }

      _lastRefreshTime = now;

      // Trigger UI state refresh
      ref.read(uiStateProvider.notifier).triggerRefresh();

      // Complete refresh after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          ref.read(uiStateProvider.notifier).completeRefresh();
        }
      });

      _logger.debug('Auto refresh completed');
    } catch (e, s) {
      _logger.error('Error during auto refresh', error: e, stackTrace: s);
    }
  }

  Future<void> _manualRefresh() async {
    try {
      ref.read(uiStateProvider.notifier).triggerRefresh();

      // Simulate refresh operation
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ref.read(uiStateProvider.notifier).completeRefresh();
      }

      _logger.debug('Manual refresh completed');
    } catch (e) {
      _logger.error('Error during manual refresh', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // Use optimized provider for loading state
    final isLoading = ref.watch(prayerLoadingSelectorProvider);
    final isRefreshing = ref.watch(isRefreshingProvider);

    return OptimizedPrayerTimesSection(
      isLoading: isLoading || isRefreshing,
      prayerOrder: widget.prayerOrder,
      colors: widget.colors,
      currentPrayerBg: widget.currentPrayerBg,
      currentPrayerBorder: widget.currentPrayerBorder,
      currentPrayerText: widget.currentPrayerText,
      currentPrayerEnum: widget.currentPrayerEnum,
      timeFormatter: widget.timeFormatter,
      onRefresh: _manualRefresh,
      scrollController: _scrollController,
      getPrayerDisplayInfo: widget.getPrayerDisplayInfo,
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

/// Factory for creating optimized prayer times sections
class OptimizedPrayerTimesSectionFactory {
  /// Create an optimized prayer times section with auto-refresh
  static Widget createWithAutoRefresh({
    required List<PrayerNotification> prayerOrder,
    required UIColors colors,
    required Color currentPrayerBg,
    required Color currentPrayerBorder,
    required Color currentPrayerText,
    required PrayerNotification? currentPrayerEnum,
    required DateFormat timeFormatter,
    required PrayerInfoBuilder getPrayerDisplayInfo,
  }) {
    return AutoRefreshPrayerTimesSection(
      key: const ValueKey('auto_refresh_prayer_times_section'),
      prayerOrder: prayerOrder,
      colors: colors,
      currentPrayerBg: currentPrayerBg,
      currentPrayerBorder: currentPrayerBorder,
      currentPrayerText: currentPrayerText,
      currentPrayerEnum: currentPrayerEnum,
      timeFormatter: timeFormatter,
      getPrayerDisplayInfo: getPrayerDisplayInfo,
    );
  }

  /// Create a basic optimized prayer times section
  static Widget create({
    required bool isLoading,
    required List<PrayerNotification> prayerOrder,
    required UIColors colors,
    required Color currentPrayerBg,
    required Color currentPrayerBorder,
    required Color currentPrayerText,
    required PrayerNotification? currentPrayerEnum,
    required DateFormat timeFormatter,
    required VoidCallback onRefresh,
    required ScrollController scrollController,
    required PrayerInfoBuilder getPrayerDisplayInfo,
  }) {
    return OptimizedPrayerTimesSection(
      key: const ValueKey('optimized_prayer_times_section'),
      isLoading: isLoading,
      prayerOrder: prayerOrder,
      colors: colors,
      currentPrayerBg: currentPrayerBg,
      currentPrayerBorder: currentPrayerBorder,
      currentPrayerText: currentPrayerText,
      currentPrayerEnum: currentPrayerEnum,
      timeFormatter: timeFormatter,
      onRefresh: onRefresh,
      scrollController: scrollController,
      getPrayerDisplayInfo: getPrayerDisplayInfo,
    );
  }
}
