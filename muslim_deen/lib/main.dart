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

  // Run non-critical async operations in parallel after locator setup
  final List<Future<void>> startupFutures = [
    _requestPermissions(),
    Future<void>(() async => tz.initializeTimeZones()),
  ];
  // LocationService.startPermissionFlow() is called during LocationService.init(),
  // which is called by PrayerService.init(), which is called by HomeView.
  // So, location permissions are handled later in the lifecycle.

  try {
    await Future.wait(startupFutures);
    locator<LoggerService>().info("Parallel startup operations completed.");
  } catch (e, s) {
    locator<LoggerService>().error(
      "Error during parallel startup operations",
      error: e,
      stackTrace: s,
    );
    // Decide if the app can continue or if this is a fatal error
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

  // Request notification permission
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
          theme: ThemeData(
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: AppColors.primary(
              Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.background(
              Brightness.dark,
            ),
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary(
                Brightness.dark,
              ),
              secondary: AppColors.accentGreen(
                Brightness.dark,
              ),
              surface: AppColors.surface(
                Brightness.dark,
              ),
              error: AppColors.error(Brightness.dark),
              onPrimary: AppColors.textPrimary(
                Brightness.dark,
              ),
              onSecondary: AppColors.textPrimary(
                Brightness.dark,
              ),
              onSurface: AppColors.textPrimary(
                Brightness.dark,
              ),
              onError: AppColors.textPrimary(
                Brightness.dark,
              ),
              brightness: Brightness.dark,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.surface(
                Brightness.dark,
              ),
              elevation: 1,
              iconTheme: IconThemeData(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              toolbarTextStyle:
                  TextTheme(
                    titleLarge: AppTextStyles.appTitle(Brightness.dark),
                  ).bodyMedium,
              titleTextStyle:
                  TextTheme(
                    titleLarge: AppTextStyles.appTitle(Brightness.dark),
                  ).titleLarge,
            ),
            cardColor: AppColors.surface(Brightness.dark),
            dividerColor: AppColors.divider(Brightness.dark),
            iconTheme: IconThemeData(
              color: AppColors.iconInactive(Brightness.dark),
            ),
            primaryIconTheme: IconThemeData(
              color: AppColors.accentGreen(Brightness.dark),
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              displayMedium: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              displaySmall: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              headlineMedium: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              headlineSmall: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              titleLarge: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              bodyLarge: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              bodyMedium: TextStyle(
                color: AppColors.textPrimary(Brightness.dark),
              ),
              bodySmall: TextStyle(
                color: AppColors.textSecondary(Brightness.dark),
              ),
              labelLarge: TextStyle(
                color: AppColors.accentGreen(Brightness.dark),
              ),
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: AppColors.accentGreen(
                Brightness.dark,
              ),
              textTheme:
                  ButtonTextTheme
                      .primary,
              colorScheme: ColorScheme.dark(
                primary: AppColors.accentGreen(Brightness.dark),
                onPrimary: AppColors.textPrimary(
                  Brightness.dark,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen(Brightness.dark),
                foregroundColor: AppColors.textPrimary(Brightness.dark),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentGreen(Brightness.dark),
              ),
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accentGreen(Brightness.dark);
                }
                return AppColors.accentGray(Brightness.dark);
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.switchTrackActive(
                    Brightness.dark,
                  );
                }
                return AppColors.accentGray(
                  Brightness.dark,
                ).withAlpha(50);
              }),
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.surface(Brightness.dark),
              selectedItemColor: AppColors.accentGreen(
                Brightness.dark,
              ),
              unselectedItemColor: AppColors.iconInactive(Brightness.dark),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppColors.accentGreen(
                Brightness.dark,
              ),
              foregroundColor: AppColors.textPrimary(Brightness.dark),
            ),
          ),
          themeMode: settingsState.themeMode,
          home: const MainScreen(),
          navigatorObservers: [
            _NavigationObserver(),
          ],
        );
      },
    );
  }
}

// Navigation observer to track route changes
class _NavigationObserver extends NavigatorObserver {
  final LoggerService _logger = locator<LoggerService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      previousRoute?.settings.name ?? 'unknown',
      route.settings.name ?? 'unknown',
      data: {'arguments': route.settings.arguments},
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.logNavigation(
      route.settings.name ?? 'unknown',
      previousRoute?.settings.name ?? 'unknown',
      data: {'arguments': previousRoute?.settings.arguments},
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

  // Lazy load views using builder functions
  static final List<Widget Function()> _widgetBuilders = <Widget Function()>[
    TesbihView.new,
    QiblaView.new,
    HomeView.new,
    MosqueView.new,
    SettingsView.new,
  ];

  // Cache for instantiated views to keep their state
  final Map<int, Widget> _cachedWidgets = {};

  // Map of tab indexes to their names for better logging
  final Map<int, String> _tabNames = {
    0: 'Tesbih',
    1: 'Qibla',
    2: 'Home',
    3: 'Mosque',
    4: 'Settings',
  };

  void _onItemTapped(int index) {
    final String from = _tabNames[_selectedIndex] ?? 'Unknown';
    final String to = _tabNames[index] ?? 'Unknown';

    _logger.logNavigation(
      from,
      to,
      data: {'fromIndex': _selectedIndex, 'toIndex': index},
    );

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget currentView;
    if (_cachedWidgets.containsKey(_selectedIndex)) {
      currentView = _cachedWidgets[_selectedIndex]!;
    } else {
      currentView = _widgetBuilders[_selectedIndex]();
      _cachedWidgets[_selectedIndex] = currentView;
    }

    return Scaffold(
      body: currentView,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.grain, "Tasbih"),
              _buildNavItem(1, Icons.explore, "Qibla"),
              _buildNavItem(2, Icons.schedule, "Prayer"),
              _buildNavItem(3, Icons.location_on, "Mosques"),
              _buildNavItem(4, Icons.more_horiz, "More"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
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
