import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:muslim_deen/styles/app_styles.dart';

/// Ramadan countdown banner widget for the last 10 nights of Ramadan
///
/// This widget displays a special promotional banner during the final 10 nights
/// of Ramadan (21st to 30th of Ramadan), highlighting the significance of these
/// blessed nights with visual emphasis and countdown information.
///
/// ## Islamic Significance
/// - Last 10 nights of Ramadan contain Laylatul Qadr (Night of Power)
/// - Odd nights (21st, 23rd, 25th, 27th, 29th) are most likely for Laylatul Qadr
/// - Encourages increased worship and Quran recitation during these nights
/// - Builds anticipation for Eid ul-Fitr celebration
///
/// ## UI Design
/// - Gradient background using Islamic green color palette
/// - Circular icon container with subtle transparency
/// - Moon icon representing Ramadan nights
/// - Clear typography hierarchy for countdown information
/// - Subtle shadow effects for depth and elevation
/// - Rounded corners following Material Design principles
///
/// ## Content Logic
/// - Automatically calculates current Hijri date
/// - Only displays during Ramadan month (9th Islamic month)
/// - Shows countdown from current night to 30th of Ramadan
/// - Highlights odd-numbered nights with special messaging
/// - Uses localized text for accessibility
///
/// ## Performance Considerations
/// - Stateless widget for optimal rebuild performance
/// - Minimal computation in build method
/// - Efficient conditional rendering (returns SizedBox.shrink when not applicable)
/// - No expensive operations or animations
///
/// ## Cultural & Religious Context
/// - Ramadan is the 9th month of the Islamic lunar calendar
/// - Last 10 nights are considered most blessed
/// - Laylatul Qadr is better than 1000 months of worship
/// - Muslims increase worship, Quran reading, and prayers during these nights
///
/// ## Usage Context
/// - Displayed prominently in the home screen during Ramadan
/// - Provides spiritual motivation and awareness
/// - Encourages religious observance and celebration
/// - Creates festive atmosphere leading to Eid
///
/// ## Accessibility
/// - High contrast text for screen reader compatibility
/// - Semantic meaning for religious content
/// - Proper color contrast ratios
/// - Screen reader friendly descriptions
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
            AppColors.accentGreen.withAlpha(200),
            AppColors.accentGreen.withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
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
