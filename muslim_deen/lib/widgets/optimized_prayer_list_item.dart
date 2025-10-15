import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/providers/optimized_providers.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';

import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/settings_view.dart';

/// Optimized prayer list item with caching and performance improvements
class OptimizedPrayerListItem extends ConsumerStatefulWidget {
  final PrayerDisplayInfoData prayerInfo;
  final DateFormat timeFormatter;
  final bool isCurrent;
  final Brightness brightness;
  final Color contentSurfaceColor;
  final Color currentPrayerItemBgColor;
  final Color currentPrayerItemBorderColor;
  final Color currentPrayerItemTextColor;
  final VoidCallback? onRefresh;

  const OptimizedPrayerListItem({
    super.key,
    required this.prayerInfo,
    required this.timeFormatter,
    required this.isCurrent,
    required this.brightness,
    required this.contentSurfaceColor,
    required this.currentPrayerItemBgColor,
    required this.currentPrayerItemBorderColor,
    required this.currentPrayerItemTextColor,
    this.onRefresh,
  });

  @override
  ConsumerState<OptimizedPrayerListItem> createState() =>
      _OptimizedPrayerListItemState();
}

class _OptimizedPrayerListItemState
    extends ConsumerState<OptimizedPrayerListItem>
    with AutomaticKeepAliveClientMixin {
  bool _isCompleted = false;
  bool _isLoading = false;

  // Performance optimization: cache completion status
  DateTime? _lastCompletionCheck;

  // Services
  late final LoggerService _logger;

  // Memoized values
  late final String _prayerKey;
  bool? _cachedNotificationEnabled;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _prayerKey =
        '${widget.prayerInfo.prayerEnum.name}_${widget.prayerInfo.time?.millisecondsSinceEpoch ?? 0}';
    _checkCompletionStatus();
  }

  void _initializeServices() {
    _logger = locator<LoggerService>();
  }

  /// Optimized completion status check with caching
  Future<void> _checkCompletionStatus() async {
    try {
      // Cache completion status for 30 seconds
      final now = DateTime.now();
      if (_lastCompletionCheck != null &&
          now.difference(_lastCompletionCheck!).inSeconds < 30) {
        return;
      }

      final prayerName = widget.prayerInfo.prayerEnum.name;

      // Use the optimized provider for completion status
      final isCompleted = ref.read(
        prayerCompletionSelectorProvider(prayerName),
      );

      if (mounted) {
        setState(() {
          _isCompleted = isCompleted;
          _lastCompletionCheck = now;
        });
      }
    } catch (e, s) {
      _logger.error(
        'Error checking prayer completion status',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Check if this prayer has already passed
  bool _hasPrayerPassed() {
    if (widget.prayerInfo.time == null) return false;
    return DateTime.now().isAfter(widget.prayerInfo.time!);
  }

  /// Toggle completion status with optimized provider usage
  Future<void> _toggleCompletionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prayerName = widget.prayerInfo.prayerEnum.name;

      // Use the optimized provider to update completion status
      await ref
          .read(optimizedPrayerCompletionProvider.notifier)
          .updatePrayerCompletion(prayerName, !_isCompleted);

      if (mounted) {
        setState(() {
          _isCompleted = !_isCompleted;
          _isLoading = false;
        });
      }

      widget.onRefresh?.call();

      _logger.debug(
        'Prayer completion toggled',
        data: {'prayerName': prayerName, 'isCompleted': _isCompleted},
      );
    } catch (e, s) {
      _logger.error(
        'Failed to toggle prayer completion',
        error: e,
        stackTrace: s,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Failed to update prayer status: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// Memoized item colors calculation
  _ItemColors _getItemColors() {
    return _ItemColors(
      background:
          widget.isCurrent
              ? widget.currentPrayerItemBgColor
              : widget.contentSurfaceColor,
      icon:
          widget.isCurrent
              ? widget.currentPrayerItemTextColor
              : AppColors.iconInactive,
      text:
          widget.isCurrent
              ? widget.currentPrayerItemTextColor
              : AppColors.textPrimary(widget.brightness),
    );
  }

  /// Memoized splash colors calculation
  _SplashColors _getSplashColors() {
    final baseColor =
        widget.isCurrent
            ? widget.currentPrayerItemTextColor
            : AppColors.primary(widget.brightness);

    return _SplashColors(
      splash: baseColor.withAlpha((0.1 * 255).round()),
      highlight: baseColor.withAlpha((0.05 * 255).round()),
    );
  }

  /// Optimized notification status check with caching
  bool _isNotificationEnabled(AppSettings settings) {
    // Cache notification enabled status
    if (_cachedNotificationEnabled == null) {
      _cachedNotificationEnabled =
          settings.notifications[widget.prayerInfo.prayerEnum] ?? false;
    }
    return _cachedNotificationEnabled!;
  }

  /// Navigate to settings
  void _navigateToSettings(BuildContext context) {
    locator<NavigationService>()
        .navigateTo<void>(
          const SettingsView(scrollToNotifications: true),
          routeName: '/settings',
        )
        .then((_) {
          widget.onRefresh?.call();
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    try {
      // Use selector to only rebuild when settings.notifications changes
      final notifications = ref.watch(
        settingsProvider.select((settings) => settings.notifications),
      );
      final themeMode = ref.watch(
        settingsProvider.select((settings) => settings.themeMode),
      );
      final timeFormat = ref.watch(
        settingsProvider.select((settings) => settings.timeFormat),
      );
      final dateFormatOption = ref.watch(
        settingsProvider.select((settings) => settings.dateFormatOption),
      );

      // Create a minimal AppSettings object for the specific properties we need
      final settings = AppSettings.defaults.copyWith(
        notifications: notifications,
        themeMode: themeMode,
        timeFormat: timeFormat,
        dateFormatOption: dateFormatOption,
      );

      final itemColors = _getItemColors();
      final splashColors = _getSplashColors();
      final isNotificationEnabled = _isNotificationEnabled(settings);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('prayer_item_$_prayerKey'),
          onDoubleTap: () => _navigateToSettings(context),
          splashColor: splashColors.splash,
          highlightColor: splashColors.highlight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: itemColors.background,
              border: const Border(top: BorderSide(color: Colors.transparent)),
            ),
            child: Row(
              children: [
                // Prayer icon
                Icon(
                  widget.prayerInfo.iconData,
                  color: itemColors.icon,
                  size: 22,
                ),
                const SizedBox(width: 16),

                // Prayer name
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.prayerInfo.name,
                    style: AppTextStyles.prayerName(widget.brightness).copyWith(
                      color: itemColors.text,
                      fontWeight:
                          widget.isCurrent ? FontWeight.bold : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                // Notification indicator
                if (!isNotificationEnabled) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.notifications_off,
                    color: Colors.orange,
                    size: 16,
                  ),
                ],

                const Spacer(),

                // Prayer time
                Text(
                  widget.prayerInfo.time != null
                      ? widget.timeFormatter.format(
                        widget.prayerInfo.time!.toLocal(),
                      )
                      : '---',
                  style: AppTextStyles.prayerTime(widget.brightness).copyWith(
                    color: itemColors.text,
                    fontWeight:
                        widget.isCurrent ? FontWeight.bold : FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 12),

                // Checkbox or loading indicator
                _isLoading
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          itemColors.icon,
                        ),
                      ),
                    )
                    : Checkbox(
                      key: ValueKey('checkbox_$_prayerKey'),
                      value: _isCompleted,
                      onChanged:
                          (_isCompleted || _hasPrayerPassed())
                              ? (bool? value) => _toggleCompletionStatus()
                              : null,
                      activeColor: itemColors.icon,
                      checkColor: itemColors.background,
                    ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _logger.error('Error building prayer list item', error: e);
      return const SizedBox.shrink();
    }
  }

  @override
  void didUpdateWidget(OptimizedPrayerListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset cache when prayer info changes
    if (oldWidget.prayerInfo.prayerEnum != widget.prayerInfo.prayerEnum) {
      _cachedNotificationEnabled = null;
      _lastCompletionCheck = null;
      _checkCompletionStatus();
    }
  }
}

/// Helper class to store item colors
class _ItemColors {
  final Color background;
  final Color icon;
  final Color text;

  const _ItemColors({
    required this.background,
    required this.icon,
    required this.text,
  });
}

/// Helper class to store splash colors
class _SplashColors {
  final Color splash;
  final Color highlight;

  const _SplashColors({required this.splash, required this.highlight});
}

/// Factory for creating optimized prayer list items with proper keys
class OptimizedPrayerListItemFactory {
  /// Create an optimized prayer list item with a unique key
  static Widget create({
    required PrayerDisplayInfoData prayerInfo,
    required DateFormat timeFormatter,
    required bool isCurrent,
    required Brightness brightness,
    required Color contentSurfaceColor,
    required Color currentPrayerItemBgColor,
    required Color currentPrayerItemBorderColor,
    required Color currentPrayerItemTextColor,
    VoidCallback? onRefresh,
  }) {
    return OptimizedPrayerListItem(
      key: ValueKey(
        'prayer_item_${prayerInfo.prayerEnum.name}_${prayerInfo.time?.millisecondsSinceEpoch ?? 0}',
      ),
      prayerInfo: prayerInfo,
      timeFormatter: timeFormatter,
      isCurrent: isCurrent,
      brightness: brightness,
      contentSurfaceColor: contentSurfaceColor,
      currentPrayerItemBgColor: currentPrayerItemBgColor,
      currentPrayerItemBorderColor: currentPrayerItemBorderColor,
      currentPrayerItemTextColor: currentPrayerItemTextColor,
      onRefresh: onRefresh,
    );
  }
}
