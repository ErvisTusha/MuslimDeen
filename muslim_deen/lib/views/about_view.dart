import 'package:flutter/material.dart';

import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/common_container_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(title: "About", brightness: brightness),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(24.0),
          decoration: CommonContainerStyles.cardDecoration(colors),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Muslim Deen App',
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle(
                  brightness,
                ).copyWith(color: colors.textColorPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                textAlign: TextAlign.center,
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.textColorPrimary.withAlpha(200)),
              ),
              const SizedBox(height: 24),
              Text(
                'Developed with Flutter.',
                textAlign: TextAlign.center,
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.textColorPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
