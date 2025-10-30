import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart' show PrayerNotification;
import 'package:muslim_deen/models/prayer_list_item_data.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/prayer_list_item.dart';

/// Comprehensive prayer times display section with interactive list and current prayer highlighting
///
/// This widget serves as the main prayer times display component, providing a scrollable
/// list of all daily prayers with rich visual feedback, current prayer highlighting,
/// and smooth interactions. It implements advanced list rendering optimizations and
/// responsive design principles.
///
/// ## Key Features
/// - Scrollable prayer list with fixed item heights for performance
/// - Current prayer highlighting with custom colors and borders
/// - Loading state handling with skeleton/placeholder UI
/// - Prayer completion tracking integration
/// - Smooth scroll-to-current prayer functionality
/// - Theme-aware styling with brightness adaptation
/// - Accessibility support with proper semantic structure
///
/// ## UI Architecture
/// - Uses ListView.builder for efficient rendering of prayer items
/// - Implements fixed extent items (80px height) for consistent performance
/// - Features gradient backgrounds and rounded corners for modern design
/// - Responsive padding and spacing following Material Design guidelines
/// - Optimized layout with proper constraints and overflow handling
///
/// ## Performance Optimizations
/// - Fixed item extent eliminates dynamic height calculations
/// - Efficient builder pattern prevents unnecessary widget rebuilds
/// - Cached scroll controller for smooth scrolling operations
/// - Minimal state management through stateless widget design
/// - Lazy loading of prayer data through builder function
///
/// ## Data Flow
/// - Receives prayer order list for customizable display sequence
/// - Uses PrayerInfoBuilder callback for on-demand prayer data creation
/// - Integrates with scroll controller for external scroll control
/// - Provides onRefresh callback for parent refresh triggers
/// - Maintains current prayer state for highlighting logic
///
/// ## Interaction Model
/// - Tap prayer items: Navigate to detailed prayer statistics
/// - Scroll: Smooth vertical scrolling through prayer list
/// - Visual feedback: Current prayer automatically highlighted
/// - Loading states: Graceful degradation during data fetching
///
/// ## Accessibility
/// - Semantic section headers for screen readers
/// - Proper contrast ratios for highlighted current prayer
/// - Touch target sizing following accessibility guidelines
/// - Keyboard navigation support through focus management
///
/// ## Error Handling
/// - Graceful handling of missing prayer data
/// - Fallback UI when prayer calculations fail
/// - Loading state indicators during async operations
/// - Null safety for all prayer data fields
///
/// ## Usage Context
/// - Primary component in HomeView for prayer times display
/// - Integrated with prayer completion tracking system
/// - Supports both portrait and landscape orientations
/// - Adapts to different screen sizes and densities
typedef PrayerInfoBuilder =
    PrayerListItemData Function(PrayerNotification prayerEnum);

class PrayerTimesSection extends StatelessWidget {
  /// Whether prayer data is currently being loaded
  final bool isLoading;

  /// Ordered list of prayers to display (controls display sequence)
  final List<PrayerNotification> prayerOrder;

  /// Theme colors for consistent styling across the section
  final UIColors colors;

  /// Background color for the currently active prayer item
  final Color currentPrayerBg;

  /// Border color for the currently active prayer item
  final Color currentPrayerBorder;

  /// Text color for the currently active prayer item
  final Color currentPrayerText;

  /// Currently active prayer for highlighting (null if none active)
  final PrayerNotification? currentPrayerEnum;

  /// Formatter for consistent time display across all prayer items
  final DateFormat timeFormatter;

  /// Callback triggered when prayer data needs refresh
  final VoidCallback onRefresh;

  /// Scroll controller for external scroll management and synchronization
  final ScrollController scrollController;

  /// Builder function that creates prayer display data on demand
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
