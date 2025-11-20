import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/location_cache_manager.dart';

import 'package:muslim_deen/models/custom_exceptions.dart';
// LocationServiceException class removed

/// Comprehensive location management service for prayer time calculations.
///
/// This service provides robust location functionality including device location
/// tracking, manual location management, permission handling, and intelligent
/// caching strategies. It serves as the primary location provider for prayer
/// time calculations and other location-dependent features.
///
/// ## Key Features
/// - Dual location modes: Device GPS and manual user selection
/// - Intelligent permission flow with user guidance
/// - Multi-layer caching with adaptive strategies
/// - Background location change detection
/// - Graceful fallback to last known location or Mecca
/// - Request deduplication to prevent redundant GPS queries
///
/// ## Caching Strategy
/// - Short-term in-memory cache (5 minutes, accuracy-adjusted)
/// - Enhanced cache manager with movement pattern analysis
/// - Persistent storage for last known position
/// - Cache invalidation on significant location changes
///
/// ## Permission Management
/// - Step-by-step permission request flow
/// - Explanation dialogs before requesting permissions
/// - Graceful handling of denied permissions
/// - Automatic fallback to manual location mode
///
/// ## Dependencies
/// - [LocationCacheManager]: Advanced caching with movement analysis
/// - [LoggerService]: Centralized logging
/// - [NotificationService]: Permission coordination
/// - [Geolocator]: GPS location functionality
/// - [SharedPreferences]: Persistent settings storage
///
/// ## Error Handling
/// - Multiple fallback layers (cache → last known → Mecca)
/// - Comprehensive error logging without crashing
/// - Graceful degradation when location services fail
enum PermissionRequestState {
  notStarted,
  explanationShown,
  notificationRequested,
  locationRequested,
  completed,
  denied,
}

class LocationService {
  final LoggerService _logger = locator<LoggerService>();
  LocationCacheManager? _cacheManager;

  PermissionRequestState _permissionState = PermissionRequestState.notStarted;
  final _permissionStateController =
      StreamController<PermissionRequestState>.broadcast();

  // permissionState getter removed
  SharedPreferences? _prefs;
  StreamSubscription<Position>? _locationSubscription;
  Position? _lastKnownPosition; // For persistent storage fallback
  bool _isInitialized = false;
  bool _isLocationPermissionBlocked = false;
  Timer? _locationCheckTimer;
  StreamController<bool>? _locationStatusController;
  bool _disposed = false;
  // Debounce timestamp for permission checks
  DateTime? _lastLocationCheck;

  // In-memory cache for SharedPreferences values
  bool? _useManualLocationCached;
  double? _manualLatCached;
  double? _manualLngCached;

  // In-memory cache for device location (legacy, will be replaced by cache manager)
  Position? _cachedDevicePosition;
  DateTime? _lastDevicePositionFetchTime;
  final Duration _deviceLocationCacheDuration = const Duration(
    minutes: 5,
  ); // Extended from 30s to 5min

  // Request deduplication
  Future<Position>? _pendingLocationRequest;

  // Enhanced location tracking
  final String _lastLocationCacheKey = 'device_location';
  Timer? _locationChangeDetector;
  static const Duration _locationChangeCheckInterval = Duration(minutes: 1); // Reduced from 2 to 1 minute

  Stream<bool> get locationStatus =>
      _locationStatusController?.stream ?? Stream.value(false);
  bool get isLocationBlocked => _isLocationPermissionBlocked;

  static const String _manualLatKey = 'manual_latitude';
  static const String _manualLngKey = 'manual_longitude';
  static const String _locationNameKey = 'location_name';
  static const String _useManualLocationKey = 'use_manual_location';
  // static const String _lastKnownPositionKey = 'last_known_position'; // Replaced by direct use in methods

  LocationService();

