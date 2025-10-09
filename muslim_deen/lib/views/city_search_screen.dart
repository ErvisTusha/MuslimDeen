import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/widgets/city_search_bar.dart';
import 'package:muslim_deen/widgets/city_search_results_list.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';

class CitySearchScreen extends StatefulWidget {
  const CitySearchScreen({super.key});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  int _searchAttempts = 0;
  static const int _maxSearchAttempts = 3;
  final LoggerService _logger = locator<LoggerService>();

  @override
  void initState() {
    super.initState();
    _logger.info('CitySearchScreen initialized');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _logger.debug('CitySearchScreen disposed');
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final searchText = _searchController.text;
      _logger.logInteraction(
        'CitySearchScreen',
        'search_changed',
        data: {'query': searchText},
      );
      if (searchText.isNotEmpty) {
        _searchAttempts = 0; // Reset attempts for a new search
        _searchPlaces(searchText);
      } else {
        setState(() {
          _searchResults.clear();
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    // Prevent API calls for very short queries
    if (query.trim().length < 3) {
      setState(() {
        _isLoading = false;
        _searchResults.clear();
        _errorMessage = "Type at least 3 characters to search";
      });
      _logger.info('Search query too short: "$query"');
      return;
    }

    _logger.info('Searching places for query: $query');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searchResults.clear();
    });
    _searchAttempts++; // Increment for the current query attempt

    try {
      // Add search query formatting to improve geocoding results
      final formattedQuery = query.trim();

      // Try with specific country codes to improve results
      List<Location> locations = [];

      try {
        // First try with the generic query
        locations = await locationFromAddress(
          formattedQuery,
        ).timeout(const Duration(seconds: 15));
      } catch (e, s) {
        // If generic query fails, try alternate approaches
        _logger.warning(
          'First geocoding attempt failed for query: $query',
          data: {'error': e.toString(), 'stackTrace': s.toString()},
        );

        try {
          // Try adding "city" to the query
          locations = await locationFromAddress(
            '$formattedQuery city',
          ).timeout(const Duration(seconds: 15));
        } catch (e2, s2) {
          _logger.warning(
            'Second geocoding attempt failed for query: $query city',
            data: {'error': e2.toString(), 'stackTrace': s2.toString()},
          );
          // Last attempt with a more specific query
          try {
            locations = await locationFromAddress(
              'City of $formattedQuery',
            ).timeout(const Duration(seconds: 15));
          } catch (e3, s3) {
            _logger.error(
              'Third geocoding attempt failed for query: City of $formattedQuery',
              data: {'error': e3.toString(), 'stackTrace': s3.toString()},
            );
            throw Exception(
              'Could not find any location for "$formattedQuery"',
            );
          }
        }
      }

      if (locations.isEmpty) {
        throw Exception('No locations found');
      }

      // Limit the number of locations to process to avoid performance issues
      final limitedLocations = locations.take(5).toList();

      for (var location in limitedLocations) {
        try {
          final List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(const Duration(seconds: 10));

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;

            String name = '';
            if (place.locality?.isNotEmpty == true) {
              name += place.locality!;
            }
            if (place.administrativeArea?.isNotEmpty == true) {
              name +=
                  name.isNotEmpty
                      ? ', ${place.administrativeArea}'
                      : place.administrativeArea!;
            }
            if (place.country?.isNotEmpty == true) {
              name += name.isNotEmpty ? ', ${place.country}' : place.country!;
            }

            // Ensure we have a meaningful name
            if (name.isEmpty) {
              name =
                  '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
            }

            if (_isRelevantResult(name, query)) {
              _searchResults.add({
                'name': name,
                'latitude': location.latitude,
                'longitude': location.longitude,
                'placemark': place,
              });
            }
          }
        } catch (e, s) {
          _logger.warning(
            'Error reverse geocoding for location',
            data: {
              'latitude': location.latitude,
              'longitude': location.longitude,
              'error': e.toString(),
              'stackTrace': s.toString(),
            },
          );
          // Continue with next location even if this one fails
        }
      }

      if (!mounted) return;
      _logger.info('Found ${_searchResults.length} results for query: $query');

      setState(() {
        _isLoading = false;
        if (_searchResults.isEmpty) {
          _errorMessage = "No locations found";
        }
      });
    } catch (e, s) {
      _logger.error(
        'Error searching places for query: $query',
        data: {
          'error': e.toString(),
          'stackTrace': s.toString(),
          'searchAttempts': _searchAttempts,
        },
      );
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = "Search Error";

        // If we've tried multiple times, provide additional guidance
        if (_searchAttempts >= _maxSearchAttempts) {
          _errorMessage =
              'Search Error Try a different city name or format. Include country name for better results.';
        }
      });
    }
  }

  bool _isRelevantResult(String text, String query) {
    if (text.isEmpty) return false;

    // Normalize strings for accent-insensitive comparison
    final normalizedText = _normalizeString(text.toLowerCase());
    final normalizedQuery = _normalizeString(query.toLowerCase());

    // Check if any part of the normalized text starts with the normalized query
    if (normalizedText.contains(normalizedQuery)) {
      return true;
    }

    // Check if any word in the text starts with any word in the query
    final textWords = normalizedText.split(' ');
    final queryWords = normalizedQuery.split(' ');

    for (final queryWord in queryWords) {
      if (queryWord.isEmpty) continue;

      for (final textWord in textWords) {
        if (textWord.isEmpty) continue;

        if (textWord.startsWith(queryWord) || queryWord.startsWith(textWord)) {
          return true;
        }
      }
    }

    return false;
  }

  // Helper method to normalize text by removing diacritics/accents
  String _normalizeString(String input) {
    const Map<String, String> accentsMap = {
      'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
      'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
      'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
      'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ç': 'c', 'ñ': 'n', 'ß': 'ss',
      // Turkish specific characters
      'ı': 'i', 'İ': 'I',
      'ğ': 'g', 'Ğ': 'G',
      'ş': 's', 'Ş': 'S',
      // Uppercase versions for existing ö and ü, if not already covered by toLowerCase()
      'Ö': 'O',
      'Ü': 'U',
      // Additional special characters (consider adding uppercase versions if needed)
      'ž': 'z', 'š': 's', 'đ': 'd', 'ć': 'c', 'č': 'c',
    };

    String result = input;
    accentsMap.forEach((accent, normal) {
      result = result.replaceAll(accent, normal);
    });

    return result;
  }

  void _selectLocation(Map<String, dynamic> location) async {
    _logger.logInteraction(
      'CitySearchScreen',
      'select_location',
      data: {
        'location_name': location['name'],
        'latitude': location['latitude'],
        'longitude': location['longitude'],
      },
    );
    try {
      final locationService = locator<LocationService>();

      await locationService.setManualLocation(
        location['latitude'] as double,
        location['longitude'] as double,
        name: location['name'] as String?,
      );

      // Enable manual location
      await locationService.setUseManualLocation(true);

      if (mounted) {
        Navigator.of(
          context,
        ).pop(true); // Return true to indicate location was set
        _logger.info(
          'Manual location set and popped from CitySearchScreen',
          data: {'location': location['name']},
        );
      }
    } catch (e, s) {
      _logger.error(
        'Error setting manual location',
        data: {
          'location_name': location['name'],
          'error': e.toString(),
          'stackTrace': s.toString(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error setting location")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = UIThemeHelper.getThemeColors(brightness);

    final Color textFieldBg =
        colors.isDarkMode
            ? const Color(0xFF3C3C3C)
            : AppColors.background(brightness);
    final Color listTileSelectedColor =
        colors.isDarkMode
            ? colors.accentColor.withAlpha(50)
            : AppColors.primary(brightness).withAlpha(30);

    return Scaffold(
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(
        title: "Set Location Manually",
        brightness: brightness,
      ),
      body: Column(
        children: [
          CitySearchBar(
            controller: _searchController,
            brightness: brightness,
            contentSurfaceColor: colors.contentSurface,
            textFieldBackgroundColor: textFieldBg,
            textColor: colors.textColorPrimary,
            hintColor: colors.textColorSecondary,
            iconColor: colors.iconInactive,
            borderColor: colors.borderColor,
            onClear: () {
              _searchController.clear();
              setState(() {
                _searchResults.clear();
                _errorMessage = null;
                _isLoading = false;
              });
            },
            onChanged: (value) => setState(() {}), // To rebuild suffix icon
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accentColor),
                ),
              ),
            ),
          if (_errorMessage != null && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.label(
                  brightness,
                ).copyWith(color: colors.errorColor),
                textAlign: TextAlign.center,
              ),
            ),
          if (_searchResults.isNotEmpty && !_isLoading)
            Expanded(
              child: CitySearchResultsList(
                searchResults: _searchResults,
                brightness: brightness,
                contentSurfaceColor: colors.contentSurface,
                textColor: colors.textColorPrimary,
                hintColor: colors.textColorSecondary,
                iconColor: colors.iconInactive,
                borderColor: colors.borderColor,
                listTileSelectedColor: listTileSelectedColor,
                onSelectLocation: _selectLocation,
              ),
            ),
        ],
      ),
    );
  }
}
