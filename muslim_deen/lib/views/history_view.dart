import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/prayer_history_service.dart';
import 'package:muslim_deen/services/tasbih_history_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final PrayerHistoryService _prayerHistoryService =
      locator<PrayerHistoryService>();
  final TasbihHistoryService _tasbihHistoryService =
      locator<TasbihHistoryService>();

  late TabController _tabController;

  // Prayer data
  Map<String, int> _weeklyPrayerStats = {};
  Map<String, int> _monthlyPrayerStats = {};
  Map<String, Map<String, bool>> _prayerCompletionGrid = {};
  int _currentPrayerStreak = 0;

  // Tasbih data
  Map<String, int> _weeklyTasbihStats = {};
  Map<String, int> _monthlyTasbihStats = {};
  Map<String, Map<String, int>> _tasbihDailyGrid = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load prayer data
      final prayerResults = await Future.wait([
        _prayerHistoryService.getWeeklyStats(),
        _prayerHistoryService.getMonthlyStats(),
        _prayerHistoryService.getDailyCompletionGrid(30),
        _prayerHistoryService.getCurrentStreak(),
      ]);

      // Load tasbih data with error handling
      Map<String, int> weeklyTasbihStats = {};
      Map<String, int> monthlyTasbihStats = {};
      Map<String, Map<String, int>> tasbihDailyGrid = {};

      try {
        final tasbihResults = await Future.wait([
          _tasbihHistoryService.getWeeklyTasbihStats(),
          _tasbihHistoryService.getMonthlyTasbihStats(),
          _tasbihHistoryService.getDailyTasbihGrid(30),
        ]);

        weeklyTasbihStats = tasbihResults[0] as Map<String, int>;
        monthlyTasbihStats = tasbihResults[1] as Map<String, int>;
        tasbihDailyGrid = tasbihResults[2] as Map<String, Map<String, int>>;
      } catch (e) {
        // Log tasbih data loading error but don't fail the entire load
        print('Error loading tasbih data: $e');
      }
      setState(() {
        _weeklyPrayerStats = prayerResults[0] as Map<String, int>;
        _monthlyPrayerStats = prayerResults[1] as Map<String, int>;
        _prayerCompletionGrid =
            prayerResults[2] as Map<String, Map<String, bool>>;
        _currentPrayerStreak = prayerResults[3] as int;

        _weeklyTasbihStats = weeklyTasbihStats;
        _monthlyTasbihStats = monthlyTasbihStats;
        _tasbihDailyGrid = tasbihDailyGrid;

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
      appBar: CustomAppBar(title: 'Historical Data', brightness: brightness),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Material(
                    color: AppColors.surface(brightness).withAlpha(240),
                    elevation: 2,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [Tab(text: 'Prayers'), Tab(text: 'Tasbih')],
                      labelColor: AppColors.primary(brightness),
                      unselectedLabelColor: AppColors.textSecondary(brightness),
                      indicatorColor: AppColors.primary(brightness),
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPrayerHistoryTab(brightness),
                        _buildTasbihHistoryTab(brightness),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildPrayerHistoryTab(Brightness brightness) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrayerStreakCard(brightness),
            const SizedBox(height: 16),
            _buildPrayerStatsCard(
              'Weekly Prayer Stats',
              _weeklyPrayerStats,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildPrayerStatsCard(
              'Monthly Prayer Stats',
              _monthlyPrayerStats,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildPrayerCompletionGrid(brightness),
          ],
        ),
      ),
    );
  }

  Widget _buildTasbihHistoryTab(Brightness brightness) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTasbihStatsCard(
              'Weekly Tasbih Stats',
              _weeklyTasbihStats,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildTasbihStatsCard(
              'Monthly Tasbih Stats',
              _monthlyTasbihStats,
              brightness,
            ),
            const SizedBox(height: 16),
            _buildTasbihDailyGrid(brightness),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerStreakCard(Brightness brightness) {
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
                  'Current Prayer Streak',
                  style: AppTextStyles.dateSecondary(brightness).copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentPrayerStreak ${_currentPrayerStreak == 1 ? 'day' : 'days'}',
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

  Widget _buildPrayerStatsCard(
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
                  'No prayer data yet.',
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

  Widget _buildTasbihStatsCard(
    String title,
    Map<String, int> stats,
    Brightness brightness,
  ) {
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
                  'No tasbih data yet.',
                  style: AppTextStyles.dateSecondary(
                    brightness,
                  ).copyWith(color: Colors.grey),
                ),
              ),
            )
          else
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: AppTextStyles.prayerName(brightness),
                    ),
                    Text(
                      '${entry.value}',
                      style: AppTextStyles.dateSecondary(brightness).copyWith(
                        color: AppColors.accentGreen(brightness),
                        fontWeight: FontWeight.w600,
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

  Widget _buildPrayerCompletionGrid(Brightness brightness) {
    if (_prayerCompletionGrid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No prayer completion data yet.',
            style: AppTextStyles.dateSecondary(
              brightness,
            ).copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    final sortedDates =
        _prayerCompletionGrid.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

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
            'Daily Prayer Completion (Last 30 Days)',
            style: AppTextStyles.prayerName(
              brightness,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...sortedDates.take(10).map((date) {
            // Show last 10 days
            final completion = _prayerCompletionGrid[date]!;
            final completedCount = completion.values.where((v) => v).length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatDate(date),
                      style: AppTextStyles.dateSecondary(brightness),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children:
                          ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].map((
                            prayer,
                          ) {
                            final isCompleted = completion[prayer] ?? false;
                            return Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color:
                                    isCompleted
                                        ? AppColors.accentGreen(brightness)
                                        : Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  prayer[0], // First letter
                                  style: TextStyle(
                                    color:
                                        isCompleted
                                            ? Colors.white
                                            : Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  Text(
                    '$completedCount/5',
                    style: AppTextStyles.dateSecondary(
                      brightness,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTasbihDailyGrid(Brightness brightness) {
    if (_tasbihDailyGrid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No tasbih data yet.',
            style: AppTextStyles.dateSecondary(
              brightness,
            ).copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    final sortedDates =
        _tasbihDailyGrid.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // Most recent first

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
            'Daily Tasbih Counts (Last 30 Days)',
            style: AppTextStyles.prayerName(
              brightness,
            ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ...sortedDates.take(10).map((date) {
            // Show last 10 days
            final counts = _tasbihDailyGrid[date]!;
            final totalCount = counts.values.fold(
              0,
              (sum, count) => sum + count,
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      _formatDate(date),
                      style: AppTextStyles.dateSecondary(brightness),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      counts.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', '),
                      style: AppTextStyles.dateSecondary(brightness),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$totalCount',
                    style: AppTextStyles.dateSecondary(brightness).copyWith(
                      color: AppColors.accentGreen(brightness),
                      fontWeight: FontWeight.w600,
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

  String _formatDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) return 'Today';
      if (dateOnly == today.subtract(const Duration(days: 1)))
        return 'Yesterday';

      return '${date.month}/${date.day}';
    } catch (e) {
      return dateKey;
    }
  }

  Color _getColorForPercentage(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }
}
