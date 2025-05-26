import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';

import 'package:muslim_deen/models/custom_exceptions.dart';
// LocationServiceException class removed

/// A service that handles location-related functionality including device location,
/// manual location settings, and location streaming.
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

  // In-memory cache for device location
  Position? _cachedDevicePosition;
  DateTime? _lastDevicePositionFetchTime;
  static const Duration _deviceLocationCacheDuration = Duration(seconds: 30);

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

      // Set device location as default if not already set
      await _setDefaultToDeviceLocation(); // This will also update cache

      await _startPermissionFlow();
      _isInitialized = true;
      _logger.info('LocationService initialized successfully.');
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

    if (!_permissionStateController.isClosed) {
      _permissionStateController.close();
    }

    if (_locationStatusController != null &&
        !_locationStatusController!.isClosed) {
      _locationStatusController!.close();
    }
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

  /// Get the current location either from device or manual settings
  Future<Position> getLocation() async {
    if (isUsingManualLocation()) {
      _logger.debug("Fetching manual location via getLocation().");
      return _getManualLocation();
    } else {
      _logger.debug("Fetching device location via getLocation().");
      // Check cache first
      if (_cachedDevicePosition != null &&
          _lastDevicePositionFetchTime != null &&
          DateTime.now().difference(_lastDevicePositionFetchTime!) <
              _deviceLocationCacheDuration) {
        _logger.info(
          'Using cached device position (fetched less than ${_deviceLocationCacheDuration.inSeconds}s ago).',
        );
        return _cachedDevicePosition!;
      }

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
            timeLimit: Duration(seconds: 10),
          ),
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () {
            _logger.warning('Geolocator.getCurrentPosition timed out.');
            throw TimeoutException('Location request timed out');
          },
        );

        _cachedDevicePosition = position;
        _lastDevicePositionFetchTime = DateTime.now();
        await cacheAsLastKnownPosition(
          position,
        ); // This also saves to persistent _lastKnownPosition
        _logger.info(
          'Fetched and cached new device position: ${position.latitude}, ${position.longitude}',
        );
        return position;
      } on TimeoutException {
        _logger.warning(
          'Location request timed out, using fallback from _getLastKnownLocationOrDefault.',
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
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(), // Timestamp is always current for this call
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
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
          return Position(
            latitude: manualLat,
            longitude: manualLng,
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
      }

      _logger.info('Using default Mecca coordinates as fallback');
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
    } catch (e) {
      _logger.error('Error getting fallback location', error: e);
      // Ultimate fallback to Mecca coordinates
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
}