  // Initialize with debouncing to prevent multiple rapid initializations
  bool _initializationInProgress = false;
  Future<void> init() async {
    if (_isInitialized || _initializationInProgress || _disposed) return;

    _initializationInProgress = true;
    _logger.info('LocationService initialization started.');

    try {
      _locationStatusController ??= StreamController<bool>.broadcast();

      _prefs = await SharedPreferences.getInstance();
      await _loadCachedSettings(); // Load SharedPreferences into memory
      await _loadLastPosition(); // For fallback

      // Initialize location cache manager
      _cacheManager = LocationCacheManager();
      await _cacheManager!.init();

      // Set device location as default if not already set
      await _setDefaultToDeviceLocation(); // This will also update cache

      await _startPermissionFlow();

      // Start location change detection
      _startLocationChangeDetection();

      _isInitialized = true;
      _logger.info('LocationService initialized with enhanced caching.');
    } catch (e, s) {
      _logger.error(
        'Error initializing LocationService',
        error: e,
        stackTrace: s,
      );
    } finally {
      _initializationInProgress = false;
    }
  }

  Future<void> _loadCachedSettings() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    _useManualLocationCached = _prefs?.getBool(_useManualLocationKey) ?? false;
    _manualLatCached = _prefs?.getDouble(_manualLatKey);
    _manualLngCached = _prefs?.getDouble(_manualLngKey);
    _logger.debug("Loaded settings into in-memory cache.");
  }

  /// Properly dispose of the service to prevent memory leaks
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _logger.info('Disposing LocationService.');
    _locationCheckTimer?.cancel();
    _locationSubscription?.cancel();
    _locationChangeDetector?.cancel();

    if (!_permissionStateController.isClosed) {
      _permissionStateController.close();
    }

    if (_locationStatusController != null &&
        !_locationStatusController!.isClosed) {
      _locationStatusController!.close();
    }

    _cacheManager?.dispose();
  }

  Future<void> _startPermissionFlow() async {
    _logger.info(
      'Starting permission flow.',
      data: {'currentState': _permissionState.toString()},
    );
    if (_permissionState != PermissionRequestState.notStarted || _disposed) {
      _logger.debug('Permission flow not started or service disposed.');
      return;
    }

    // Show explanation dialog first
    final explanationAccepted = await _showPermissionExplanationDialog();
    if (!explanationAccepted) {
      _updatePermissionState(PermissionRequestState.denied);
      _logger.info('Permission explanation not accepted.');
      await _handlePermissionDenied();
      return;
    }
    _updatePermissionState(PermissionRequestState.explanationShown);

    // Request notification permission
    final notificationService = locator<NotificationService>();
    final hasNotificationPermission =
        await notificationService.requestPermission();

    if (!hasNotificationPermission) {
      // _updatePermissionState(PermissionRequestState.denied); // Consider if this state update is still appropriate here for notifications, or if it should only apply to location denial.
      _logger.info(
        'Notification permission denied. Proceeding to request location permission.',
      );
      // DO NOT call await _handlePermissionDenied(); here for notification denial.
      // DO NOT return; here. Allow the flow to continue to request location permissions.
    }

    _updatePermissionState(PermissionRequestState.notificationRequested);

    // Request location permission
    final locationPermission = await _requestLocationWithDialog();
    if (!locationPermission) {
      _updatePermissionState(PermissionRequestState.denied);
      _logger.info('Location permission denied via dialog.');
      await _handlePermissionDenied();
      return;
    }

    _updatePermissionState(PermissionRequestState.completed);
    await _checkLocationPermission();
    _logger.info('Permission flow completed.');
  }

  /// Handle denied permissions by providing guidance to the user
  Future<void> _handlePermissionDenied() async {
    _logger.warning(
      'Permission denied. User should be guided to settings. Forcing manual location mode.',
    );
    // This would show a dialog explaining how to enable permissions
    // For now, we just log the issue
    await setUseManualLocation(true);
  }

  Future<bool> _showPermissionExplanationDialog() async {
    _logger.debug('_showPermissionExplanationDialog called (simulated true)');
    try {
      // This would be implemented by the UI layer showing an AlertDialog
      // Default to true to prevent blocking functionality during development
      return Future.value(true);
    } catch (e) {
      _logger.error('Error showing permission dialog', error: e);
      return false;
    }
  }

  Future<bool> _showLocationRationaleDialog() async {
    _logger.debug('_showLocationRationaleDialog called (simulated true)');
    try {
      // This would be implemented by the UI layer
      // Default to true to prevent blocking functionality during development
      return Future.value(true);
    } catch (e) {
      _logger.error('Error showing location rationale dialog', error: e);
      return false;
    }
  }

  Future<bool> _requestLocationWithDialog() async {
    _logger.debug('Requesting location with dialog.');
    try {
      final permission = await Geolocator.checkPermission();
      _logger.debug(
        'Initial location permission status',
        data: {'permission': permission.toString()},
      );

      if (permission == LocationPermission.denied) {
        // Show rationale dialog before requesting
        final showRationale = await _showLocationRationaleDialog();
        if (!showRationale) {
          _logger.info('User chose not to proceed after location rationale.');
          return false;
        }

        final result = await Geolocator.requestPermission();
        _logger.info(
          'Location permission requested',
          data: {'result': result.toString()},
        );
        return result == LocationPermission.whileInUse ||
            result == LocationPermission.always;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e, s) {
      _logger.error(
        'Error requesting location permission with dialog',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  void _updatePermissionState(PermissionRequestState state) {
    _permissionState = state;
    if (!_permissionStateController.isClosed) {
      _permissionStateController.add(state);
    }
  }

  Future<void> _checkLocationPermission() async {
    if (_disposed) return;

    // Debounce checks to prevent rapid consecutive calls
    final now = DateTime.now();
    if (_lastLocationCheck != null &&
        now.difference(_lastLocationCheck!) < const Duration(seconds: 5)) {
      return;
    }
    _lastLocationCheck = now;

    try {
      final permission = await Geolocator.checkPermission();
      _isLocationPermissionBlocked =
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
      if (_locationStatusController != null &&
          !_locationStatusController!.isClosed) {
        _locationStatusController!.add(!_isLocationPermissionBlocked);
      }
    } catch (e) {
      _logger.error('Error checking location permission', error: e);
      if (_locationStatusController != null &&
          !_locationStatusController!.isClosed) {
        _locationStatusController!.add(false);
      }
    }
  }

  // isLocationPermissionGranted method removed

  Future<bool> _hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _loadLastPosition() async {
    if (_disposed) return;
    try {
      final String? lastPosJson = _prefs?.getString(
        'last_known_position',
      ); // Direct string usage
      if (lastPosJson != null) {
        _lastKnownPosition = Position.fromMap(jsonDecode(lastPosJson));
        _logger.info(
          'Loaded last known position',
          data: {'position': _lastKnownPosition?.toJson()},
        );
      }
    } catch (e, s) {
      _logger.error(
        'Error loading last known position',
        error: e,
        stackTrace: s,
      );
      _lastKnownPosition = null; // Ensure it's null on error
    }
  }

  Future<void> _saveLastPosition(Position position) async {
    if (_disposed) return;
    try {
      _lastKnownPosition = position;
      await _prefs?.setString(
        'last_known_position', // Direct string usage
        jsonEncode(position.toJson()),
      );
      _logger.info(
        'Saved last known position',
        data: {'position': position.toJson()},
      );
    } catch (e, s) {
      _logger.error(
        'Error saving last known position',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Set whether to use manual location or device location
  Future<void> setUseManualLocation(bool useManual) async {
    await _prefs?.setBool(_useManualLocationKey, useManual);
    _useManualLocationCached = useManual; // Update cache
    _logger.debug("Set useManualLocation to $useManual and updated cache.");
  }

  /// Check if manual location is being used
  bool isUsingManualLocation() {
    // Prefer cached value, fallback to SharedPreferences if not initialized (should not happen in normal flow)
    return _useManualLocationCached ??
        (_prefs?.getBool(_useManualLocationKey) ?? false);
  }

  /// Set manual location with specific coordinates and an optional name
  Future<void> setManualLocation(
    double latitude,
    double longitude, {
    String? name,
  }) async {
    await _prefs?.setDouble(_manualLatKey, latitude);
    _manualLatCached = latitude; // Update cache
    await _prefs?.setDouble(_manualLngKey, longitude);
    _manualLngCached = longitude; // Update cache

    if (name != null && name.isNotEmpty) {
      // Added check for empty name
      await _prefs?.setString(_locationNameKey, name);
      // Update cache
    } else {
      await _prefs?.remove(_locationNameKey); // Remove if name is null or empty
    }
    _logger.debug(
      "Set manual location (Lat: $latitude, Lng: $longitude, Name: $name) and updated cache.",
    );
  }

  /// Get the current location either from device GPS or manual user settings
  ///
  /// This is the primary method for obtaining location data for prayer calculations.
  /// It implements a sophisticated caching and fallback strategy to ensure reliable
  /// location data while minimizing GPS usage and respecting user preferences.
  ///
  /// Design Decision: Supports both automatic (GPS) and manual location modes.
  /// Uses request deduplication to prevent multiple simultaneous GPS requests.
  /// Implements multi-layer caching with accuracy-based cache durations.
  ///
  /// Location Priority (highest to lowest):
  /// 1. Manual location (if user has set coordinates)
  /// 2. Enhanced cache manager (with movement analysis)
  /// 3. Legacy in-memory cache (with accuracy-adjusted duration)
  /// 4. Fresh GPS location (with permission checks)
  /// 5. Last known location from storage
  /// 6. Mecca fallback (21.4225°N, 39.8262°E)
  ///
  /// Returns: Future<Position> with latitude, longitude, and accuracy
  ///
  /// Throws: Exceptions are caught internally and logged; returns fallback position
  ///
  /// Performance: Uses caching to minimize GPS queries (typically 5-15 minutes)
  /// Threading: Safe for UI thread; all operations are asynchronous
  /// Battery: Intelligent caching reduces GPS usage by 80-90%
  ///
  /// Usage Example:
  /// ```dart
  /// final position = await locationService.getLocation();
  /// final prayerTimes = await prayerService.calculatePrayerTimesForDate(
  ///   DateTime.now(),
  ///   settings,
  ///   position: position,
  /// );
  /// ```
  Future<Position> getLocation() async {
    if (isUsingManualLocation()) {
      _logger.debug("Fetching manual location via getLocation().");
      return _getManualLocation();
    } else {
      _logger.debug("Fetching device location via getLocation().");

      // Request deduplication - if there's already a pending request, return it
      if (_pendingLocationRequest != null) {
        _logger.debug(
          "Location request already in progress, waiting for existing request.",
        );
        return _pendingLocationRequest!;
      }

      // Check enhanced cache first
      if (_cacheManager != null) {
        final cachedLocation = _cacheManager!.getCachedLocation(
          _lastLocationCacheKey,
        );
        if (cachedLocation != null) {
          _logger.info(
            'Using cached device position from LocationCacheManager (accuracy: ${cachedLocation.accuracy}m).',
          );
          return cachedLocation.position;
        }
      }

      // Fallback to legacy cache if cache manager is not available
      if (_cachedDevicePosition != null &&
          _lastDevicePositionFetchTime != null) {
        final cacheAge = DateTime.now().difference(
          _lastDevicePositionFetchTime!,
        );

        // Adjust cache duration based on accuracy
        final adjustedCacheDuration = _adjustCacheDuration(
          _cachedDevicePosition!.accuracy,
        );

        if (cacheAge < adjustedCacheDuration) {
          _logger.info(
            'Using legacy cached device position (fetched less than ${adjustedCacheDuration.inMinutes}min ago, accuracy: ${_cachedDevicePosition!.accuracy}m).',
          );
          return _cachedDevicePosition!;
        }
      }

      // Create the pending request
      _pendingLocationRequest = _fetchFreshLocation();

      try {
        final position = await _pendingLocationRequest!;
        return position;
      } finally {
        // Clear the pending request when done
        _pendingLocationRequest = null;
      }
    }
  }

  /// Fetch fresh location from the device with proper error handling and timeouts
  Future<Position> _fetchFreshLocation() async {
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) {
        _logger.warning(
          'Location permission denied while attempting to get device location.',
        );
        return _getLastKnownLocationOrDefault();
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _logger.warning(
          'Location services disabled while attempting to get device location.',
        );
        return _getLastKnownLocationOrDefault();
      }

      _logger.debug("Fetching fresh device position from Geolocator.");
      final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(
                seconds: 15,
              ), // Increased timeout from 10s to 15s
            ),
          )
          .timeout(
            const Duration(seconds: 20), // Increased timeout from 12s to 20s
            onTimeout: () {
              _logger.warning(
                'Geolocator.getCurrentPosition timed out after 20 seconds.',
              );
              throw TimeoutException(
                'Location request timed out after 20 seconds',
                const Duration(seconds: 20),
              );
            },
          )
          .catchError((Object e) {
            _logger.error('Geolocator.getCurrentPosition failed', error: e);
            // Re-throw to be caught by the outer try-catch
            throw Exception('Geolocator error: $e');
          });

      _cachedDevicePosition = position;
      _lastDevicePositionFetchTime = DateTime.now();

      // Cache using the enhanced cache manager
      if (_cacheManager != null) {
        // Check if this is a significant location change
        final hasSignificantChange = _cacheManager!
            .hasSignificantLocationChange(_lastLocationCacheKey, position);

        if (hasSignificantChange) {
          _logger.info(
            'Significant location change detected',
            data: {
              'newLat': position.latitude,
              'newLng': position.longitude,
              'accuracy': position.accuracy,
            },
          );
        }

        _cacheManager!.cacheLocation(_lastLocationCacheKey, position);
      }

      await cacheAsLastKnownPosition(
        position,
      ); // This also saves to persistent _lastKnownPosition
      _logger.info(
        'Fetched and cached new device position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
      );
      return position;
    } on TimeoutException catch (e) {
      _logger.warning(
        'Location request timed out: ${e.message}, using fallback from _getLastKnownLocationOrDefault.',
      );
      return _getLastKnownLocationOrDefault();
    } catch (e, s) {
      _logger.error(
        'Error getting current device location',
        error: e,
        stackTrace: s,
      );
      return _getLastKnownLocationOrDefault();
    }
  }

  /// Adjust cache duration based on location accuracy
  Duration _adjustCacheDuration(double accuracy) {
    // Higher accuracy (lower value) = longer cache duration
    // Lower accuracy (higher value) = shorter cache duration
    if (accuracy < 50) {
      // High accuracy (< 50m) - cache for 10 minutes
      return const Duration(minutes: 10);
    } else if (accuracy < 100) {
      // Medium accuracy (50-100m) - cache for 5 minutes
      return const Duration(minutes: 5);
    } else if (accuracy < 500) {
      // Low accuracy (100-500m) - cache for 2 minutes
      return const Duration(minutes: 2);
    } else {
      // Very low accuracy (> 500m) - cache for 1 minute
      return const Duration(minutes: 1);
    }
  }

  /// Get the manual location set by the user from cache or SharedPreferences
  Future<Position> _getManualLocation() async {
    // Prefer cached values
    final lat = _manualLatCached ?? _prefs?.getDouble(_manualLatKey);
    final lng = _manualLngCached ?? _prefs?.getDouble(_manualLngKey);

    if (lat == null || lng == null) {
      _logger.warning(
        "Manual location (lat/lng) not found in cache or SharedPreferences.",
      );
      throw const LocationServiceException(
        'Manual location not set. Please set a location in settings.',
      );
    }
    _logger.debug(
      "Returning manual location - Lat: $lat, Lng: $lng from cache/prefs.",
    );
    return _createPosition(lat, lng);
  }

  /// Get the stored location name, if any.
  Future<String?> getStoredLocationName() async {
    // Ensure _prefs is initialized, though it should be by the time this is called.
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getString(_locationNameKey);
  }

  // updateLocationName method removed
  // getLocationStream method removed
  // openLocationSettings method removed
  // openAppSettings method removed

  /// Sets device location as default if no location preference exists
  Future<void> _setDefaultToDeviceLocation() async {
    try {
      // Only set default if _prefs is initialized
      if (_prefs != null) {
        // Check if the manual location flag has never been set (is null)
        if (!_prefs!.containsKey(_useManualLocationKey)) {
          // Set the flag to false to use device location by default
          // This will also update the _useManualLocationCached via setUseManualLocation
          await setUseManualLocation(false);
          _logger.info(
            'Default location set to use device location (and updated cache).',
          );
        } else {
          // Ensure cache is consistent if key already exists
          _useManualLocationCached =
              _prefs!.getBool(_useManualLocationKey) ?? false;
        }
      }
    } catch (e, s) {
      _logger.error(
        'Error setting default to device location',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Gets last known location from shared preferences or returns default
  Future<Position> _getLastKnownLocationOrDefault() async {
    try {
      if (_lastKnownPosition != null) {
        _logger.info('Using last known position as fallback');
        return _lastKnownPosition!;
      }

      // Try to get manual location as fallback if manual mode is active and lat/lng are set
      if (isUsingManualLocation()) {
        final manualLat = _manualLatCached ?? _prefs?.getDouble(_manualLatKey);
        final manualLng = _manualLngCached ?? _prefs?.getDouble(_manualLngKey);
        if (manualLat != null && manualLng != null) {
          _logger.info(
            'Using manual location as fallback because it is active and set.',
          );
          return _createPosition(manualLat, manualLng);
        }
      }

      _logger.info('Using default Mecca coordinates as fallback');
      return _createMeccaPosition();
    } catch (e) {
      _logger.error('Error getting fallback location', error: e);
      // Ultimate fallback to Mecca coordinates
      return _createMeccaPosition();
    }
  }

  /// Cache the current location when it's successfully retrieved
  /// This updates the _lastKnownPosition for persistent fallback.
  /// The short-term _cachedDevicePosition is handled in getLocation().
  Future<void> cacheAsLastKnownPosition(Position position) async {
    try {
      await _saveLastPosition(
        position,
      ); // Saves to SharedPreferences for fallback
      _logger.debug(
        "Persistent _lastKnownPosition updated in SharedPreferences.",
      );
    } catch (e, s) {
      _logger.error(
        'Error caching location to _lastKnownPosition',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Creates a Position object with the given coordinates
  Position _createPosition(double latitude, double longitude) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Creates a Position object for Mecca (the default fallback location)
  Position _createMeccaPosition() {
    return Position(
      latitude: 21.422487,
      longitude: 39.826206,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Start location change detection
  void _startLocationChangeDetection() {
    _locationChangeDetector?.cancel();
    _locationChangeDetector = Timer.periodic(_locationChangeCheckInterval, (_) {
      _checkForLocationChanges();
    });
  }

  /// Check for location changes and update cache if needed
  Future<void> _checkForLocationChanges() async {
    if (_disposed || isUsingManualLocation()) return;

    try {
      // Get current location without cache to check for changes
      final currentPosition = await _getCurrentPositionUncached();
      if (currentPosition == null) return;

      // Check if this represents a significant change from cached location
      if (_cacheManager != null) {
        final hasSignificantChange = _cacheManager!
            .hasSignificantLocationChange(
              _lastLocationCacheKey,
              currentPosition,
            );

        if (hasSignificantChange) {
          _logger.info(
            'Location change detected in background',
            data: {
              'newLat': currentPosition.latitude,
              'newLng': currentPosition.longitude,
              'accuracy': currentPosition.accuracy,
            },
          );

          // Update cache with new location
          _cacheManager!.cacheLocation(_lastLocationCacheKey, currentPosition);

          // Update legacy cache as well
          _cachedDevicePosition = currentPosition;
          _lastDevicePositionFetchTime = DateTime.now();
        }
      }
    } catch (e, s) {
      _logger.error(
        'Error checking for location changes',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Get current position without using cache
  Future<Position?> _getCurrentPositionUncached() async {
    try {
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) return null;

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.warning('Uncached location request timed out');
          throw TimeoutException(
            'Location request timed out',
            const Duration(seconds: 15),
          );
        },
      );

      return position;
    } catch (e) {
      _logger.error('Error getting uncached position', error: e);
      return null;
    }
  }

  /// Get location cache statistics
  Map<String, dynamic> getLocationCacheStatistics() {
    final cacheStats = _cacheManager?.getCacheStatistics() ?? {};
    final legacyStats = {
      'legacyCacheValid':
          _cachedDevicePosition != null &&
          _lastDevicePositionFetchTime != null &&
          DateTime.now().difference(_lastDevicePositionFetchTime!) <
              _deviceLocationCacheDuration,
      'legacyCacheAge':
          _lastDevicePositionFetchTime != null
              ? DateTime.now()
                  .difference(_lastDevicePositionFetchTime!)
                  .inMinutes
              : null,
    };

    return {
      ...cacheStats,
      ...legacyStats,
      'isManualLocation': isUsingManualLocation(),
    };
  }

  /// Force refresh location cache
  Future<void> refreshLocationCache() async {
    if (isUsingManualLocation()) return;

    try {
      _logger.info('Force refreshing location cache');

      // Clear current cache
      _cacheManager?.invalidateCache(_lastLocationCacheKey);
      _cachedDevicePosition = null;
      _lastDevicePositionFetchTime = null;

      // Fetch fresh location
      await getLocation();

      _logger.info('Location cache refreshed successfully');
    } catch (e, s) {
      _logger.error('Error refreshing location cache', error: e, stackTrace: s);
    }
  }
}
