import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart'; // Added import
import 'package:muslim_deen/widgets/message_display.dart'; // Added import

class QiblaView extends StatefulWidget {
  const QiblaView({super.key});

  @override
  State<QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<QiblaView>
    with SingleTickerProviderStateMixin {
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
      final permissionStatus = await Geolocator.checkPermission();
      final hasPermission =
          permissionStatus == LocationPermission.whileInUse ||
          permissionStatus == LocationPermission.always;
      if (!hasPermission) {
        _logger.error(
          'Location permission not granted for Qibla finder',
          data: {'status': permissionStatus.toString()},
        );
        if (mounted) {
          setState(() {
            _errorMessage =
                'Location permission denied. Please enable it in settings.';
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
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        _currentCity = placemarks.isNotEmpty ? placemarks.first.locality : null;
      } catch (_) {
        _currentCity = null;
      }

      if (_qiblaDirection == null) {
        _logger.error('Failed to calculate Qibla direction.');
        throw Exception('Could not calculate Qibla direction.');
      }

      _logger.info('True Qibla direction calculated: $_qiblaDirection°');

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
    if (now.difference(_lastCompassUpdate).inMilliseconds >
            _compassUpdateThrottleMs &&
        mounted) {
      _lastCompassUpdate = now;
      setState(() {
        _magneticHeading = event.heading;
        _logger.debug(
          '[DEBUG-QIBLA] Updated magnetic heading: $_magneticHeading°',
        );
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
    final brightness = Theme.of(context).brightness;
    // final bool isDarkMode = brightness == Brightness.dark; // No longer needed for scaffoldBg

    // Define colors similar to TesbihView
    // final Color scaffoldBg = // Replaced by AppColors.getScaffoldBackground
    //     isDarkMode
    //         ? AppColors.surface(brightness)
    //         : AppColors.background(brightness);
    final bool isDarkMode =
        brightness == Brightness.dark; // Still needed for other color logic
    final Color contentSurface =
        isDarkMode
            ? const Color(0xFF2C2C2C)
            : AppColors.background(brightness); // For cards/containers
    final Color accentColor = AppColors.accentGreen(brightness);
    AppColors.error(brightness);
    final Color textColorPrimary = AppColors.textPrimary(brightness);
    final Color textColorSecondary = AppColors.textSecondary(brightness);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(
        title: "Qibla Finder",
        brightness: brightness,
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: _rotationAnimation,
              child: Icon(
                Icons.explore,
                color: isDarkMode ? textColorPrimary : Colors.white,
              ),
            ),
            tooltip: "Retry",
            onPressed:
                _isLoading
                    ? null
                    : () {
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
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  strokeWidth: 3,
                )
                : _errorMessage != null
                ? _buildErrorView(
                  brightness,
                  accentColor,
                ) // Removed isDarkMode, contentSurface, errorColor
                : _buildQiblaView(
                  brightness,
                  isDarkMode,
                  contentSurface,
                  accentColor,
                  textColorPrimary,
                  textColorSecondary,
                ),
      ),
    );
  }

  Widget _buildErrorView(
    Brightness brightness,
    // bool isDarkMode, // Removed
    // Color contentSurface, // Removed
    // Color errorColor, // Removed as MessageDisplay handles its error color
    Color accentColor, // Still needed for button if not error state
  ) {
    // The original _buildErrorView had complex message processing.
    // For now, using the simpler _errorMessage or a generic one.
    // If specific messages are crucial, _getProcessedErrorMessage would need to be implemented.
    String displayMessage = _errorMessage ?? "An unknown error occurred.";
    if (displayMessage ==
        'Location permission denied. Please enable it in settings.') {
      // Keep specific important messages if desired
    } else if (displayMessage.contains('permission')) {
      displayMessage = "Location permission error. Please check settings.";
    } else if (displayMessage.contains('service is disabled')) {
      displayMessage = "Location service is disabled. Please enable it.";
    } else if (displayMessage.contains('Compass sensor error')) {
      displayMessage = "Compass sensor error. Please try again.";
    }

    return MessageDisplay(
      message: displayMessage,
      icon: Icons.error_outline_rounded,
      onRetry: _initQiblaFinder,
      isError: true,
      // The retry button color will be AppColors.error if isError is true,
      // or AppColors.accentGreen if isError is false (which is not the case here).
      // The accentColor param for _buildErrorView might not be needed if we always use error styling.
    );
  }

  Widget _buildQiblaView(
    Brightness brightness,
    bool isDarkMode,
    Color contentSurface,
    Color accentColor,
    Color textColorPrimary,
    Color textColorSecondary,
  ) {
    final aligned = _isQiblaAligned();
    final helpText = _getAlignmentHelpText();
    final compassData = _buildCompassView(
      aligned,
      brightness,
      isDarkMode,
      contentSurface,
      accentColor,
      textColorPrimary,
      textColorSecondary,
    );
    final compassStack = compassData[0] as Widget;
    final qiblaIndicatorColor =
        compassData[1]
            as Color; // This is the color for the Qibla direction arrow/icon

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Point your phone towards the Kaaba",
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(brightness).copyWith(
              color: textColorPrimary, // Use primary text color
            ),
          ),
          const SizedBox(height: 16), // Adjusted spacing
          Icon(
            Icons.mosque_rounded,
            size: 48,
            color: qiblaIndicatorColor,
          ), // Use the dynamic arrow color
          const SizedBox(height: 12), // Adjusted spacing
          Expanded(child: Center(child: compassStack)),
          const SizedBox(height: 16),
          if (helpText.isNotEmpty)
            Text(
              helpText,
              textAlign: TextAlign.center,
              style: AppTextStyles.prayerName(brightness).copyWith(
                // Using prayerName style for prominence
                color: aligned ? accentColor : textColorPrimary,
                fontWeight: aligned ? FontWeight.bold : FontWeight.normal,
                fontSize: 17,
              ),
            ),
          const SizedBox(height: 20),
          _buildLocationInfo(
            brightness,
            isDarkMode,
            contentSurface,
            textColorPrimary,
            textColorSecondary,
          ),
        ],
      ),
    );
  }

