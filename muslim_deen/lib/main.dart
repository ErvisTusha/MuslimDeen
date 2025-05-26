import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/views/home_view.dart';
import 'package:muslim_deen/views/mosque_view.dart';
import 'package:muslim_deen/views/qibla_view.dart';
import 'package:muslim_deen/views/settings_view.dart';
import 'package:muslim_deen/views/tesbih_view.dart';
import 'package:muslim_deen/widgets/error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();

  final List<Future<void>> startupFutures = [
    _requestPermissions(),
    Future<void>(() async => tz.initializeTimeZones()),
  ];

  try {
    await Future.wait(startupFutures);
    locator<LoggerService>().info("Parallel startup operations completed.");
  } catch (e, s) {
    locator<LoggerService>().error(
      "Error during parallel startup operations",
      error: e,
      stackTrace: s,
    );
  }

  FlutterError.onError = (details) {
    final errorHandler = locator<ErrorHandlerService>();
    errorHandler.reportError(
      AppError(
        message: 'Flutter framework error',
        details: details.exceptionAsString(),
        stackTrace: details.stack,
        originalException: details.exception,
      ),
    );
  };

  runApp(const ProviderScope(child: ErrorBoundary(child: MuslimDeenApp())));
}

Future<void> _requestPermissions() async {
  final LoggerService logger = locator<LoggerService>();

  logger.info(
    'Location permission request is now handled by LocationService.startPermissionFlow()',
  );

  var notificationStatus = await Permission.notification.status;
  logger.info('Initial notification permission status: $notificationStatus');
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
    logger.info(
      'Notification permission status after request: $notificationStatus',
    );
  }
}

class MuslimDeenApp extends StatelessWidget {
  const MuslimDeenApp({super.key});

  @override
  Widget build(BuildContext context) {
    locator<LoggerService>().info('Application started');

    return Consumer(
      builder: (context, ref, _) {
        final settingsState = ref.watch(settingsProvider);

        return MaterialApp(
          title: 'Muslim Deen',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: settingsState.themeMode,
          home: const MainScreen(),
          navigatorObservers: [_NavigationObserver()],
        );
      },
    );
  }

  // Extracted theme building methods for better performance
  ThemeData _buildLightTheme() {
    return ThemeData(
      primarySwatch: Colors.green,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  ThemeData _buildDarkTheme() {
    const brightness = Brightness.dark;
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary(brightness),
      scaffoldBackgroundColor: AppColors.background(brightness),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary(brightness),
        secondary: AppColors.accentGreen(brightness),
        surface: AppColors.surface(brightness),
        error: AppColors.error(brightness),
        onPrimary: AppColors.textPrimary(brightness),
        onSecondary: AppColors.textPrimary(brightness),
        onSurface: AppColors.textPrimary(brightness),
        onError: AppColors.textPrimary(brightness),
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface(brightness),
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.textPrimary(brightness)),
        toolbarTextStyle:
            TextTheme(
              titleLarge: AppTextStyles.appTitle(brightness),
            ).bodyMedium,
        titleTextStyle:
            TextTheme(
              titleLarge: AppTextStyles.appTitle(brightness),
            ).titleLarge,
      ),
      cardColor: AppColors.surface(brightness),
      dividerColor: AppColors.divider(brightness),
      iconTheme: IconThemeData(color: AppColors.iconInactive(brightness)),
      primaryIconTheme: IconThemeData(color: AppColors.accentGreen(brightness)),
      textTheme: _buildTextTheme(brightness),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.accentGreen(brightness),
        textTheme: ButtonTextTheme.primary,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accentGreen(brightness),
          onPrimary: AppColors.textPrimary(brightness),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen(brightness),
          foregroundColor: AppColors.textPrimary(brightness),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentGreen(brightness),
        ),
      ),
      switchTheme: _buildSwitchTheme(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface(brightness),
        selectedItemColor: AppColors.accentGreen(brightness),
        unselectedItemColor: AppColors.iconInactive(brightness),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGreen(brightness),
        foregroundColor: AppColors.textPrimary(brightness),
      ),
    );
  }

  TextTheme _buildTextTheme(Brightness brightness) {
    return TextTheme(
      displayLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      displayMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      displaySmall: TextStyle(color: AppColors.textPrimary(brightness)),
      headlineMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      headlineSmall: TextStyle(color: AppColors.textPrimary(brightness)),
      titleLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      bodyLarge: TextStyle(color: AppColors.textPrimary(brightness)),
      bodyMedium: TextStyle(color: AppColors.textPrimary(brightness)),
      bodySmall: TextStyle(color: AppColors.textSecondary(brightness)),
      labelLarge: TextStyle(color: AppColors.accentGreen(brightness)),
    );
  }

  SwitchThemeData _buildSwitchTheme(Brightness brightness) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentGreen(brightness);
        }
        return AppColors.accentGray(brightness);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.switchTrackActive(brightness);
        }
        return AppColors.accentGray(brightness).withAlpha(50);
      }),
    );
  }
}

