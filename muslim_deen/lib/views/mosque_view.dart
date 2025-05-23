import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/map_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/common_container_styles.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/loading_error_state_builder.dart';

Future<void> _openMosqueInMapsApp(BuildContext context, Mosque mosque) async {
  final String query = Uri.encodeComponent(mosque.name);
  final String coordinates =
      '${mosque.location.latitude},${mosque.location.longitude}';

  List<String> urls = [];

  if (Platform.isAndroid) {
    urls = [
      'geo:$coordinates?q=$coordinates($query)',
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    ];
  } else if (Platform.isIOS) {
    urls = [
      'maps:$coordinates?q=$query',
      'https://maps.apple.com/?q=$query&ll=$coordinates',
      'https://www.google.com/maps/search/?api=1&query=$coordinates',
    ];
  } else {
    urls = ['https://www.google.com/maps/search/?api=1&query=$coordinates'];
  }

  bool launched = false;
  for (final url in urls) {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
      launched = true;
      break;
    }
  }

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open maps app. Coordinates: $coordinates'),
        backgroundColor: Colors.orange,
      ),
    );
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
      if (_locationService.isLocationBlocked) {
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
    final colors = UIThemeHelper.getThemeColors(brightness);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(
        title: "Nearby Mosques",
        brightness: brightness,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colors.isDarkMode ? colors.textColorPrimary : Colors.white,
            ),
            onPressed: _isLoading ? null : _loadNearbyMosques,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: LoadingErrorStateBuilder(
        isLoading: _isLoading,
        errorMessage: _errorMessage,
        onRetry: _loadNearbyMosques,
        loadingText: "Finding nearby mosques...",
        child: _buildMosqueListView(colors),
      ),
    );
  }

  Widget _buildMosqueListView(UIColors colors) {
    return Column(
      children: [
        // Mosque image at the top
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/mosque_placeholder.jpg'),
              fit: BoxFit.cover,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Nearby Mosques",
                  style: AppTextStyles.sectionTitle(colors.brightness).copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        // List of mosques
        Expanded(
          child:
              _nearbyMosques.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mosque_rounded,
                            size: 64,
                            color: colors.textColorSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No mosques found nearby",
                            style: AppTextStyles.sectionTitle(
                              colors.brightness,
                            ).copyWith(color: colors.textColorPrimary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Try refreshing or check your location settings",
                            style: AppTextStyles.label(
                              colors.brightness,
                            ).copyWith(color: colors.textColorSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _nearbyMosques.length,
                    itemBuilder: (context, index) {
                      final mosque = _nearbyMosques[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: CommonContainerStyles.cardDecoration(
                          colors,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration:
                                CommonContainerStyles.iconContainerDecoration(
                                  colors,
                                ),
                            child: Icon(
                              Icons.mosque_rounded,
                              color: colors.accentColor,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            mosque.name,
                            style: AppTextStyles.prayerName(
                              colors.brightness,
                            ).copyWith(
                              color: colors.textColorPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: colors.accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.directions,
                                color: Colors.white,
                              ),
                              onPressed: () => _openMosqueInMaps(mosque),
                              tooltip: "Get directions",
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
