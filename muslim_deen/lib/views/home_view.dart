import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../models/app_settings.dart';
import '../models/custom_exceptions.dart'; // Added
import '../models/prayer_display_info_data.dart';
import '../providers/providers.dart'; // Changed for Riverpod
import '../service_locator.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import '../widgets/prayer_list_item.dart';
import '../widgets/prayer_countdown_timer.dart';
import 'settings_view.dart';

class HomeView extends ConsumerStatefulWidget {
  // Changed
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState(); // Changed
}

class _HomeViewState extends ConsumerState<HomeView> with WidgetsBindingObserver {
  // Changed
  final LocationService _locationService = locator<LocationService>();
  final PrayerService _prayerService = locator<PrayerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();
  final LoggerService _logger = locator<LoggerService>();
  final ScrollController _scrollController = ScrollController();
  static const double _prayerItemHeight = 80.0;
  Timer? _dailyRefreshTimer; // VoidCallback? _settingsListener; // Removed
  // AppSettings? _previousSettings; // Removed
  ProviderSubscription? _settingsListenerSubscription; // Added for listenManual
  String? _lastKnownCity; // Store last known location details for loading state
  String?
  _lastKnownCountry; // Note: Loading/error states are managed through FutureBuilder
  // late final SettingsProvider _settingsProvider; // Removed

  bool _isUiFetchInProgress = false; // Flag for UI-triggered fetches

  // Cached DateFormat instances
  late DateFormat _gregorianDateFormatter;
  late DateFormat _timeFormatter;
  AppSettings? _cachedSettingsForFormatters;
  Locale? _cachedLocaleForFormatters;

  adhan.PrayerTimes? _prayerTimes;
  String _nextPrayerName = '';
  String _currentPrayerName = '';
  PrayerNotification? _currentPrayerEnum; // Added
  DateTime? _nextPrayerDateTime; // Stores the time of the next prayer
  late Future<Map<String, dynamic>> _dataLoadingFuture; // Renamed future

