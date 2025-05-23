import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../styles/app_styles.dart';
import '../styles/ui_theme_helper.dart';

/// A builder widget that handles common loading and error states
class LoadingErrorStateBuilder extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final Widget child;
  final VoidCallback onRetry;
  final String? loadingText;

  const LoadingErrorStateBuilder({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.child,
    required this.onRetry,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.accentColor),
              strokeWidth: 3,
            ),
            if (loadingText != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingText!,
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.textColorSecondary),
              ),
            ],
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: colors.errorColor, size: 48),
              const SizedBox(height: 16),
              Text(
                _getProcessedErrorMessage(errorMessage!),
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.errorColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  foregroundColor: colors.accentColor,
                ),
                child: const Text('Retry'),
              ),
              ..._buildActionButtons(errorMessage!),
            ],
          ),
        ),
      );
    }

    return child;
  }

  String _getProcessedErrorMessage(String errorMessage) {
    if (errorMessage ==
        'Location permission denied. Please enable it in settings.') {
      return errorMessage;
    } else if (errorMessage.contains('permission')) {
      return "Location permission error. Please check settings.";
    } else if (errorMessage.contains('service is disabled')) {
      return "Location service is disabled. Please enable it.";
    } else if (errorMessage.contains('Compass sensor error')) {
      return "Compass sensor error. Please try again.";
    }
    return errorMessage;
  }

  List<Widget> _buildActionButtons(String errorMessage) {
    final List<Widget> buttons = [];

    if (errorMessage.contains('permission') ||
        errorMessage.contains('permanently denied')) {
      buttons.addAll([
        const SizedBox(height: 8),
        TextButton(
          onPressed: Geolocator.openAppSettings,
          child: const Text("Open App Settings"),
        ),
      ]);
    }

    if (errorMessage.contains('services are disabled')) {
      buttons.addAll([
        const SizedBox(height: 8),
        TextButton(
          onPressed: Geolocator.openLocationSettings,
          child: const Text("Open Location Settings"),
        ),
      ]);
    }

    return buttons;
  }
}
