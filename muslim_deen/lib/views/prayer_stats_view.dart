import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class PrayerStatsView extends StatefulWidget {
  const PrayerStatsView({super.key});

  @override
  State<PrayerStatsView> createState() => _PrayerStatsViewState();
}

class _PrayerStatsViewState extends State<PrayerStatsView> {
  final PrayerHistoryService _historyService = locator<PrayerHistoryService>();

  Map<String, int> _weeklyStats = {};
  Map<String, int> _monthlyStats = {};
  double _weeklyCompletionRate = 0.0;
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _historyService.getWeeklyStats(),
        _historyService.getMonthlyStats(),
        _historyService.getCompletionRate(days: 7),
        _historyService.getCurrentStreak(),
      ]);

      setState(() {
        _weeklyStats = results[0] as Map<String, int>;
        _monthlyStats = results[1] as Map<String, int>;
        _weeklyCompletionRate = results[2] as double;
        _currentStreak = results[3] as int;
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
      appBar: CustomAppBar(title: 'Prayer Statistics', brightness: brightness),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadStats,
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
    final percentage = (_weeklyCompletionRate * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Completion',
                style: AppTextStyles.prayerName(
                  brightness,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.sectionTitle(brightness).copyWith(
                  color: AppColors.accentGreen(brightness),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _weeklyCompletionRate,
              minHeight: 10,
              backgroundColor:
                  brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentGreen(brightness),
              ),
            ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.prayerName(
              brightness,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (stats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No prayer data yet. Start tracking!',
                  style: AppTextStyles.dateSecondary(
                    brightness,
                  ).copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ...prayers.map((prayer) {
              final count = stats[prayer] ?? 0;
              final maxCount = title.contains('Weekly') ? 7 : 30;
              final percentage = count / maxCount;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prayer,
                          style: AppTextStyles.prayerName(brightness),
                        ),
                        Text(
                          '$count/$maxCount',
                          style: AppTextStyles.dateSecondary(
                            brightness,
                          ).copyWith(
                            color: AppColors.accentGreen(brightness),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor:
                            brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForPercentage(percentage),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
