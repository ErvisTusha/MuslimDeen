import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/settings_view.dart'; // For navigation

class PrayerListItem extends ConsumerStatefulWidget {
  final PrayerDisplayInfoData prayerInfo;
  final DateFormat timeFormatter;
  final bool isCurrent;
  final Brightness brightness;
  final Color contentSurfaceColor;
  final Color currentPrayerItemBgColor;
  final Color currentPrayerItemBorderColor;
  final Color currentPrayerItemTextColor;
  final VoidCallback? onRefresh; // Callback to trigger refresh in HomeView

  const PrayerListItem({
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
  ConsumerState<PrayerListItem> createState() => _PrayerListItemState();
}

class _PrayerListItemState extends ConsumerState<PrayerListItem> {
  bool _isCompleted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  Future<void> _checkCompletionStatus() async {
    final prayerHistoryService = locator<PrayerHistoryService>();
    final isCompleted = await prayerHistoryService.isPrayerCompletedToday(
      widget.prayerInfo.prayerEnum.name,
    );
    if (mounted) {
      setState(() {
        _isCompleted = isCompleted;
      });
    }
  }

  /// Check if this prayer has already passed (time is in the past)
  bool _hasPrayerPassed() {
    if (widget.prayerInfo.time == null) return false;
    return DateTime.now().isAfter(widget.prayerInfo.time!);
  }

  Future<void> _toggleCompletion() async {
    // Prevent marking upcoming prayers as done
    if (!_isCompleted && !_hasPrayerPassed()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot mark ${widget.prayerInfo.name} as done - prayer time has not arrived yet',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prayerHistoryService = locator<PrayerHistoryService>();
      if (_isCompleted) {
        await prayerHistoryService.unmarkPrayerCompleted(
          widget.prayerInfo.prayerEnum.name,
        );
      } else {
        await prayerHistoryService.markPrayerCompleted(
          widget.prayerInfo.prayerEnum.name,
        );
      }

      setState(() {
        _isCompleted = !_isCompleted;
        _isLoading = false;
      });

      widget.onRefresh?.call();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update prayer status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final itemColors = _getItemColors();
    final splashColors = _getSplashColors();
    final isNotificationEnabled =
        settings.notifications[widget.prayerInfo.prayerEnum] ?? false;

    return Material(
      color: Colors.transparent,
      child: InkWell(
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
              Icon(
                widget.prayerInfo.iconData,
                color: itemColors.icon,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                widget.prayerInfo.name,
                style: AppTextStyles.prayerName(widget.brightness).copyWith(
                  color: itemColors.text,
                  fontWeight:
                      widget.isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (!isNotificationEnabled) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.notifications_off,
                  color: Colors.orange.withAlpha(180),
                  size: 16,
                ),
              ],
              const Spacer(),
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
                    value: _isCompleted,
                    onChanged:
                        (_isCompleted || _hasPrayerPassed())
                            ? (bool? value) => _toggleCompletion()
                            : null, // Disable checkbox for upcoming prayers
                    activeColor: itemColors.icon,
                    checkColor: itemColors.background,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the appropriate colors for the item based on its state
  _ItemColors _getItemColors() {
    return _ItemColors(
      background:
          widget.isCurrent
              ? widget.currentPrayerItemBgColor
              : widget.contentSurfaceColor,
      icon:
          widget.isCurrent
              ? widget.currentPrayerItemTextColor
              : AppColors.iconInactive(widget.brightness),
      text:
          widget.isCurrent
              ? widget.currentPrayerItemTextColor
              : AppColors.textPrimary(widget.brightness),
    );
  }

  /// Returns the appropriate splash colors for the item based on its state
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

  /// Navigates to the settings screen and calls the refresh callback when returning
  void _navigateToSettings(BuildContext context) {
    locator<NavigationService>().navigateTo<void>(
      const SettingsView(scrollToNotifications: true),
      routeName: '/settings',
    ).then((_) {
      widget.onRefresh?.call();
    });
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
