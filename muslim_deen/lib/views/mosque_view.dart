import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/message_display.dart';

Future<void> _openMosqueInMapsApp(BuildContext context, Mosque mosque) async {
  if (!context.mounted) return;

  final logger = locator<LoggerService>();
  final lat = mosque.location.latitude;
  final lng = mosque.location.longitude;
  final query = Uri.encodeComponent(
    mosque.name.isNotEmpty ? mosque.name : '$lat,$lng',
  );

  final appleUrl = Uri.parse('maps://?q=$query&ll=$lat,$lng');
  final googleUrl = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$query',
  );
  final genericUrl = Uri.parse('geo:$lat,$lng?q=$query');

  bool launched = false;

  try {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      if (await canLaunchUrl(appleUrl)) {
        launched = true;
        await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      }
    }

    if (!launched && await canLaunchUrl(googleUrl)) {
      launched = true;
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    }

    if (!launched && await canLaunchUrl(genericUrl)) {
      launched = true;
      await launchUrl(genericUrl, mode: LaunchMode.externalApplication);
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error opening map")));
      logger.warning(
        'Could not launch any map application for mosque: ${mosque.name}',
      );
    }
  } catch (e, s) {
    logger.error(
      'Error launching map for mosque: ${mosque.name}',
      data: {'error': e.toString(), 'stackTrace': s.toString()},
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error opening map")));
    }
  }
}

class MosqueView extends StatefulWidget {
  const MosqueView({super.key});

  @override
  State<MosqueView> createState() => _MosqueViewState();
}

class _MosqueViewState extends State<MosqueView> {
  final LocationService _locationService = locator<LocationService>();
  final MapService _mapService = locator<MapService>();
  final LoggerService _logger = locator<LoggerService>();
  Position? _currentPosition;
  List<Mosque> _nearbyMosques = [];
  bool _isLoading = true;
  String? _errorMessage;
  final double _searchRadius = 5000;
  Timer? _locationCheckTimer;

  @override
  void dispose() {
    _logger.debug('MosqueView disposed');
    _locationCheckTimer?.cancel();
    super.dispose();
  }

  void _startLocationCheck() {
    _logger.debug('Starting location permission check timer.');
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // _locationService.checkLocationPermission(); // Removed direct call
        // The locationStatus stream should update based on LocationService's internal checks
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _logger.info('MosqueView initialized');
    _startLocationCheck();
    _locationService.locationStatus.listen((hasPermission) {
      if (!mounted) return;

      if (!hasPermission) {
        _logger.warning('Location permission denied in MosqueView (listener)');
        setState(() {
          _errorMessage =
              "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again.";
          _isLoading = false;
          _nearbyMosques = [];
        });
      } else {
        final bool hadPermissionError =
            _errorMessage ==
            "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again.";
        final bool needsLoadAttempt =
            _nearbyMosques.isEmpty && _currentPosition == null;

        if (hadPermissionError || needsLoadAttempt) {
          _logger.info(
            'Location permission now available, attempting to load/reload nearby mosques.',
          );
          setState(() {
            _errorMessage = null;
          });
          _loadNearbyMosques();
        }
      }
    });
    _loadNearbyMosques();
  }

