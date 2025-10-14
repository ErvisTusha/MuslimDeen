import 'package:flutter/material.dart';
import 'package:muslim_deen/services/fasting_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// Ramadan Fasting Checkbox Widget
/// Shows during Ramadan month and allows marking fast as completed after Maghrib
class RamadanFastingCheckbox extends StatefulWidget {
  final FastingService? fastingService;
  final bool isAfterMaghrib;

  const RamadanFastingCheckbox({
    super.key,
    required this.fastingService,
    required this.isAfterMaghrib,
  });

  @override
  State<RamadanFastingCheckbox> createState() => _RamadanFastingCheckboxState();
}

class _RamadanFastingCheckboxState extends State<RamadanFastingCheckbox> {
  bool _isChecked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkTodaysFastStatus();
  }

  @override
  void didUpdateWidget(RamadanFastingCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check status when widget updates (e.g., time changes)
    _checkTodaysFastStatus();
  }

  Future<void> _checkTodaysFastStatus() async {
    if (widget.fastingService == null) return;

    try {
      final today = DateTime.now();
      final record = await widget.fastingService!.getFastingRecordForDate(today);
      if (mounted) {
        setState(() {
          _isChecked = record?.status.name == 'completed';
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFast() async {
    if (widget.fastingService == null || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isChecked) {
        // Uncheck - this would be unusual, but allow it
        // For now, just update the UI state
        setState(() => _isChecked = false);
      } else {
        // Check - mark fast as completed
        await widget.fastingService!.markFastAsCompleted(DateTime.now());
        setState(() => _isChecked = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ramadan fast marked as completed! 🌙'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update fast status')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isEnabled = widget.isAfterMaghrib && !_isLoading;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isChecked
              ? AppColors.accentGreen.withAlpha(100)
              : AppColors.borderColor(brightness),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isChecked
                  ? AppColors.accentGreen.withAlpha(50)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _isChecked
                  ? AppColors.accentGreen
                  : AppColors.textSecondary(brightness),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramadan Fast Completed',
                  style: AppTextStyles.sectionTitle(brightness).copyWith(
                    color: _isChecked
                        ? AppColors.accentGreen
                        : AppColors.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEnabled
                      ? 'Tap to mark your Ramadan fast as completed'
                      : 'Available after Maghrib prayer',
                  style: AppTextStyles.label(brightness).copyWith(
                    fontSize: 12,
                    color: isEnabled
                        ? AppColors.textSecondary(brightness)
                        : AppColors.textSecondary(brightness).withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Checkbox(
              value: _isChecked,
              onChanged: isEnabled ? (_) => _toggleFast() : null,
              activeColor: AppColors.accentGreen,
              checkColor: Colors.white,
            ),
        ],
      ),
    );
  }
}