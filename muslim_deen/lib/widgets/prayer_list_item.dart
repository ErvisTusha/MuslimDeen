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
    final Color itemBackgroundColor =
        isCurrent ? currentPrayerItemBgColor : contentSurfaceColor;
    final Color itemIconColor =
        isCurrent ? currentPrayerItemTextColor : AppColors.iconInactive(brightness);
    final Color itemTextColor =
        isCurrent ? currentPrayerItemTextColor : AppColors.textPrimary(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) =>
                  const SettingsView(scrollToNotifications: true),
              settings: const RouteSettings(name: '/settings'),
            ),
          ).then((_) {
            onRefresh?.call();
          });
        },
        splashColor: isCurrent
            ? currentPrayerItemTextColor.withAlpha((0.1 * 255).round())
            : AppColors.primary(brightness).withAlpha((0.1 * 255).round()),
        highlightColor: isCurrent
            ? currentPrayerItemTextColor.withAlpha((0.05 * 255).round())
            : AppColors.primary(brightness).withAlpha((0.05 * 255).round()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: itemBackgroundColor,
            border: const Border(top: BorderSide(color: Colors.transparent)), // Assuming this was intentional
          ),
          child: Row(
            children: [
              Icon(
                prayerInfo.iconData,
                color: itemIconColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                prayerInfo.name,
                style: AppTextStyles.prayerName(brightness).copyWith(
                  color: itemTextColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                prayerInfo.time != null
                    ? timeFormatter.format(prayerInfo.time!.toLocal())
                    : '---',
                style: AppTextStyles.prayerTime(brightness).copyWith(
                  color: itemTextColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}