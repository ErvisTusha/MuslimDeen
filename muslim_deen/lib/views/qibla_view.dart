import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/compass_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/location_permission_helper.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/common_container_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/loading_error_state_builder.dart';

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
      // Use the new location permission helper
      final validation =
          await LocationPermissionHelper.validateLocationAccess();
      if (!validation.isValid) {
        if (mounted) {
          setState(() {
            _errorMessage = validation.errorMessage;
            _isLoading = false;
          });
        }
        return;
      }

      final position = await LocationPermissionHelper.getCurrentPosition();

      // Get Qibla direction (which is already true Qibla from the service)
      _qiblaDirection = await _compassService.getQiblaDirection(position);

      // Get current city name using the helper
      _currentCity = await LocationPermissionHelper.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

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
    final colors = UIThemeHelper.getThemeColors(brightness);

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
                color:
                    colors.isDarkMode ? colors.textColorPrimary : Colors.white,
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
      body: LoadingErrorStateBuilder(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _initQiblaFinder,
        loadingText: "Finding Qibla direction...",
        child: _buildQiblaView(colors),
      ),
    );
  }

  Widget _buildQiblaView(UIColors colors) {
    final aligned = _isQiblaAligned();
    final helpText = _getAlignmentHelpText();
    final compassData = _buildCompassView(aligned, colors);
    final compassStack = compassData[0] as Widget;
    final qiblaIndicatorColor = compassData[1] as Color;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Point your phone towards the Kaaba",
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle(
              colors.brightness,
            ).copyWith(color: colors.textColorPrimary),
          ),
          const SizedBox(height: 16),
          Icon(Icons.mosque_rounded, size: 48, color: qiblaIndicatorColor),
          const SizedBox(height: 12),
          Expanded(child: Center(child: compassStack)),
          const SizedBox(height: 16),
          if (helpText.isNotEmpty)
            Text(
              helpText,
              textAlign: TextAlign.center,
              style: AppTextStyles.prayerName(colors.brightness).copyWith(
                color: aligned ? colors.accentColor : colors.textColorPrimary,
                fontWeight: aligned ? FontWeight.bold : FontWeight.normal,
                fontSize: 17,
              ),
            ),
          const SizedBox(height: 20),
          _buildLocationInfo(colors),
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

  List<dynamic> _buildCompassView(bool aligned, UIColors colors) {
    final magneticAngleForDial =
        _magneticHeading != null ? -_degreesToRadians(_magneticHeading!) : 0.0;

    Color qiblaArrowColor = colors.errorColor; // Default to error color
    if (_magneticHeading != null && _qiblaDirection != null) {
      final diff = (_magneticHeading! - _qiblaDirection!).abs() % 360;
      final err = diff > 180 ? 360 - diff : diff;
      qiblaArrowColor =
          err <= 5
              ? colors
                  .accentColor // Aligned color
              : err <= 20
              ? Colors
                  .amber // Close color
              : colors.errorColor; // Far off color
    }

    final stack = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          // Compass Dial Background
          width: 300,
          height: 300,
          decoration: CommonContainerStyles.circularDecoration(
            colors,
            isAligned: aligned,
          ),
        ),
        Transform.rotate(
          angle: magneticAngleForDial,
          child: _buildCompassDirections(colors),
        ),
        if (_magneticHeading != null && _qiblaDirection != null)
          CustomPaint(
            size: const Size(240, 240),
            painter: _QiblaDirectionPainter(
              qiblaAngleFromTrueNorth: _qiblaDirection!,
              magneticDeviceHeading: _magneticHeading!,
              magneticDeclination: 0.0,
              arrowColor: qiblaArrowColor,
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
                colors.brightness,
              ).copyWith(color: colors.textColorSecondary, fontSize: 16),
            ),
          ),
      ],
    );
    return [stack, qiblaArrowColor];
  }

  Widget _buildCompassDirections(UIColors colors) {
    final TextStyle directionStyle = AppTextStyles.label(
      colors.brightness,
    ).copyWith(color: colors.textColorSecondary, fontSize: 16);
    final TextStyle northStyle = AppTextStyles.label(
      colors.brightness,
    ).copyWith(
      color: colors.accentColor,
      fontWeight: FontWeight.bold,
      fontSize: 18,
    );

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

  Widget _buildLocationInfo(UIColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: CommonContainerStyles.infoPanelDecoration(colors),
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
                    colors.brightness,
                  ).copyWith(color: colors.textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _magneticHeading != null
                      ? '${_magneticHeading!.toInt()}° (M)'
                      : "N/A",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(colors.brightness).copyWith(
                    color: colors.textColorPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          CommonContainerStyles.divider(colors),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Qibla Direction",
                  style: AppTextStyles.label(
                    colors.brightness,
                  ).copyWith(color: colors.textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _qiblaDirection != null
                      ? '${_qiblaDirection!.toInt()}°'
                      : "N/A",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(colors.brightness).copyWith(
                    color: colors.accentColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          CommonContainerStyles.divider(colors),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Current Location",
                  style: AppTextStyles.label(
                    colors.brightness,
                  ).copyWith(color: colors.textColorSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  _currentCity ?? "N/A",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.prayerTime(colors.brightness).copyWith(
                    color: colors.textColorPrimary,
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
    if (_magneticHeading == null || _qiblaDirection == null) return '';
    if (_isQiblaAligned()) return "Qibla aligned!";

    double diff = _qiblaDirection! - _magneticHeading!;
    while (diff <= -180) {
      diff += 360;
    }
    while (diff > 180) {
      diff -= 360;
    }

    final int diffInt = diff.round();
    if (diffInt > 5) {
      return 'Turn right (~$diffInt°)';
    }
    if (diffInt < -5) {
      return 'Turn left (~${diffInt.abs()}°)';
    }
    if (diffInt.abs() > 0 && diffInt.abs() <= 5) {
      return "Almost there!";
    }
    return '';
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
