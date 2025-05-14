// Standard library imports
import 'dart:async';
import 'dart:math' as math;

// Third-party imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Local imports
import '../l10n/app_localizations.dart';
import '../service_locator.dart';
import '../services/compass_service.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../styles/app_styles.dart';

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView>
    with SingleTickerProviderStateMixin {
  final LocationService _locationService = locator<LocationService>();
  final CompassService _compassService = locator<CompassService>();
  final LoggerService _logger = locator<LoggerService>();

  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  double? _magneticHeading; // Raw heading from compass
  double? _qiblaDirection; // True Qibla direction
  StreamSubscription<CompassEvent>? _compassSubscription;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentCity;

  // Throttle compass updates to reduce UI updates
  DateTime _lastCompassUpdate = DateTime.now();
  static const int _compassUpdateThrottleMs = 100;

  @override
  void initState() {
    super.initState();
    _logger.info('QiblaView initialized');

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(_animationController);

    _initQiblaFinder();
  }

  @override
  void dispose() {
    _logger.debug('QiblaView disposed');
    _compassSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initQiblaFinder() async {
    _logger.debug('Initializing Qibla finder');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        _logger.error('Location permission not granted for Qibla finder');
        if (mounted) {
          setState(() {
            _errorMessage = 'Location permission denied. Please enable it in settings.';
            _isLoading = false;
          });
        }
        return;
      }

      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _logger.error('Location service is disabled for Qibla finder');
        throw Exception('Location service is disabled');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      // Get Qibla direction (which is already true Qibla from the service)
      _qiblaDirection = await _compassService.getQiblaDirection(position);
      // Optionally fetch current city name via reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        _currentCity = placemarks.isNotEmpty ? placemarks.first.locality : null;
      } catch (_) {
        _currentCity = null;
      }

      if (_qiblaDirection == null) {
        _logger.error('Failed to calculate Qibla direction.');
        throw Exception('Could not calculate Qibla direction.');
      }

      _logger.info(
        'True Qibla direction calculated: $_qiblaDirection°',
      );

      _compassSubscription?.cancel();

      if (_compassService.compassEvents == null) {
        _logger.error('Compass sensor not available');
        throw Exception('Compass sensor not available');
      }

      _compassSubscription = _compassService.compassEvents!.listen(
        _handleCompassEvent,
        onError: _handleCompassError,
      );
    } catch (e) {
      _logger.error(
        'Error in Qibla finder initialization',
        error: e.toString(),
      );
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCompassEvent(CompassEvent event) {
    final now = DateTime.now();
    if (now.difference(_lastCompassUpdate).inMilliseconds > _compassUpdateThrottleMs &&
        mounted) {
      _lastCompassUpdate = now;
      setState(() {
        _magneticHeading = event.heading;
        _logger.debug('[DEBUG-QIBLA] Updated magnetic heading: $_magneticHeading°');
      });
    }
  }

  void _handleCompassError(dynamic error) {
    _logger.error('Compass sensor error', error: error.toString());
    if (mounted) {
      setState(() {
        _errorMessage = 'Compass sensor error: $error';
        _magneticHeading = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(localizations.qiblaLabel, style: AppTextStyles.appTitle),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _rotationAnimation,
              child: const Icon(Icons.explore, color: Colors.white),
            ),
            tooltip: localizations.retry,
            onPressed: () {
              _logger.logInteraction(
                'QiblaView',
                'Refresh live qibla direction',
              );
              _initQiblaFinder();
            },
          ),
        ],
      ),
      body: Center(
        child:
            _isLoading
                ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                )
                : _errorMessage != null
                ? _buildErrorView(localizations)
                : _buildQiblaView(localizations),
      ),
    );
  }

  Widget _buildErrorView(AppLocalizations localizations) {
    String msg = _errorMessage ?? '';
    if (msg == 'Location permission denied. Please enable it in settings.') {
      msg = 'Location permission is required for Qibla finder. Please enable it in your browser/device settings.';
    } else if (msg.contains('permission')) {
      msg =
          '${localizations.qiblaErrorLocation}\n\nThe qibla view requires access to your live location.';
    } else if (msg.contains('service is disabled')) {
      msg =
          '${localizations.qiblaErrorLocation}\n\nPlease enable location services to use the qibla feature.';
    } else if (msg.contains('Location unavailable')) {
      msg =
          '${localizations.qiblaErrorLocation}\n\nCouldn\'t access your current location.';
    } else if (msg.contains('Compass')) {
      msg = localizations.qiblaErrorSensor;
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            msg,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _logger.logInteraction(
                'QiblaView',
                'Retry after error',
                data: {'error': _errorMessage},
              );
              _initQiblaFinder();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
            ),
            child: Text(localizations.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaView(AppLocalizations localizations) {
    final aligned = _isQiblaAligned();
    final helpText = _getAlignmentHelpText(localizations);
    final compassData = _buildCompassView(aligned);
    final compassStack = compassData[0] as Widget;
    final arrowColor = compassData[1] as Color;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            localizations.qiblaInstruction,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.mosque, size: 40, color: arrowColor),
          const SizedBox(height: 10),
          Expanded(child: Center(child: compassStack)),
          const SizedBox(height: 15),
          if (helpText.isNotEmpty)
            Text(
              helpText,
              textAlign: TextAlign.center,
              style: AppTextStyles.prayerName.copyWith(
                color: aligned ? AppColors.primary : AppColors.textPrimary,
                fontWeight: aligned ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 15),
          _buildLocationInfo(localizations),
        ],
      ),
    );
  }

  bool _isQiblaAligned() {
    if (_magneticHeading == null || _qiblaDirection == null) return false;
    // Compare magnetic heading with True Qibla direction
    // The painter will handle displaying this correctly.
    // Alignment means the device's magnetic north is pointing towards True Qibla.
    final diff = (_magneticHeading! - _qiblaDirection!).abs() % 360;
    final err = diff > 180 ? 360 - diff : diff;
    return err <= 5; // 5 degrees tolerance
  }

  List<dynamic> _buildCompassView(bool aligned) {
    // Render compass dial and arrow
    final magneticAngleForDial =
        _magneticHeading != null ? -_degreesToRadians(_magneticHeading!) : 0.0;

    Color arrowColor = Colors.red;
    // Alignment color logic should use trueHeading against true Qibla direction
    if (_magneticHeading != null && _qiblaDirection != null) {
      // Difference between magnetic heading and True Qibla.
      // This difference determines the arrow color based on how far off the user is.
      final diff = (_magneticHeading! - _qiblaDirection!).abs() % 360;
      final err = diff > 180 ? 360 - diff : diff;
      arrowColor = err <= 5 // 5 degrees tolerance
          ? AppColors.primary
          : err <= 20 // 20 degrees tolerance
              ? Colors.amber
              : Colors.red;
    }

    final stack = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                aligned ? Border.all(color: AppColors.primary, width: 3) : null,
          ),
        ),
        Transform.rotate(
          angle: magneticAngleForDial, // Rotate compass card with magnetic heading
          child: _buildCompassDirections(AppLocalizations.of(context)!),
        ),
        // Custom painter draws arrow relative to magnetic north
        if (_magneticHeading != null && _qiblaDirection != null)
          CustomPaint(
            size: const Size(240, 240),
            painter: QiblaDirectionPainter(
              qiblaAngleFromTrueNorth: _qiblaDirection!,
              magneticDeviceHeading: _magneticHeading!,
              magneticDeclination: 0.0, // Pass 0.0 as declination is not used for True Qibla
              arrowColor: arrowColor,
            ),
          ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: arrowColor, shape: BoxShape.circle),
        ),
        if (_magneticHeading == null) // Check magnetic heading for sensor data
          Container(
            width: 280,
            height: 280,
            alignment: Alignment.center,
            child: Text(
              AppLocalizations.of(context)!.qiblaNoCompassData,
              textAlign: TextAlign.center,
              style: AppTextStyles.currentPrayer,
            ),
          ),
      ],
    );
    return [stack, arrowColor];
  }

  Widget _buildCompassDirections(AppLocalizations localizations) {
    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            child: Text(
              localizations.qiblaDirectionNorth,
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          Positioned(
            right: 10,
            child: Text(
              localizations.qiblaDirectionEast,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          Positioned(
            bottom: 10,
            child: Text(
              localizations.qiblaDirectionSouth,
              style: AppTextStyles.sectionTitle,
            ),
          ),
          Positioned(
            left: 10,
            child: Text(
              localizations.qiblaDirectionWest,
              style: AppTextStyles.sectionTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Flexible(
          child: Column(
            children: [
              Text(
                localizations.qiblaCurrentDirectionLabel,
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              Text(
                // Display true heading if available, otherwise magnetic, or N/A
                _magneticHeading != null
                    ? '${_magneticHeading!.toInt()}° (M)'
                    : localizations.qiblaNotAvailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.currentPrayer,
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: [
              Text(
                localizations.qiblaDirectionLabel, // This is True Qibla
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              Text(
                _qiblaDirection != null
                    ? '${_qiblaDirection!.toInt()}°' // Already true
                    : localizations.qiblaNotAvailable,
                textAlign: TextAlign.center,
                style: AppTextStyles.currentPrayer,
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            children: [
              Text(
                localizations.currentLocation,
                style: AppTextStyles.label,
                textAlign: TextAlign.center,
              ),
              Text(
                _currentCity ?? localizations.unknown,
                textAlign: TextAlign.center,
                style: AppTextStyles.currentPrayer,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAlignmentHelpText(AppLocalizations localizations) {
    // Use trueHeading for alignment help text
    if (_magneticHeading == null || _qiblaDirection == null) return '';
    if (_isQiblaAligned()) return localizations.qiblaAligned;

    // Calculate difference: how much to turn the device (magnetic heading) to align with True Qibla.
    double diff = _qiblaDirection! - _magneticHeading!;
    while (diff <= -180) { diff += 360; }
    while (diff > 180)  { diff -= 360; }

    // More descriptive turn instructions
    final int diffInt = diff.round();
    if (diffInt > 5) { // Adjusted threshold for more practical advice
      return '${localizations.qiblaTurnRight} (~$diffInt°)';
    }
    if (diffInt < -5) { // Adjusted threshold
      return '${localizations.qiblaTurnLeft} (~${diffInt.abs()}°)';
    }
    // Very close but not aligned
    if (diffInt.abs() > 0 && diffInt.abs() <= 5) {
      return localizations.qiblaAlmostThere;
    }
    return ''; // Should ideally be covered by _isQiblaAligned
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
}

class QiblaDirectionPainter extends CustomPainter {
  final double qiblaAngleFromTrueNorth;
  final double magneticDeviceHeading;
  final double magneticDeclination;
  final Color arrowColor;

  QiblaDirectionPainter({
    required this.qiblaAngleFromTrueNorth,
    required this.magneticDeviceHeading,
    required this.magneticDeclination,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // The qiblaAngleFromTrueNorth is already relative to true north
    // The compass/device heading we get is relative to magnetic north
    // Since the compass rotates based on magnetic north, we need to:
    // 1. Convert the qibla angle to be relative to magnetic north
    // 2. Then calculate the relative angle between that and our magnetic heading
    final qiblaAngleFromMagneticNorth = (qiblaAngleFromTrueNorth - magneticDeclination + 360) % 360;
    
    // Calculate display angle for arrow (in radians)
    final displayAngleRadians = ((qiblaAngleFromMagneticNorth - magneticDeviceHeading + 360) % 360) * (math.pi / 180);

    final end = Offset(
      center.dx + radius * math.sin(displayAngleRadians),
      center.dy - radius * math.cos(displayAngleRadians),
    );

    canvas.drawLine(center, end, paint);

    // Draw arrow head
    const arrowSize = 15.0;
    final angle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    final path = Path()
      ..moveTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();
    
    final fill = Paint()..color = arrowColor;
    canvas.drawPath(path, fill);
  }

  @override
  bool shouldRepaint(covariant QiblaDirectionPainter old) =>
      old.qiblaAngleFromTrueNorth != qiblaAngleFromTrueNorth ||
      old.magneticDeviceHeading != magneticDeviceHeading ||
      old.magneticDeclination != magneticDeclination ||
      old.arrowColor != arrowColor;
}
