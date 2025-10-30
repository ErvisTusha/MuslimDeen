import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// Settings UI Elements - Reusable components for settings screens
///
/// This file provides specialized UI components designed specifically for settings
/// screens in the MuslimDeen application. These components ensure consistent
/// styling, proper accessibility, and optimal user experience across all
/// settings-related interfaces.
///
/// ## Design Philosophy
/// - Clean, minimal design appropriate for Islamic application context
/// - Consistent spacing and typography using AppStyles
/// - Theme-aware colors supporting light and dark modes
/// - Touch-friendly interaction areas with proper feedback
/// - Accessibility-first approach with clear visual hierarchy
///
/// ## Component Types
/// - SettingsSectionHeader: Section dividers with optional trailing widgets
/// - SettingsListItem: Interactive list items with icons and navigation
///
/// ## Theme Integration
/// - Automatic adaptation to system brightness settings
/// - Consistent use of AppColors for brand coherence
/// - AppTextStyles for readable, scalable typography
/// - Proper contrast ratios for accessibility compliance
///
/// ## Interaction Patterns
/// - SettingsListItem provides clear tap feedback with navigation arrows
/// - Section headers create visual hierarchy and grouping
/// - Consistent padding and margins for touch accessibility
/// - Smooth animations and transitions for professional feel
///
/// ## Performance Considerations
/// - Stateless widgets for optimal rebuild performance
/// - Minimal state management and computation
/// - Efficient theme resolution without expensive operations
/// - Reusable components reduce code duplication
///
/// ## Usage Guidelines
/// - Use SettingsSectionHeader to group related settings
/// - SettingsListItem for individual setting options with navigation
/// - Maintain consistent icon usage across similar settings
/// - Test all components in both light and dark themes
///
/// ## Accessibility Features
/// - High contrast text and icons for screen readers
/// - Touch target sizing meets accessibility guidelines
/// - Clear visual hierarchy with proper spacing
/// - Semantic structure for assistive technologies

/// Settings Section Header - Visual divider for settings sections
///
/// This widget provides a consistent header for grouping related settings
/// options, creating clear visual hierarchy and organization in settings screens.
/// It supports optional trailing widgets for additional actions or information.
///
/// ## Key Features
/// - Prominent section title with primary color accent
/// - Optional trailing widget for actions or status indicators
/// - Proper spacing and padding for visual separation
/// - Theme-aware styling with brightness adaptation
/// - Accessibility support with semantic structure
///
/// ## Layout & Spacing
/// - Top padding: 24pt for section separation
/// - Bottom padding: 8pt for content spacing
/// - Horizontal padding: 8pt for edge margins
/// - Uses Row layout with expanded title and optional trailing
///
/// ## Typography
/// - Uses AppTextStyles.sectionTitle for consistent hierarchy
/// - Primary color accent for visual prominence
/// - Readable font weight and size for section identification
///
/// ## Usage Examples
/// - "Prayer Settings", "Notification Preferences", "Location Services"
/// - Can include trailing icons for section-specific actions
/// - Supports keys for testing and accessibility automation
///
/// ## Performance
/// - Stateless widget with minimal build overhead
/// - Efficient theme resolution and style application
class SettingsSectionHeader extends StatelessWidget {
  /// The title text displayed as the section header
  final String title;

  /// Optional widget displayed at the end of the header row
  /// Can be used for action buttons, status indicators, or additional info
  final Widget? trailing;

  /// Optional key for testing and accessibility purposes
  /// Renamed from 'key' to avoid conflict with Widget.key
  final Key? sectionKey;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.sectionKey,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Row(
        key: sectionKey,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle(
                brightness,
              ).copyWith(color: AppColors.primary(brightness)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Settings List Item - Interactive settings option with navigation
///
/// This widget represents an individual settings option that users can tap
/// to navigate to a detailed settings screen or toggle a preference. It provides
/// clear visual feedback and consistent interaction patterns.
///
/// ## Key Features
/// - Icon, title, and subtitle for clear information hierarchy
/// - Navigation arrow indicating tappable action
/// - Rounded container with subtle border for modern appearance
/// - Theme-aware colors and proper contrast ratios
/// - Touch feedback with visual state changes
///
/// ## Layout Structure
/// - Leading icon for visual identification
/// - Title and subtitle text stack for information density
/// - Trailing navigation arrow for action indication
/// - Container with background, border, and rounded corners
///
/// ## Interaction Design
/// - Full ListTile area is tappable for accessibility
/// - Visual feedback through container styling
/// - Navigation arrow suggests further interaction
/// - Consistent spacing and touch target sizing
///
/// ## Styling Details
/// - Background uses AppColors.background for theme consistency
/// - Border uses AppColors.borderColor for subtle definition
/// - Icons use AppColors.iconInactive for muted appearance
/// - Text styles follow AppTextStyles hierarchy
///
/// ## Usage Examples
/// - "Prayer Times", "Location Settings", "Notification Preferences"
/// - Each item navigates to detailed configuration screens
/// - Icons should be semantically meaningful for the setting type
///
/// ## Accessibility
/// - Large touch targets meeting accessibility guidelines
/// - Clear visual hierarchy with icon, title, and subtitle
/// - Semantic ListTile structure for screen readers
/// - High contrast colors for visibility
///
/// ## Performance
/// - Stateless widget with efficient rebuilds
/// - Minimal layout complexity for smooth scrolling
/// - Reusable component reduces memory footprint
class SettingsListItem extends StatelessWidget {
  /// Icon displayed at the leading edge of the list item
  /// Should be semantically relevant to the setting type
  final IconData icon;

  /// Main title text for the settings option
  /// Should be concise and clearly describe the setting
  final String title;

  /// Secondary descriptive text providing additional context
  /// Can show current value, description, or status information
  final String subtitle;

  /// Callback function executed when the item is tapped
  /// Typically navigates to a detailed settings screen
  final VoidCallback onTap;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor(brightness)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.iconInactive),
        title: Text(title, style: AppTextStyles.prayerName(brightness)),
        subtitle: Text(subtitle, style: AppTextStyles.label(brightness)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.iconInactive,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
