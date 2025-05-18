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
// import 'package:provider/provider.dart'; // Removed

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/providers.dart'; // Changed for Riverpod
import '../service_locator.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../services/storage_service.dart';
import '../styles/app_styles.dart';
import 'settings_view.dart';

String _formatDuration(Duration duration) {
  if (duration.isNegative) {
    return "00:00:00"; // Or handle as 'Now'/'Passed' if needed elsewhere
  }
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  duration = duration.abs(); // Ensure positive duration for formatting
  String twoDigitHours = twoDigits(duration.inHours);
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
}

class HomeView extends ConsumerStatefulWidget {
  // Changed
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState(); // Changed
}

class _HomeViewState extends ConsumerState<HomeView> {
  // Changed
  final LocationService _locationService = locator<LocationService>();
  final PrayerService _prayerService = locator<PrayerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();
  final LoggerService _logger = locator<LoggerService>();
  final ScrollController _scrollController = ScrollController();
  static const double _prayerItemHeight = 80.0;
  Timer? _permissionCheckTimer;
  Timer? _dailyRefreshTimer; // VoidCallback? _settingsListener; // Removed
  // AppSettings? _previousSettings; // Removed
  String? _lastKnownCity; // Store last known location details for loading state
  String?
  _lastKnownCountry; // Note: Loading/error states are managed through FutureBuilder
  // late final SettingsProvider _settingsProvider; // Removed

