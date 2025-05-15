import 'dart:async';
import 'dart:convert';
// import 'package:geocoding/geocoding.dart'; // Removed unused import
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/notification_service.dart';
import '../services/logger_service.dart';

/// Custom exception for location service related errors
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}

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
  // Permission request state
  PermissionRequestState _permissionState = PermissionRequestState.notStarted;
  final _permissionStateController =
      StreamController<PermissionRequestState>.broadcast();

  Stream<PermissionRequestState> get permissionState =>
      _permissionStateController.stream;
  // Private fields
  SharedPreferences? _prefs;
  StreamSubscription<Position>? _locationSubscription;
  Position? _lastKnownPosition;
  bool _isInitialized = false;
  bool _isLocationPermissionBlocked = false;
  Timer? _locationCheckTimer;
  StreamController<bool>? _locationStatusController;
  bool _disposed = false;
  // Debounce timestamp for permission checks
  DateTime? _lastLocationCheck;

  // Public getters
  Stream<bool> get locationStatus =>
      _locationStatusController?.stream ?? Stream.value(false);
  bool get isLocationBlocked => _isLocationPermissionBlocked;

  // Constants
  static const LocationSettings defaultLocationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 100, // Update only if moved 100 meters
    timeLimit: Duration(seconds: 10), // Add timeout to prevent hanging
  );

  static const String _manualLatKey = 'manual_latitude';
  static const String _manualLngKey = 'manual_longitude';
  static const String _locationNameKey = 'location_name';
  static const String _useManualLocationKey = 'use_manual_location';
  static const String _lastKnownPositionKey = 'last_known_position';
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
      await _loadLastPosition();

      // Set device location as default if not already set
      await setDefaultToDeviceLocation();

      await startPermissionFlow();
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

  Future<void> startPermissionFlow() async {
    _logger.info(
      'Starting permission flow.',
      data: {'currentState': _permissionState.toString()},
    );
    if (_permissionState != PermissionRequestState.notStarted || _disposed) {
      _logger.debug('Permission flow not started or service disposed.');
      return;
    }

    // Show explanation dialog first
    final explanationAccepted = await showPermissionExplanationDialog();
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
    final locationPermission = await requestLocationWithDialog();
    if (!locationPermission) {
      _updatePermissionState(PermissionRequestState.denied);
      _logger.info('Location permission denied via dialog.');
      await _handlePermissionDenied();
      return;
    }

    _updatePermissionState(PermissionRequestState.completed);
    await checkLocationPermission();
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

  Future<bool> showPermissionExplanationDialog() async {
    _logger.debug('showPermissionExplanationDialog called (simulated true)');
    try {
      // This would be implemented by the UI layer showing an AlertDialog
      // Default to true to prevent blocking functionality during development
      return Future.value(true);
    } catch (e) {
      _logger.error('Error showing permission dialog', error: e);
      return false;
    }
  }

  Future<bool> showLocationRationaleDialog() async {
    _logger.debug('showLocationRationaleDialog called (simulated true)');
    try {
      // This would be implemented by the UI layer
      // Default to true to prevent blocking functionality during development
      return Future.value(true);
    } catch (e) {
      _logger.error('Error showing location rationale dialog', error: e);
      return false;
    }
  }

  Future<bool> requestLocationWithDialog() async {
    _logger.debug('Requesting location with dialog.');
    try {
      final permission = await Geolocator.checkPermission();
      _logger.debug(
        'Initial location permission status',
        data: {'permission': permission.toString()},
      );

      if (permission == LocationPermission.denied) {
        // Show rationale dialog before requesting
        final showRationale = await showLocationRationaleDialog();
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

  Future<void> checkLocationPermission() async {
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

  // Keep original method name for compatibility
  Future<bool> isLocationPermissionGranted() => hasLocationPermission();

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> _loadLastPosition() async {
    if (_disposed) return;
    try {
      final String? lastPosJson = _prefs?.getString(_lastKnownPositionKey);
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
        _lastKnownPositionKey,
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
  }

  /// Check if manual location is being used
  bool isUsingManualLocation() {
    return _prefs?.getBool(_useManualLocationKey) ?? false;
  }

  /// Set manual location with specific coordinates and an optional name
  Future<void> setManualLocation(
    double latitude,
    double longitude, {
    String? name,
  }) async {
    await _prefs?.setDouble(_manualLatKey, latitude);
    await _prefs?.setDouble(_manualLngKey, longitude);

    if (name != null) {
      await _prefs?.setString(_locationNameKey, name);
    }
  }

  /// Get the current location either from device or manual settings
  Future<Position> getLocation() async {
    if (isUsingManualLocation()) {
      return getManualLocation();
    } else {
      try {
        // Check permission status first
        final hasPermission = await _checkLocationPermission();
        if (!hasPermission) {
          _logger.warning('Location permission denied');
          return _getLastKnownLocationOrDefault();
        }

        final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isServiceEnabled) {
          _logger.warning('Location services disabled');
          return _getLastKnownLocationOrDefault();
        }

        // Set a shorter timeout and handle it properly
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5), // Reduced from 10 to 5 seconds
          ),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            _logger.warning('Location request timed out, using fallback');
            throw TimeoutException('Location request timed out');
          },
        );

        // Save position for future reference
        await cacheCurrentLocation(position);

        return position;
      } catch (e) {
        _logger.error('Error getting current location', error: e);
        return _getLastKnownLocationOrDefault();
      }
    }
  }

  /// Get the manual location set by the user
  Future<Position> getManualLocation() async {
    final lat = _prefs?.getDouble(_manualLatKey);
    final lng = _prefs?.getDouble(_manualLngKey);

    if (lat == null || lng == null) {
      throw const LocationServiceException(
        'Manual location not set. Please set a location in settings.',
      );
    }

    return Position(
      latitude: lat,
      longitude: lng,
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

  Future<String?> getLocationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_locationNameKey);
  }

  Stream<Position> getLocationStream({LocationSettings? settings}) async* {
    await _locationSubscription?.cancel();

    final stream = Geolocator.getPositionStream(
          locationSettings: settings ?? defaultLocationSettings,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: (sink) {
            _logger.info('Location stream timed out');
            sink.close();
          },
        )
        .handleError((error) {
          _logger.error('Location stream error', error: error);
          // Log the error. Don't return a value here, let the stream handle errors/closure.
          // If a fallback is needed, it should be handled by the stream consumer
          // or by adding an error event to the sink if appropriate.
          // Returning _lastKnownPosition here incorrectly terminates the stream processing.
          // Consider adding error to sink: sink.addError(error); sink.close();
          // Or just let the stream close/error out naturally.
          // For now, just log and let the stream manage itself.
          // If _lastKnownPosition is needed as a fallback, the UI/consumer should use it.
          // throw error; // Re-throwing might be appropriate depending on desired stream behavior
        });

    _locationSubscription = stream.listen((position) {
      _lastKnownPosition = position;
      _saveLastPosition(position);
    }, onError: (e) => _logger.error('Location subscription error', error: e));

    yield* stream;
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Sets device location as default if no location preference exists
  Future<void> setDefaultToDeviceLocation() async {
    try {
      // Only set default if _prefs is initialized
      if (_prefs != null) {
        // Check if the manual location flag has never been set (is null)
        if (!_prefs!.containsKey(_useManualLocationKey)) {
          // Set the flag to false to use device location by default
          await _prefs!.setBool(_useManualLocationKey, false);
          _logger.info('Default location set to use device location');
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

  /// Check if location permission is granted
  Future<bool> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      _logger.error('Error checking location permission', error: e);
      return false;
    }
  }

  /// Gets last known location from shared preferences or returns default
  Future<Position> _getLastKnownLocationOrDefault() async {
    try {
      // Try to get cached location from preferences
      if (_lastKnownPosition != null) {
        _logger.info('Using last known position as fallback');
        return _lastKnownPosition!;
      }

      // Try to get manual location as fallback
      if (_prefs?.containsKey(_manualLatKey) == true &&
          _prefs?.containsKey(_manualLngKey) == true) {
        _logger.info('Using manual location as fallback');
        return getManualLocation();
      }

      // If no cached location, return a default location (Mecca)
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
  Future<void> cacheCurrentLocation(Position position) async {
    try {
      await _saveLastPosition(position);
    } catch (e) {
      _logger.error('Error caching location', error: e);
    }
  }
}
