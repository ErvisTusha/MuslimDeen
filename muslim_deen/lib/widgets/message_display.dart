import 'package:flutter/material.dart';
import 'package:muslim_deen/styles/app_styles.dart'; // For AppColors, AppTextStyles

class MessageDisplay extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final bool isError;
  final BoxDecoration? customContainerStyle; // Optional custom styling

  const MessageDisplay({
    Key? key,
    required this.message,
    this.icon,
    this.onRetry,
    this.isError = false,
    this.customContainerStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final defaultContainerColor =
        isError
            ? AppColors.error(brightness).withValues(alpha: 0.1)
            : AppColors.surface(brightness); // Or another appropriate default

    final defaultBorderColor =
        isError
            ? AppColors.error(brightness)
            : AppColors.borderColor(brightness);

    final containerStyle =
        customContainerStyle ??
        BoxDecoration(
          color: defaultContainerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: defaultBorderColor),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

    final messageColor =
        isError
            ? AppColors.error(brightness)
            : AppTextStyles.label(
              brightness,
            ).color; // Or AppColors.textSecondary

    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: containerStyle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 48,
                color:
                    isError
                        ? AppColors.error(brightness)
                        : AppColors.primary(brightness),
              ),
            if (icon != null) const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.label(
                brightness,
              ).copyWith(color: messageColor, height: 1.5),
            ),
            if (onRetry != null) const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  // backgroundColor: isError ? AppColors.error(brightness) : AppColors.primary(brightness),
                  // foregroundColor: isError ? Colors.white : null, // Or AppColors.textOnPrimary(brightness)
                ),
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
