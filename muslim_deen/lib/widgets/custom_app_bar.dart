import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim_deen/styles/app_styles.dart'; // Corrected path

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Brightness brightness;
  final List<Widget>? actions; // Optional actions

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.brightness,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine if dark mode is active, to ensure correct status bar icon brightness
    // final bool isDarkMode = brightness == Brightness.dark; // This was simplified

    return AppBar(
      title: Text(title, style: AppTextStyles.appTitle(brightness)),
      backgroundColor: AppColors.primary(brightness),
      elevation: 2.0,
      shadowColor: AppColors.shadowColor(brightness),
      centerTitle: true,
      actions: actions,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: AppColors.primary(brightness),
        // Simplified from isDarkMode ? Brightness.light : Brightness.light
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
