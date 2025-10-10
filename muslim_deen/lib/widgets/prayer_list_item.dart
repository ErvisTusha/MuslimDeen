import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/settings_view.dart'; // For navigation

class PrayerListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final itemColors = _getItemColors();
    final splashColors = _getSplashColors();

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
            border: const Border(
              top: BorderSide(color: Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              Icon(prayerInfo.iconData, color: itemColors.icon, size: 22),
              const SizedBox(width: 16),
              Text(
                prayerInfo.name,
                style: AppTextStyles.prayerName(brightness).copyWith(
                  color: itemColors.text,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                prayerInfo.time != null
                    ? timeFormatter.format(prayerInfo.time!.toLocal())
                    : '---',
                style: AppTextStyles.prayerTime(brightness).copyWith(
                  color: itemColors.text,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
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
      background: isCurrent ? currentPrayerItemBgColor : contentSurfaceColor,
      icon: isCurrent
          ? currentPrayerItemTextColor
          : AppColors.iconInactive(brightness),
      text: isCurrent
          ? currentPrayerItemTextColor
          : AppColors.textPrimary(brightness),
    );
  }

  /// Returns the appropriate splash colors for the item based on its state
  _SplashColors _getSplashColors() {
    final baseColor = isCurrent
        ? currentPrayerItemTextColor
        : AppColors.primary(brightness);
    
    return _SplashColors(
      splash: baseColor.withAlpha((0.1 * 255).round()),
      highlight: baseColor.withAlpha((0.05 * 255).round()),
    );
  }

  /// Navigates to the settings screen and calls the refresh callback when returning
  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const SettingsView(scrollToNotifications: true),
        settings: const RouteSettings(name: '/settings'),
      ),
    ).then((_) {
      onRefresh?.call();
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

  const _SplashColors({
    required this.splash,
    required this.highlight,
  });
}