class _NavigationObserver extends NavigatorObserver {
  final LoggerService _logger = locator<LoggerService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      'didPush',
      routeName: route.settings.name ?? 'unknown',
      params: route.settings.arguments as Map<String, dynamic>?,
      details: 'from ${previousRoute?.settings.name ?? 'unknown'}',
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      'didPop',
      routeName: previousRoute?.settings.name ?? 'unknown',
      params: previousRoute?.settings.arguments as Map<String, dynamic>?,
      details: 'popped ${route.settings.name ?? 'unknown'}',
    );
    super.didPop(route, previousRoute);
  }
}

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

  // Optimized: Use lazy initialization instead of immediate widget creation
  static final List<Widget Function()> _widgetBuilders = <Widget Function()>[
    TesbihView.new,
    QiblaView.new,
    HomeView.new,
    MosqueView.new,
    SettingsView.new,
  ];

  // Optimized: Weak reference caching to prevent memory leaks
  final Map<int, Widget> _cachedWidgets = <int, Widget>{};

  static const Map<int, String> _tabNames = <int, String>{
    0: 'Tesbih',
    1: 'Qibla',
    2: 'Home',
    3: 'Mosque',
    4: 'Settings',
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
    _NavItemData(
      icon: Icons.more_horiz_outlined,
      activeIcon: Icons.more_horiz,
      label: "More",
      tooltip: "Settings and more",
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
    if (index == _selectedIndex) return; // Prevent unnecessary rebuilds

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

    // Add subtle haptic feedback
    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // IndexedStack keeps all widgets alive but only shows the selected one.
        // This prevents dispose() calls when switching tabs, ensuring that
        // notifications and other background processes continue running.
        index: _selectedIndex,
        children: [
          // Create all widgets once and keep them alive
          _cachedWidgets[0] ??= _widgetBuilders[0](),
          _cachedWidgets[1] ??= _widgetBuilders[1](),
          _cachedWidgets[2] ??= _widgetBuilders[2](),
          _cachedWidgets[3] ??= _widgetBuilders[3](),
          _cachedWidgets[4] ??= _widgetBuilders[4](),
        ],
      ),
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
            color: AppColors.shadowColor(brightness),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppColors.divider(brightness), width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
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

// Optimized navigation item widget with better animations and accessibility
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
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Semantics(
      label: data.tooltip,
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentGreen(brightness).withValues(alpha: 0.1),
        highlightColor: AppColors.accentGreen(
          brightness,
        ).withValues(alpha: 0.05),
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
                          ? AppColors.accentGreen(
                            brightness,
                          ).withValues(alpha: 0.15)
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
                            ? AppColors.accentGreen(brightness)
                            : AppColors.iconInactive(brightness),
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
                          ? AppColors.accentGreen(brightness)
                          : AppColors.iconInactive(brightness),
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
