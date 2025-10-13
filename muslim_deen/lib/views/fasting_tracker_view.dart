import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/fasting_record.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/fasting_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

/// Fasting Tracker View - displays fasting statistics, Ramadan countdown, and fasting calendar
class FastingTrackerView extends ConsumerStatefulWidget {
  const FastingTrackerView({super.key});

  @override
  ConsumerState<FastingTrackerView> createState() => _FastingTrackerViewState();
}

class _FastingTrackerViewState extends ConsumerState<FastingTrackerView> {
  FastingService? _fastingService;

  FastingStats? _fastingStats;
  Map<String, dynamic>? _ramadanInfo;
  List<FastingRecord> _currentMonthRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      _fastingService = await locator.getAsync<FastingService>();
      await _loadData();
    } catch (e) {
      // Handle service not ready
      setState(() => _isLoading = false);
      // Could show an error message or retry
    }
  }

  Future<void> _loadData() async {
    if (_fastingService == null) return;

    setState(() => _isLoading = true);

    try {
      final stats = await _fastingService!.getFastingStats();
      final ramadanInfo = _fastingService!.getRamadanCountdown();
      final now = DateTime.now();
      final monthRecords = await _fastingService!.getFastingRecordsForMonth(now.year, now.month);

      setState(() {
        _fastingStats = stats;
        _ramadanInfo = ramadanInfo;
        _currentMonthRecords = monthRecords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error - could show snackbar
    }
  }

  Future<void> _markFastAsCompleted() async {
    if (_fastingService == null) return;

    try {
      await _fastingService!.markFastAsCompleted(DateTime.now());
      await _loadData(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fast marked as completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark fast as completed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: CustomAppBar(title: 'Fasting Tracker', brightness: brightness),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ramadan Countdown Banner
                  if ((_ramadanInfo?['isRamadan'] as bool? ?? false) || ((_ramadanInfo?['daysUntilRamadan'] as int? ?? 0) <= 30))
                    _buildRamadanBanner(brightness),

                  const SizedBox(height: 16),

                  // Fasting Statistics
                  _buildFastingStats(brightness),

                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(brightness),

                  const SizedBox(height: 16),

                  // Monthly Calendar
                  _buildMonthlyCalendar(brightness),
                ],
              ),
            ),
    );
  }

  Widget _buildRamadanBanner(Brightness brightness) {
    final isRamadan = _ramadanInfo?['isRamadan'] as bool? ?? false;
    final daysUntil = _ramadanInfo?['daysUntilRamadan'] as int? ?? 0;
    final currentDay = _ramadanInfo?['currentDay'] as int?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentGreen(brightness).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentGreen(brightness).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRamadan ? Icons.star : Icons.schedule,
                color: AppColors.accentGreen(brightness),
              ),
              const SizedBox(width: 8),
              Text(
                isRamadan ? 'Ramadan Mubarak!' : 'Ramadan Countdown',
                style: AppTextStyles.sectionTitle(brightness),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isRamadan && currentDay != null)
            Text(
              'Day $currentDay of 30',
              style: AppTextStyles.prayerTime(brightness).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.accentGreen(brightness),
              ),
            )
          else if (daysUntil > 0)
            Text(
              '$daysUntil days until Ramadan',
              style: AppTextStyles.prayerTime(brightness),
            ),
        ],
      ),
    );
  }

  Widget _buildFastingStats(Brightness brightness) {
    if (_fastingStats == null) return const SizedBox.shrink();

    final stats = _fastingStats!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(brightness),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fasting Statistics',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Current Streak',
                  '${stats.currentStreak}',
                  Icons.local_fire_department,
                  Colors.orange,
                  brightness,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Longest Streak',
                  '${stats.longestStreak}',
                  Icons.emoji_events,
                  Colors.amber,
                  brightness,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Fasts',
                  '${stats.completedFasts}/${stats.totalFasts}',
                  Icons.check_circle,
                  Colors.green,
                  brightness,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  'Completion Rate',
                  '${(stats.completionRate * 100).toStringAsFixed(0)}%',
                  Icons.analytics,
                  Colors.blue,
                  brightness,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.prayerTime(brightness).copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.label(brightness).copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markFastAsCompleted,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Fasted'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen(brightness),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(Brightness brightness) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final day = index + 1;
              final date = DateTime(now.year, now.month, day);
              final record = _currentMonthRecords.firstWhere(
                (r) => r.date.day == day,
                orElse: () => FastingRecord(
                  id: '',
                  date: date,
                  type: FastingType.voluntary,
                  status: FastingStatus.notStarted,
                ),
              );

              return _buildCalendarDay(date, record, brightness);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(DateTime date, FastingRecord record, Brightness brightness) {
    final isToday = date.day == DateTime.now().day &&
                   date.month == DateTime.now().month &&
                   date.year == DateTime.now().year;

    Color backgroundColor;
    Color textColor;

    switch (record.status) {
      case FastingStatus.completed:
        backgroundColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        break;
      case FastingStatus.broken:
        backgroundColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        break;
      case FastingStatus.excused:
        backgroundColor = Colors.orange.withValues(alpha: 0.2);
        textColor = Colors.orange;
        break;
      default:
        backgroundColor = isToday ? AppColors.accentGreen(brightness).withValues(alpha: 0.1) : Colors.transparent;
        textColor = AppColors.textPrimary(brightness);
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: AppColors.accentGreen(brightness), width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}