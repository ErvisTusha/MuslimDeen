// Standard library imports

// Third-party package imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemUiOverlayStyle

// Local application imports
import '../l10n/app_localizations.dart';
import '../styles/app_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Define colors similar to TesbihView
    final Color scaffoldBg = isDarkMode ? AppColors.surface(brightness) : AppColors.background(brightness);
    final Color contentSurface = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.primaryVariant(brightness);
    final Color textColor = AppColors.textPrimary(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          localizations.aboutTitle,
          style: AppTextStyles.appTitle(brightness),
        ),
        backgroundColor: AppColors.primary(brightness),
        elevation: 2.0,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary(brightness),
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.light,
        ),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: contentSurface,
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor(brightness).withAlpha(isDarkMode ? 30 : 50),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Muslim Deen App',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(brightness).copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0', // Consider localizing if needed
                textAlign: TextAlign.center,
                style: AppTextStyles.label(brightness).copyWith(color: textColor.withAlpha(200)),
              ),
              const SizedBox(height: 24),
              Text(
                'Developed with Flutter.', // Consider localizing
                textAlign: TextAlign.center,
                style: AppTextStyles.label(brightness).copyWith(color: textColor), // Changed to label as bodyText is not defined
              ),
            ],
          ),
        ),
      ),
    );
  }
}