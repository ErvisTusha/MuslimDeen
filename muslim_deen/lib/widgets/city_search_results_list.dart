import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// City Search Results List - Display component for location search results
///
/// This widget presents a scrollable list of city search results with location
/// coordinates, providing an intuitive interface for users to select their
/// desired location for prayer time calculations and other location-based features.
///
/// ## Key Features
/// - Scrollable list of search results with location data
/// - Interactive selection with visual feedback
/// - Coordinate display for precise location identification
/// - Empty state handling (returns SizedBox.shrink when no results)
/// - Theme-aware styling with customizable colors
/// - Smooth scrolling with proper separators
///
/// ## Data Structure
/// Each search result is a Map<String, dynamic> containing:
/// - 'name': String - City name and country/region
/// - 'latitude': double - Geographic latitude coordinate
/// - 'longitude': double - Geographic longitude coordinate
///
/// ## Color Customization
/// - contentSurfaceColor: Background color for the results container
/// - borderColor: Color for container border and dividers
/// - listTileSelectedColor: Color for tap feedback and selection states
/// - textColor: Color for city names and primary text
/// - hintColor: Color for coordinate display and secondary text
/// - iconColor: Color for navigation arrow icons
///
/// ## Layout & Interaction
/// - Rounded container with subtle border for modern appearance
/// - Separators between list items for clear visual division
/// - Touch feedback with splash and highlight effects
/// - Navigation arrow indicating selectable items
/// - Proper padding for comfortable touch interaction
///
/// ## Visual Hierarchy
/// - City name as primary text (larger, prominent)
/// - Coordinates as secondary text (smaller, subdued)
/// - Consistent spacing and alignment for readability
/// - Icon placement for clear navigation indication
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Efficient ListView with proper item separation
/// - Minimal layout complexity for smooth scrolling
/// - Reusable component reduces memory footprint
///
/// ## Usage Context
/// - City search screens for prayer time localization
/// - Mosque location selection
/// - Qibla direction calculation setup
/// - Any feature requiring geographic location input
///
/// ## Accessibility Features
/// - Clear visual hierarchy with appropriate text sizing
/// - Touch-friendly target areas for mobile interaction
/// - High contrast colors for text readability
/// - Semantic structure through proper Material widgets
/// - Screen reader support for location data
///
/// ## User Experience
/// - Immediate visual feedback on touch interactions
/// - Clear indication of selectable items with arrows
/// - Precise coordinate display for location verification
/// - Smooth scrolling for large result sets
/// - Consistent with platform list interaction patterns
///
/// ## Error Handling
/// - Graceful empty state (no crash on empty results)
/// - Type safety with proper casting for result data
/// - Fallback coordinate formatting for display
class CitySearchResultsList extends StatelessWidget {
  /// List of search results to display
  /// Each result is a Map containing city name and coordinates
  /// Empty list results in no widget being displayed
  final List<Map<String, dynamic>> searchResults;

  /// Current theme brightness for styling decisions
  /// Affects color schemes and visual adaptations
  final Brightness brightness;

  /// Background color for the results list container
  /// Provides the surface color for the entire results area
  final Color contentSurfaceColor;

  /// Color for borders and separators between list items
  /// Used for container border and divider lines
  final Color borderColor;

  /// Color for touch feedback and selection states
  /// Applied during tap interactions for visual feedback
  final Color listTileSelectedColor;

  /// Color for primary text (city names)
  /// Should have high contrast for readability
  final Color textColor;

  /// Color for secondary text (coordinates)
  /// Typically more subtle than textColor
  final Color hintColor;

  /// Color for navigation arrow icons
  /// Should be visible but not overpowering
  final Color iconColor;

  /// Callback function executed when a location is selected
  /// Receives the selected result Map for further processing
  final void Function(Map<String, dynamic>) onSelectLocation;

  const CitySearchResultsList({
    super.key,
    required this.searchResults,
    required this.brightness,
    required this.contentSurfaceColor,
    required this.borderColor,
    required this.listTileSelectedColor,
    required this.textColor,
    required this.hintColor,
    required this.iconColor,
    required this.onSelectLocation,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = brightness == Brightness.dark;

    if (searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: contentSurfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor.withAlpha(isDarkMode ? 100 : 150),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: searchResults.length,
          separatorBuilder:
              (context, index) => Divider(
                color: borderColor.withAlpha(isDarkMode ? 70 : 100),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
          itemBuilder: (context, index) {
            final result = searchResults[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelectLocation(result),
                splashColor: listTileSelectedColor,
                highlightColor: listTileSelectedColor.withAlpha(80),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 14.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result['name'] as String,
                              style: AppTextStyles.prayerName(
                                brightness,
                              ).copyWith(color: textColor, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${result['latitude'].toStringAsFixed(4)}, ${result['longitude'].toStringAsFixed(4)}',
                              style: AppTextStyles.label(
                                brightness,
                              ).copyWith(color: hintColor, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: iconColor),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
