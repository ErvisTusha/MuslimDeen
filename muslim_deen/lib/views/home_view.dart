import 'dart:async';

import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/custom_exceptions.dart';
import 'package:muslim_deen/models/prayer_list_item_data.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/providers/prayer_providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/fasting_service.dart';
import 'package:muslim_deen/services/navigation_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/views/moon_phase_details_view.dart';
import 'package:muslim_deen/views/prayer_stats_view.dart';
import 'package:muslim_deen/views/settings_view.dart';
import 'package:muslim_deen/widgets/common_container_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/loading_error_state_builder.dart';
import 'package:muslim_deen/widgets/prayer_countdown_timer.dart';
import 'package:muslim_deen/widgets/prayer_times_section.dart';
import 'package:muslim_deen/widgets/ramadan_countdown_banner.dart';
import 'package:muslim_deen/widgets/ramadan_fasting_checkbox.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerTimesAsync = ref.watch(prayerTimesProvider);
    final isRamadanAsync = ref.watch(isRamadanProvider);
    final fastingServiceAsync = ref.watch(fastingServiceProvider);
    final appSettings = ref.watch(settingsProvider);
    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);
    final prayerColors = _getPrayerItemColors(colors);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(
        title: "Prayer Times",
        brightness: brightness,
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_2),
            onPressed: () => _navigateToMoonPhases(context),
            tooltip: 'Moon Phase Details',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateToPrayerStats(context),
            tooltip: 'Prayer Statistics',
          ),
        ],
      ),
      body: prayerTimesAsync.when(
        data:
            (prayerTimes) => _buildMainContent(
              isLoading: false,
              prayerTimes: prayerTimes,
              displayCity: "Mecca", // Replace with actual city
              displayCountry: "Saudi Arabia", // Replace with actual country
              appSettings: appSettings,
              colors: colors,
              prayerColors: prayerColors,
              isRamadan: isRamadanAsync.maybeWhen(
                data: (isRamadan) => isRamadan,
                orElse: () => false,
              ),
              fastingService: fastingServiceAsync.value,
              ref: ref,
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          final String errorMessage = _processLoadError(error);
          return LoadingErrorStateBuilder(
            isLoading: false,
            errorMessage: errorMessage,
            onRetry: () => ref.refresh(prayerTimesProvider),
            child: Container(),
          );
        },
      ),
    );
  }

  PrayerItemColors _getPrayerItemColors(UIColors colors) {
    return PrayerItemColors(
      currentPrayerBg:
          colors.isDarkMode
              ? colors.accentColor.withAlpha((0.15 * 255).round())
              : AppColors.primary(
                colors.brightness,
              ).withAlpha((0.1 * 255).round()),
      currentPrayerBorder:
          colors.isDarkMode
              ? colors.accentColor.withAlpha((0.7 * 255).round())
              : AppColors.primary(colors.brightness),
      currentPrayerText:
          colors.isDarkMode
              ? colors.accentColor
              : AppColors.primary(colors.brightness),
    );
  }

  Widget _buildMainContent({
    required bool isLoading,
    required adhan.PrayerTimes? prayerTimes,
    required String? displayCity,
    required String? displayCountry,
    required AppSettings appSettings,
    required UIColors colors,
    required PrayerItemColors prayerColors,
    required bool isRamadan,
    required FastingService? fastingService,
    required WidgetRef ref,
  }) {
    final now = DateTime.now();
    final _gregorianDateFormatter = DateFormat(
      appSettings.dateFormatOption == DateFormatOption.dayMonthYear
          ? 'd MMMM yyyy'
          : appSettings.dateFormatOption == DateFormatOption.monthDayYear
          ? 'MMMM d, yyyy'
          : 'yyyy MMMM d',
      Localizations.localeOf(ref.context).toString(),
    );
    final formattedGregorian = _gregorianDateFormatter.format(now);
    final hijri = HijriCalendar.now();
    final formattedHijri =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';

    final List<PrayerNotification> prayerOrder = [
      PrayerNotification.fajr,
      PrayerNotification.sunrise,
      PrayerNotification.dhuhr,
      PrayerNotification.asr,
      PrayerNotification.maghrib,
      PrayerNotification.isha,
    ];

    return Column(
      children: [
        _buildLocationAndDateSection(
          formattedGregorian,
          formattedHijri,
          displayCity,
          displayCountry,
          colors,
          ref.context,
        ),
        const RamadanCountdownBanner(),
        if (isRamadan)
          RamadanFastingCheckbox(
            fastingService: fastingService,
            isAfterMaghrib: _isAfterMaghrib(ref),
          ),
        _buildCurrentNextPrayerSection(isLoading, colors, ref),
        PrayerTimesSection(
          isLoading: isLoading,
          prayerOrder: prayerOrder,
          colors: colors,
          currentPrayerBg: prayerColors.currentPrayerBg,
          currentPrayerBorder: prayerColors.currentPrayerBorder,
          currentPrayerText: prayerColors.currentPrayerText,
          currentPrayerEnum: _getPrayerNotificationFromAdhanPrayer(
            ref.watch(currentPrayerProvider),
          ),
          timeFormatter: DateFormat(
            appSettings.timeFormat == TimeFormat.twentyFourHour
                ? 'HH:mm'
                : 'hh:mm a',
            Localizations.localeOf(ref.context).toString(),
          ),
          onRefresh: () => ref.refresh(prayerTimesProvider),
          scrollController: ScrollController(),
          getPrayerDisplayInfo:
              (prayerEnum) => _getPrayerDisplayInfo(
                prayerEnum,
                prayerTimes,
                appSettings,
                ref,
              ),
        ),
      ],
    );
  }

  Widget _buildLocationAndDateSection(
    String formattedGregorian,
    String formattedHijri,
    String? displayCity,
    String? displayCountry,
    UIColors colors,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: () => _navigateToSettings(context, scrollToDate: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedGregorian,
                  style: AppTextStyles.date(
                    colors.brightness,
                  ).copyWith(fontSize: 15),
                ),
                Text(
                  formattedHijri,
                  style: AppTextStyles.dateSecondary(
                    colors.brightness,
                  ).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            child: GestureDetector(
              onDoubleTap:
                  () => _navigateToSettings(context, scrollToLocation: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (displayCity?.isNotEmpty == true)
                    Text(
                      displayCity!,
                      style: AppTextStyles.locationCity(colors.brightness),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  if (displayCountry?.isNotEmpty == true)
                    Text(
                      displayCountry!,
                      style: AppTextStyles.locationCountry(colors.brightness),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentNextPrayerSection(
    bool isLoading,
    UIColors colors,
    WidgetRef ref,
  ) {
    final currentPrayer = ref.watch(currentPrayerProvider);
    final nextPrayer = ref.watch(nextPrayerProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: CommonContainerStyles.cardDecoration(colors),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Current Prayer",
                  style: AppTextStyles.label(
                    colors.brightness,
                  ).copyWith(color: colors.textColorSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '...' : currentPrayer,
                  style: AppTextStyles.currentPrayer(
                    colors.brightness,
                  ).copyWith(color: colors.textColorPrimary, fontSize: 26),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Next Prayer",
                  style: AppTextStyles.label(
                    colors.brightness,
                  ).copyWith(color: colors.textColorSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '...' : nextPrayer,
                  style: AppTextStyles.nextPrayer(
                    colors.brightness,
                  ).copyWith(color: colors.accentColor, fontSize: 26),
                ),
                Builder(
                  builder: (context) {
                    final prayerTimes = ref.watch(prayerTimesProvider);
                    final nextPrayerTime = prayerTimes.when(
                      data:
                          (times) =>
                              locator<PrayerService>().getNextPrayerTime(),
                      loading: () => Future.value(null),
                      error: (error, stackTrace) => Future.value(null),
                    );

                    return FutureBuilder<DateTime?>(
                      future: nextPrayerTime,
                      builder: (context, snapshot) {
                        Duration initialCountdownDuration = Duration.zero;
                        if (!isLoading &&
                            snapshot.hasData &&
                            snapshot.data != null) {
                          final now = DateTime.now();
                          if (snapshot.data!.isAfter(now)) {
                            initialCountdownDuration = snapshot.data!
                                .difference(now);
                          }
                        }
                        return PrayerCountdownTimer(
                          initialDuration:
                              isLoading
                                  ? Duration.zero
                                  : initialCountdownDuration,
                          textStyle: AppTextStyles.countdownTimer(
                            colors.brightness,
                          ).copyWith(color: colors.accentColor),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings(
    BuildContext context, {
    bool scrollToDate = false,
    bool scrollToLocation = false,
  }) {
    locator<NavigationService>()
        .navigateTo<void>(
          SettingsView(
            scrollToDate: scrollToDate,
            scrollToLocation: scrollToLocation,
          ),
          routeName: '/settings',
        )
        .then((_) {
          // Since we are using providers, the UI will update automatically.
        });
  }

  void _navigateToPrayerStats(BuildContext context) {
    locator<NavigationService>().navigateTo<void>(
      const PrayerStatsView(),
      routeName: '/prayer-stats',
    );
  }

  void _navigateToMoonPhases(BuildContext context) {
    locator<NavigationService>().navigateTo<MoonPhaseDetailsView>(
      MoonPhaseDetailsView(),
      routeName: '/moon-phases',
    );
  }

  String _processLoadError(Object? error) {
    String specificError =
        'Failed to load prayer times. Please check connection and location settings.';
    if (error is PrayerDataException) {
      specificError = error.message;
    } else if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('Location services are disabled')) {
        specificError =
            'Location services are disabled. Please enable them in your device settings.';
      } else if (errorString.contains('Location permissions are denied')) {
        specificError =
            'Location permission denied. Please grant permission to show prayer times.';
      } else if (errorString.contains('permanently denied')) {
        specificError =
            'Location permission permanently denied. Please enable it in app settings.';
      } else if (errorString.contains('Could not determine location')) {
        specificError =
            'Could not determine your location. Please ensure location services are enabled and permissions granted.';
      } else if (errorString.contains('StorageService not initialized')) {
        specificError = 'Initialization error. Please restart the app.';
      }
    } else if (error != null) {
      specificError = 'An unexpected error occurred: ${error.toString()}';
    }
    return specificError;
  }

  PrayerListItemData _getPrayerDisplayInfo(
    PrayerNotification prayerEnum,
    adhan.PrayerTimes? prayerTimes,
    AppSettings appSettings, // Added appSettings parameter
    WidgetRef ref,
  ) {
    // Ensure prayerTimes is not null before calling getOffsettedPrayerTime
    if (prayerTimes == null) {
      // Return a default or error state
      String prayerNameStr = prayerEnum.toString().split('.').last;
      prayerNameStr =
          prayerNameStr[0].toUpperCase() + prayerNameStr.substring(1);
      return PrayerListItemData(
        name: prayerNameStr,
        time: null,
        prayerEnum: prayerEnum,
        iconData: Icons.error_outline, // Default error icon
      );
    }

    // Get prayer details from helper method
    final prayerDetails = _getPrayerDetails(prayerEnum);

    // Get offsetted time
    final time = locator<PrayerService>().getOffsettedPrayerTimeSync(
      prayerDetails.prayerName,
      prayerTimes,
      appSettings,
    );

    return PrayerListItemData(
      name: prayerDetails.displayName,
      time: time,
      prayerEnum: prayerEnum,
      iconData: prayerDetails.icon,
    );
  }

  bool _isAfterMaghrib(WidgetRef ref) {
    final prayerTimes = ref.watch(prayerTimesProvider);
    return prayerTimes.when(
      data: (times) {
        if (times.maghrib == null) return false;
        final now = DateTime.now();
        final maghribTime = times.maghrib!;
        final nowTime = DateTime(0, 0, 0, now.hour, now.minute);
        final maghribDateTime = DateTime(
          0,
          0,
          0,
          maghribTime.hour,
          maghribTime.minute,
        );
        return nowTime.isAfter(maghribDateTime);
      },
      loading: () => false,
      error: (error, stackTrace) => false,
    );
  }

  _PrayerDetails _getPrayerDetails(PrayerNotification prayerEnum) {
    switch (prayerEnum) {
      case PrayerNotification.fajr:
        return const _PrayerDetails(
          prayerName: "fajr",
          displayName: "Fajr",
          icon: Icons.wb_sunny_outlined,
        );
      case PrayerNotification.sunrise:
        return const _PrayerDetails(
          prayerName: "sunrise",
          displayName: "Sunrise",
          icon: Icons.wb_twilight_outlined,
        );
      case PrayerNotification.dhuhr:
        return const _PrayerDetails(
          prayerName: "dhuhr",
          displayName: "Dhuhr",
          icon: Icons.wb_sunny,
        );
      case PrayerNotification.asr:
        return const _PrayerDetails(
          prayerName: "asr",
          displayName: "Asr",
          icon: Icons.wb_twilight,
        );
      case PrayerNotification.maghrib:
        return const _PrayerDetails(
          prayerName: "maghrib",
          displayName: "Maghrib",
          icon: Icons.brightness_4_outlined,
        );
      case PrayerNotification.isha:
        return const _PrayerDetails(
          prayerName: "isha",
          displayName: "Isha",
          icon: Icons.nights_stay,
        );
    }
  }

  PrayerNotification? _getPrayerNotificationFromAdhanPrayer(
    String adhanPrayer,
  ) {
    if (adhanPrayer == adhan.Prayer.fajr) return PrayerNotification.fajr;
    if (adhanPrayer == adhan.Prayer.sunrise) return PrayerNotification.sunrise;
    if (adhanPrayer == adhan.Prayer.dhuhr) return PrayerNotification.dhuhr;
    if (adhanPrayer == adhan.Prayer.asr) return PrayerNotification.asr;
    if (adhanPrayer == adhan.Prayer.maghrib) return PrayerNotification.maghrib;
    if (adhanPrayer == adhan.Prayer.isha) return PrayerNotification.isha;
    return null;
  }
}

class _PrayerDetails {
  final String prayerName;
  final String displayName;
  final IconData icon;

  const _PrayerDetails({
    required this.prayerName,
    required this.displayName,
    required this.icon,
  });
}

class PrayerItemColors {
  final Color currentPrayerBg;
  final Color currentPrayerBorder;
  final Color currentPrayerText;

  PrayerItemColors({
    required this.currentPrayerBg,
    required this.currentPrayerBorder,
    required this.currentPrayerText,
  });
}
