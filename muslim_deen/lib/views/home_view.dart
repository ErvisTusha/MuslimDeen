import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/models/custom_exceptions.dart';
import 'package:muslim_deen/models/prayer_display_info_data.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/views/settings_view.dart';
import 'package:muslim_deen/widgets/common_container_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/loading_error_state_builder.dart';
import 'package:muslim_deen/widgets/prayer_countdown_timer.dart';
import 'package:muslim_deen/widgets/prayer_list_item.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView>
    with WidgetsBindingObserver {
  final LocationService _locationService = locator<LocationService>();
  final PrayerService _prayerService = locator<PrayerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();
  final LoggerService _logger = locator<LoggerService>();
  final ScrollController _scrollController = ScrollController();
  static const double _prayerItemHeight = 80.0;
  Timer? _dailyRefreshTimer;
  ProviderSubscription? _settingsListenerSubscription; // Added for listenManual
  String? _lastKnownCity; // Store last known location details for loading state
  String?
  _lastKnownCountry; // Note: Loading/error states are managed through FutureBuilder

  bool _isUiFetchInProgress = false; // Flag for UI-triggered fetches

  // Cached DateFormat instances
  late DateFormat _gregorianDateFormatter;
  late DateFormat _timeFormatter;
  AppSettings? _cachedSettingsForFormatters;
  Locale? _cachedLocaleForFormatters;

  adhan.PrayerTimes? _prayerTimes;
  String _nextPrayerName = '';
  String _currentPrayerName = '';
  PrayerNotification? _currentPrayerEnum;
  DateTime? _nextPrayerDateTime; // Stores the time of the next prayer
  late Future<Map<String, dynamic>> _dataLoadingFuture;

  @override
  void initState() {
    super.initState();
    _logger.info('HomeView initialized');
    WidgetsBinding.instance.addObserver(this);

    // Initial data load and scheduling
    _dataLoadingFuture = _fetchDataAndScheduleNotifications();

    // Initial permission check
    ref.read(settingsProvider.notifier).refreshNotificationPermissionStatus();

    // Listen to settings changes using Riverpod with listenManual
    _settingsListenerSubscription = ref.listenManual<AppSettings>(
      settingsProvider,
      (previous, next) {
        _logger.debug(
          'Settings changed (via ref.listenManual in initState)',
          data: {
            'newSettings': next.toJson(),
            'previousSettings': previous?.toJson(),
          },
        );
        _handleSettingsChange(next, previous);
      },
    );

    // Start daily refresh timer
    _startDailyRefreshTimer();
  }

  void _initOrUpdateDateFormatters(AppSettings settings, Locale locale) {
    if (_cachedSettingsForFormatters == null ||
        _cachedLocaleForFormatters == null ||
        _cachedSettingsForFormatters!.dateFormatOption !=
            settings.dateFormatOption ||
        _cachedSettingsForFormatters!.timeFormat != settings.timeFormat ||
        _cachedLocaleForFormatters != locale) {
      final gregorianDatePattern =
          settings.dateFormatOption == DateFormatOption.dayMonthYear
              ? 'd MMMM yyyy'
              : settings.dateFormatOption == DateFormatOption.monthDayYear
              ? 'MMMM d, yyyy'
              : 'yyyy MMMM d';
      _gregorianDateFormatter = DateFormat(
        gregorianDatePattern,
        locale.toString(),
      );

      _timeFormatter = DateFormat(
        settings.timeFormat == TimeFormat.twentyFourHour ? 'HH:mm' : 'hh:mm a',
        locale.toString(),
      );
      _cachedSettingsForFormatters = settings;
      _cachedLocaleForFormatters = locale;
      _logger.debug("DateFormatters updated.");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ref.read(settingsProvider);
    final locale = Localizations.localeOf(context);
    _initOrUpdateDateFormatters(settings, locale);
  }

  @override
  void dispose() {
    _logger.debug('HomeView dispose started');
    WidgetsBinding.instance.removeObserver(this); // Remove observer

    // First, stop any active timers to prevent new location/notification requests
    _dailyRefreshTimer?.cancel();
    _settingsListenerSubscription?.close(); // Dispose of the settings listener

    // Clear UI-related state immediately
    _prayerTimes = null;
    _nextPrayerDateTime = null;

    // Cancel notifications before cleaning up services
    // This ensures no new notifications are scheduled during cleanup
    _notificationService.cancelAllNotifications().then((_) {
      _logger.debug('Notifications cancelled during dispose');
    });

    // Clean up location service first to stop any active location streams
    // This addresses the Geolocator foreground service issue
    _locationService.dispose();

    // Note: Removed recalculatePrayerTimesIfNeeded call from dispose
    // as it's unnecessary during widget cleanup and causes ref access after disposal

    // Clean up UI controllers last
    _scrollController.dispose();

    super.dispose();

    _logger.info('HomeView cleanup completed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _logger.info("App resumed, checking notification permissions.");
      if (mounted) {
        ref
            .read(settingsProvider.notifier)
            .refreshNotificationPermissionStatus();
      }
    }
  }

  /// Starts a timer to refresh prayer times daily around midnight.
  void _startDailyRefreshTimer() {
    _dailyRefreshTimer?.cancel();

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    // Schedule the first refresh at midnight
    _dailyRefreshTimer = Timer(durationUntilMidnight, () {
      _logger.info("Daily refresh triggered at midnight.");
      if (mounted) {
        setState(() {
          _dataLoadingFuture = _fetchDataAndScheduleNotifications();
        });
        _dailyRefreshTimer = Timer.periodic(const Duration(days: 1), (timer) {
          _logger.info("Daily refresh triggered (periodic).");
          if (mounted) {
            setState(() {
              _dataLoadingFuture = _fetchDataAndScheduleNotifications();
            });
          } else {
            timer.cancel();
          }
        });
      }
    });
    _logger.info(
      "Scheduled next daily refresh",
      data: {'durationUntilMidnight': durationUntilMidnight.toString()},
    );
  }

  /// Handles changes detected by the SettingsProvider listener.
  void _handleSettingsChange(
    AppSettings newSettings,
    AppSettings? oldSettings,
  ) {
    _logger.debug(
      'Settings changed in HomeView',
      data: {
        'newSettings': newSettings.toJson(),
        'oldSettings': oldSettings?.toJson(),
      },
    );
    // No need to check _prayerTimes == null here, rescheduling only happens if it's not null anyway.
    if (!mounted || oldSettings == null) return;

    bool needsReschedule = false;
    bool needsReload = false;

    // Check relevant settings for changes that require reloading prayer times
    if (newSettings.calculationMethod != oldSettings.calculationMethod ||
        newSettings.madhab != oldSettings.madhab) {
      needsReload = true;
      needsReschedule = true; // Reload implies reschedule
      _logger.info(
        "Calculation method or Madhab change detected, reloading data...",
        data: {
          'oldMethod': oldSettings.calculationMethod,
          'newMethod': newSettings.calculationMethod,
          'oldMadhab': oldSettings.madhab,
          'newMadhab': newSettings.madhab,
        },
      );
    }
    // Check for changes that only require rescheduling notifications
    else if (!mapEquals(newSettings.notifications, oldSettings.notifications)) {
      needsReschedule = true;
      _logger.info(
        "Notification settings change detected, rescheduling notifications...",
        data: {
          'oldNotifications': oldSettings.notifications.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
          'newNotifications': newSettings.notifications.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        },
      );
    }

    if (needsReload) {
      // Trigger data reload, which will then reschedule notifications upon completion
      setState(() {
        _dataLoadingFuture = _fetchDataAndScheduleNotifications();
      });
    } else if (needsReschedule && _prayerTimes != null) {
      // Only reschedule if prayer times are available
      // Only notification toggles changed, just reschedule with current prayer times
      _scheduleAllPrayerNotifications(context, _prayerTimes!);
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

  /// Updates the current/next prayer names and scrolls to the current prayer.
  /// The countdown timer is handled separately by PrayerCountdownTimer.
  void _updatePrayerTimingsDisplay() {
    // No need to call this every second anymore.
    // It will be called once when data loads and potentially when prayer changes.
    final currentPrayerTimes = _prayerTimes;
    if (currentPrayerTimes == null) return;

    try {
      final currentPrayerStr = _prayerService.getCurrentPrayer();
      final nextPrayerStr = _prayerService.getNextPrayer();

      final newCurrentPrayerEnum = _getPrayerNotificationFromAdhanPrayer(
        currentPrayerStr,
      );
      final newNextPrayerEnum = _getPrayerNotificationFromAdhanPrayer(
        nextPrayerStr,
      );

      // AppSettings needed for _getPrayerDisplayInfo for offsets
      final appSettings = ref.read(settingsProvider);

      String currentPrayerDisplayName = '---';
      if (newCurrentPrayerEnum != null && _prayerTimes != null) {
        currentPrayerDisplayName =
            _getPrayerDisplayInfo(
              newCurrentPrayerEnum,
              _prayerTimes!,
              appSettings,
            ).name;
      } else if (newCurrentPrayerEnum != null) {
        currentPrayerDisplayName =
            newCurrentPrayerEnum.toString().split('.').last;
        _logger.warning(
          "_prayerTimes was null in _updatePrayerTimingsDisplay for current prayer, using enum name.",
        );
      }

      String nextPrayerDisplayName = '---';
      if (newNextPrayerEnum != null && _prayerTimes != null) {
        nextPrayerDisplayName =
            _getPrayerDisplayInfo(
              newNextPrayerEnum,
              _prayerTimes!,
              appSettings,
            ).name;
      } else if (newNextPrayerEnum != null) {
        nextPrayerDisplayName = newNextPrayerEnum.toString().split('.').last;
        _logger.warning(
          "_prayerTimes was null in _updatePrayerTimingsDisplay for next prayer, using enum name.",
        );
      }

      if (mounted) {
        final bool currentPrayerChanged =
            _currentPrayerEnum != newCurrentPrayerEnum;

        setState(() {
          _currentPrayerEnum = newCurrentPrayerEnum;
          _currentPrayerName = currentPrayerDisplayName;
          _nextPrayerName = nextPrayerDisplayName;
        });

        if (currentPrayerChanged && _currentPrayerEnum != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _scrollToPrayer(_currentPrayerEnum);
            }
          });
        }
      }
    } catch (e, s) {
      _logger.error(
        "Error updating prayer timings display",
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      if (mounted) {
        setState(() {
          _currentPrayerEnum = null;
          _currentPrayerName = 'Error';
          _nextPrayerName = 'Error';
        });
      }
    }
  }

  /// Scrolls the list view to the specified prayer item.
  void _scrollToPrayer(PrayerNotification? prayerEnum) {
    if (prayerEnum == null) {
      _logger.warning("Cannot scroll, prayerEnum is null.");
      return;
    }

    final List<PrayerNotification> prayerOrder = [
      PrayerNotification.fajr,
      PrayerNotification.sunrise,
      PrayerNotification.dhuhr,
      PrayerNotification.asr,
      PrayerNotification.maghrib,
      PrayerNotification.isha,
    ];
    final index = prayerOrder.indexOf(prayerEnum);

    if (index != -1 && _scrollController.hasClients) {
      final offset = index * _prayerItemHeight;
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _logger.debug(
        "Scrolling to prayer",
        data: {
          'prayerEnum': prayerEnum.toString(),
          'index': index,
          'offset': offset,
        },
      );
    } else {
      _logger.warning(
        "Could not scroll to prayer",
        data: {
          'prayerEnum': prayerEnum.toString(),
          'index': index,
          'hasClients': _scrollController.hasClients,
        },
      );
    }
  }

  /// Attempts to parse a location string into city and country components.
  /// Handles formats like "City, Country", "City", "Lat, Lon".
  Map<String, String?> _parseLocationName(String? locationName) {
    String? city;
    String? country;

    if (locationName == null || locationName.trim().isEmpty) {
      return {'city': 'Unknown', 'country': null};
    }

    locationName = locationName.trim();

    final coordRegex = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    if (coordRegex.hasMatch(locationName)) {
      return {'city': 'Current Location', 'country': null};
    } else if (locationName.contains(',')) {
      final parts = locationName.split(',');
      city = parts[0].trim();
      country = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

      if (city.isEmpty) {
        city = country ?? 'Unknown';
        country = null;
      }
    } else {
      city = locationName;
      country = null;
    }

    if (city.isEmpty) {
      city = 'Unknown';
    }

    return {'city': city, 'country': country};
  }

  /// Fetches location, calculates prayer times, and schedules notifications.
  /// This is the main function called on init, retry, and settings change.
  Future<Map<String, dynamic>> _fetchDataAndScheduleNotifications() async {
    _logger.info('Starting _fetchDataAndScheduleNotifications...');
    try {
      Position? position;
      String? locationNameToUse;

      final isUsingManualLocation = _locationService.isUsingManualLocation();

      if (isUsingManualLocation) {
        position = await _locationService.getLocation();
        locationNameToUse = await _locationService.getStoredLocationName();
        _logger.info(
          "Using manually set location",
          data: {'locationName': locationNameToUse},
        );
      } else {
        try {
          position = await _locationService.getLocation();
          await _locationService.cacheAsLastKnownPosition(position);
          _logger.info(
            "Fetched current device location",
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );

          try {
            final List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              final String? city =
                  placemark.locality?.isNotEmpty == true
                      ? placemark.locality
                      : placemark.subAdministrativeArea?.isNotEmpty == true
                      ? placemark.subAdministrativeArea
                      : placemark.administrativeArea;
              final String? country = placemark.country;
              _logger.info(
                "Geocoding successful",
                data: {'city': city, 'country': country},
              );

              if (city != null && city.isNotEmpty) {
                locationNameToUse =
                    country != null && country.isNotEmpty
                        ? '$city, $country'
                        : city;
              } else if (country != null && country.isNotEmpty) {
                locationNameToUse = country;
              } else {
                locationNameToUse =
                    '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
              }
              // Removed direct StorageService.saveLocation call
              // locator<StorageService>().saveLocation(
              //   position.latitude,
              //   position.longitude,
              //   locationName: locationNameToUse,
              // );
              _logger.info(
                "Device location geocoded", // Updated log message
                data: {'locationName': locationNameToUse},
              );
            } else {
              locationNameToUse =
                  '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
            }
            // Removed direct StorageService.saveLocation call
            // locator<StorageService>().saveLocation(
            //   position.latitude,
            //   position.longitude,
            //   locationName: locationNameToUse,
            // );
          } catch (e, s) {
            _logger.warning(
              'Geocoding error, falling back to coordinates',
              data: {'error': e.toString(), 'stackTrace': s.toString()},
            );
            locationNameToUse =
                '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
            // Removed direct StorageService.saveLocation call
            // locator<StorageService>().saveLocation(
            //   position.latitude,
            //   position.longitude,
            //   locationName: locationNameToUse,
            // );
          }
        } catch (e, s) {
          _logger.error(
            "Failed to get device location even after LocationService fallbacks.",
            data: {'error': e.toString(), 'stackTrace': s.toString()},
          );
          // Re-throw the exception or a new one to indicate failure to the FutureBuilder
          throw Exception(
            'Could not determine device location. Please check permissions and network. Error: ${e.toString()}',
          );
        }
      }

      final displayNames = _parseLocationName(locationNameToUse);
      final displayCity = displayNames['city'];
      final displayCountry = displayNames['country'];

      if (mounted) {
        setState(() {
          _lastKnownCity = displayCity;
          _lastKnownCountry = displayCountry;
        });
      }

      String? logSettingsJson;
      if (mounted) {
        try {
          final currentSettings = ref.read(settingsProvider);
          logSettingsJson = jsonEncode(currentSettings.toJson());
        } catch (e, s) {
          _logger.warning(
            'Could not read settings for logging in _fetchDataAndScheduleNotifications',
            data: {'error': e.toString(), 'stackTrace': s.toString()},
          );
          logSettingsJson = 'Error_retrieving_settings_for_log';
        }
      } else {
        logSettingsJson = 'context_not_mounted';
      }

      _logger.info(
        "Calculating prayer times for position",
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'settings_json': logSettingsJson,
        },
      );

      if (!mounted) return {};
      final settings = ref.read(settingsProvider);

      final adhan.PrayerTimes? calculatedPrayerTimes = await _prayerService
          .calculatePrayerTimesForToday(settings);

      if (calculatedPrayerTimes == null) {
        _logger.error(
          'Prayer times calculation returned null in HomeView',
          data: {'settings': settings.toJson()},
        );
        throw Exception('Failed to calculate prayer times: Result was null.');
      }

      _logger.info(
        "Prayer times calculated successfully",
        data: {
          'fajr': calculatedPrayerTimes.fajr?.toIso8601String(),
          'sunrise': calculatedPrayerTimes.sunrise?.toIso8601String(),
          'dhuhr': calculatedPrayerTimes.dhuhr?.toIso8601String(),
          'asr': calculatedPrayerTimes.asr?.toIso8601String(),
          'maghrib': calculatedPrayerTimes.maghrib?.toIso8601String(),
          'isha': calculatedPrayerTimes.isha?.toIso8601String(),
        },
      );

      final DateTime? nextPrayerTime = await _prayerService.getNextPrayerTime();

      _prayerTimes = calculatedPrayerTimes;
      _nextPrayerDateTime = nextPrayerTime;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleAllPrayerNotifications(context, calculatedPrayerTimes);
          _updatePrayerTimingsDisplay();

          if (_currentPrayerEnum != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _scrollToPrayer(_currentPrayerEnum);
            });
          }
        }
      });

      return {
        'prayerTimes': calculatedPrayerTimes,
        'displayCity': displayCity,
        'displayCountry': displayCountry,
        'position': position,
        'locationName': locationNameToUse,
        'nextPrayerTime': nextPrayerTime,
      };
    } on Exception catch (e, s) {
      _logger.error(
        'Error in _fetchDataAndScheduleNotifications',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      _prayerTimes = null;
      _nextPrayerDateTime = null;
      rethrow;
    }
  }

  String _processLoadError(Object? error) {
    _logger.error(
      'FutureBuilder caught error',
      data: {'error': error.toString()},
    );
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

  /// Schedules notifications for all prayer times based on current settings.
  /// Cancels existing notifications before scheduling new ones.
  Future<void> _scheduleAllPrayerNotifications(
    BuildContext context,
    adhan.PrayerTimes prayerTimes,
  ) async {
    // Read settings before checking mounted to avoid ref access after disposal
    final appSettings = ref.read(settingsProvider);

    if (!mounted) return;

    _logger.info("Scheduling/Rescheduling notifications...");

    await _notificationService.cancelAllNotifications();

    for (var prayerEnum in PrayerNotification.values) {
      final prayerInfo = _getPrayerDisplayInfo(
        prayerEnum,
        prayerTimes,
        appSettings,
      );
      final bool isEnabled = appSettings.notifications[prayerEnum] ?? false;

      if (prayerInfo.time != null && isEnabled) {
        await _notificationService.schedulePrayerNotification(
          id: prayerEnum.index,
          localizedTitle: "Prayer Time: ${prayerInfo.name}",
          localizedBody: "It's time for ${prayerInfo.name} prayer.",
          prayerTime: prayerInfo.time!,
          isEnabled: true,
          appSettings: appSettings,
        );
      }
    }
    _logger.info("Finished scheduling/rescheduling notifications.");
  }

  PrayerDisplayInfoData _getPrayerDisplayInfo(
    PrayerNotification prayerEnum,
    adhan.PrayerTimes? prayerTimes,
    AppSettings appSettings, // Added appSettings parameter
  ) {
    DateTime? time;
    String name;
    IconData icon;

    // Ensure prayerTimes is not null before calling getOffsettedPrayerTime
    if (prayerTimes == null) {
      _logger.debug(
        "_getPrayerDisplayInfo called with null prayerTimes for $prayerEnum",
      );
      // Return a default or error state
      String prayerNameStr = prayerEnum.toString().split('.').last;
      prayerNameStr =
          prayerNameStr[0].toUpperCase() + prayerNameStr.substring(1);
      return PrayerDisplayInfoData(
        name: prayerNameStr,
        time: null,
        prayerEnum: prayerEnum,
        iconData: Icons.error_outline, // Default error icon
      );
    }

    switch (prayerEnum) {
      case PrayerNotification.fajr:
        name = "Fajr";
        icon = Icons.wb_sunny_outlined; // Dawn/Sunrise icon
        time = _prayerService.getOffsettedPrayerTime(
          "fajr",
          prayerTimes,
          appSettings,
        );
        break;
      case PrayerNotification.sunrise:
        name = "Sunrise";
        icon = Icons.wb_twilight_outlined; // Sunrise icon
        time = _prayerService.getOffsettedPrayerTime(
          "sunrise",
          prayerTimes,
          appSettings,
        );
        break;
      case PrayerNotification.dhuhr:
        name = "Dhuhr";
        icon = Icons.wb_sunny; // Midday sun
        time = _prayerService.getOffsettedPrayerTime(
          "dhuhr",
          prayerTimes,
          appSettings,
        );
        break;
      case PrayerNotification.asr:
        name = "Asr";
        icon = Icons.wb_twilight; // Afternoon/twilight
        time = _prayerService.getOffsettedPrayerTime(
          "asr",
          prayerTimes,
          appSettings,
        );
        break;
      case PrayerNotification.maghrib:
        name = "Maghrib";
        icon = Icons.brightness_4_outlined; // Sunset icon
        time = _prayerService.getOffsettedPrayerTime(
          "maghrib",
          prayerTimes,
          appSettings,
        );
        break;
      case PrayerNotification.isha:
        name = "Isha";
        icon = Icons.nights_stay; // Moon/night icon
        time = _prayerService.getOffsettedPrayerTime(
          "isha",
          prayerTimes,
          appSettings,
        );
        break;
    }
    return PrayerDisplayInfoData(
      name: name,
      time: time,
      prayerEnum: prayerEnum,
      iconData: icon,
    );
  }

  /// Handles the logic for refreshing UI data, typically after returning from settings.
  void _triggerUIRefresh({bool clearLocationCache = false}) {
    if (_isUiFetchInProgress) {
      _logger.info("UI fetch already in progress, refresh skipped.");
      return;
    }
    _logger.info("UI refresh triggered.");
    setState(() {
      _isUiFetchInProgress = true;
      if (clearLocationCache) {
        _prayerTimes = null;
        _lastKnownCity = null;
        _lastKnownCountry = null;
      }
      _dataLoadingFuture = _fetchDataAndScheduleNotifications().whenComplete(
        () {
          if (mounted) {
            _isUiFetchInProgress = false;
          } else {
            _isUiFetchInProgress =
                false; // Ensure it's reset even if not mounted
          }
          _logger.debug("_isUiFetchInProgress reset after UI refresh fetch.");
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild on any settings change
    final appSettings = ref.watch(settingsProvider);
    final locale = Localizations.localeOf(context);
    _initOrUpdateDateFormatters(appSettings, locale); // Update formatters

    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);

    // Prayer-specific colors
    final prayerColors = _getPrayerItemColors(colors);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(title: "Prayer Times", brightness: brightness),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildMainContent(
              isLoading: true,
              prayerTimes: _prayerTimes,
              displayCity: _lastKnownCity ?? "Loading...",
              displayCountry: _lastKnownCountry,
              appSettings: appSettings,
              colors: colors,
              prayerColors: prayerColors,
            );
          } else if (snapshot.hasError) {
            final String errorMessage = _processLoadError(snapshot.error);
            return LoadingErrorStateBuilder(
              isLoading: false,
              errorMessage: errorMessage,
              onRetry: _triggerUIRefresh,
              child: Container(), // This won't be shown due to error
            );
          } else if (snapshot.hasData) {
            final snapshotData = snapshot.data!;
            final loadedCity = snapshotData['displayCity'] as String?;
            final loadedCountry = snapshotData['displayCountry'] as String?;

            return _buildMainContent(
              isLoading: false,
              prayerTimes: _prayerTimes!,
              displayCity: loadedCity,
              displayCountry: loadedCountry,
              appSettings: appSettings,
              colors: colors,
              prayerColors: prayerColors,
            );
          } else {
            return LoadingErrorStateBuilder(
              isLoading: false,
              errorMessage: "An unexpected error occurred.",
              onRetry: _triggerUIRefresh,
              child: Container(), // This won't be shown due to error
            );
          }
        },
      ),
    );
  }

  /// Creates prayer-specific colors
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

  /// Builds the main content of the Scaffold body.
  Widget _buildMainContent({
    required bool isLoading,
    required adhan.PrayerTimes? prayerTimes,
    required String? displayCity,
    required String? displayCountry,
    required AppSettings appSettings,
    required UIColors colors,
    required PrayerItemColors prayerColors,
  }) {
    final now = DateTime.now();
    // Use cached formatters
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
        ),
        _buildCurrentNextPrayerSection(isLoading, colors),
        _buildPrayerTimesSection(
          isLoading,
          prayerTimes,
          prayerOrder,
          appSettings,
          colors,
          prayerColors,
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
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: () => _navigateToSettings(scrollToDate: true),
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
              onDoubleTap: () => _navigateToSettings(scrollToLocation: true),
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

  Widget _buildCurrentNextPrayerSection(bool isLoading, UIColors colors) {
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
                  isLoading ? '...' : _currentPrayerName,
                  style: AppTextStyles.currentPrayer(
                    colors.brightness,
                  ).copyWith(color: colors.textColorPrimary),
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
                  isLoading ? '...' : _nextPrayerName,
                  style: AppTextStyles.nextPrayer(
                    colors.brightness,
                  ).copyWith(color: colors.accentColor),
                ),
                Builder(
                  builder: (context) {
                    Duration initialCountdownDuration = Duration.zero;
                    if (!isLoading && _nextPrayerDateTime != null) {
                      final now = DateTime.now();
                      if (_nextPrayerDateTime!.isAfter(now)) {
                        initialCountdownDuration = _nextPrayerDateTime!
                            .difference(now);
                      }
                    }
                    return PrayerCountdownTimer(
                      initialDuration:
                          isLoading ? Duration.zero : initialCountdownDuration,
                      textStyle: AppTextStyles.countdownTimer(
                        colors.brightness,
                      ).copyWith(color: colors.accentColor),
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

  Widget _buildPrayerTimesSection(
    bool isLoading,
    adhan.PrayerTimes? prayerTimes,
    List<PrayerNotification> prayerOrder,
    AppSettings appSettings,
    UIColors colors,
    PrayerItemColors prayerColors,
  ) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Prayer Times",
                style: AppTextStyles.sectionTitle(
                  colors.brightness,
                ).copyWith(color: colors.textColorPrimary),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: _buildPrayerListDecoration(colors),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: prayerOrder.length,
                      separatorBuilder:
                          (context, index) => Divider(
                            color: colors.borderColor.withAlpha(
                              colors.isDarkMode ? 70 : 100,
                            ),
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                      itemBuilder: (context, index) {
                        final prayerEnum = prayerOrder[index];
                        final prayerInfo = _getPrayerDisplayInfo(
                          prayerEnum,
                          prayerTimes,
                          appSettings,
                        );

                        final bool isCurrent =
                            !isLoading &&
                            _currentPrayerEnum == prayerInfo.prayerEnum;

                        return PrayerListItem(
                          prayerInfo: prayerInfo,
                          timeFormatter: _timeFormatter,
                          isCurrent: isCurrent,
                          brightness: colors.brightness,
                          contentSurfaceColor: colors.contentSurface,
                          currentPrayerItemBgColor:
                              prayerColors.currentPrayerBg,
                          currentPrayerItemBorderColor:
                              prayerColors.currentPrayerBorder,
                          currentPrayerItemTextColor:
                              prayerColors.currentPrayerText,
                          onRefresh: _triggerUIRefresh,
                        );
                      },
                    ),
                  ),
                ),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colors.accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildPrayerListDecoration(UIColors colors) {
    return BoxDecoration(
      color: colors.contentSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colors.borderColor.withAlpha(colors.isDarkMode ? 70 : 100),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadowColor(
            colors.brightness,
          ).withAlpha(colors.isDarkMode ? 20 : 40),
          spreadRadius: 0,
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  void _navigateToSettings({
    bool scrollToDate = false,
    bool scrollToLocation = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (context) => SettingsView(
              scrollToDate: scrollToDate,
              scrollToLocation: scrollToLocation,
            ),
        settings: const RouteSettings(name: '/settings'),
      ),
    ).then((_) {
      if (mounted) {
        _triggerUIRefresh();
      }
    });
  }
}