  Future<void> _loadNearbyMosques() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nearbyMosques = [];
    });
    _logger.info('Loading nearby mosques...');

    try {
      // await _locationService.checkLocationPermission(); // Removed direct call
      // getLocation() will handle permission checks internally.
      if (_locationService.isLocationBlocked) {
        // This check can remain as a quick exit
        _logger.warning(
          'Location permission is blocked. User needs to enable it.',
        );
        setState(() {
          _errorMessage =
              "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again.";
          _isLoading = false;
        });
        return;
      }
      _currentPosition = await _locationService.getLocation();
      if (_currentPosition == null) {
        _logger.warning('Current position is null, cannot load mosques.');
        throw Exception('Location unavailable');
      }
      _logger.info(
        'Current position obtained: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
      );

      _nearbyMosques = await _mapService.findNearbyMosques(
        _currentPosition!,
        radius: _searchRadius,
      );
      _logger.info('Found ${_nearbyMosques.length} nearby mosques.');
    } on Exception catch (e, s) {
      _logger.error(
        'Error loading nearby mosques',
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Error loading nearby mosques: ${e.toString()}';
            });
          }
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

  Future<void> _openMosqueInMaps(Mosque mosque) async {
    _logger.logInteraction(
      'MosqueView',
      'open_in_maps',
      data: {'mosque_name': mosque.name, 'widget': 'MosqueCard'},
    );
    await _openMosqueInMapsApp(context, mosque);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // final bool isDarkMode = brightness == Brightness.dark; // No longer needed for scaffoldBg

    // final Color scaffoldBg = // Replaced by AppColors.getScaffoldBackground
    //     isDarkMode
    //         ? AppColors.surface(brightness)
    //         : AppColors.background(brightness);
    final bool isDarkMode =
        brightness == Brightness.dark; // Still needed for other color logic
    final Color contentSurface =
        isDarkMode ? const Color(0xFF2C2C2C) : AppColors.background(brightness);
    final Color cardBorderColor = AppColors.borderColor(
      brightness,
    ).withAlpha(isDarkMode ? 100 : 150);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(
        title: "Nearby Mosques",
        brightness: brightness,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color:
                  isDarkMode ? AppColors.textPrimary(brightness) : Colors.white,
            ),
            onPressed: _isLoading ? null : _loadNearbyMosques,
            tooltip: "Refresh",
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.accentGreen(brightness),
                  ),
                  strokeWidth: 3,
                ),
              )
              : _errorMessage != null
              ? MessageDisplay(
                message: _errorMessage ?? "Unknown error",
                icon: Icons.error_outline_rounded,
                onRetry: _loadNearbyMosques,
                isError: true,
              )
              : _buildMosqueListView(
                brightness,
                isDarkMode, // Pass isDarkMode
                contentSurface, // Pass contentSurface
                cardBorderColor,
              ),
    );
  }

  Widget _buildMosqueListView(
    Brightness brightness,
    bool isDarkMode, // Add isDarkMode parameter
    Color contentSurface, // Add contentSurface parameter
    Color cardBorderColor,
  ) {
    if (_nearbyMosques.isEmpty) {
      return const MessageDisplay(
        message:
            "No mosques found nearby. Try adjusting search radius or location.",
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: _nearbyMosques.length,
      itemBuilder:
          (context, index) => _buildMosqueCard(
            _nearbyMosques[index],
            index == 0,
            brightness,
            isDarkMode,
            contentSurface,
            cardBorderColor,
          ),
    );
  }

  Widget _buildMosqueCard(
    Mosque mosque,
    bool isFeatured,
    Brightness brightness,
    bool isDarkMode,
    Color cardBackgroundColor,
    Color cardBorderColor,
  ) {
    final Color textColor = AppColors.textPrimary(brightness);
    final Color directionsIconColor = AppColors.accentGreen(brightness);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openMosqueInMaps(mosque),
        splashColor: directionsIconColor.withAlpha((0.1 * 255).round()),
        highlightColor: directionsIconColor.withAlpha((0.05 * 255).round()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFeatured)
              Image.asset(
                'assets/images/mosque_placeholder.jpg',
                height: 160,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name.isNotEmpty
                              ? mosque.name
                              : 'Unknown location',
                          style: AppTextStyles.sectionTitle(
                            brightness,
                          ).copyWith(color: textColor, fontSize: 17),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: directionsIconColor.withAlpha(
                        (isDarkMode ? 0.2 * 255 : 0.15 * 255).round(),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.directions_rounded,
                        color: directionsIconColor,
                      ),
                      onPressed: () => _openMosqueInMaps(mosque),
                      tooltip: "Open in Maps",
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
