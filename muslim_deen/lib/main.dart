import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/services/notification_service.dart';

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
import 'package:muslim_deen/widgets/error_boundary.dart';
import 'package:muslim_deen/config/app_localization_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await setupLocator();
    
    // Initialize enhanced accessibility

    
  } catch (e, s) {
    // If service locator fails, we can't use the logger, so print to console
    debugPrint('Failed to setup service locator: $e');
    debugPrint('Stack trace: $s');
    // Try to run the app anyway with minimal setup
    runApp(const ErrorApp());
    return;
  }

  final List<Future<void>> startupFutures = [
    _requestPermissions(),
    Future<void>(() async => tz.initializeTimeZones()),
    Future<void>(() async {
      final notificationService = locator<NotificationService>();
      await notificationService.init();
      await notificationService.rescheduleAllNotifications();
    }),
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
    // Continue anyway - don't let startup failures crash the app
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

        final currentLocale = _getLocaleFromSettings(settingsState.language);
        
        return MaterialApp(
          title: 'Muslim Deen',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: settingsState.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainScreen(),
          locale: currentLocale,
          supportedLocales: AppLocalizationConfig.supportedLocales,
          navigatorKey: locator<NavigationService>().navigatorKey,
          navigatorObservers: [_NavigationObserver()],
          // Add RTL support for scroll views and other directional elements
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0), // Ensure consistent text scaling
              ),
              child: Directionality(
                textDirection: AppLocalizationConfig.getTextDirection(
                  Localizations.localeOf(context),
                ),
                child: child!,
              ),
            );
          },
        );
      },
    );
  }

  // Extracted theme building methods for better performance
  ThemeData _buildLightTheme() {
    const brightness = Brightness.light;
    return ThemeData.light().copyWith(
      primaryColor: AppColors.primary(brightness),
      scaffoldBackgroundColor: AppColors.background(brightness),
      colorScheme: ColorScheme.light(
        primary: AppColors.primary(brightness),
        secondary: AppColors.accentGreen,
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
        toolbarTextStyle: AppTextStyles.appTitle(brightness),
        titleTextStyle: AppTextStyles.appTitle(brightness),
      ),
      cardColor: AppColors.surface(brightness),
      dividerColor: AppColors.divider,
      iconTheme: IconThemeData(color: AppColors.iconInactive),
      primaryIconTheme: IconThemeData(color: AppColors.accentGreen),
      textTheme: _buildTextTheme(brightness),
      switchTheme: _buildSwitchTheme(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface(brightness),
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.iconInactive,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGreen,
        foregroundColor: AppColors.textPrimary(brightness),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const brightness = Brightness.dark;
    return ThemeData.dark().copyWith(
      primaryColor: AppColors.primary(brightness),
      scaffoldBackgroundColor: AppColors.background(brightness),
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary(brightness),
        secondary: AppColors.accentGreen,
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
      dividerColor: AppColors.divider,
      iconTheme: IconThemeData(color: AppColors.iconInactive),
      primaryIconTheme: IconThemeData(color: AppColors.accentGreen),
      textTheme: _buildTextTheme(brightness),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.accentGreen,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.textPrimary(brightness),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentGreen,
        ),
      ),
      switchTheme: _buildSwitchTheme(brightness),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface(brightness),
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.iconInactive,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentGreen,
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
      labelLarge: TextStyle(color: AppColors.accentGreen),
    );
  }

  SwitchThemeData _buildSwitchTheme(Brightness brightness) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.accentGreen;
        }
        return AppColors.accentGray;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.switchTrackActive;
        }
        return AppColors.accentGray.withAlpha(50);
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
    HadithView.new,
    IslamicCalendarView.new,
    FastingTrackerView.new,
    ZakatCalculatorView.new,
  ];

  // Optimized: Weak reference caching to prevent memory leaks
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

  void _onOverflowItemTapped(int index) {
    // Overflow items are at indices 4, 5, 6, 7, 8 (Settings, Hadith, Calendar, Fasting, Zakat)
    final actualIndex = index + 4; // Add 4 to get the real index

    if (actualIndex == _selectedIndex) return; // Prevent unnecessary rebuilds

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

    // Add subtle haptic feedback
    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (int i = 0; i < _widgetBuilders.length; i++)
            _cachedWidgets[i] ??= _widgetBuilders[i](),
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
            color: AppColors.shadowColor,
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Main navigation items
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
              // Overflow menu button
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

// Overflow menu button widget
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
                value: 0, // Settings
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
                value: 1, // Hadith
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
                value: 2, // Calendar
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
                value: 3, // Fasting
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
                value: 4, // Zakat
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
                    Icons.more_vert, // Vertical ellipsis
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



/// Convert language setting string to proper Locale
Locale _getLocaleFromSettings(String languageCode) {
  switch (languageCode) {
    case 'ar':
      return const Locale('ar', 'SA');
    case 'ur':
      return const Locale('ur', 'PK');
    case 'fa':
      return const Locale('fa', 'IR');
    case 'tr':
      return const Locale('tr', 'TR');
    case 'id':
      return const Locale('id', 'ID');
    case 'ms':
      return const Locale('ms', 'MY');
    case 'fr':
      return const Locale('fr', 'FR');
    case 'en':
    default:
      return const Locale('en', 'US');
  }
}

/// Fallback app shown when service locator initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The app failed to start properly. Please try restarting the app.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: main,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
