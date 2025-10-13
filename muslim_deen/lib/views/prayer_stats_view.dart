import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/services/prayer_analytics_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class PrayerStatsView extends StatefulWidget {
  const PrayerStatsView({super.key});

  @override
  State<PrayerStatsView> createState() => _PrayerStatsViewState();
}

class _PrayerStatsViewState extends State<PrayerStatsView> {
  final PrayerHistoryService _historyService = locator<PrayerHistoryService>();
  final PrayerAnalyticsService _analyticsService = locator<PrayerAnalyticsService>();

  Map<String, int> _weeklyStats = {};
  Map<String, int> _monthlyStats = {};
  double _weeklyCompletionRate = 0.0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _isLoading = true;

  // Advanced analytics data
  PrayerTrendData? _trendData;
  double _consistencyScore = 0.0;
  PrayerPerformanceData? _performanceData;

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
        _historyService.getBestStreak(),
        _analyticsService.analyzeTrends(days: 30),
        _analyticsService.getConsistencyScore(days: 30),
        _analyticsService.getPerformanceInsights(days: 30),
      ]);

      setState(() {
        _weeklyStats = results[0] as Map<String, int>;
        _monthlyStats = results[1] as Map<String, int>;
        _weeklyCompletionRate = results[2] as double;
        _currentStreak = results[3] as int;
        _bestStreak = results[4] as int;
        _trendData = results[5] as PrayerTrendData?;
        _consistencyScore = results[6] as double;
        _performanceData = results[7] as PrayerPerformanceData?;
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
                      _buildConsistencyScoreCard(brightness),
                      const SizedBox(height: 16),
                      _buildTrendCard(brightness),
                      const SizedBox(height: 16),
                      _buildPerformanceInsightsCard(brightness),
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
                if (_bestStreak > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Best: $_bestStreak ${_bestStreak == 1 ? 'day' : 'days'}',
                    style: AppTextStyles.dateSecondary(
                      brightness,
                    ).copyWith(color: Colors.white70, fontSize: 14),
                  ),
                ],
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
        border: Border.all(color: AppColors.divider(brightness), width: 1),
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
    // Prayer names as stored in database (lowercase enum names)
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    // Display names (capitalized)
    final displayNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    final total = prayers.fold<int>(
      0,
      (sum, prayer) => sum + (stats[prayer] ?? 0),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle(brightness)),
          const SizedBox(height: 16),
          ...List.generate(prayers.length, (index) {
            final prayer = prayers[index];
            final displayName = displayNames[index];
            final count = stats[prayer] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: AppTextStyles.prayerName(brightness),
                    ),
                  ),
                  Text(
                    '$count',
                    style: AppTextStyles.prayerName(
                      brightness,
                    ).copyWith(fontWeight: FontWeight.bold),
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
                style: AppTextStyles.prayerName(
                  brightness,
                ).copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildConsistencyScoreCard(Brightness brightness) {
    final score = (_consistencyScore * 100).round();
    final scoreColor = _getConsistencyColor(score);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface(brightness),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider(brightness), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.timeline,
              color: AppColors.primary(brightness),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Consistency Score',
              style: AppTextStyles.sectionTitle(brightness),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: _consistencyScore,
                backgroundColor: AppColors.divider(brightness),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '$score%',
              style: AppTextStyles.sectionTitle(brightness).copyWith(
                color: scoreColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _getConsistencyMessage(score),
          style: AppTextStyles.dateSecondary(brightness),
        ),
      ],
    ),
  );
}

  Widget _buildTrendCard(Brightness brightness) {
    if (_trendData == null) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppColors.primary(brightness),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Prayer Trends (30 Days)',
                style: AppTextStyles.sectionTitle(brightness),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No trend data available',
            style: AppTextStyles.dateSecondary(brightness),
          ),
        ],
      ),
    );
  }

  final trendIcon = _trendData!.trendDirection == TrendDirection.improving
      ? Icons.trending_up
      : _trendData!.trendDirection == TrendDirection.declining
          ? Icons.trending_down
          : Icons.trending_flat;
  final trendColor = _trendData!.trendDirection == TrendDirection.improving
      ? Colors.green
      : _trendData!.trendDirection == TrendDirection.declining
          ? Colors.red
          : AppColors.primary(brightness);

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface(brightness),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider(brightness), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              trendIcon,
              color: trendColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Prayer Trends (30 Days)',
              style: AppTextStyles.sectionTitle(brightness),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTrendMetric(
              'Average Daily',
              '${_trendData!.averagePrayersPerDay.toStringAsFixed(1)}',
              brightness,
            ),
            _buildTrendMetric(
              'Best Day',
              '${_trendData!.bestDayCount}',
              brightness,
            ),
            _buildTrendMetric(
              'Trend',
              _getTrendText(_trendData!.trendDirection),
              brightness,
              color: trendColor,
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildPerformanceInsightsCard(Brightness brightness) {
    if (_performanceData == null) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider(brightness), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppColors.primary(brightness),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Performance Insights',
                style: AppTextStyles.sectionTitle(brightness),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'No performance data available',
            style: AppTextStyles.dateSecondary(brightness),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface(brightness),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.divider(brightness), width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights,
              color: AppColors.primary(brightness),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Performance Insights',
              style: AppTextStyles.sectionTitle(brightness),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInsightItem(
          'Most Consistent Prayer',
          _performanceData!.mostConsistentPrayer,
          brightness,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          'Least Consistent Prayer',
          _performanceData!.leastConsistentPrayer,
          brightness,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          'Best Performing Day',
          _performanceData!.bestPerformingDay,
          brightness,
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          'Improvement Area',
          _performanceData!.improvementArea,
          brightness,
        ),
      ],
    ),
  );
}

  Widget _buildTrendMetric(String label, String value, Brightness brightness,
      {Color? color}) {
    return Column(
    children: [
      Text(
        value,
        style: AppTextStyles.sectionTitle(brightness).copyWith(
          color: color ?? AppColors.primary(brightness),
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: AppTextStyles.dateSecondary(brightness).copyWith(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

  Widget _buildInsightItem(String label, String? value, Brightness brightness) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: AppTextStyles.prayerName(brightness).copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: AppTextStyles.prayerName(brightness),
          ),
        ),
      ],
    );
  }

  Color _getConsistencyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getConsistencyMessage(int score) {
    if (score >= 80) return 'Excellent consistency! Keep up the great work.';
    if (score >= 60) return 'Good consistency. Room for improvement.';
    return 'Consistency needs improvement. Try to maintain regular prayer times.';
  }

  String _getTrendText(TrendDirection direction) {
    switch (direction) {
      case TrendDirection.improving:
        return 'Improving';
      case TrendDirection.declining:
        return 'Declining';
      case TrendDirection.stable:
        return 'Stable';
    }
  }
}
