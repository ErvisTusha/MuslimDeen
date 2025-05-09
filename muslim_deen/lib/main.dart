import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'l10n/app_localizations.dart';
import 'providers/settings_provider.dart';
import 'service_locator.dart';
import 'services/logger_service.dart';
import 'views/home_view.dart';
import 'views/mosque_view.dart';
import 'views/qibla_view.dart';
import 'views/settings_view.dart';
import 'views/tesbih_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await setupLocator();
  runApp(const MuslimDeenApp());
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

    return ChangeNotifierProvider(
      create: (context) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder:
            (context, settings, _) => MaterialApp(
              onGenerateTitle:
                  (context) => AppLocalizations.of(context)!.appTitle,
              theme: ThemeData(
                primarySwatch: Colors.green,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              darkTheme: ThemeData(
                brightness: Brightness.dark,
                primarySwatch: Colors.green,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              themeMode: settings.settings.themeMode,
              locale: _parseLocale(settings.settings.language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const MainScreen(),
              navigatorObservers: [
                // Add navigation observer for route logging
                _NavigationObserver(),
              ],
            ),
      ),
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

  static const List<Widget> _widgetOptions = <Widget>[
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
              color: isSelected ? Colors.green.shade100 : Colors.transparent,
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
