import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'l10n/app_localizations.dart';
import 'providers/providers.dart';
import 'service_locator.dart';
import 'services/error_handler_service.dart';
import 'services/logger_service.dart';
import 'styles/app_styles.dart'; // Import AppColors
import 'views/home_view.dart';
import 'views/mosque_view.dart';
import 'views/qibla_view.dart';
import 'views/settings_view.dart';
import 'views/tesbih_view.dart';
import 'widgets/error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(); // Initialize service locator first
  await _requestPermissions(); // Then request permissions
  tz.initializeTimeZones();

  // Set up error handling for Flutter framework errors
  FlutterError.onError = (details) {
    final errorHandler = locator<ErrorHandlerService>(); // Use locator
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

  // Request location permission
  // var locationStatus = await Permission.location.status;
  // logger.info('Initial location permission status: $locationStatus');
  // if (!locationStatus.isGranted) {
  //   locationStatus = await Permission.location.request();
  //   logger.info('Location permission status after request: $locationStatus');
  // }
  logger.info('Location permission request is now handled by LocationService.startPermissionFlow()');

  // Request notification permission
  var notificationStatus = await Permission.notification.status;
  logger.info('Initial notification permission status: $notificationStatus');
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
    logger.info('Notification permission status after request: $notificationStatus');
  }
}

class MuslimDeenApp extends StatelessWidget {
  const MuslimDeenApp({super.key});

  Locale _parseLocale(String languageCode) {
    final code = languageCode.trim().toLowerCase();
    final localeMap = {
      'ar': const Locale('ar'),
      'tr': const Locale('tr'),
      'sq': const Locale('sq'),
      'fr': const Locale('fr'),
      'es': const Locale('es'),
      'pt_br': const Locale('pt', 'BR'),
    };

    return localeMap[code] ?? const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    // Log app start
    locator<LoggerService>().info('Application started');

    return Consumer(
      builder: (context, ref, _) {
        final settingsState = ref.watch(settingsProvider);

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(
            primarySwatch: Colors.green,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: AppColors.primary(Brightness.dark), // Now very dark gray / black
            scaffoldBackgroundColor: AppColors.background(Brightness.dark), // Now black
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary(Brightness.dark),         // Main interactive elements (very dark gray)
              secondary: AppColors.accentGreen(Brightness.dark),   // Accent color (green)
              surface: AppColors.surface(Brightness.dark),         // Cards, dialogs (very dark gray)
              error: AppColors.error(Brightness.dark),
              onPrimary: AppColors.textPrimary(Brightness.dark),   // Text on primary (white)
              onSecondary: AppColors.textPrimary(Brightness.dark), // Text on accent (white or black depending on accent's brightness)
              onSurface: AppColors.textPrimary(Brightness.dark),   // Text on surface (white)
              onError: AppColors.textPrimary(Brightness.dark),     // Text on error (white)
              brightness: Brightness.dark, // Explicitly set brightness
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.surface(Brightness.dark), // AppBar uses surface color
              elevation: 1,
              iconTheme: IconThemeData(color: AppColors.textPrimary(Brightness.dark)),
              toolbarTextStyle: TextTheme(
                titleLarge: AppTextStyles.appTitle(Brightness.dark),
              ).bodyMedium,
              titleTextStyle: TextTheme(
                titleLarge: AppTextStyles.appTitle(Brightness.dark),
              ).titleLarge,
            ),
            cardColor: AppColors.surface(Brightness.dark),
            dividerColor: AppColors.divider(Brightness.dark),
            iconTheme: IconThemeData(color: AppColors.iconInactive(Brightness.dark)), // Default icon color
            primaryIconTheme: IconThemeData(color: AppColors.accentGreen(Brightness.dark)), // Icons that should be green
            textTheme: TextTheme(
              displayLarge: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              displayMedium: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              displaySmall: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              headlineMedium: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              headlineSmall: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              titleLarge: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              bodyLarge: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              bodyMedium: TextStyle(color: AppColors.textPrimary(Brightness.dark)),
              bodySmall: TextStyle(color: AppColors.textSecondary(Brightness.dark)),
              labelLarge: TextStyle(color: AppColors.accentGreen(Brightness.dark)), // Buttons use accent green
            ),
            buttonTheme: ButtonThemeData(
              buttonColor: AppColors.accentGreen(Brightness.dark), // Buttons use accent green
              textTheme: ButtonTextTheme.primary, // Ensures text on button is contrasting
              colorScheme: ColorScheme.dark(
                primary: AppColors.accentGreen(Brightness.dark),
                onPrimary: AppColors.textPrimary(Brightness.dark), // Text on green buttons
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
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accentGreen(Brightness.dark);
                }
                return AppColors.accentGray(Brightness.dark); // Off state
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.switchTrackActive(Brightness.dark); // Uses accentGreen with alpha
                }
                return AppColors.accentGray(Brightness.dark).withAlpha(50); // Off state track
              }),
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: AppColors.surface(Brightness.dark),
              selectedItemColor: AppColors.accentGreen(Brightness.dark), // Selected item is green
              unselectedItemColor: AppColors.iconInactive(Brightness.dark),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppColors.accentGreen(Brightness.dark), // FAB is green
              foregroundColor: AppColors.textPrimary(Brightness.dark),
            ),
          ),
          themeMode: settingsState.themeMode,
          locale: _parseLocale(settingsState.language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MainScreen(),
          navigatorObservers: [
            // Add navigation observer for route logging
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

  static final List<Widget> _widgetOptions = <Widget>[
    TesbihView(),
    QiblaView(),
    HomeView(),
    MosqueView(),
    SettingsView(),
  ];

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

    // Log navigation between tabs
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
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
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
              _buildNavItem(0, Icons.grain, localizations.tasbihLabel),
              _buildNavItem(1, Icons.explore, localizations.qiblaLabel),
              _buildNavItem(2, Icons.schedule, localizations.prayerLabel),
              _buildNavItem(3, Icons.location_on, localizations.mosquesLabel),
              _buildNavItem(4, Icons.more_horiz, localizations.moreLabel),
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
              color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent, // Use theme color
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
