import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

class CitySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Brightness brightness;
  final Color contentSurfaceColor;
  final Color textFieldBackgroundColor;
  final Color textColor;
  final Color hintColor;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback onClear;
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
