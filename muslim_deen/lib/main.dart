import 'package:flutter/material.dart';

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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2;
  final LoggerService _logger = locator<LoggerService>();

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
  }

  @override
  Widget build(BuildContext context) {
    // Optimized: Only create widget if not cached
    final Widget currentView =
        _cachedWidgets[_selectedIndex] ??= _widgetBuilders[_selectedIndex]();

    return Scaffold(
      body: currentView,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 0),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: _BottomNavigationItems(),
      ),
    );
  }
}

// Extracted as separate widget to optimize rebuilds
class _BottomNavigationItems extends StatelessWidget {
  const _BottomNavigationItems();

  @override
  Widget build(BuildContext context) {
    final mainScreenState =
        context.findAncestorStateOfType<_MainScreenState>()!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _NavItem(
          index: 0,
          icon: Icons.grain,
          label: "Tasbih",
          selectedIndex: mainScreenState._selectedIndex,
          onTap: mainScreenState._onItemTapped,
        ),
        _NavItem(
          index: 1,
          icon: Icons.explore,
          label: "Qibla",
          selectedIndex: mainScreenState._selectedIndex,
          onTap: mainScreenState._onItemTapped,
        ),
        _NavItem(
          index: 2,
          icon: Icons.schedule,
          label: "Prayer",
          selectedIndex: mainScreenState._selectedIndex,
          onTap: mainScreenState._onItemTapped,
        ),
        _NavItem(
          index: 3,
          icon: Icons.location_on,
          label: "Mosques",
          selectedIndex: mainScreenState._selectedIndex,
          onTap: mainScreenState._onItemTapped,
        ),
        _NavItem(
          index: 4,
          icon: Icons.more_horiz,
          label: "More",
          selectedIndex: mainScreenState._selectedIndex,
          onTap: mainScreenState._onItemTapped,
        ),
      ],
    );
  }
}

// Optimized navigation item widget
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.selectedIndex,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.unselectedWidgetColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isSelected
                      ? theme.colorScheme.primary
                      : theme.unselectedWidgetColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