  bool _isQiblaAligned() {
    if (_magneticHeading == null || _qiblaDirection == null) return false;
    final diff = (_magneticHeading! - _qiblaDirection!).abs() % 360;
    final err = diff > 180 ? 360 - diff : diff;
    return err <= 5; // 5 degrees tolerance
  }

  List<dynamic> _buildCompassView(
    bool aligned,
    Brightness brightness,
    bool isDarkMode,
    Color contentSurface,
    Color accentColor,
    Color textColorPrimary,
    Color textColorSecondary,
  ) {
    final magneticAngleForDial =
        _magneticHeading != null ? -_degreesToRadians(_magneticHeading!) : 0.0;

    Color qiblaArrowColor = AppColors.error(
      brightness,
    ); // Default to error color
    if (_magneticHeading != null && _qiblaDirection != null) {
      final diff = (_magneticHeading! - _qiblaDirection!).abs() % 360;
      final err = diff > 180 ? 360 - diff : diff;
      qiblaArrowColor =
          err <= 5
              ? accentColor // Aligned color
              : err <= 20
              ? Colors
                  .amber // Close color
              : AppColors.error(brightness); // Far off color
    }

    final stack = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          // Compass Dial Background
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: contentSurface, // Use contentSurface for dial background
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor(
                  brightness,
                ).withAlpha(isDarkMode ? 30 : 50),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
            border:
                aligned
                    ? Border.all(color: accentColor, width: 3)
                    : Border.all(
                      color: AppColors.borderColor(
                        brightness,
                      ).withAlpha(isDarkMode ? 100 : 150),
                      width: 1,
                    ),
          ),
        ),
        Transform.rotate(
          angle: magneticAngleForDial,
          child: _buildCompassDirections(
            brightness,
            accentColor,
            textColorSecondary,
          ),
        ),
        if (_magneticHeading != null && _qiblaDirection != null)
          CustomPaint(
            size: const Size(240, 240), // Painter area
            painter: _QiblaDirectionPainter(
              qiblaAngleFromTrueNorth: _qiblaDirection!,
              magneticDeviceHeading: _magneticHeading!,
              magneticDeclination:
                  0.0, // Assuming 0.0 as flutter_compass might provide true heading or declination calculation is not implemented.
              arrowColor: qiblaArrowColor, // Pass the calculated arrow color
            ),
          ),
        Container(
          // Center dot
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: qiblaArrowColor,
            shape: BoxShape.circle,
          ),
        ),
        if (_magneticHeading == null)
          Container(
            width: 280,
            height: 280,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            child: Text(
              "No compass data",
              textAlign: TextAlign.center,
              style: AppTextStyles.label(
                brightness,
              ).copyWith(color: textColorSecondary, fontSize: 16),
            ),
          ),
      ],
    );
    return [
      stack,
      qiblaArrowColor,
    ]; // Return the arrow color for the mosque icon
  }

  Widget _buildCompassDirections(
    Brightness brightness,
    Color accentColor,
    Color textColorSecondary,
  ) {
    final TextStyle directionStyle = AppTextStyles.label(
      brightness,
    ).copyWith(color: textColorSecondary, fontSize: 16);
    final TextStyle northStyle = AppTextStyles.label(
      brightness,
    ).copyWith(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18);

    return SizedBox(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 10, child: Text("N", style: northStyle)),
          Positioned(right: 15, child: Text("E", style: directionStyle)),
          Positioned(bottom: 10, child: Text("S", style: directionStyle)),
          Positioned(left: 15, child: Text("W", style: directionStyle)),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(
    Brightness brightness,
    bool isDarkMode,
    Color contentSurface,
    Color textColorPrimary,
    Color textColorSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: contentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderColor(
            brightness,
          ).withAlpha(isDarkMode ? 70 : 100),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor(
              brightness,
            ).withAlpha(isDarkMode ? 20 : 30),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Current Direction",
                  style: AppTextStyles.label(
                    brightness,
                  ).copyWith(color: textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _magneticHeading != null
                      ? '${_magneticHeading!.toInt()}° (M)'
                      : "N/A",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(brightness).copyWith(
                    color: textColorPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: AppColors.borderColor(
              brightness,
            ).withAlpha(isDarkMode ? 70 : 100),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Qibla Direction",
                  style: AppTextStyles.label(
                    brightness,
                  ).copyWith(color: textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _qiblaDirection != null
                      ? '${_qiblaDirection!.toInt()}°'
                      : "N/A",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(brightness).copyWith(
                    color: AppColors.accentGreen(brightness),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ), // Highlight Qibla
                ),
              ],
            ),
          ),
          Container(
            height: 30,
            width: 1,
            color: AppColors.borderColor(
              brightness,
            ).withAlpha(isDarkMode ? 70 : 100),
          ),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Current Location",
                  style: AppTextStyles.label(
                    brightness,
                  ).copyWith(color: textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentCity ??
                      "N/A", // Use qiblaNotAvailable if city is null
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(brightness).copyWith(
                    color: textColorPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAlignmentHelpText() {
    // Use trueHeading for alignment help text
    if (_magneticHeading == null || _qiblaDirection == null) return '';
    if (_isQiblaAligned()) return "Qibla aligned!";

    // Calculate difference: how much to turn the device (magnetic heading) to align with True Qibla.
    double diff = _qiblaDirection! - _magneticHeading!;
    while (diff <= -180) {
      diff += 360;
    }
    while (diff > 180) {
      diff -= 360;
    }

    // More descriptive turn instructions
    final int diffInt = diff.round();
    if (diffInt > 5) {
      // Adjusted threshold for more practical advice
      return 'Turn right (~$diffInt°)';
    }
    if (diffInt < -5) {
      // Adjusted threshold
      return 'Turn left (~${diffInt.abs()}°)';
    }
    // Very close but not aligned
    if (diffInt.abs() > 0 && diffInt.abs() <= 5) {
      return "Almost there!";
    }
    return ''; // Should ideally be covered by _isQiblaAligned
  }

  double _degreesToRadians(double degrees) => degrees * (math.pi / 180);
}

class _QiblaDirectionPainter extends CustomPainter {
  final double qiblaAngleFromTrueNorth;
  final double magneticDeviceHeading;
  final double magneticDeclination;
  final Color arrowColor;

  _QiblaDirectionPainter({
    required this.qiblaAngleFromTrueNorth,
    required this.magneticDeviceHeading,
    required this.magneticDeclination,
    required this.arrowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint =
        Paint()
          ..color = arrowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    // The qiblaAngleFromTrueNorth is already relative to true north
    // The compass/device heading we get is relative to magnetic north
    // Since the compass rotates based on magnetic north, we need to:
    // 1. Convert the qibla angle to be relative to magnetic north
    // 2. Then calculate the relative angle between that and our magnetic heading
    final qiblaAngleFromMagneticNorth =
        (qiblaAngleFromTrueNorth - magneticDeclination + 360) % 360;

    // Calculate display angle for arrow (in radians)
    final displayAngleRadians =
        ((qiblaAngleFromMagneticNorth - magneticDeviceHeading + 360) % 360) *
        (math.pi / 180);

    final end = Offset(
      center.dx + radius * math.sin(displayAngleRadians),
      center.dy - radius * math.cos(displayAngleRadians),
    );

    canvas.drawLine(center, end, paint);

    // Draw arrow head
    const arrowSize = 15.0;
    final angle = math.atan2(end.dy - center.dy, end.dx - center.dx);
    final path =
        Path()
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
  bool shouldRepaint(covariant _QiblaDirectionPainter old) =>
      old.qiblaAngleFromTrueNorth != qiblaAngleFromTrueNorth ||
      old.magneticDeviceHeading != magneticDeviceHeading ||
      old.magneticDeclination != magneticDeclination ||
      old.arrowColor != arrowColor;
}
