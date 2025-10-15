import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart' show PrayerNotification;
import 'package:muslim_deen/models/prayer_list_item_data.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/prayer_list_item.dart';

typedef PrayerInfoBuilder =
    PrayerListItemData Function(PrayerNotification prayerEnum);

class PrayerTimesSection extends StatelessWidget {
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

  const PrayerTimesSection({
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
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (context) {
                  // defensively pick a text color that meets contrast requirements
                  final safeColor = UIThemeHelper.contrastSafeTextColor(
                    colors.textColorPrimary,
                    colors.contentSurface,
                  );
                  return Text(
                    "Prayer Times",
                    style: AppTextStyles.sectionTitle(
                      colors.brightness,
                    ).copyWith(color: safeColor),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: _buildPrayerListDecoration(colors),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: prayerOrder.length,
                      itemExtent:
                          80.0, // Set a fixed item extent for performance
                      itemBuilder: (context, index) {
                        final prayerEnum = prayerOrder[index];
                        final prayerInfo = getPrayerDisplayInfo(prayerEnum);
                        final bool isCurrent =
                            !isLoading &&
                            currentPrayerEnum == prayerInfo.prayerEnum;

                        return PrayerListItem(
                          prayerInfo: prayerInfo,
                          timeFormatter: timeFormatter,
                          isCurrent: isCurrent,
                          brightness: colors.brightness,
                          contentSurfaceColor: colors.contentSurface,
                          currentPrayerItemBgColor: currentPrayerBg,
                          currentPrayerItemBorderColor: currentPrayerBorder,
                          currentPrayerItemTextColor: currentPrayerText,
                          onRefresh: onRefresh,
                        );
                      },
                    ),
                  ),
                ),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildPrayerListDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor.withAlpha(colors.isDarkMode ? 20 : 40),
          spreadRadius: 0,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
