import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class PrayerStatsHistoryView extends StatefulWidget {
  const PrayerStatsHistoryView({super.key});

  @override
  State<PrayerStatsHistoryView> createState() => _PrayerStatsHistoryViewState();
}

class _PrayerStatsHistoryViewState extends State<PrayerStatsHistoryView> {
  final PrayerHistoryService _historyService = locator<PrayerHistoryService>();

  Map<String, int> _weeklyStats = {};
  Map<String, int> _monthlyStats = {};
  double _weeklyCompletionRate = 0.0;
  int _currentStreak = 0;
  Map<String, Map<String, bool>> _completionGrid = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _historyService.getWeeklyStats(),
        _historyService.getMonthlyStats(),
        _historyService.getCompletionRate(days: 7),
        _historyService.getCurrentStreak(),
        _historyService.getDailyCompletionGrid(30),
      ]);

      setState(() {
        _weeklyStats = results[0] as Map<String, int>;
        _monthlyStats = results[1] as Map<String, int>;
        _weeklyCompletionRate = results[2] as double;
        _currentStreak = results[3] as int;
        _completionGrid = results[4] as Map<String, Map<String, bool>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: CustomAppBar(title: 'Prayer Statistics & History', brightness: brightness),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStreakCard(brightness),
                  const SizedBox(height: 16),
                  _buildCompletionRateCard(brightness),
                  const SizedBox(height: 16),
                  _buildStatsCard(
                    'Weekly Stats (Last 7 Days)',
                    _weeklyStats,
                    brightness,
                  ),
                  const SizedBox(height: 16),
                  _buildStatsCard(
                    'Monthly Stats (Last 30 Days)',
                    _monthlyStats,
                    brightness,
                  ),
                  const SizedBox(height: 24),
                  _buildHistorySection(brightness),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStreakCard(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary(brightness).withAlpha(200),
            AppColors.primary(brightness).withAlpha(150),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary(brightness).withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Streak',
                  style: AppTextStyles.dateSecondary(brightness).copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentStreak ${_currentStreak == 1 ? 'day' : 'days'}',
                  style: AppTextStyles.sectionTitle(brightness).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRateCard(Brightness brightness) {
    final percentage = (_weeklyCompletionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider(brightness),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: AppColors.primary(brightness),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Weekly Completion Rate',
                style: AppTextStyles.sectionTitle(brightness),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _weeklyCompletionRate,
                  backgroundColor: AppColors.divider(brightness),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary(brightness),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '$percentage%',
                style: AppTextStyles.sectionTitle(brightness).copyWith(
                  color: AppColors.primary(brightness),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    String title,
    Map<String, int> stats,
    Brightness brightness,
  ) {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final total = prayers.fold<int>(
      0,
      (sum, prayer) => sum + (stats[prayer] ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider(brightness),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.sectionTitle(brightness),
          ),
          const SizedBox(height: 16),
          ...prayers.map((prayer) {
            final count = stats[prayer] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prayer,
                      style: AppTextStyles.prayerName(brightness),
                    ),
                  ),
                  Text(
                    '$count',
                    style: AppTextStyles.prayerName(brightness).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Divider(color: AppColors.divider(brightness)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Total',
                style: AppTextStyles.prayerName(brightness).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$total',
                style: AppTextStyles.sectionTitle(brightness).copyWith(
                  color: AppColors.primary(brightness),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prayer History (Last 30 Days)',
          style: AppTextStyles.sectionTitle(brightness).copyWith(
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.divider(brightness),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildHistoryHeader(brightness),
              const SizedBox(height: 16),
              _buildHistoryGrid(brightness),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader(Brightness brightness) {
    final prayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            'Date',
            style: AppTextStyles.label(brightness).copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...prayers.map((prayer) => Expanded(
          child: Text(
            prayer,
            style: AppTextStyles.label(brightness).copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        )),
      ],
    );
  }

  Widget _buildHistoryGrid(Brightness brightness) {
    final sortedDates = _completionGrid.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    return Column(
      children: sortedDates.map((dateKey) {
        final dateData = _completionGrid[dateKey]!;
        final date = DateTime.parse(dateKey);
        final isToday = dateKey == _getDateKey(DateTime.now());

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary(brightness).withAlpha(20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '${date.month}/${date.day}',
                  style: AppTextStyles.label(brightness).copyWith(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              ...['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((prayer) {
                final isCompleted = dateData[prayer] ?? false;
                return Expanded(
                  child: Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primary(brightness)
                            : AppColors.divider(brightness),
                      ),
                      child: isCompleted
                          ? Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                          : null,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}