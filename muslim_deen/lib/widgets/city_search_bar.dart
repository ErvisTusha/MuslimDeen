import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart';

class CitySearchBar extends StatefulWidget {
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
  State<CitySearchBar> createState() => _CitySearchBarState();
}

class _CitySearchBarState extends State<CitySearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = widget.brightness == Brightness.dark;

    return Container(
      color: widget.contentSurfaceColor,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: "Search for a city",
          hintStyle: AppTextStyles.label(widget.brightness).copyWith(color: widget.hintColor),
          prefixIcon: Icon(Icons.search, color: widget.iconColor),
          filled: true,
          fillColor: widget.textFieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: widget.borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: widget.borderColor.withAlpha(isDarkMode ? 150 : 200),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(
              color: AppColors.primary(widget.brightness),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14.0,
            horizontal: 16.0,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: widget.iconColor),
                  onPressed: widget.onClear,
                )
              : null,
        ),
        style: AppTextStyles.prayerTime(widget.brightness).copyWith(color: widget.textColor),
        autofocus: true,
        onChanged: widget.onChanged,
      ),
    );
  }
}