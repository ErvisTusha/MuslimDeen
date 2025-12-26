import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/fasting_tracker_view.dart';
import 'package:muslim_deen/views/hadith_view.dart';
import 'package:muslim_deen/views/home_view.dart';
import 'package:muslim_deen/views/islamic_calendar_view.dart';
import 'package:muslim_deen/views/mosque_view.dart';
import 'package:muslim_deen/views/qibla_view.dart';
import 'package:muslim_deen/views/settings_view.dart';
import 'package:muslim_deen/views/tesbih_view.dart';
import 'package:muslim_deen/views/zakat_calculator_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  final LoggerService _logger = locator<LoggerService>();
  late AnimationController _animationController;
  late Animation<double> _animation;

  static final List<Widget Function()> _widgetBuilders = <Widget Function()>[
    TesbihView.new,
    QiblaView.new,
    HomeView.new,
    MosqueView.new,
    SettingsView.new,
    HadithView.new,
    IslamicCalendarView.new,
    FastingTrackerView.new,
    ZakatCalculatorView.new,
  ];

  final Map<int, Widget> _cachedWidgets = <int, Widget>{};

  static const Map<int, String> _tabNames = <int, String>{
    0: 'Tesbih',
    1: 'Qibla',
    2: 'Home',
    3: 'Mosque',
    4: 'Settings',
    5: 'Hadith',
    6: 'Calendar',
    7: 'Fasting',
    8: 'Zakat',
  };

  static const List<_NavItemData> _navItems = [
    _NavItemData(
      icon: Icons.grain,
      activeIcon: Icons.grain,
      label: "Tasbih",
      tooltip: "Open Tasbih counter",
    ),
    _NavItemData(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: "Qibla",
      tooltip: "Find Qibla direction",
    ),
    _NavItemData(
      icon: Icons.schedule_outlined,
      activeIcon: Icons.schedule,
      label: "Prayer",
      tooltip: "Prayer times",
    ),
    _NavItemData(
      icon: Icons.location_on_outlined,
      activeIcon: Icons.location_on,
      label: "Mosques",
      tooltip: "Find nearby mosques",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    final String from = _tabNames[_selectedIndex] ?? 'Unknown';
    final String to = _tabNames[index] ?? 'Unknown';

    _logger.logNavigation(
      'BottomNavTap',
      routeName: to,
      details: 'from $from',
      params: {'fromIndex': _selectedIndex, 'toIndex': index},
    );

    setState(() {
      _selectedIndex = index;
    });

    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  void _onOverflowItemTapped(int index) {
    final actualIndex = index + 4;

    if (actualIndex == _selectedIndex) return;

    final String from = _tabNames[_selectedIndex] ?? 'Unknown';
    final String to = _tabNames[actualIndex] ?? 'Unknown';

    _logger.logNavigation(
      'OverflowMenuTap',
      routeName: to,
      details: 'from $from',
      params: {'fromIndex': _selectedIndex, 'toIndex': actualIndex},
    );

    setState(() {
      _selectedIndex = actualIndex;
    });

    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _cachedWidgets[_selectedIndex] ??= _widgetBuilders[_selectedIndex](),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(brightness),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              ...List.generate(_navItems.length, (index) {
                return Expanded(
                  child: _NavItem(
                    index: index,
                    data: _navItems[index],
                    selectedIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    animation: _animation,
                  ),
                );
              }),
              SizedBox(
                width: 48,
                child: _OverflowMenuButton(
                  onItemSelected: _onOverflowItemTapped,
                  animation: _animation,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.data,
    required this.selectedIndex,
    required this.onTap,
    required this.animation,
  });

  final int index;
  final _NavItemData data;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return Semantics(
      label: data.tooltip,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentGreen.withValues(alpha: 0.1),
        highlightColor: AppColors.accentGreen.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? AppColors.accentGreen.withValues(alpha: 0.15)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isSelected ? data.activeIcon : data.icon,
                    key: ValueKey('$index-$isSelected'),
                    color:
                        isSelected
                            ? AppColors.accentGreen
                            : AppColors.iconInactive,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color:
                      isSelected
                          ? AppColors.accentGreen
                          : AppColors.iconInactive,
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                ),
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverflowMenuButton extends StatelessWidget {
  const _OverflowMenuButton({
    required this.onItemSelected,
    required this.animation,
  });

  final ValueChanged<int> onItemSelected;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Semantics(
      label: 'More options',
      button: true,
      child: PopupMenuButton<int>(
        onSelected: onItemSelected,
        itemBuilder:
            (BuildContext context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: AppColors.iconInactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: AppColors.textPrimary(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Icon(
                      Icons.book_outlined,
                      color: AppColors.iconInactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Hadith',
                      style: TextStyle(
                        color: AppColors.textPrimary(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.iconInactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Calendar',
                      style: TextStyle(
                        color: AppColors.textPrimary(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 3,
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_outlined,
                      color: AppColors.iconInactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Fasting Tracker',
                      style: TextStyle(
                        color: AppColors.textPrimary(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 4,
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.iconInactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Zakat Calculator',
                      style: TextStyle(
                        color: AppColors.textPrimary(brightness),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accentGreen.withValues(alpha: 0.1),
          highlightColor: AppColors.accentGreen.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.iconInactive,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: AppColors.iconInactive,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                  child: const Text(
                    'More',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
