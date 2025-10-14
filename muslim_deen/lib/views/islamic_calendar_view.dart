import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:muslim_deen/models/islamic_event.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/providers/service_providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/islamic_events_service.dart';
import 'package:muslim_deen/services/moon_phases_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/moon_phase_details_view.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class IslamicCalendarView extends ConsumerStatefulWidget {
  const IslamicCalendarView({super.key});

  @override
  ConsumerState<IslamicCalendarView> createState() =>
      _IslamicCalendarViewState();
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
  String? _errorMessage;

  // Search and filter state
  String _searchQuery = '';
  IslamicEventType? _selectedEventType;
  IslamicEventCategory? _selectedEventCategory;
  bool _showEventsList = false;
  List<Map<String, dynamic>> _filteredEvents = [];

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
      final eventMaps =
          events
              .map(
                (event) => {
                  'date':
                      event.gregorianDate?.toIso8601String() ??
                      event
                          .getGregorianDateForYear(_selectedDate.year)
                          .toIso8601String(),
                  'name': event.title,
                  'type': event.type.name,
                  'category': event.category.name,
                  'description': event.description,
                  'significance': event.significance,
                  'tags': event.tags,
                },
              )
              .toList();
      setState(() {
        _monthlyEvents = eventMaps;
        _filteredEvents = eventMaps; // Initialize filtered events
      });

      // Load moon phases for the month
      final moonPhases = await _moonPhasesService.getMoonPhasesForMonth(
        _selectedDate.year,
        _selectedDate.month,
      );
      setState(() => _moonPhases = moonPhases);
    } catch (e) {
      // Handle error by showing a message to the user
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load monthly data. Please try again.";
          _monthlyEvents = [];
          _filteredEvents = [];
        });
      }
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

    final prayerTimes = await prayerService.calculatePrayerTimesForDate(
      day,
      settings,
    );
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

  Future<void> _searchEvents() async {
    if (_searchQuery.isEmpty &&
        _selectedEventType == null &&
        _selectedEventCategory == null) {
      setState(() => _filteredEvents = _monthlyEvents);
      return;
    }

    try {
      List<Map<String, dynamic>> filteredEvents = [];

      if (_searchQuery.isNotEmpty) {
        // Use the service's search functionality
        final searchResults = await _eventsService.searchEvents(
          _searchQuery,
          year: _selectedDate.year,
        );
        filteredEvents =
            searchResults
                .map(
                  (event) => {
                    'date':
                        event.gregorianDate?.toIso8601String() ??
                        event
                            .getGregorianDateForYear(_selectedDate.year)
                            .toIso8601String(),
                    'name': event.title,
                    'type': event.type.name,
                    'category': event.category.name,
                    'description': event.description,
                    'significance': event.significance,
                    'tags': event.tags,
                  },
                )
                .toList();
      } else {
        // Filter by type/category from the already loaded monthly events
        filteredEvents =
            _monthlyEvents
                .where(
                  (event) =>
                      (_selectedEventType == null ||
                          event['type'] == _selectedEventType!.name) &&
                      (_selectedEventCategory == null ||
                          event['category'] == _selectedEventCategory!.name),
                )
                .toList();
      }

      setState(() => _filteredEvents = filteredEvents);
    } catch (e) {
      // Handle error silently
      setState(() => _filteredEvents = []);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedEventType = null;
      _selectedEventCategory = null;
    });
    _searchEvents();
  }

  Widget _buildCalendarView(Brightness brightness, List<DateTime> days) {
    return GridView.builder(
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
                      ? AppColors.accentGreen.withValues(alpha: 0.3)
                      : isToday
                      ? AppColors.primary(brightness).withValues(alpha: 0.2)
                      : isCurrentMonth
                      ? AppColors.surface(brightness)
                      : AppColors.surface(brightness).withValues(alpha: 0.5),
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
                      ? Border.all(color: AppColors.accentGreen, width: 2)
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
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (event.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event,
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (moonPhase.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 1,
                    ),
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
    );
  }

  Widget _buildEventsListView(Brightness brightness) {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: AppColors.textSecondary(brightness),
            ),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: AppTextStyles.sectionTitle(
                brightness,
              ).copyWith(color: AppColors.textSecondary(brightness)),
            ),
            if (_searchQuery.isNotEmpty ||
                _selectedEventType != null ||
                _selectedEventCategory != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Try adjusting your search or filters',
                  style: AppTextStyles.prayerTime(
                    brightness,
                  ).copyWith(color: AppColors.textSecondary(brightness)),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEvents.length,
      itemBuilder: (context, index) {
        final event = _filteredEvents[index];
        final eventDate = DateTime.parse(event['date'] as String);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event['name'] as String,
                        style: AppTextStyles.sectionTitle(brightness),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM dd').format(eventDate),
                        style: TextStyle(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event['description'] as String,
                  style: AppTextStyles.prayerTime(brightness),
                ),
                if (event['significance'] != null &&
                    (event['significance'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Significance: ${event['significance']}',
                    style: AppTextStyles.prayerTime(
                      brightness,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildEventChip(
                      brightness,
                      event['type'] as String,
                      AppColors.primary(brightness),
                    ),
                    const SizedBox(width: 8),
                    _buildEventChip(
                      brightness,
                      event['category'] as String,
                      AppColors.accentGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventChip(Brightness brightness, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final days = _getDaysInMonth(_selectedDate);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Islamic Calendar',
        brightness: brightness,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_2),
            onPressed: () {
              locator<NavigationService>().navigateTo<MoonPhaseDetailsView>(
                MoonPhaseDetailsView(),
              );
            },
            tooltip: 'Moon Phase Details',
          ),
        ],
      ),
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
          // Search and Filter Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // View toggle and search row
                Row(
                  children: [
                    // View toggle
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('Calendar'),
                            icon: Icon(Icons.calendar_view_month),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('Events'),
                            icon: Icon(Icons.list),
                          ),
                        ],
                        selected: {_showEventsList},
                        onSelectionChanged: (Set<bool> selected) {
                          setState(() => _showEventsList = selected.first);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Islamic events...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon:
                        _searchQuery.isNotEmpty ||
                                _selectedEventType != null ||
                                _selectedEventCategory != null
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearFilters,
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.surface(brightness),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _searchEvents();
                  },
                ),
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Event Type filters
                      ...IslamicEventType.values.map(
                        (type) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            label: Text(type.name.toUpperCase()),
                            selected: _selectedEventType == type,
                            onSelected: (selected) {
                              setState(
                                () =>
                                    _selectedEventType = selected ? type : null,
                              );
                              _searchEvents();
                            },
                          ),
                        ),
                      ),
                      // Error banner when data load fails
                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          color: Colors.red.withOpacity(0.06),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.prayerTime(brightness).copyWith(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.redAccent),
                                onPressed: () {
                                  setState(() => _errorMessage = null);
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Event Category filters
                      ...IslamicEventCategory.values.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            label: Text(category.name.toUpperCase()),
                            selected: _selectedEventCategory == category,
                            onSelected: (selected) {
                              setState(
                                () =>
                                    _selectedEventCategory =
                                        selected ? category : null,
                              );
                              _searchEvents();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
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
          // Calendar grid or Events list
          Expanded(
            child:
                _showEventsList
                    ? _buildEventsListView(brightness)
                    : _buildCalendarView(brightness, days),
          ),
          // Prayer times display (only show in calendar view)
          if (!_showEventsList &&
              _selectedDay != null &&
              _selectedDayPrayers != null)
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
                            style: AppTextStyles.prayerTime(
                              brightness,
                            ).copyWith(fontWeight: FontWeight.bold),
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
