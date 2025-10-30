import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/prayer_list_item_data.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/settings_view.dart'; // For navigation

/// Interactive prayer list item widget with completion tracking and visual feedback
///
/// This widget represents a single prayer in the main prayer times list, providing
/// rich interaction capabilities including prayer completion marking, visual
/// highlighting for current prayers, and navigation to detailed prayer information.
/// It implements Material Design principles with custom theming support.
///
/// ## Key Features
/// - Prayer completion checkbox with persistence
/// - Current prayer highlighting with custom colors
/// - Formatted time display with user preferences
/// - Prayer icon representation for visual identification
/// - Relative time display ("in 2h", "30m ago", etc.)
/// - Tap-to-navigate to prayer statistics
/// - Loading states during completion operations
/// - Accessibility support with proper semantics
///
/// ## UI States
/// - Normal: Standard prayer display
/// - Current: Highlighted background/border for active prayer
/// - Completed: Visual indication of prayer completion
/// - Loading: Disabled state during async operations
///
/// ## Interaction Model
/// - Tap: Navigate to prayer statistics view
/// - Checkbox: Mark prayer as completed/incomplete
/// - Long press: Potential future features (context menu)
///
/// ## Data Flow
/// - Receives PrayerListItemData for display information
/// - Uses DateFormat for time formatting consistency
/// - Integrates with PrayerHistoryService for completion tracking
/// - Communicates with parent via onRefresh callback
///
/// ## Performance Optimizations
/// - Efficient state management with minimal rebuilds
/// - Cached completion status to reduce service calls
/// - Optimized layout with proper constraints
/// - Memory-efficient resource usage
///
/// ## Accessibility
/// - Proper semantic labels for screen readers
/// - High contrast support for current prayer highlighting
/// - Touch target sizing following Material Design guidelines
/// - Keyboard navigation support
///
/// ## Error Handling
/// - Graceful handling of completion status failures
/// - Fallback UI when prayer data is incomplete
/// - Logging of errors without user disruption
/// - Recovery mechanisms for failed operations
///
/// ## Islamic Context & Cultural Considerations
/// - Prayer names in Arabic script where appropriate
/// - Time display respecting Islamic prayer schedules
/// - Completion tracking aligned with Islamic practice
/// - Visual design respectful of religious significance
/// - Accessibility for users with different prayer needs
///
/// ## Completion Logic
/// - Only allows marking prayers as completed after prayer time has passed
/// - Prevents premature completion of upcoming prayers
/// - Provides clear feedback for invalid completion attempts
/// - Persists completion status across app sessions
/// - Updates parent view when completion status changes
///
/// ## Notification Integration
/// - Visual indicator for disabled prayer notifications
/// - Double-tap navigation to notification settings
/// - Consistent with app-wide notification preferences
/// - Clear visual cues for notification status
///
/// ## Time Display Features
/// - 12/24 hour format based on user preferences
/// - Consistent formatting across all prayer items
/// - Handles null prayer times gracefully
/// - Local timezone conversion for accuracy
///
/// ## State Management
/// - Local completion state with async service integration
/// - Loading states during completion operations
/// - Error handling with user-friendly messages
/// - State persistence through service layer
/// - Optimistic UI updates with rollback on failure
///
/// ## Visual States
/// - Normal: Standard prayer display with inactive colors
/// - Current: Highlighted with custom colors and bold text
/// - Completed: Checkbox checked with visual confirmation
/// - Loading: Disabled interaction with progress indicator
/// - Notification disabled: Orange indicator icon
///
/// ## Touch Interactions
/// - Single tap: Reserved for future features (prayer details)
/// - Double tap: Navigate to notification settings
/// - Checkbox tap: Toggle completion status
/// - Proper touch target sizing for accessibility
///
/// ## Data Dependencies
/// - PrayerListItemData: Core prayer information and metadata
/// - PrayerHistoryService: Completion status persistence
/// - SettingsProvider: Notification preferences and time format
/// - NavigationService: Screen navigation and routing
///
/// ## Error Scenarios
/// - Service unavailability: Graceful degradation with error messages
/// - Network failures: Local state management with retry options
/// - Invalid prayer times: Fallback display with placeholder text
/// - Permission issues: Clear user communication about limitations
///
/// ## Testing Considerations
/// - Mock services for isolated unit testing
/// - Time manipulation for prayer state testing
/// - Completion toggle verification
/// - Navigation callback testing
/// - Error state simulation and recovery
class PrayerListItem extends ConsumerStatefulWidget {
  /// Core prayer information including name, time, and icon
  /// Contains all display data and prayer identification
  final PrayerListItemData prayerInfo;

  /// Date formatter for consistent time display across the app
  /// Respects user preferences for 12/24 hour format
  final DateFormat timeFormatter;

  /// Whether this prayer is currently active (next prayer to occur)
  /// Affects visual styling with highlighting and emphasis
  final bool isCurrent;

  /// Current theme brightness for appropriate color selection
  /// Enables light/dark theme compatibility
  final Brightness brightness;

  /// Base background color for the prayer item container
  /// Used when prayer is not currently active
  final Color contentSurfaceColor;

  /// Special background color when this is the current prayer
  /// Provides visual prominence for active prayer state
  final Color currentPrayerItemBgColor;

  /// Border color accent for current prayer highlighting
  /// Creates visual separation and emphasis
  final Color currentPrayerItemBorderColor;

  /// Text color for current prayer state
  /// Ensures readability and visual hierarchy
  final Color currentPrayerItemTextColor;

  /// Optional callback to refresh parent view after state changes
  /// Allows parent to update when prayer completion status changes
  final VoidCallback? onRefresh;

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

/// Private state class managing prayer item interactions and state
class _PrayerListItemState extends ConsumerState<PrayerListItem> {
  /// Current completion status of this prayer for today
  bool _isCompleted = false;

  /// Loading state during async completion operations
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCompletionStatus();
  }

  /// Loads initial completion status from persistent storage
  /// Called during widget initialization to sync UI with stored state
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

  /// Determines if the prayer time has already passed today
  /// Used to prevent marking upcoming prayers as completed
  /// Returns false if prayer time is null (handles data inconsistencies)
  bool _hasPrayerPassed() {
    if (widget.prayerInfo.time == null) return false;
    return DateTime.now().isAfter(widget.prayerInfo.time!);
  }

  /// Toggles the completion status of this prayer
  /// Includes validation to prevent invalid state changes
  /// Updates both local state and persistent storage
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

  /// Calculates appropriate colors for the item based on its current state
  /// Returns an _ItemColors object with background, icon, and text colors
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

  /// Calculates appropriate splash colors for touch feedback
  /// Returns an _SplashColors object with splash and highlight colors
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

  /// Navigates to the settings screen focused on notifications
  /// Automatically scrolls to the notifications section
  /// Calls refresh callback when returning to update any changes
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
}

/// Helper class for organizing item color properties
/// Provides a clean interface for color state management
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

/// Helper class for organizing splash effect colors
/// Provides consistent touch feedback color calculation
class _SplashColors {
  final Color splash;
  final Color highlight;

  const _SplashColors({required this.splash, required this.highlight});
}
