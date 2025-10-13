import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/islamic_events_service.dart';
import 'package:muslim_deen/services/moon_phases_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class IslamicCalendarView extends ConsumerStatefulWidget {
  const IslamicCalendarView({super.key});

  @override
  ConsumerState<IslamicCalendarView> createState() => _IslamicCalendarViewState();
}

class _IslamicCalendarViewState extends ConsumerState<IslamicCalendarView> {
  late DateTime _selectedDate;
  late HijriCalendar _selectedHijriDate;
  DateTime? _selectedDay;
  Map<String, DateTime>? _selectedDayPrayers;

  final IslamicEventsService _eventsService = locator<IslamicEventsService>();
  final MoonPhasesService _moonPhasesService = locator<MoonPhasesService>();

  List<Map<String, dynamic>> _monthlyEvents = [];
  Map<DateTime, String> _moonPhases = {};

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
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    try {
      // Load Islamic events for the month
      final events = await _eventsService.getEventsForMonth(
        _selectedDate.year,
        _selectedDate.month,
      );
      final eventMaps = events.map((event) => {
        'date': event.gregorianDate?.toIso8601String() ?? event.getGregorianDateForYear(_selectedDate.year).toIso8601String(),
        'name': event.title,
        'type': event.type.name,
        'description': event.description,
      }).toList();
      setState(() => _monthlyEvents = eventMaps);

      // Load moon phases for the month
      final moonPhases = await _moonPhasesService.getMoonPhasesForMonth(
        _selectedDate.year,
        _selectedDate.month,
      );
      setState(() => _moonPhases = moonPhases);
    } catch (e) {
      // Handle error silently for now
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
      _selectedHijriDate = HijriCalendar.fromDate(_selectedDate);
      _selectedDay = null;
      _selectedDayPrayers = null;
    });
    _loadMonthlyData();
  }

  Future<void> _loadPrayerTimesForDay(DateTime day) async {
    final prayerService = ref.read(prayerServiceProvider);
    final settings = ref.read(settingsProvider);

    final prayerTimes = await prayerService.calculatePrayerTimesForDate(day, settings);
    setState(() {
      _selectedDay = day;
      _selectedDayPrayers = {
        'Fajr': prayerTimes.fajr!,
        'Sunrise': prayerTimes.sunrise!,
        'Dhuhr': prayerTimes.dhuhr!,
        'Asr': prayerTimes.asr!,
        'Maghrib': prayerTimes.maghrib!,
        'Isha': prayerTimes.isha!,
      };
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
    // Check loaded events for this date
    for (final event in _monthlyEvents) {
      final eventDate = DateTime.parse(event['date'] as String);
      if (eventDate.year == date.year &&
          eventDate.month == date.month &&
          eventDate.day == date.day) {
        return event['name'] as String;
      }
    }
    return '';
  }

  String _getMoonPhase(DateTime date) {
    return _moonPhases[date] ?? '';
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
                final moonPhase = _getMoonPhase(day);

                return GestureDetector(
                  onTap: () => _loadPrayerTimesForDay(day),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color:
                          _selectedDay != null &&
                          _selectedDay!.year == day.year &&
                          _selectedDay!.month == day.month &&
                          _selectedDay!.day == day.day
                              ? AppColors.accentGreen(brightness).withValues(alpha: 0.3)
                              : isToday
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
                              : _selectedDay != null &&
                                _selectedDay!.year == day.year &&
                                _selectedDay!.month == day.month &&
                                _selectedDay!.day == day.day
                              ? Border.all(
                                color: AppColors.accentGreen(brightness),
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen(brightness).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event,
                              style: TextStyle(
                                fontSize: 8,
                                color: AppColors.accentGreen(brightness),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (moonPhase.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              moonPhase,
                              style: const TextStyle(
                                fontSize: 7,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Prayer times display
          if (_selectedDay != null && _selectedDayPrayers != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface(brightness),
                border: Border(
                  top: BorderSide(
                    color: AppColors.surface(brightness).withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prayer Times - ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
                    style: AppTextStyles.sectionTitle(brightness),
                  ),
                  const SizedBox(height: 8),
                  ..._selectedDayPrayers!.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: AppTextStyles.prayerTime(brightness),
                          ),
                          Text(
                            DateFormat('HH:mm').format(entry.value),
                            style: AppTextStyles.prayerTime(brightness).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
