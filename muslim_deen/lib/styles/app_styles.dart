import 'package:flutter/material.dart';

/// Core color palette
class AppColors {
  static const Color primary = Colors.green;
  static const Color primaryLight = Color(0xFFEBF3EC);
  static const Color background = Colors.white;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  static const Color divider = Color(0xFFE0E0E0);
  
  // Specialized colors
  static final Color shadowColor = Colors.black.withAlpha(13);
  static final Color borderColor = Colors.grey.shade200;
  static final Color iconInactive = Colors.grey.shade600;
  static final Color switchTrackActive = primary.withAlpha(77);
  static const Color error = Colors.red;
}

/// Text styles used throughout the app
class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle date = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle dateSecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle prayerName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle prayerNameCurrent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle arabicName = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle currentPrayer = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  static const TextStyle nextPrayer = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle countdownTimer = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle prayerTime = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle snackBarText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle prayerTimeCurrent = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}

/// Common decorations used in the app
class AppDecorations {
  static BoxDecoration headerDecoration = BoxDecoration(
    color: AppColors.primary,
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowColor,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration currentPrayerBox = BoxDecoration(
    color: AppColors.primaryLight,
    borderRadius: BorderRadius.circular(10),
  );

  static BoxDecoration prayerItemDecoration({bool isCurrent = false}) => BoxDecoration(
    color: isCurrent ? AppColors.primaryLight : AppColors.background,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.borderColor),
  );
}
