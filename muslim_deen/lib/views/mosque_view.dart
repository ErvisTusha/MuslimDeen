import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../service_locator.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/logger_service.dart';
import '../styles/app_styles.dart';

Future<void> openMosqueInMapsApp(BuildContext context, Mosque mosque) async {
  if (!context.mounted) return;

  final logger = locator<LoggerService>();
  final lat = mosque.location.latitude;
  final lng = mosque.location.longitude;
  final query = Uri.encodeComponent(
    mosque.name.isNotEmpty ? mosque.name : '$lat,$lng',
  );
  final localizations = AppLocalizations.of(context)!;

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
      ).showSnackBar(SnackBar(content: Text(localizations.errorOpeningMap)));
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
      ).showSnackBar(SnackBar(content: Text(localizations.errorOpeningMap)));
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
        _locationService.checkLocationPermission();
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
      // The 'localizations' variable previously defined here was unused.
      // If context-dependent operations (like accessing AppLocalizations)
      // are needed in this listener in the future, ensure context is accessed safely,
      // potentially using WidgetsBinding.instance.addPostFrameCallback if the
      // listener can fire before the first frame is complete.

      if (!hasPermission) {
        _logger.warning('Location permission denied in MosqueView (listener)');
        setState(() {
          // Use a more informative, localized message
          _errorMessage = "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again.";
          _isLoading = false; // Ensure loading indicator stops
          _nearbyMosques = []; // Clear any potentially stale mosque data
        });
      } else { // Permission is now true
        // Determine if a reload is needed:
        // 1. If the specific permission error was previously shown.
        // 2. Or if it's an initial state where mosques haven't loaded and position is unknown.
        final bool hadPermissionError = _errorMessage == "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again.";
        final bool needsLoadAttempt = _nearbyMosques.isEmpty && _currentPosition == null;

        if (hadPermissionError || needsLoadAttempt) {
          _logger.info('Location permission now available, attempting to load/reload nearby mosques.');
          setState(() {
            _errorMessage = null; // Clear previous error message before new load attempt
          });
          _loadNearbyMosques();
        }
      }
    });
    _loadNearbyMosques();
  }

  Future<void> _loadNearbyMosques() async {
    // Localizations will be fetched safely inside the catch block if an error occurs,
    // and the state update will be scheduled after the current frame.

    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors at the start of a load attempt
      _nearbyMosques = [];
    });
    _logger.info('Loading nearby mosques...');

    try {
      await _locationService.checkLocationPermission();
      if (_locationService.isLocationBlocked) {
        _logger.warning('Location permission is blocked. User needs to enable it.');
        setState(() {
          _errorMessage = "Location permission is required to find nearby mosques. Please enable it in your browser settings and try again."; // Set informative message
          _isLoading = false; // Stop loading
        });
        return; // Exit early, preventing the exception
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
          if (mounted) { // Re-check mounted as callback is asynchronous
            // Safely get localizations and update state after the frame
            final localizations = AppLocalizations.of(context)!;
            setState(() {
              _errorMessage = localizations.mosquesError(e.toString());
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
    await openMosqueInMapsApp(context, mosque);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Define colors similar to TesbihView
    final Color scaffoldBg = isDarkMode ? AppColors.surface(brightness) : AppColors.background(brightness);
    final Color contentSurface = isDarkMode ? const Color(0xFF2C2C2C) : AppColors.background(brightness); // Cards on a slightly lighter dark bg
    final Color cardBorderColor = AppColors.borderColor(brightness).withAlpha(isDarkMode ? 100 : 150);
    // final Color iconColor = AppColors.iconInactive(brightness); // For refresh icon if not on AppBar primary

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(localizations.mosquesLabel, style: AppTextStyles.appTitle(brightness)),
        backgroundColor: AppColors.primary(brightness),
        elevation: 2.0,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary(brightness),
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.light,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: isDarkMode ? AppColors.textPrimary(brightness) : Colors.white), // Adjusted for AppBar contrast
            onPressed: _isLoading ? null : _loadNearbyMosques, // Disable while loading
            tooltip: localizations.retry,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGreen(brightness)),
                strokeWidth: 3,
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(brightness, isDarkMode, contentSurface, localizations)
              : _buildMosqueListView(brightness, isDarkMode, contentSurface, cardBorderColor, localizations),
    );
  }

  Widget _buildErrorView(Brightness brightness, bool isDarkMode, Color contentSurface, AppLocalizations localizations) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: contentSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error(brightness).withAlpha(100)),
           boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor(brightness).withAlpha(isDarkMode ? 20 : 40),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error(brightness), size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? localizations.mosquesError('Unknown error'),
              style: AppTextStyles.label(brightness).copyWith(color: AppColors.error(brightness), fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(localizations.retry),
              onPressed: _loadNearbyMosques,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen(brightness),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: AppTextStyles.label(brightness).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMosqueListView(Brightness brightness, bool isDarkMode, Color contentSurface, Color cardBorderColor, AppLocalizations localizations) {
    if (_nearbyMosques.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
           decoration: BoxDecoration(
            color: contentSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor(brightness).withAlpha(isDarkMode ? 100 : 150)),
             boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor(brightness).withAlpha(isDarkMode ? 20 : 40),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, color: AppColors.textSecondary(brightness), size: 48),
              const SizedBox(height: 16),
              Text(
                localizations.mosquesNoResults,
                style: AppTextStyles.label(brightness).copyWith(color: AppColors.textSecondary(brightness), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Consistent padding around the list
      itemCount: _nearbyMosques.length,
      itemBuilder: (context, index) => _buildMosqueCard(
        _nearbyMosques[index],
        index == 0, // isFeatured for the first item
        brightness,
        isDarkMode,
        contentSurface,
        cardBorderColor,
        localizations,
      ),
    );
  }

  Widget _buildMosqueCard(
    Mosque mosque,
    bool isFeatured,
    Brightness brightness,
    bool isDarkMode,
    Color cardBackgroundColor, // Use this for card background
    Color cardBorderColor,
    AppLocalizations localizations,
  ) {
    final Color textColor = AppColors.textPrimary(brightness);
    // final Color secondaryTextColor = AppColors.textSecondary(brightness);
    final Color directionsIconColor = AppColors.accentGreen(brightness); // Make directions icon stand out

    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Spacing between cards
      elevation: 0, // Elevation handled by container shadow if needed, or keep minimal
      color: cardBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cardBorderColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias, // Ensures content respects border radius
      child: InkWell( // Make the whole card tappable
        onTap: () => _openMosqueInMaps(mosque),
        splashColor: directionsIconColor.withAlpha((0.1 * 255).round()),
        highlightColor: directionsIconColor.withAlpha((0.05 * 255).round()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFeatured) // Fallback placeholder if no photo URL, as Mosque class doesn't have photoUrl
              Image.asset(
                'assets/images/mosque_placeholder.jpg',
                height: 160,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center, // Center align items vertically
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mosque.name.isNotEmpty ? mosque.name : localizations.unknownLocation,
                          style: AppTextStyles.sectionTitle(brightness).copyWith(color: textColor, fontSize: 17),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Removed mosque.address as it's not part of the Mosque class
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container( // Button-like appearance for directions
                    decoration: BoxDecoration(
                      color: directionsIconColor.withAlpha((isDarkMode ? 0.2 * 255 : 0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.directions_rounded, color: directionsIconColor),
                      onPressed: () => _openMosqueInMaps(mosque),
                      tooltip: localizations.mosquesOpenInMaps,
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
