// Standard library imports

// Third-party package imports
import 'package:flutter/material.dart';

// Local application imports
import '../l10n/app_localizations.dart';
import '../styles/app_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          localizations.aboutTitle,
          style: AppTextStyles.appTitle,
        ),
        backgroundColor: AppColors.primary,
        elevation: 2.0,
        shadowColor: AppColors.shadowColor,
        centerTitle: true,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Muslim Deen App\nVersion 1.0.0\n\nDeveloped with Flutter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}