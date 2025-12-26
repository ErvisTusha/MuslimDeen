import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muslim_deen/config/app_localization_config.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/styles/app_themes.dart';
import 'package:muslim_deen/views/main_view.dart';
import 'package:muslim_deen/widgets/navigation_observer.dart';

class MuslimDeenApp extends ConsumerWidget {
  const MuslimDeenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Muslim Deen',
      theme: AppThemes.buildLightTheme(),
      darkTheme: AppThemes.buildDarkTheme(),
      themeMode: settings.themeMode,
      locale: AppLocalizationConfig.getLocaleFromSettings(settings.language),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizationConfig.supportedLocales,
      navigatorKey: locator<NavigationService>().navigatorKey,
      navigatorObservers: [AppNavigationObserver()],
      home: const MainScreen(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: Directionality(
            textDirection: AppLocalizationConfig.getTextDirection(
              Localizations.localeOf(context),
            ),
            child: child!,
          ),
        );
      },
    );
  }
}
