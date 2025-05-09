import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final LocationService _locationService = locator<LocationService>();
  final PrayerService _prayerService = locator<PrayerService>();
  final NotificationService _notificationService =
      locator<NotificationService>();
  final LoggerService _logger = locator<LoggerService>();
  final ScrollController _scrollController = ScrollController();
  static const double _prayerItemHeight = 80.0;
  Timer? _permissionCheckTimer;
  Timer? _dailyRefreshTimer;
  VoidCallback? _settingsListener; // Listener for settings changes
  AppSettings? _previousSettings; // Store previous settings for comparison
  String? _lastKnownCity; // Store last known location details for loading state
  String? _lastKnownCountry;
  late final SettingsProvider _settingsProvider; // cache provider for safe disposal

  void _startPermissionCheck() {
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        context.read<SettingsProvider>().checkNotificationPermissionStatus();
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
    // Cache SettingsProvider to avoid context lookup in dispose
    _settingsProvider = context.read<SettingsProvider>();
    // Initial data load and scheduling
    _dataLoadingFuture = _fetchDataAndScheduleNotifications();

    // Initial permission check and start periodic check
    _settingsProvider.checkNotificationPermissionStatus();
    _startPermissionCheck();

    // Store initial settings and add listener
    _previousSettings = _settingsProvider.settings;
    _settingsListener = () => _handleSettingsChange(_settingsProvider.settings);
    _settingsProvider.addListener(_settingsListener!);

    // Start daily refresh timer
    _startDailyRefreshTimer();
  }

  @override
  void dispose() {
    _logger.debug('HomeView disposed');
    _permissionCheckTimer?.cancel();
    _dailyRefreshTimer?.cancel();
    
    final listener = _settingsListener;
    _settingsListener = null;
    if (listener != null) {
      _settingsProvider.removeListener(listener);
    }
    
    _scrollController.dispose();
    super.dispose();
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
  void _handleSettingsChange(AppSettings newSettings) {
    _logger.debug(
      'Settings changed in HomeView',
      data: {'newSettings': newSettings.toJson()},
    );
    // No need to check _prayerTimes == null here, rescheduling only happens if it's not null anyway.
    if (!mounted || _previousSettings == null) return;

    bool needsReschedule = false;
    bool needsReload = false;

    // Check relevant settings for changes that require reloading prayer times
    if (newSettings.calculationMethod != _previousSettings!.calculationMethod ||
        newSettings.madhab != _previousSettings!.madhab) {
      needsReload = true;
      needsReschedule = true; // Reload implies reschedule
      _logger.info(
        "Calculation method or Madhab change detected, reloading data...",
        data: {
          'oldMethod': _previousSettings!.calculationMethod,
          'newMethod': newSettings.calculationMethod,
          'oldMadhab': _previousSettings!.madhab,
          'newMadhab': newSettings.madhab,
        },
      );
    }
    // Check for changes that only require rescheduling notifications
    else if (!mapEquals(
      newSettings.notifications,
      _previousSettings!.notifications,
    )) {
      needsReschedule = true;
      _logger.info(
        "Notification settings change detected, rescheduling notifications...",
        data: {
          'oldNotifications': _previousSettings!.notifications.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
          'newNotifications': newSettings.notifications.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        },
      );
    }

    // Update previous settings regardless
    _previousSettings = newSettings;

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
        // Get current device location
        try {
          position = await _locationService.getLocation();
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
          final currentSettings = context.read<SettingsProvider>().settings;
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
      final settings = context.read<SettingsProvider>().settings;

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
    final settingsProvider = context.read<SettingsProvider>();
    final settings = settingsProvider.settings;

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
      final bool isEnabled = settings.notifications[prayer] ?? false;

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
    // Use watch to rebuild on any settings change
    final settingsProvider = context.watch<SettingsProvider>();
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(localizations.appTitle, style: AppTextStyles.appTitle),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataLoadingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading indicator but also the basic structure if prayer times exist
            return _buildMainContent(
              isLoading: true,
              prayerTimes: _prayerTimes,
              displayCity: _lastKnownCity ?? localizations.loading,
              displayCountry: _lastKnownCountry,
              settingsProvider: settingsProvider,
              localizations: localizations,
            );
          } else if (snapshot.hasError) {
            String errorMessage = _processLoadError(snapshot.error);
            // Show error UI
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _dataLoadingFuture =
                              _fetchDataAndScheduleNotifications();
                        });
                      },
                      child: Text(localizations.retry),
                    ),
                    if (errorMessage.contains('permission'))
                      TextButton(
                        onPressed: () => _locationService.openAppSettings(),
                        child: Text(localizations.openAppSettings),
                      ),
                    if (errorMessage.contains('services are disabled'))
                      TextButton(
                        onPressed:
                            () => _locationService.openLocationSettings(),
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
              settingsProvider: settingsProvider,
              localizations: localizations,
            );
          } else {
            return Center(
              child: Text(localizations.unexpectedError(localizations.unknown)),
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
    required SettingsProvider settingsProvider,
    required AppLocalizations localizations,
  }) {
    // Dynamic settings and formatting within content build
    final settings = settingsProvider.settings;
    final now = DateTime.now();
    // Choose date pattern based on user setting
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
    // Time format for prayer list
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
        // Location and Date Info
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                    Text(formattedGregorian, style: AppTextStyles.date),
                    Text(formattedHijri, style: AppTextStyles.dateSecondary),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: GestureDetector(
                  onDoubleTap: () {
                    // Navigate to settings view with location section focus
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const SettingsView(scrollToLocation: true),
                        settings: const RouteSettings(name: '/settings'),
                      ),
                    ).then((_) {
                      // Refresh data when returning from settings - ensure a complete refresh
                      if (mounted) {
                        setState(() {
                          // Force a complete refresh of data
                          _prayerTimes = null; // Reset prayer times
                          _lastKnownCity = null; // Reset cached location
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
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              displayCity ?? localizations.unknownLocation,
                              style: AppTextStyles.date,
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      if (displayCountry != null && displayCountry.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Text(
                            displayCountry,
                            style: AppTextStyles.dateSecondary,
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

        const SizedBox(height: 16),

        // Current & Next Prayer Box
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align children to the top
            children: [
              // Current Prayer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.currentPrayerTitle,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? '...'
                          : _currentPrayerName, // Show loading or actual name
                      style: AppTextStyles.currentPrayer,
                    ),
                  ],
                ),
              ),
              // Next Prayer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      localizations.nextPrayerTitle,
                      style: AppTextStyles.label,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading
                          ? '...'
                          : _nextPrayerName, // Show loading or actual name
                      style: AppTextStyles.nextPrayer,
                    ),
                    // Use the new PrayerCountdownTimer widget here
                    Builder(
                      // Use Builder to get fresh DateTime.now()
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
                          // Use zero duration if loading or time is null/past
                          initialDuration:
                              isLoading
                                  ? Duration.zero
                                  : initialCountdownDuration,
                          textStyle: AppTextStyles.countdownTimer,
                          localizations: localizations,
                        );
                      },
                    ), // End of Builder
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              localizations.prayerTimesTitle,
              style: AppTextStyles.sectionTitle,
            ),
          ),
        ),

        // Prayer times list
        Expanded(
          child: Stack(
            // Use Stack to overlay loading indicator
            children: [
              ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: prayerOrder.length,
                itemBuilder: (context, index) {
                  final prayerEnum = prayerOrder[index];
                  DateTime? prayerTime;
                  String prayerNameString; // Name for display and icon lookup

                  switch (prayerEnum) {
                    case PrayerNotification.fajr:
                      prayerTime = prayerTimes?.fajr; // Use nullable access
                      prayerNameString = localizations.prayerNameFajr;
                      break;
                    case PrayerNotification.sunrise:
                      prayerTime = prayerTimes?.sunrise; // Use nullable access
                      prayerNameString = localizations.prayerNameSunrise;
                      break;
                    case PrayerNotification.dhuhr:
                      prayerTime = prayerTimes?.dhuhr; // Use nullable access
                      prayerNameString = localizations.prayerNameDhuhr;
                      break;
                    case PrayerNotification.asr:
                      prayerTime = prayerTimes?.asr; // Use nullable access
                      prayerNameString = localizations.prayerNameAsr;
                      break;
                    case PrayerNotification.maghrib:
                      prayerTime = prayerTimes?.maghrib; // Use nullable access
                      prayerNameString = localizations.prayerNameMaghrib;
                      break;
                    case PrayerNotification.isha:
                      prayerTime = prayerTimes?.isha; // Use nullable access
                      prayerNameString = localizations.prayerNameIsha;
                      break;
                  }

                  // Get notification enabled status from provider's settings
                  final bool isEnabled =
                      settings.notifications[prayerEnum] ?? false;
                  // Check if this prayer is the current one (only if not loading)
                  final bool isCurrent =
                      !isLoading && _currentPrayerName == prayerNameString;

                  return _buildPrayerItemWithSwitch(
                    prayerNameString, // Localized name for display
                    prayerEnum, // Enum value for updating settings
                    prayerTime,
                    timeFormat,
                    isCurrent,
                    isEnabled, // Pass enabled status
                    settingsProvider, // Pass provider for updates
                  );
                },
              ),
              if (isLoading) // Overlay loading indicator
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a single row in the prayer times list, without the toggle switch.
  Widget _buildPrayerItemWithSwitch(
    String name,
    PrayerNotification prayerEnum,
    DateTime? time,
    DateFormat format,
    bool isCurrent,
    bool isEnabled,
    SettingsProvider settingsProvider,
  ) {
    return GestureDetector(
      onDoubleTap: () {
        // Navigate to settings screen with notification section when prayer is double-tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => const SettingsView(scrollToNotifications: true),
            settings: const RouteSettings(name: '/settings'),
          ),
        ).then((_) {
          // Refresh data if needed after returning from settings
          setState(() {
            _dataLoadingFuture = _fetchDataAndScheduleNotifications();
          });
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            // Prayer Icon
            Icon(
              _getPrayerIcon(name),
              color: isCurrent ? AppColors.primary : AppColors.iconInactive,
              size: 24, // Increased from 20 to 24
            ),
            const SizedBox(width: 12),

            // Prayer Name with increased font size
            Text(
              name,
              style: TextStyle(
                fontSize: 18, // Increased from 16 to 18
                fontWeight: FontWeight.w600, // Changed from w500 to w600
                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
              ),
            ),

            const Spacer(),

            // Prayer Time
            Text(
              time != null ? format.format(time.toLocal()) : '---',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isCurrent ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
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
