import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// Widget to display a banner during the last 10 nights of Ramadan
class RamadanCountdownBanner extends StatelessWidget {
  const RamadanCountdownBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hijriDate = HijriCalendar.now();

    // Check if we're in Ramadan's last 10 nights (21st to 30th)
    if (hijriDate.hMonth != 9 || hijriDate.hDay < 21) {
      return const SizedBox.shrink();
    }

    final daysLeft = 30 - hijriDate.hDay;
    final isOddNight = hijriDate.hDay % 2 == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accentGreen(brightness).withAlpha(200),
            AppColors.accentGreen(brightness).withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(brightness),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nights_stay, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last 10 Nights of Ramadan',
                  style: AppTextStyles.prayerName(
                    brightness,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${daysLeft == 0 ? 'Last night' : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left'}${isOddNight ? ' • Odd Night ✨' : ''}',
                  style: AppTextStyles.dateSecondary(
                    brightness,
                  ).copyWith(color: Colors.white.withAlpha(230)),
                ),
              ],
            ),
          ),
          if (isOddNight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('🌟', style: const TextStyle(fontSize: 20)),
            ),
        ],
      ),
    );
  }
}
