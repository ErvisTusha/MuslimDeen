import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// City Search Bar - Specialized search input for location selection
///
/// This widget provides a themed search bar specifically designed for city
/// and location search functionality in the MuslimDeen application. It offers
/// comprehensive customization options for colors and styling while maintaining
/// consistent behavior and accessibility standards.
///
/// ## Key Features
/// - Customizable color scheme for different contexts
/// - Auto-focus for immediate user interaction
/// - Clear button that appears when text is entered
/// - Proper border styling with focus states
/// - Theme-aware design with brightness adaptation
/// - Accessibility-compliant touch targets and contrast
///
/// ## Color Customization
/// - contentSurfaceColor: Background color for the container
/// - textFieldBackgroundColor: Fill color for the text input area
/// - textColor: Color for entered text
/// - hintColor: Color for placeholder hint text
/// - iconColor: Color for search and clear icons
/// - borderColor: Color for input border in normal state
///
/// ## Interaction Design
/// - Search icon prefix for clear visual identification
/// - Clear button suffix that appears dynamically with text
/// - Focus state with primary color border highlighting
/// - Rounded corners for modern, friendly appearance
/// - Proper padding for comfortable touch interaction
///
/// ## Layout & Spacing
/// - Container padding: 16pt horizontal, 16pt top, 12pt bottom
/// - Text field padding: 14pt vertical, 16pt horizontal
/// - Border radius: 10pt for smooth, modern appearance
/// - Icon sizing appropriate for touch accessibility
///
/// ## Theme Integration
/// - Supports both light and dark mode through brightness parameter
/// - Uses AppTextStyles for consistent typography
/// - AppColors.primary for focus state highlighting
/// - Alpha transparency adjustments for dark mode borders
///
/// ## Usage Context
/// - City/location selection screens for prayer time calculations
/// - Mosque finder functionality
/// - Qibla direction setup
/// - Any location-based feature requiring user input
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Efficient color application without expensive computations
/// - Minimal state management through controller callbacks
/// - Reusable component reduces code duplication
///
/// ## Accessibility Features
/// - Auto-focus for keyboard users
/// - Clear visual feedback for interactive elements
/// - High contrast colors for text readability
/// - Touch-friendly target sizes for mobile interaction
/// - Screen reader support through semantic TextField structure
///
/// ## User Experience
/// - Immediate usability with auto-focus behavior
/// - Clear visual feedback for text entry and clearing
/// - Consistent with platform search bar conventions
/// - Smooth transitions between states (empty/filled/focused)
class CitySearchBar extends StatelessWidget {
  /// Controller for managing the text input state
  /// Handles text changes, clearing, and external state management
  final TextEditingController controller;

  /// Current theme brightness for styling decisions
  /// Determines color schemes and visual adaptations
  final Brightness brightness;

  /// Background color for the search bar container
  /// Provides surface color for the entire widget area
  final Color contentSurfaceColor;

  /// Background color for the text input field itself
  /// Fill color that appears behind the entered text
  final Color textFieldBackgroundColor;

  /// Color for the text entered by the user
  /// Should have high contrast against textFieldBackgroundColor
  final Color textColor;

  /// Color for the hint text when no text is entered
  /// Typically more subtle than textColor for visual hierarchy
  final Color hintColor;

  /// Color for icons (search prefix and clear suffix)
  /// Should be visible but not overpowering
  final Color iconColor;

  /// Color for the input border in normal (unfocused) state
  /// Provides subtle definition for the input area
  final Color borderColor;

  /// Callback function executed when clear button is tapped
  /// Should clear the controller text and reset search state
  final VoidCallback onClear;

  /// Callback function executed when text content changes
  /// Provides the new text value for search processing
  final ValueChanged<String> onChanged;

  const CitySearchBar({
    super.key,
    required this.controller,
    required this.brightness,
    required this.contentSurfaceColor,
    required this.textFieldBackgroundColor,
    required this.textColor,
    required this.hintColor,
    required this.iconColor,
    required this.borderColor,
    required this.onClear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = brightness == Brightness.dark;

    return Container(
      color: contentSurfaceColor,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: "Search for a city",
          hintStyle: AppTextStyles.label(brightness).copyWith(color: hintColor),
          prefixIcon: Icon(Icons.search, color: iconColor),
          filled: true,
          fillColor: textFieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: borderColor.withAlpha(isDarkMode ? 150 : 200),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: AppColors.primary(brightness),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 16.0,
          ),
          suffixIcon:
              controller.text.isNotEmpty
                  ? IconButton(
                    icon: Icon(Icons.clear, color: iconColor),
                    onPressed: onClear,
                  )
                  : null,
        ),
        style: AppTextStyles.prayerTime(brightness).copyWith(color: textColor),
        autofocus: true,
        onChanged: onChanged,
      ),
    );
  }
}
