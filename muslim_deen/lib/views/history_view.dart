import 'package:flutter/material.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
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
  final TasbihHistoryService _tasbihHistoryService =
      locator<TasbihHistoryService>();
  final LoggerService _logger = locator<LoggerService>();

  late TabController _tabController;

  // Tasbih data
  Map<String, int> _weeklyTasbihStats = {};
  Map<String, int> _monthlyTasbihStats = {};
  Map<String, Map<String, int>> _tasbihDailyGrid = {};
  int _currentTasbihStreak = 0;
  int _bestTasbihStreak = 0;

  bool _isLoading = true;
  Future<void>? _activeLoad;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
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

  Future<void> _loadData() {
    _activeLoad ??= _safeLoadData();
    return _activeLoad!;
  }

  Future<void> _safeLoadData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // Get current dhikr targets from TasbihView settings
      final dhikrTargets = await _tasbihHistoryService.getCurrentDhikrTargets();

      final tasbihResults = await Future.wait([
        _tasbihHistoryService.getWeeklyTasbihStats(),
        _tasbihHistoryService.getMonthlyTasbihStats(),
        _tasbihHistoryService.getDailyTasbihGrid(30),
        _tasbihHistoryService.getCurrentTasbihStreak(
          customTargets: dhikrTargets,
        ),
        _tasbihHistoryService.getBestTasbihStreak(),
      ]);

      if (!mounted) return;

      setState(() {
        _weeklyTasbihStats = tasbihResults[0] as Map<String, int>;
        _monthlyTasbihStats = tasbihResults[1] as Map<String, int>;
        _tasbihDailyGrid = tasbihResults[2] as Map<String, Map<String, int>>;
        _currentTasbihStreak = tasbihResults[3] as int;
        _bestTasbihStreak = tasbihResults[4] as int;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to load tasbih history data',
        error: e,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
    } finally {
      _activeLoad = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: CustomAppBar(title: 'Tasbih History', brightness: brightness),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: _buildTasbihHistoryTab(brightness),
                ),
              ),
    );
  }

  Widget _buildTasbihHistoryTab(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTasbihStreakCard(brightness),
        const SizedBox(height: 16),
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
    );
  }

  Widget _buildTasbihStreakCard(Brightness brightness) {
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
                  'Current Tasbih Streak',
                  style: AppTextStyles.dateSecondary(brightness).copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentTasbihStreak ${_currentTasbihStreak == 1 ? 'day' : 'days'}',
                  style: AppTextStyles.sectionTitle(brightness).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                if (_bestTasbihStreak > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Best: $_bestTasbihStreak ${_bestTasbihStreak == 1 ? 'day' : 'days'}',
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
                        color: AppColors.accentGreen,
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
                      color: AppColors.accentGreen,
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
}