  @override
  void initState() {
    super.initState();
    _logger.info('HomeView initialized');
    WidgetsBinding.instance.addObserver(this); // Add observer

    // Initial data load and scheduling
    _dataLoadingFuture = _fetchDataAndScheduleNotifications();

    // Initial permission check
    ref
        .read(settingsProvider.notifier)
        .checkNotificationPermissionStatus(); // Changed

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
      _gregorianDateFormatter =
          DateFormat(gregorianDatePattern, locale.toString());

      _timeFormatter = DateFormat(
        settings.timeFormat == TimeFormat.twentyFourHour
            ? 'HH:mm'
            : 'hh:mm a',
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

    // Reset prayer service after location service
    // since prayer calculations depend on location
    _prayerService.reset();

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
        ref.read(settingsProvider.notifier).checkNotificationPermissionStatus();
      }
    }
  }

  /// Starts a timer to refresh prayer times daily around midnight.
  void _startDailyRefreshTimer() {
    _dailyRefreshTimer?.cancel(); // Cancel existing timer if any

    final now = DateTime.now();
    // Calculate duration until the next midnight
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
    // Signature changed
    _logger.debug(
      'Settings changed in HomeView',
      data: {
        'newSettings': newSettings.toJson(),
        'oldSettings': oldSettings?.toJson(),
      },
    );
    // No need to check _prayerTimes == null here, rescheduling only happens if it's not null anyway.
    if (!mounted || oldSettings == null) return; // Changed

    bool needsReschedule = false;
    bool needsReload = false;

    // Check relevant settings for changes that require reloading prayer times
    if (newSettings.calculationMethod !=
            oldSettings.calculationMethod || // Changed
        newSettings.madhab != oldSettings.madhab) {
      // Changed
      needsReload = true;
      needsReschedule = true; // Reload implies reschedule
      _logger.info(
        "Calculation method or Madhab change detected, reloading data...",
        data: {
          'oldMethod': oldSettings.calculationMethod, // Changed
          'newMethod': newSettings.calculationMethod,
          'oldMadhab': oldSettings.madhab, // Changed
          'newMadhab': newSettings.madhab,
        },
      );
    }
    // Check for changes that only require rescheduling notifications
    else if (!mapEquals(
      newSettings.notifications,
      oldSettings.notifications, // Changed
    )) {
      needsReschedule = true;
      _logger.info(
        "Notification settings change detected, rescheduling notifications...",
        data: {
          'oldNotifications': oldSettings.notifications.map(
            // Changed
            (key, value) => MapEntry(key.toString(), value),
          ),
          'newNotifications': newSettings.notifications.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        },
      );
    }

    // _previousSettings = newSettings; // Removed, Riverpod manages state

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

  PrayerNotification? _getPrayerNotificationFromAdhanPrayer(String adhanPrayer) {
    if (adhanPrayer == adhan.Prayer.fajr) return PrayerNotification.fajr;
    if (adhanPrayer == adhan.Prayer.sunrise) return PrayerNotification.sunrise;
    if (adhanPrayer == adhan.Prayer.dhuhr) return PrayerNotification.dhuhr;
    if (adhanPrayer == adhan.Prayer.asr) return PrayerNotification.asr;
    if (adhanPrayer == adhan.Prayer.maghrib) return PrayerNotification.maghrib;
    if (adhanPrayer == adhan.Prayer.isha) return PrayerNotification.isha;
    return null; // For 'none' or other cases
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

      final newCurrentPrayerEnum =
          _getPrayerNotificationFromAdhanPrayer(currentPrayerStr);
      final newNextPrayerEnum =
          _getPrayerNotificationFromAdhanPrayer(nextPrayerStr);

      String currentPrayerDisplayName = '---';
      if (newCurrentPrayerEnum != null && _prayerTimes != null) {
        currentPrayerDisplayName =
            _getPrayerDisplayInfo(newCurrentPrayerEnum, _prayerTimes!).name;
      } else if (newCurrentPrayerEnum != null) {
        // Fallback if _prayerTimes is somehow null but enum is not
        // This case should ideally not happen if data is loaded correctly
        currentPrayerDisplayName = newCurrentPrayerEnum.toString().split('.').last;
         _logger.warning("_prayerTimes was null in _updatePrayerTimingsDisplay for current prayer, using enum name.");
      }


      String nextPrayerDisplayName = '---';
      if (newNextPrayerEnum != null && _prayerTimes != null) {
        nextPrayerDisplayName =
            _getPrayerDisplayInfo(newNextPrayerEnum, _prayerTimes!).name;
      } else if (newNextPrayerEnum != null) {
        nextPrayerDisplayName = newNextPrayerEnum.toString().split('.').last;
        _logger.warning("_prayerTimes was null in _updatePrayerTimingsDisplay for next prayer, using enum name.");
      }


      if (mounted) {
        final bool currentPrayerChanged =
            _currentPrayerEnum != newCurrentPrayerEnum;

        setState(() {
          _currentPrayerEnum = newCurrentPrayerEnum;
          // _nextPrayerEnum was removed, newNextPrayerEnum is still used for _nextPrayerName
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
          // _nextPrayerEnum was removed
          _currentPrayerName = 'Error';
          _nextPrayerName = 'Error';
        });
      }
    }
  }

  /// Scrolls the list view to the specified prayer item.
  void _scrollToPrayer(PrayerNotification? prayerEnum) { // Changed parameter
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
        data: {'prayerEnum': prayerEnum.toString(), 'index': index, 'offset': offset},
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

    // Check if it looks like coordinates
    final coordRegex = RegExp(r'^-?\d+(\.\d+)?,\s*-?\d+(\.\d+)?$');
    if (coordRegex.hasMatch(locationName)) {
      return {'city': 'Current Location', 'country': null};
    } else if (locationName.contains(',')) {
      // Assume "City, Country" or similar
      final parts = locationName.split(',');
      city = parts[0].trim();
      // If more than one comma, join the rest as country
      country = parts.length > 1 ? parts.sublist(1).join(',').trim() : null;

      if (city.isEmpty) {
        city = country ?? 'Unknown';
        country = null;
      }
    } else {
      // Assume it's just a city or place name
      city = locationName;
      country = null;
    }

    // Ensure city is never null or empty for display
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
      // Set loading state is handled by the FutureBuilder

      Position? position; // Keep as nullable: Position? position;
      String? locationNameToUse;

      // Use the injected _locationService instance
      final isUsingManualLocation = _locationService.isUsingManualLocation();

      if (isUsingManualLocation) {
        // Use the injected _locationService instance
        position = await _locationService.getLocation();
        locationNameToUse = await _locationService.getLocationName();
        _logger.info(
          "Using manually set location",
          data: {'locationName': locationNameToUse},
        );
      } else {
        // Get current device location with proper error handling
        try {
          position = await _locationService.getLocation();
          // Cache successful location data
          await _locationService.cacheCurrentLocation(position);
          _logger.info(
            "Fetched current device location",
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );

          // Try reverse geocoding the current location
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
            } else {
              locationNameToUse =
                  '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
            }

            // Update saved location with new values
            locator<StorageService>().saveLocation(
              position.latitude,
              position.longitude,
              locationName: locationNameToUse,
              setManualMode: false,
            );
            _logger.info(
              "Updated location in storage",
              data: {'locationName': locationNameToUse},
            );
          } catch (e, s) {
            _logger.warning(
              'Geocoding error, falling back to coordinates',
              data: {'error': e.toString(), 'stackTrace': s.toString()},
            );
            locationNameToUse =
                '${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}';
            locator<StorageService>().saveLocation(
              position.latitude,
              position.longitude,
              locationName: locationNameToUse,
              setManualMode: false,
            );
          }
        } catch (e, s) {
          // If getting current location fails, fallback to saved location
          _logger.warning(
            "Error getting current location, falling back to saved location",
            data: {'error': e.toString(), 'stackTrace': s.toString()},
          );
          final double? savedLat = locator<StorageService>().getLatitude();
          final double? savedLng = locator<StorageService>().getLongitude();
          final String? savedName = locator<StorageService>().getLocationName();

          if (savedLat != null && savedLng != null) {
            position = Position(
              latitude: savedLat,
              longitude: savedLng,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
            locationNameToUse = savedName;
          } else {
            throw Exception(
              'Could not determine location. Both current and saved locations failed.',
            );
          }
        }
      }

      // Parse the location name for display
      final displayNames = _parseLocationName(locationNameToUse);
      final displayCity = displayNames['city'];
      final displayCountry = displayNames['country'];

      // Store fetched location for loading state display
      // Ensure these are assigned correctly
      if (mounted) {
        // Check mounted before accessing state
        setState(() {
          _lastKnownCity = displayCity;
          _lastKnownCountry = displayCountry;
        });
      }

      // Check if mounted before accessing context for settings in logger
      String? logSettingsJson;
      if (mounted) {
        try {
          final currentSettings = ref.read(settingsProvider); // Changed
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

      // At this point, if position couldn't be determined, an exception should have been thrown.
      // Thus, position should not be null here.
      _logger.info(
        "Calculating prayer times for position",
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'settings_json': logSettingsJson,
        },
      );

      if (!mounted) return {};
      final settings = ref.read(settingsProvider); // Changed

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

      // Get the next prayer time for the countdown timer
      final nextPrayerTime = _prayerService.getNextPrayerTime();

      // Update state variables *before* scheduling notifications
      _prayerTimes = calculatedPrayerTimes;
      _nextPrayerDateTime = nextPrayerTime;

      // Schedule notifications now that prayer times are calculated
      // Use addPostFrameCallback to ensure context is valid and build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scheduleAllPrayerNotifications(context, calculatedPrayerTimes);
          // Update display and scroll after scheduling
          _updatePrayerTimingsDisplay(); // This will now also set _currentPrayerEnum

          // Scroll to the initial current prayer using the enum
          // _updatePrayerTimingsDisplay would have set _currentPrayerEnum
          // We need to ensure _currentPrayerEnum is set before calling _scrollToPrayer
          // The _updatePrayerTimingsDisplay call above handles this.
          // If _currentPrayerEnum is not null, scroll to it.
          if (_currentPrayerEnum != null) {
             WidgetsBinding.instance.addPostFrameCallback((_) { // Ensure scroll happens after build
                if(mounted) _scrollToPrayer(_currentPrayerEnum);
             });
          }
        }
      });

      // Return data needed for the UI build
      return {
        'prayerTimes': calculatedPrayerTimes, // Still needed for initial build
        'displayCity': displayCity,
        'displayCountry': displayCountry,
        'position': position,
        'locationName': locationNameToUse,
        'nextPrayerTime': nextPrayerTime, // Still needed for initial build
      };
    } on Exception catch (e, s) {
      _logger.error(
        'Error in _fetchDataAndScheduleNotifications',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      // Reset prayer times on error to avoid using stale data
      _prayerTimes = null;
      _nextPrayerDateTime = null;
      rethrow;
    }
  }

  // Helper to process errors for display in FutureBuilder
  String _processLoadError(Object? error) {
    _logger.error(
      'FutureBuilder caught error',
      data: {'error': error.toString()},
    );
    String specificError =
        'Failed to load prayer times. Please check connection and location settings.';
    if (error is PrayerDataException) {
      specificError = error.message; // Use the message from PrayerDataException
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
      // Handle non-Exception errors if necessary
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
    // Ensure widget is still mounted before accessing context or scheduling
    if (!mounted) return;

    // final localizations = AppLocalizations.of(context)!; // Removed
    // Use read here as this function is called from post-frame callbacks or FutureBuilder,
    // and we don't want this specific function call to trigger rebuilds on settings change.
    // The watch() in the build method handles reacting to settings changes.
    final appSettings = ref.read(settingsProvider); // Changed
    // final settings = settingsProvider.settings; // Removed, use appSettings

    _logger.info("Scheduling/Rescheduling notifications...");

    await _notificationService
        .cancelAllNotifications(); // Clear existing before scheduling new ones

    for (var prayerEnum in PrayerNotification.values) {
      final prayerInfo = _getPrayerDisplayInfo(prayerEnum, prayerTimes);
      final bool isEnabled = appSettings.notifications[prayerEnum] ?? false;

      if (prayerInfo.time != null && isEnabled) {
        await _notificationService.schedulePrayerNotification(
          id: prayerEnum.index,
          localizedTitle: "Prayer Time: ${prayerInfo.name}", // Simplified title
          localizedBody: "It's time for ${prayerInfo.name} prayer.",
          prayerTime: prayerInfo.time!,
          isEnabled: true, // This is always true if we reach here
          appSettings: appSettings, // Pass the current appSettings
        );
      }
    }
    _logger.info("Finished scheduling/rescheduling notifications.");
  }

  PrayerDisplayInfoData _getPrayerDisplayInfo(
      PrayerNotification prayerEnum, adhan.PrayerTimes? prayerTimes) {
    DateTime? time;
    String name;
    IconData icon;

    switch (prayerEnum) {
      case PrayerNotification.fajr:
        time = prayerTimes?.fajr;
        name = "Fajr";
        icon = Icons.wb_sunny_outlined; // Dawn/Sunrise icon
        break;
      case PrayerNotification.sunrise:
        time = prayerTimes?.sunrise;
        name = "Sunrise";
        icon = Icons.wb_twilight_outlined; // Sunrise icon
        break;
      case PrayerNotification.dhuhr:
        time = prayerTimes?.dhuhr;
        name = "Dhuhr";
        icon = Icons.wb_sunny; // Midday sun
        break;
      case PrayerNotification.asr:
        time = prayerTimes?.asr;
        name = "Asr";
        icon = Icons.wb_twilight; // Afternoon/twilight
        break;
      case PrayerNotification.maghrib:
        time = prayerTimes?.maghrib;
        name = "Maghrib";
        icon = Icons.brightness_4_outlined; // Sunset icon
        break;
      case PrayerNotification.isha:
        time = prayerTimes?.isha;
        name = "Isha";
        icon = Icons.nights_stay; // Moon/night icon
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
      _dataLoadingFuture = _fetchDataAndScheduleNotifications().whenComplete(() {
        if (mounted) {
          _isUiFetchInProgress = false;
        } else {
          _isUiFetchInProgress = false; // Ensure it's reset even if not mounted
        }
        _logger.debug("_isUiFetchInProgress reset after UI refresh fetch.");
      });
    });
  }

  Widget _buildRetryButton(Brightness brightness) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.refresh),
      onPressed: _triggerUIRefresh,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGreen(brightness),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        textStyle: AppTextStyles.label(brightness).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      label: Text("Retry"), // Replaced localizations.retry;
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to rebuild on any settings change
    final appSettings = ref.watch(settingsProvider);
    final locale = Localizations.localeOf(context);
    _initOrUpdateDateFormatters(appSettings, locale); // Update formatters

    // final localizations = AppLocalizations.of(context)!; // Removed
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Define colors similar to TesbihView
    final Color scaffoldBg =
        isDarkMode
            ? AppColors.surface(brightness)
            : AppColors.background(brightness);
    final Color contentSurface =
        isDarkMode
            ? const Color(0xFF2C2C2C)
            : AppColors.primaryVariant(brightness); // For cards/containers
    final Color currentPrayerItemBg =
        isDarkMode
            ? AppColors.accentGreen(brightness).withAlpha((0.15 * 255).round())
            : AppColors.primary(brightness).withAlpha((0.1 * 255).round());
    final Color currentPrayerItemBorder =
        isDarkMode
            ? AppColors.accentGreen(brightness).withAlpha((0.7 * 255).round())
            : AppColors.primary(brightness);
    final Color currentPrayerItemText =
        isDarkMode
            ? AppColors.accentGreen(brightness)
            : AppColors.primary(brightness);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Prayer Times", // Replaced localizations.appTitle;
          style: AppTextStyles.appTitle(brightness),
        ),
        backgroundColor: AppColors.primary(brightness),
        elevation: 2,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary(brightness),
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.light,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildMainContent(
              isLoading: true,
              prayerTimes: _prayerTimes,
              displayCity:
                  _lastKnownCity ??
                  "Loading...", // Replaced localizations.loading;
              displayCountry: _lastKnownCountry,
              appSettings: appSettings,
              // localizations: localizations, // Removed
              brightness: brightness,
              isDarkMode: isDarkMode,
              scaffoldBg: scaffoldBg,
              contentSurface: contentSurface,
              currentPrayerItemBg: currentPrayerItemBg,
              currentPrayerItemBorder: currentPrayerItemBorder,
              currentPrayerItemText: currentPrayerItemText,
            );
          } else if (snapshot.hasError) {
            final String errorMessage = _processLoadError(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppColors.error(brightness),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: AppTextStyles.label(brightness).copyWith(
                        color: AppColors.error(brightness),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildRetryButton(brightness),
                    if (errorMessage.contains('permission') ||
                        errorMessage.contains('permanently denied'))
                      TextButton(
                        onPressed: _locationService.openAppSettings,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary(brightness),
                        ),
                        child: Text(
                          "Open App Settings",
                        ), // Replaced localizations.openAppSettings;
                      ),
                    if (errorMessage.contains('services are disabled'))
                      TextButton(
                        onPressed: _locationService.openLocationSettings,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary(brightness),
                        ),
                        child: Text(
                          "Open Location Settings",
                        ), // Replaced localizations.openLocationSettings;
                      ),
                  ],
                ),
              ),
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
              // localizations: localizations, // Removed
              brightness: brightness,
              isDarkMode: isDarkMode,
              scaffoldBg: scaffoldBg,
              contentSurface: contentSurface,
              currentPrayerItemBg: currentPrayerItemBg,
              currentPrayerItemBorder: currentPrayerItemBorder,
              currentPrayerItemText: currentPrayerItemText,
            );
          } else {
            return Center(
              // Fallback for unexpected state
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary(brightness),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "An unexpected error occurred.", // Replaced localizations.unexpectedError(localizations.unknown);
                    style: AppTextStyles.label(
                      brightness,
                    ).copyWith(color: AppColors.textSecondary(brightness)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildRetryButton(brightness),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the main content of the Scaffold body.
  Widget _buildMainContent({
    required bool isLoading,
    required adhan.PrayerTimes? prayerTimes,
    required String? displayCity,
    required String? displayCountry,
    required AppSettings appSettings,
    // required AppLocalizations localizations, // Removed
    required Brightness brightness,
    required bool isDarkMode,
    required Color scaffoldBg,
    required Color contentSurface,
    required Color currentPrayerItemBg,
    required Color currentPrayerItemBorder,
    required Color currentPrayerItemText,
  }) {
    final now = DateTime.now();
    // Use cached formatters
    final formattedGregorian = _gregorianDateFormatter.format(now);
    final hijri = HijriCalendar.now();
    final formattedHijri =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
    // _timeFormatter is used directly where needed (e.g., passed to _buildPrayerItemWithSwitch)

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
        Padding(
          // Location and Date Info - no separate card, directly on scaffoldBg
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            8,
          ), // Increased top padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder:
                          (context) => const SettingsView(scrollToDate: true),
                      settings: const RouteSettings(name: '/settings'),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _triggerUIRefresh();
                    }
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedGregorian,
                      style: AppTextStyles.date(
                        brightness,
                      ).copyWith(fontSize: 15),
                    ),
                    Text(
                      formattedHijri,
                      style: AppTextStyles.dateSecondary(
                        brightness,
                      ).copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: GestureDetector(
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder:
                            (context) =>
                                const SettingsView(scrollToLocation: true),
                        settings: const RouteSettings(name: '/settings'),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _triggerUIRefresh(clearLocationCache: true);
                      }
                    });
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppColors.textPrimary(brightness),
                            size: 15, // Adjusted size
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayCity ??
                                  "Loading...", // Replaced localizations.loading;
                              style: AppTextStyles.date(
                                brightness,
                              ).copyWith(fontSize: 15),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (displayCountry != null && displayCountry.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 20.0,
                          ), // Keep padding for alignment
                          child: Text(
                            displayCountry,
                            style: AppTextStyles.dateSecondary(
                              brightness,
                            ).copyWith(fontSize: 13),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current & Next Prayer Box
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ), // Added vertical margin
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: contentSurface, // Use contentSurface from TesbihView
            borderRadius: BorderRadius.circular(12), // Consistent rounding
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor(
                  brightness,
                ).withAlpha(isDarkMode ? 30 : 50),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Prayer", // Replaced localizations.currentPrayerTitle;
                      style: AppTextStyles.label(
                        brightness,
                      ).copyWith(color: AppColors.textSecondary(brightness)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : _currentPrayerName,
                      style: AppTextStyles.currentPrayer(
                        brightness,
                      ).copyWith(color: AppColors.textPrimary(brightness)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Next Prayer", // Replaced localizations.nextPrayerTitle;
                      style: AppTextStyles.label(
                        brightness,
                      ).copyWith(color: AppColors.textSecondary(brightness)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : _nextPrayerName,
                      style: AppTextStyles.nextPrayer(brightness).copyWith(
                        color: AppColors.accentGreen(brightness),
                      ), // Highlight next prayer
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
                              isLoading
                                  ? Duration.zero
                                  : initialCountdownDuration,
                             textStyle: AppTextStyles.countdownTimer(
                               brightness,
                             ).copyWith(color: AppColors.accentGreen(brightness)),
                           );
                         },
                       ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), // Adjusted padding
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Prayer Times", // Replaced localizations.prayerTimesTitle;
              style: AppTextStyles.sectionTitle(
                brightness,
              ).copyWith(color: AppColors.textPrimary(brightness)),
            ),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  16,
                ), // Margin for the list container
                decoration: BoxDecoration(
                  color: contentSurface, // Background for the list area
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderColor(
                      brightness,
                    ).withAlpha(isDarkMode ? 70 : 100),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor(
                        brightness,
                      ).withAlpha(isDarkMode ? 20 : 40),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  // To ensure border radius is respected by ListView
                  borderRadius: BorderRadius.circular(11),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero, // Remove default padding
                    itemCount: prayerOrder.length,
                    separatorBuilder:
                        (context, index) => Divider(
                          color: AppColors.borderColor(
                            brightness,
                          ).withAlpha(isDarkMode ? 70 : 100),
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                    itemBuilder: (context, index) {
                      final prayerEnum = prayerOrder[index];
                      final prayerInfo =
                          _getPrayerDisplayInfo(prayerEnum, prayerTimes);

                      // final bool isEnabled = settings.notifications[prayerEnum] ?? false; // Unused
                      final bool isCurrent = !isLoading &&
                          _currentPrayerEnum == prayerInfo.prayerEnum; // Compare enums

                      return PrayerListItem(
                        prayerInfo: prayerInfo,
                        timeFormatter: _timeFormatter,
                        isCurrent: isCurrent,
                        brightness: brightness,
                        contentSurfaceColor: contentSurface,
                        currentPrayerItemBgColor: currentPrayerItemBg,
                        currentPrayerItemBorderColor: currentPrayerItemBorder,
                        currentPrayerItemTextColor: currentPrayerItemText,
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
                      AppColors.accentGreen(brightness),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
