import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class IslamicCalendarView extends StatefulWidget {
  const IslamicCalendarView({super.key});

  @override
  State<IslamicCalendarView> createState() => _IslamicCalendarViewState();
}

class _IslamicCalendarViewState extends State<IslamicCalendarView> {
  late DateTime _selectedDate;
  late HijriCalendar _selectedHijriDate;

  static const List<String> _islamicMonths = [
    'Muharram',
    'Safar',
    'Rabi\' al-awwal',
    'Rabi\' al-thani',
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedHijriDate = HijriCalendar.fromDate(_selectedDate);
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
      _selectedHijriDate = HijriCalendar.fromDate(_selectedDate);
    });
  }

  List<DateTime> _getDaysInMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    final days = <DateTime>[];

    // Add days from previous month to fill the first week
    final firstWeekday = firstDay.weekday;
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    for (int i = 0; i < 42; i++) {
      // 6 weeks * 7 days
      final day = startDate.add(Duration(days: i));
      if (day.month == date.month ||
          day.month == date.month - 1 ||
          day.month == date.month + 1) {
        days.add(day);
      }
    }

    return days
        .takeWhile((day) => day.isBefore(lastDay.add(const Duration(days: 1))))
        .toList();
  }

  String _getIslamicEvent(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    // Simple events - in a real app, this would be more comprehensive
    if (hijri.hMonth == 1 && hijri.hDay == 1) return 'Islamic New Year';
    if (hijri.hMonth == 9 && hijri.hDay == 1) return 'Ramadan Begins';
    if (hijri.hMonth == 10 && hijri.hDay == 1) return 'Eid al-Fitr';
    if (hijri.hMonth == 12 && hijri.hDay == 10) return 'Eid al-Adha';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final days = _getDaysInMonth(_selectedDate);

    return Scaffold(
      appBar: CustomAppBar(title: 'Islamic Calendar', brightness: brightness),
      body: Column(
        children: [
          // Header with month/year
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Column(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: AppTextStyles.appTitle(brightness),
                    ),
                    Text(
                      '${_islamicMonths[_selectedHijriDate.hMonth - 1]} ${_selectedHijriDate.hYear}',
                      style: AppTextStyles.sectionTitle(brightness),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          // Day headers
          Row(
            children:
                ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: AppTextStyles.label(
                              brightness,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isCurrentMonth = day.month == _selectedDate.month;
                final isToday =
                    day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;
                final event = _getIslamicEvent(day);

                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color:
                        isToday
                            ? AppColors.primary(
                              brightness,
                            ).withValues(alpha: 0.2)
                            : isCurrentMonth
                            ? AppColors.surface(brightness)
                            : AppColors.surface(
                              brightness,
                            ).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        isToday
                            ? Border.all(
                              color: AppColors.primary(brightness),
                              width: 2,
                            )
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          color:
                              isCurrentMonth
                                  ? AppColors.textPrimary(brightness)
                                  : AppColors.textSecondary(brightness),
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (event.isNotEmpty)
                        Text(
                          event,
                          style: TextStyle(
                            fontSize: 8,
                            color: AppColors.accentGreen(brightness),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