  void _startPermissionCheck() {
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        ref
            .read(settingsProvider.notifier)
            .checkNotificationPermissionStatus(); // Changed
      }
    });
  }

  adhan.PrayerTimes? _prayerTimes;
  String _nextPrayerName = '';
  String _currentPrayerName = '';
  DateTime? _nextPrayerDateTime; // Stores the time of the next prayer
  late Future<Map<String, dynamic>> _dataLoadingFuture; // Renamed future

  @override
  void initState() {
    super.initState();
    _logger.info('HomeView initialized');
    // Initial data load and scheduling
    _dataLoadingFuture = _fetchDataAndScheduleNotifications();

    // Initial permission check and start periodic check
    ref
        .read(settingsProvider.notifier)
        .checkNotificationPermissionStatus(); // Changed
    _startPermissionCheck();

    // Listen to settings changes using Riverpod
    // Defer the listener setup until after the first frame
    // Settings listening is now handled in build method

    // Start daily refresh timer
    _startDailyRefreshTimer();
  }

  @override
  void dispose() {
    _logger.debug('HomeView dispose started');

    // First, stop any active timers to prevent new location/notification requests
    _permissionCheckTimer?.cancel();
    _dailyRefreshTimer?.cancel();

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
      // final timeRemaining = _prayerService.getTimeUntilNextPrayer(); // Duration is now handled by the timer widget

      final formattedCurrentPrayer = _formatPrayerName(currentPrayerStr);
      final formattedNextPrayer = _formatPrayerName(nextPrayerStr);

      // Check if mounted before calling setState
      if (mounted) {
        // Check if current prayer changed to trigger scroll
        bool currentPrayerChanged =
            _currentPrayerName != formattedCurrentPrayer;

        setState(() {
          _currentPrayerName = formattedCurrentPrayer;
          _nextPrayerName = formattedNextPrayer;
          // _timeTillNextPrayer = timeRemaining; // Duration state removed
        });

        // Scroll to the current prayer item if it changed
        if (currentPrayerChanged &&
            _currentPrayerName != '---' &&
            _currentPrayerName != 'Error') {
          // Use addPostFrameCallback to ensure the list view has been built/updated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Check mounted again inside callback
              _scrollToPrayer(_currentPrayerName);
            }
          });
        }
      }
    } catch (e, s) {
      // Handle potential errors from prayer service (e.g., not initialized)
      _logger.error(
        "Error updating prayer timings display",
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      if (mounted) {
        setState(() {
          // Optionally reset display values or show an indicator
          _currentPrayerName = 'Error';
          _nextPrayerName = 'Error';
          // _timeTillNextPrayer = Duration.zero; // Duration state removed
        });
      }
    }
  }

  /// Scrolls the list view to the specified prayer item.
  void _scrollToPrayer(String prayerName) {
    // Find the index based on the string name within the PrayerNotification enum values
    final prayerEnum = _getPrayerEnumFromString(prayerName);
    if (prayerEnum == null) {
      _logger.warning("Could not find enum for prayer name: $prayerName");
      return;
    }
    // Use the order defined in _buildPrayerTimesUI for consistency
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
        data: {'prayerName': prayerName, 'index': index, 'offset': offset},
      );
    } else {
      _logger.warning(
        "Could not scroll to prayer",
        data: {
          'prayerName': prayerName,
          'index': index,
          'hasClients': _scrollController.hasClients,
        },
      );
    }
  }

  /// Formats standard prayer names from adhan library to localized display names.
  /// Returns '---' for non-standard names or 'none'.
  String _formatPrayerName(String prayer) {
    final standardPrayers = {
      adhan.Prayer.fajr,
      adhan.Prayer.sunrise,
      adhan.Prayer.dhuhr,
      adhan.Prayer.asr,
      adhan.Prayer.maghrib,
      adhan.Prayer.isha,
    };

    if (prayer.isEmpty ||
        prayer == adhan.Prayer.none ||
        !standardPrayers.contains(prayer)) {
      return '---';
    }

    // Use localized names based on the prayer string from adhan library
    final localizations = AppLocalizations.of(context)!;

    // Use if-else statements instead of switch with non-constant patterns
    if (prayer == adhan.Prayer.fajr) {
      return localizations.prayerNameFajr;
    } else if (prayer == adhan.Prayer.sunrise) {
      return localizations.prayerNameSunrise;
    } else if (prayer == adhan.Prayer.dhuhr) {
      return localizations.prayerNameDhuhr;
    } else if (prayer == adhan.Prayer.asr) {
      return localizations.prayerNameAsr;
    } else if (prayer == adhan.Prayer.maghrib) {
      return localizations.prayerNameMaghrib;
    } else if (prayer == adhan.Prayer.isha) {
      return localizations.prayerNameIsha;
    } else {
      return prayer[0].toUpperCase() + prayer.substring(1); // Fallback
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
      var parts = locationName.split(',');
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
            List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final placemark = placemarks.first;
              String? city =
                  placemark.locality?.isNotEmpty == true
                      ? placemark.locality
                      : placemark.subAdministrativeArea?.isNotEmpty == true
                      ? placemark.subAdministrativeArea
                      : placemark.administrativeArea;
              String? country = placemark.country;
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
          double? savedLat = locator<StorageService>().getLatitude();
          double? savedLng = locator<StorageService>().getLongitude();
          String? savedName = locator<StorageService>().getLocationName();

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

      adhan.PrayerTimes calculatedPrayerTimes = await _prayerService
          .calculatePrayerTimesForToday(settings);
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
          _updatePrayerTimingsDisplay();
          final initialCurrentPrayer = _prayerService.getCurrentPrayer();
          final formattedInitialCurrent = _formatPrayerName(
            initialCurrentPrayer,
          );
          if (formattedInitialCurrent != '---' &&
              formattedInitialCurrent != 'Error') {
            _scrollToPrayer(formattedInitialCurrent);
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
    if (error is Exception) {
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

    final localizations = AppLocalizations.of(context)!;
    // Use read here as this function is called from post-frame callbacks or FutureBuilder,
    // and we don't want this specific function call to trigger rebuilds on settings change.
    // The watch() in the build method handles reacting to settings changes.
    final appSettings = ref.read(settingsProvider); // Changed
    // final settings = settingsProvider.settings; // Removed, use appSettings

    _logger.info("Scheduling/Rescheduling notifications...");

    await _notificationService
        .cancelAllNotifications(); // Clear existing before scheduling new ones

    for (var prayer in PrayerNotification.values) {
      DateTime? prayerTime;
      String localizedName;

      switch (prayer) {
        case PrayerNotification.fajr:
          prayerTime = prayerTimes.fajr;
          localizedName = localizations.prayerNameFajr;
          break;
        case PrayerNotification.sunrise:
          // Sunrise notification is included for completeness, but typically not enabled by default.
          // The UI switch and settings map control whether it's actually scheduled.
          prayerTime = prayerTimes.sunrise;
          localizedName = localizations.prayerNameSunrise;
          break;
        case PrayerNotification.dhuhr:
          prayerTime = prayerTimes.dhuhr;
          localizedName = localizations.prayerNameDhuhr;
          break;
        case PrayerNotification.asr:
          prayerTime = prayerTimes.asr;
          localizedName = localizations.prayerNameAsr;
          break;
        case PrayerNotification.maghrib:
          prayerTime = prayerTimes.maghrib;
          localizedName = localizations.prayerNameMaghrib;
          break;
        case PrayerNotification.isha:
          prayerTime = prayerTimes.isha;
          localizedName = localizations.prayerNameIsha;
          break;
      }

      // Get enabled status from SettingsProvider, default to false if not found
      final bool isEnabled =
          appSettings.notifications[prayer] ?? false; // Changed

      // Only schedule if we have a valid time and notifications are enabled
      if (prayerTime != null && isEnabled) {
        await _notificationService.schedulePrayerNotification(
          id:
              prayer
                  .index, // Use enum index as a unique ID for each notification
          localizedTitle: localizations.notificationPrayerTitle(localizedName),
          localizedBody: localizations.notificationPrayerBody(localizedName),
          prayerTime: prayerTime,
          isEnabled: true,
        );
      }
    }

    // _notificationsScheduled = true; // Flag no longer needed
    _logger.info("Finished scheduling/rescheduling notifications.");
  }

  // Helper to map prayer name string to PrayerNotification enum
  PrayerNotification? _getPrayerEnumFromString(String name) {
    final localizations = AppLocalizations.of(context)!;

    if (name == localizations.prayerNameFajr) {
      return PrayerNotification.fajr;
    }
    if (name == localizations.prayerNameSunrise) {
      return PrayerNotification.sunrise;
    }
    if (name == localizations.prayerNameDhuhr) {
      return PrayerNotification.dhuhr;
    }
    if (name == localizations.prayerNameAsr) {
      return PrayerNotification.asr;
    }
    if (name == localizations.prayerNameMaghrib) {
      return PrayerNotification.maghrib;
    }
    if (name == localizations.prayerNameIsha) {
      return PrayerNotification.isha;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Listen for settings changes
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      _logger.debug(
        'Settings changed (via ref.listen)',
        data: {
          'newSettings': next.toJson(),
          'previousSettings': previous?.toJson(),
        },
      );
      _handleSettingsChange(next, previous);
    });

    // Use watch to rebuild on any settings change
    final appSettings = ref.watch(settingsProvider);
    final localizations = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Define colors similar to TesbihView
    final Color scaffoldBg = isDarkMode ? AppColors.surface(brightness) : AppColors.background(brightness);
    final Color contentSurface = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.primaryVariant(brightness); // For cards/containers
    final Color currentPrayerItemBg = isDarkMode ? AppColors.accentGreen(brightness).withAlpha((0.15 * 255).round()) : AppColors.primary(brightness).withAlpha((0.1 * 255).round());
    final Color currentPrayerItemBorder = isDarkMode ? AppColors.accentGreen(brightness).withAlpha((0.7 * 255).round()) : AppColors.primary(brightness);
    final Color currentPrayerItemText = isDarkMode ? AppColors.accentGreen(brightness) : AppColors.primary(brightness);


    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(localizations.appTitle, style: AppTextStyles.appTitle(brightness)),
        backgroundColor: AppColors.primary(brightness),
        elevation: 2,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary(brightness),
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.light,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildMainContent(
              isLoading: true,
              prayerTimes: _prayerTimes,
              displayCity: _lastKnownCity ?? localizations.loading,
              displayCountry: _lastKnownCountry,
              appSettings: appSettings,
              localizations: localizations,
              brightness: brightness,
              isDarkMode: isDarkMode,
              scaffoldBg: scaffoldBg,
              contentSurface: contentSurface,
              currentPrayerItemBg: currentPrayerItemBg,
              currentPrayerItemBorder: currentPrayerItemBorder,
              currentPrayerItemText: currentPrayerItemText,
            );
          } else if (snapshot.hasError) {
            String errorMessage = _processLoadError(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error(brightness), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: AppTextStyles.label(brightness).copyWith(color: AppColors.error(brightness), fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {
                          _dataLoadingFuture =
                              _fetchDataAndScheduleNotifications();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen(brightness),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: AppTextStyles.label(brightness).copyWith(fontWeight: FontWeight.w600), // Changed to label
                      ),
                      label: Text(localizations.retry),
                    ),
                    if (errorMessage.contains('permission') || errorMessage.contains('permanently denied'))
                      TextButton(
                        onPressed: () => _locationService.openAppSettings(),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary(brightness)),
                        child: Text(localizations.openAppSettings),
                      ),
                    if (errorMessage.contains('services are disabled'))
                      TextButton(
                        onPressed: () => _locationService.openLocationSettings(),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary(brightness)),
                        child: Text(localizations.openLocationSettings),
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
              localizations: localizations,
              brightness: brightness,
              isDarkMode: isDarkMode,
              scaffoldBg: scaffoldBg,
              contentSurface: contentSurface,
              currentPrayerItemBg: currentPrayerItemBg,
              currentPrayerItemBorder: currentPrayerItemBorder,
              currentPrayerItemText: currentPrayerItemText,
            );
          } else {
            return Center( // Fallback for unexpected state
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: AppColors.textSecondary(brightness), size: 48),
                  const SizedBox(height:16),
                  Text(
                    localizations.unexpectedError(localizations.unknown),
                    style: AppTextStyles.label(brightness).copyWith(color: AppColors.textSecondary(brightness)),
                    textAlign: TextAlign.center,
                  ),
                   const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {
                          _dataLoadingFuture =
                              _fetchDataAndScheduleNotifications();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGreen(brightness),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: AppTextStyles.label(brightness).copyWith(fontWeight: FontWeight.w600), // Changed to label
                      ),
                      label: Text(localizations.retry),
                    ),
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
    required AppLocalizations localizations,
    required Brightness brightness,
    required bool isDarkMode,
    required Color scaffoldBg,
    required Color contentSurface,
    required Color currentPrayerItemBg,
    required Color currentPrayerItemBorder,
    required Color currentPrayerItemText,
  }) {
    final settings = appSettings;
    final now = DateTime.now();
    final datePattern =
        settings.dateFormatOption == DateFormatOption.dayMonthYear
            ? 'd MMMM yyyy'
            : settings.dateFormatOption == DateFormatOption.monthDayYear
            ? 'MMMM d, yyyy'
            : 'yyyy MMMM d';
    final formattedGregorian = DateFormat(
      datePattern,
      Localizations.localeOf(context).toString(),
    ).format(now);
    final hijri = HijriCalendar.now();
    final formattedHijri =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';
    final timeFormat = DateFormat(
      settings.timeFormat == TimeFormat.twentyFourHour ? 'HH:mm' : 'hh:mm a',
      Localizations.localeOf(context).toString(),
    );

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
        Padding( // Location and Date Info - no separate card, directly on scaffoldBg
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), // Increased top padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => const SettingsView(scrollToDate: true),
                      settings: const RouteSettings(name: '/settings'),
                    ),
                  ).then((_) {
                    setState(() {
                      _dataLoadingFuture = _fetchDataAndScheduleNotifications();
                    });
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedGregorian, style: AppTextStyles.date(brightness).copyWith(fontSize: 15)),
                    Text(formattedHijri, style: AppTextStyles.dateSecondary(brightness).copyWith(fontSize: 13)),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: GestureDetector(
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const SettingsView(scrollToLocation: true),
                        settings: const RouteSettings(name: '/settings'),
                      ),
                    ).then((_) {
                      if (mounted) {
                        setState(() {
                          _prayerTimes = null;
                          _lastKnownCity = null;
                          _lastKnownCountry = null;
                          _dataLoadingFuture =
                              _fetchDataAndScheduleNotifications();
                        });
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
                              displayCity ?? localizations.loading, // Show loading if city is null
                              style: AppTextStyles.date(brightness).copyWith(fontSize: 15),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (displayCountry != null && displayCountry.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0), // Keep padding for alignment
                          child: Text(
                            displayCountry,
                            style: AppTextStyles.dateSecondary(brightness).copyWith(fontSize: 13),
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added vertical margin
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: contentSurface, // Use contentSurface from TesbihView
            borderRadius: BorderRadius.circular(12), // Consistent rounding
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor(brightness).withAlpha(isDarkMode ? 30 : 50),
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
                      localizations.currentPrayerTitle,
                      style: AppTextStyles.label(brightness).copyWith(color: AppColors.textSecondary(brightness)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : _currentPrayerName,
                      style: AppTextStyles.currentPrayer(brightness).copyWith(color: AppColors.textPrimary(brightness)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      localizations.nextPrayerTitle,
                      style: AppTextStyles.label(brightness).copyWith(color: AppColors.textSecondary(brightness)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? '...' : _nextPrayerName,
                      style: AppTextStyles.nextPrayer(brightness).copyWith(color: AppColors.accentGreen(brightness)), // Highlight next prayer
                    ),
                    Builder(
                      builder: (context) {
                        Duration initialCountdownDuration = Duration.zero;
                        if (!isLoading && _nextPrayerDateTime != null) {
                          final now = DateTime.now();
                          if (_nextPrayerDateTime!.isAfter(now)) {
                            initialCountdownDuration = _nextPrayerDateTime!.difference(now);
                          }
                        }
                        return PrayerCountdownTimer(
                          initialDuration: isLoading ? Duration.zero : initialCountdownDuration,
                          textStyle: AppTextStyles.countdownTimer(brightness).copyWith(color: AppColors.accentGreen(brightness)),
                          localizations: localizations,
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
              localizations.prayerTimesTitle,
              style: AppTextStyles.sectionTitle(brightness).copyWith(color: AppColors.textPrimary(brightness)),
            ),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Margin for the list container
                decoration: BoxDecoration(
                  color: contentSurface, // Background for the list area
                  borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: AppColors.borderColor(brightness).withAlpha(isDarkMode ? 70 : 100)),
                   boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor(brightness).withAlpha(isDarkMode ? 20 : 40),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                ),
                child: ClipRRect( // To ensure border radius is respected by ListView
                  borderRadius: BorderRadius.circular(11),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero, // Remove default padding
                    itemCount: prayerOrder.length,
                    separatorBuilder: (context, index) => Divider(
                      color: AppColors.borderColor(brightness).withAlpha(isDarkMode ? 70 : 100),
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final prayerEnum = prayerOrder[index];
                      DateTime? prayerTime;
                      String prayerNameString;

                      switch (prayerEnum) {
                        case PrayerNotification.fajr:
                          prayerTime = prayerTimes?.fajr;
                          prayerNameString = localizations.prayerNameFajr;
                          break;
                        case PrayerNotification.sunrise:
                          prayerTime = prayerTimes?.sunrise;
                          prayerNameString = localizations.prayerNameSunrise;
                          break;
                        case PrayerNotification.dhuhr:
                          prayerTime = prayerTimes?.dhuhr;
                          prayerNameString = localizations.prayerNameDhuhr;
                          break;
                        case PrayerNotification.asr:
                          prayerTime = prayerTimes?.asr;
                          prayerNameString = localizations.prayerNameAsr;
                          break;
                        case PrayerNotification.maghrib:
                          prayerTime = prayerTimes?.maghrib;
                          prayerNameString = localizations.prayerNameMaghrib;
                          break;
                        case PrayerNotification.isha:
                          prayerTime = prayerTimes?.isha;
                          prayerNameString = localizations.prayerNameIsha;
                          break;
                      }

                      final bool isEnabled = settings.notifications[prayerEnum] ?? false;
                      final bool isCurrent = !isLoading && _currentPrayerName == prayerNameString;

                      return _buildPrayerItemWithSwitch(
                        prayerNameString,
                        prayerEnum,
                        prayerTime,
                        timeFormat,
                        isCurrent,
                        isEnabled,
                        brightness, // Pass brightness
                        isDarkMode,
                        contentSurface,
                        currentPrayerItemBg,
                        currentPrayerItemBorder,
                        currentPrayerItemText,
                      );
                    },
                  ),
                ),
              ),
              if (isLoading)
                Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen(brightness)))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerItemWithSwitch(
    String name,
    PrayerNotification prayerEnum,
    DateTime? time,
    DateFormat format,
    bool isCurrent,
    bool isEnabled,
    Brightness brightness,
    bool isDarkMode,
    Color contentSurfaceColor, // Renamed from contentSurface to avoid conflict
    Color currentPrayerItemBgColor, // Renamed
    Color currentPrayerItemBorderColor, // Renamed
    Color currentPrayerItemTextColor, // Renamed
  ) {
    final Color itemBackgroundColor = isCurrent ? currentPrayerItemBgColor : contentSurfaceColor; // Use contentSurfaceColor for non-current
    // final Color itemBorderColor = isCurrent ? currentPrayerItemBorderColor : AppColors.borderColor(brightness).withAlpha(0); // No border for non-current if inside a card
    final Color itemIconColor = isCurrent ? currentPrayerItemTextColor : AppColors.iconInactive(brightness);
    final Color itemTextColor = isCurrent ? currentPrayerItemTextColor : AppColors.textPrimary(brightness);

    return Material( // For InkWell splash
      color: Colors.transparent, // Make Material transparent
      child: InkWell(
        onDoubleTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const SettingsView(scrollToNotifications: true),
              settings: const RouteSettings(name: '/settings'),
            ),
          ).then((_) {
            setState(() {
              _dataLoadingFuture = _fetchDataAndScheduleNotifications();
            });
          });
        },
        splashColor: isCurrent ? currentPrayerItemTextColor.withAlpha((0.1 * 255).round()) : AppColors.primary(brightness).withAlpha((0.1 * 255).round()),
        highlightColor: isCurrent ? currentPrayerItemTextColor.withAlpha((0.05 * 255).round()) : AppColors.primary(brightness).withAlpha((0.05 * 255).round()),
        child: Container(
          // margin: const EdgeInsets.symmetric(vertical: 0), // Removed margin, handled by separator
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjusted padding
          decoration: BoxDecoration( // This decoration is now for the InkWell's child, or remove if list items are plain
            color: itemBackgroundColor, // Applied calculated background
            // borderRadius: BorderRadius.circular(10), // Removed if list items are plain within a card
            border: Border( // Apply border only if current, or rely on Divider
              top: BorderSide(color: Colors.transparent), // Example: only bottom border from divider
            )
          ),
          child: Row(
            children: [
              Icon(
                _getPrayerIcon(name),
                color: itemIconColor,
                size: 22, // Slightly smaller icon
              ),
              const SizedBox(width: 16), // Increased spacing
              Text(
                name,
                style: AppTextStyles.prayerName(brightness).copyWith(
                  color: itemTextColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                time != null ? format.format(time.toLocal()) : '---',
                style: AppTextStyles.prayerTime(brightness).copyWith(
                  color: itemTextColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    // Get localizations from context
    final localizations = AppLocalizations.of(context)!;

    // Use standardized checks with localized prayer names
    if (prayerName == localizations.prayerNameFajr) {
      return Icons.wb_sunny_outlined; // Dawn/Sunrise icon
    } else if (prayerName == localizations.prayerNameSunrise) {
      return Icons.wb_twilight_outlined; // Sunrise icon
    } else if (prayerName == localizations.prayerNameDhuhr) {
      return Icons.wb_sunny; // Midday sun
    } else if (prayerName == localizations.prayerNameAsr) {
      return Icons.wb_twilight; // Afternoon/twilight
    } else if (prayerName == localizations.prayerNameMaghrib) {
      return Icons.brightness_4_outlined; // Sunset icon
    } else if (prayerName == localizations.prayerNameIsha) {
      return Icons.nights_stay; // Moon/night icon
    } else {
      return Icons.access_time; // Fallback icon
    }
  }
}

/// A widget that displays a countdown timer for the next prayer.
/// It manages its own timer to update every second, optimizing rebuilds.
class PrayerCountdownTimer extends StatefulWidget {
  final Duration initialDuration;
  final TextStyle? textStyle; // Optional style for the text
  final AppLocalizations localizations; // Add localizations parameter

  const PrayerCountdownTimer({
    super.key,
    required this.initialDuration,
    this.textStyle,
    required this.localizations, // Add localizations parameter
  });

  @override
  State<PrayerCountdownTimer> createState() => _PrayerCountdownTimerState();
}

class _PrayerCountdownTimerState extends State<PrayerCountdownTimer> {
  late Duration _currentDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentDuration = widget.initialDuration;
    _startInternalTimer();
  }

  @override
  void didUpdateWidget(PrayerCountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the initial duration passed from the parent changes (e.g., prayer time updated),
    // reset the timer with the new duration.
    if (widget.initialDuration != oldWidget.initialDuration) {
      _timer?.cancel();
      _currentDuration = widget.initialDuration;
      _startInternalTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startInternalTimer() {
    // Only start timer if duration is positive
    if (_currentDuration.isNegative) {
      // Ensure the display is correct even if the initial duration is negative
      if (mounted) setState(() {});
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentDuration = _currentDuration - const Duration(seconds: 1);
        if (_currentDuration.isNegative) {
          // Stop the timer when it reaches zero or becomes negative
          timer.cancel();
          // Optionally: Trigger a callback to notify parent that timer finished
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the text to display based on the duration
    final String displayText =
        _currentDuration.isNegative
            ? widget
                .localizations
                .now // Use localized "Now" string
            : widget.localizations.homeTimeIn(
              _formatDuration(_currentDuration),
            ); // Use localized "In XX:XX:XX" format

    return Text(
      displayText,
      style:
          widget.textStyle ??
          const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ), // Use provided style or default
    );
  }
}
