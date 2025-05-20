import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/app_settings.dart';
import '../providers/providers.dart';
import '../providers/settings_notifier.dart';
import '../service_locator.dart';
import '../services/location_service.dart';
import '../services/logger_service.dart';
import '../styles/app_styles.dart';
import 'about_view.dart';
import 'city_search_screen.dart';

class SettingsView extends ConsumerStatefulWidget {
  // Add constructor parameters to indicate where to scroll initially
  final bool scrollToNotifications;
  final bool scrollToLocation;
  final bool scrollToDate;

  const SettingsView({
    super.key,
    this.scrollToNotifications = false,
    this.scrollToLocation = false,
    this.scrollToDate = false,
  });

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final LocationService _locationService = locator<LocationService>();
  final LoggerService _logger = locator<LoggerService>();
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Add scroll controller to manage scrolling
  final ScrollController _scrollController = ScrollController();
  // Add global keys for sections we need to scroll to
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No need for explicit Provider.of call - Riverpod manages this
  }

  @override
  void initState() {
    super.initState();
    _logger.info('SettingsView initialized');
    _loadCurrentLocation();

    // Schedule scroll to appropriate section after build if requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Use Future.delayed with Duration.zero to ensure scrolling happens
      // after the current build cycle and layout phase is fully complete,
      // giving more time for GlobalKey contexts to be established.
      Future.delayed(Duration.zero, () {
        if (!mounted) return;

        if (widget.scrollToNotifications) {
          _logger.debug('Delayed auto-scroll to notifications section');
          _scrollToNotificationsSection();
        } else if (widget.scrollToLocation) {
          _logger.debug('Delayed auto-scroll to location section');
          _scrollToLocationSection();
          // The _showLocationOptionsDialog is called within _scrollToLocationSection
        } else if (widget.scrollToDate) {
          _logger.debug('Delayed auto-scroll to date section');
          _scrollToDateSection();
        }
      });
    });
  }

  @override
  void dispose() {
    _logger.debug('SettingsView disposed');
    // Dispose the scroll controller
    _scrollController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    _logger.debug('Loading current location in settings');

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Force a fresh location request by using Geolocator directly when in automatic mode
      if (!_locationService.isUsingManualLocation()) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );
          if (!mounted) return;
          _logger.info(
            'Updated current location',
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'automatic': true,
            },
          );
          setState(() {
            _currentPosition = position;
            _isLoadingLocation = false;
          });
          return;
        } catch (e, s) {
          _logger.error(
            'Error getting direct location',
            error: e.toString(),
            stackTrace: s,
          );
          // Fall through to use LocationService as backup
        }
      }

      // Use LocationService as fallback or when in manual mode
      final position = await _locationService.getLocation();
      if (!mounted) return;

      // Log location information
      _logger.info(
        'Using cached/manual location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'automatic': false,
        },
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      _logger.error('Failed to load location', error: e.toString());
      if (!mounted) return;

      setState(() {
        _isLoadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // Method to scroll to date (appearance) section
  void _scrollToDateSection() {
    _logger.debug('Attempting to scroll to Date & Time section');
    if (!mounted) {
      _logger.warning(
        '_scrollToDateSection: Widget not mounted when trying to scroll.',
      );
      return;
    }
    if (_dateKey.currentContext != null && _scrollController.hasClients) {
      try {
        Scrollable.ensureVisible(
          _dateKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.0, // Align to the top of the viewport
        );
        _logger.debug(
          'Successfully initiated scroll to Date & Time section using ensureVisible.',
        );
      } catch (e, s) {
        _logger.error(
          'Error in _scrollToDateSection using ensureVisible',
          error: e.toString(),
          stackTrace: s,
        );
      }
    } else {
      _logger.warning(
        '_scrollToDateSection: context or scrollController not ready',
        data: {
          'dateKeyCurrentContext_isNull': _dateKey.currentContext == null,
          'scrollControllerHasClients': _scrollController.hasClients,
        },
      );
    }
    // Show date format dialog after scrolling if requested
    if (widget.scrollToDate && mounted) {
      // This if statement was missing its closing brace
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          final settingsNotifierInstance = ref.read(settingsProvider.notifier);
          // Get the current settings to pass the dateFormatOption
          final currentSettings = ref.read(settingsProvider);
          _showDateFormatDialog(
            context,
            currentSettings.dateFormatOption,
            settingsNotifierInstance,
          );
        }
      });
    } // <-- Added missing closing brace for the if statement on line 197
  }

  // Method to scroll to notifications section
  void _scrollToNotificationsSection() {
    if (!mounted) {
      _logger.warning(
        '_scrollToNotificationsSection: Widget not mounted when trying to scroll.',
      );
      return;
    }
    if (_notificationsKey.currentContext != null &&
        _scrollController.hasClients) {
      Scrollable.ensureVisible(
        _notificationsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
  }

  // Method to scroll to location section
  void _scrollToLocationSection() {
    if (!mounted) {
      _logger.warning(
        '_scrollToLocationSection: Widget not mounted when trying to scroll.',
      );
      return;
    }
    // Try to scroll the location section into view
    if (_locationKey.currentContext != null && _scrollController.hasClients) {
      Scrollable.ensureVisible(
        _locationKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
    // Fallback: scroll to bottom to ensure location section is visible
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Add a small delay before showing the location options dialog
    if (widget.scrollToLocation) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _showLocationOptionsDialog(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    // final appLocalizations = AppLocalizations.of(context)!;

    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        title: Text("Settings", style: AppTextStyles.appTitle(brightness)),
        backgroundColor: AppColors.primary(brightness),
        elevation: 2.0,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary(brightness),
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader("Appearance", brightness),

          _buildSettingsItem(
            icon: Icons.language,
            title: "Language",
            subtitle: "English",
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change language',
                data: {'current': "English"},
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Language selection is temporarily disabled."),
                ),
              );
            },
          ),

          _buildSettingsItem(
            icon: Icons.color_lens_outlined,
            title: "Theme",
            subtitle: _getThemeName(settings.themeMode),
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change theme',
                data: {'current': settings.themeMode.toString()},
              );
              _showThemePicker(context, settings.themeMode, settingsNotifier);
            },
          ),

          _buildSectionHeader("Tesbih & Sound", brightness),

          _buildSettingsItem(
            icon: Icons.music_note_outlined,
            title: "Azan Sound",
            subtitle: _getAzanSoundDisplayName(
              settings.azanSoundForStandardPrayers,
            ),
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change Azan sound',
                data: {'current': settings.azanSoundForStandardPrayers},
              );
              _showAzanSoundSelectionDialog(
                context,
                settings.azanSoundForStandardPrayers,
                settingsNotifier,
              );
            },
          ),

          _buildSectionHeader(
            "Notifications",
            brightness,
            trailing:
                ref.watch(settingsProvider.notifier).areNotificationsBlocked
                    ? Icon(
                      Icons.notifications_off,
                      size: 16,
                      color: Colors.orange,
                    )
                    : null,
            key: _notificationsKey,
          ),

          ...PrayerNotification.values.map(
            (prayer) => _buildNotificationSwitch(
              prayer: prayer,
              value: settings.notifications[prayer] ?? false,
              onChanged: (value) {
                _logger.logInteraction(
                  'SettingsView',
                  'Toggle prayer notification',
                  data: {'prayer': prayer.toString(), 'enabled': value},
                );
                settingsNotifier.setPrayerNotification(prayer, value);
              },
            ),
          ),

          _buildSectionHeader("Prayer Calculation", brightness),

          _buildSettingsItem(
            icon: Icons.calculate_outlined,
            title: "Calculation Method",
            subtitle: _getCalculationMethodName(
              settings.calculationMethod,
            ),
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change calculation method',
                data: {'current': settings.calculationMethod},
              );
              _showCalculationMethodPicker(context, settings.calculationMethod, settingsNotifier);
            },
          ),

          _buildSettingsItem(
            icon: Icons.school_outlined,
            title: "Asr Time",
            subtitle: _getMadhabName(settings.madhab),
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change madhab',
                data: {'current': settings.madhab},
              );
              _showMadhabPicker(context, settings.madhab, settingsNotifier);
            },
          ),

          Container(
            key: _locationKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Location", brightness),
                _buildLocationTile(context),
              ],
            ),
          ),

          // Date & Time and Units section grouped for scrolling
          Column(
            key: _dateKey, // Moved GlobalKey here
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                "Date & Time",
                brightness,
                // key: _dateKey, // Removed GlobalKey from here
              ),
              _buildSettingsItem(
                icon: Icons.calendar_today,
                title: "Date Format",
                subtitle: _getDateFormatName(
                  settings.dateFormatOption,
                ),
                onTap: () {
                  _logger.logInteraction(
                    'SettingsView',
                    'Change date format',
                    data: {'current': settings.dateFormatOption.toString()},
                  );
                  _showDateFormatDialog(
                    context,
                    settings.dateFormatOption,
                    settingsNotifier,
                  );
                },
              ),
              _buildSettingsItem(
                icon: Icons.access_time,
                title: "Time Format",
                subtitle: _getTimeFormatName(
                  settings.timeFormat,
                ),
                onTap: () {
                  _logger.logInteraction(
                    'SettingsView',
                    'Change time format',
                    data: {'current': settings.timeFormat.toString()},
                  );
                  _showTimeFormatDialog(
                    context,
                    settings.timeFormat,
                    settingsNotifier,
                  );
                },
              ),
            ],
          ),

          _buildSectionHeader("Other", brightness),

          _buildSettingsItem(
            icon: Icons.info_outline,
            title: "About",
            subtitle: "About this app",
            onTap: () {
              _logger.logInteraction('SettingsView', 'Open about screen');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Brightness brightness, {Widget? trailing, Key? key}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Row(
        key: key,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sectionTitle(brightness).copyWith(
                color: AppColors.primary(brightness),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor(brightness)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.iconInactive(brightness)),
        title: Text(title, style: AppTextStyles.prayerName(brightness)),
        subtitle: Text(subtitle, style: AppTextStyles.label(brightness)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.iconInactive(brightness),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildNotificationSwitch({
    required PrayerNotification prayer,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final localSettingsNotifier = ref.read(settingsProvider.notifier);
    final bool isBlocked = localSettingsNotifier.areNotificationsBlocked;
    final brightness = Theme.of(context).brightness;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color:
            isBlocked
                ? AppColors.background(brightness).withAlpha(178)
                : AppColors.background(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor(brightness)),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              _getPrayerName(prayer),
              style: AppTextStyles.prayerName(brightness).copyWith(
                color: isBlocked ? AppColors.iconInactive(brightness) : null,
              ),
            ),
            subtitle: Text(
              "Receive notification for ${_getPrayerName(prayer)} prayer",
              style: AppTextStyles.label(brightness).copyWith(
                color: isBlocked ? AppColors.iconInactive(brightness) : null,
              ),
            ),
            value: value,
            onChanged: isBlocked ? null : onChanged,
            activeColor: AppColors.primary(brightness),
            activeTrackColor: AppColors.switchTrackActive(brightness),
            secondary: Icon(
              isBlocked
                  ? Icons.notifications_off
                  : Icons.notifications_outlined,
              color: AppColors.iconInactive(brightness),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          if (isBlocked)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Notifications are blocked. Enable them in system settings.",
                      style: AppTextStyles.label(brightness).copyWith(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(
    BuildContext context,
  ) {
    final brightness = Theme.of(context).brightness;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background(brightness),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor(brightness)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: AppColors.iconInactive(brightness),
            ),
            title: Text(
              "Location",
              style: AppTextStyles.prayerName(brightness),
            ),
            subtitle: FutureBuilder<bool?>(
              future: Future.value(_locationService.isUsingManualLocation()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    "Loading",
                    style: AppTextStyles.label(brightness),
                  );
                }

                final isManualLocation = snapshot.data ?? false;

                if (isManualLocation) {
                  return FutureBuilder<String?>(
                    future: _locationService.getLocationName(),
                    builder: (context, nameSnapshot) {
                      return Text(
                        nameSnapshot.data ?? "Unknown Location",
                        style: AppTextStyles.label(brightness),
                      );
                    },
                  );
                } else {
                  return _isLoadingLocation
                      ? Text(
                        "Loading",
                        style: AppTextStyles.label(brightness),
                      )
                      : _currentPosition != null
                      ? Text(
                        "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                        style: AppTextStyles.label(brightness),
                      )
                      : Text(
                        "Not Set",
                        style: AppTextStyles.label(brightness),
                      );
                }
              },
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.iconInactive(brightness),
            ),
            onTap: () {
              _logger.logInteraction('SettingsView', 'Open location options');
              _showLocationOptionsDialog(context);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationOptionsDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background(brightness),
          title: Text(
            "Location",
            style: AppTextStyles.sectionTitle(brightness),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.my_location, color: AppColors.primary(brightness)),
                title: Text(
                  'Current Device Location',
                  style: AppTextStyles.prayerName(brightness),
                ),
                onTap: () async {
                  _logger.logInteraction(
                    'SettingsView',
                    'Select current device location',
                  );
                  Navigator.pop(dialogContext);
                  await _locationService.setUseManualLocation(false);
                  _loadCurrentLocation();
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              Divider(color: AppColors.divider(brightness)),
              ListTile(
                leading: Icon(Icons.search, color: AppColors.primary(brightness)),
                title: Text(
                  "Set Location Manually",
                  style: AppTextStyles.prayerName(brightness),
                ),
                onTap: () async {
                  _logger.logInteraction(
                    'SettingsView',
                    'Open manual location selection',
                  );
                  Navigator.pop(dialogContext);

                  if (!mounted) return;

                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CitySearchScreen(),
                    ),
                  );

                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary(brightness)),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  void _showThemePicker(BuildContext context, ThemeMode currentThemeMode, SettingsNotifier notifier) {
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color dialogBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final Color textColor = AppColors.textPrimary(brightness);
    final Color accentColor = AppColors.accentGreen(brightness);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Select Theme",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((themeMode) {
              return RadioListTile<ThemeMode>(
                title: Text(
                  _getThemeName(themeMode),
                  style: TextStyle(color: textColor),
                ),
                value: themeMode,
                groupValue: currentThemeMode, // Use passed currentThemeMode
                activeColor: accentColor,
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    notifier.updateThemeMode(value); // Corrected method name
                    Navigator.of(context).pop();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAzanSoundSelectionDialog(
    BuildContext context,
    String currentAzanSound,
    SettingsNotifier settingsNotifier,
  ) {
    final brightness = Theme.of(context).brightness;
    final List<String> azanSounds = [
      'makkah_adhan.mp3',
      'madinah_adhan.mp3',
      'alaqsa_adhan.mp3',
      'azaan_turkish.mp3',
    ];

    String? tempSelectedAzan = currentAzanSound;

    showDialog(
      context: context,
      builder: (dialogContext) {
        // Changed context to dialogContext for clarity
        return StatefulBuilder(
          // Used StatefulBuilder to manage dialog state
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.background(brightness),
              title: Text(
                "Azan Sound",
                style: AppTextStyles.sectionTitle(brightness),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: azanSounds.length,
                  itemBuilder: (BuildContext context, int index) {
                    final soundFile = azanSounds[index];
                    return RadioListTile<String>(
                      title: Text(
                        _getAzanSoundDisplayName(soundFile),
                        style: AppTextStyles.prayerName(brightness),
                      ),
                      value: soundFile,
                      groupValue: tempSelectedAzan, // Use temporary selection
                      activeColor: AppColors.primary(brightness),
                      onChanged: (value) async {
                        if (value != null) {
                          setStateDialog(() {
                            // Update dialog state
                            tempSelectedAzan = value;
                          });
                          await _audioPlayer.stop();
                          try {
                            await _audioPlayer.play(
                              AssetSource('audio/$value'),
                            );
                            _logger.info('Playing Azan preview: $value');
                          } catch (e, s) {
                            _logger.error(
                              'Error playing Azan preview',
                              error: e.toString(),
                              stackTrace: s,
                            );
                          }
                        }
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    await _audioPlayer.stop();
                    if (mounted) {
                      navigator.pop();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary(brightness),
                  ),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    if (tempSelectedAzan != null) {
                      settingsNotifier.updateAzanSoundForStandardPrayers(
                        tempSelectedAzan!,
                      );
                    }
                    final navigator = Navigator.of(dialogContext);
                    await _audioPlayer.stop();
                    if (mounted) {
                      navigator.pop();
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary(brightness),
                  ),
                  child: Text("Confirm"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) async {
      // Ensure audio stops if dialog is dismissed by tapping outside
      await _audioPlayer.stop();
    });
  }

  String _getAzanSoundDisplayName(
    String fileName,
  ) {
    // Helper to convert filename to a more readable display name
    // This could be enhanced with actual localized names if available
    if (fileName.isEmpty) return "Not Set"; // Or some default
    String name = fileName.replaceAll('_adhan.mp3', '').replaceAll('_', ' ');
    name = name.replaceAll('azaan ', ''); // for azaan_turkish
    name = name[0].toUpperCase() + name.substring(1);
    if (name.toLowerCase().contains('makkah')) {
      return "Makkah Adhan";
    }
    if (name.toLowerCase().contains('madinah')) {
      return "Madinah Adhan";
    }
    if (name.toLowerCase().contains('alaqsa')) {
      return "Al-Aqsa Adhan";
    }
    if (name.toLowerCase().contains('turkish')) {
      return "Turkish Adhan";
    }
    return name; // Fallback to a processed name
  }

  String _getThemeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return "System";
      case ThemeMode.light:
        return "Light";
      case ThemeMode.dark:
        return "Dark";
    }
  }

  String _getCalculationMethodName(String method) { // Added this function
    // This is a placeholder. You might want to map keys to display names.
    // For example, if method is 'MuslimWorldLeague', return 'Muslim World League'
    // This depends on how your calculation method strings are stored and how you want to display them.
    return method;
  }

  String _getMadhabName(String madhab) { // Changed Madhab to String
    // Assuming madhab is stored as a string like 'shafi' or 'hanafi'
    if (madhab.toLowerCase() == 'shafi') return "Shafi";
    if (madhab.toLowerCase() == 'hanafi') return "Hanafi";
    return madhab; // Fallback to the raw string if not recognized
  }

  String _getPrayerName(
    PrayerNotification prayer,
  ) {
    switch (prayer) {
      case PrayerNotification.fajr:
        return "Fajr";
      case PrayerNotification.sunrise:
        return "Sunrise";
      case PrayerNotification.dhuhr:
        return "Dhuhr";
      case PrayerNotification.asr:
        return "Asr";
      case PrayerNotification.maghrib:
        return "Maghrib";
      case PrayerNotification.isha:
        return "Isha";
    }
  }

  String _getDateFormatName(DateFormatOption option) {
    switch (option) {
      case DateFormatOption.dayMonthYear:
        return "Day Month Year";
      case DateFormatOption.monthDayYear:
        return "Month Day Year";
      case DateFormatOption.yearMonthDay:
        return "Year Month Day";
    }
  }

  String _getTimeFormatName(TimeFormat format) {
    switch (format) {
      case TimeFormat.twelveHour:
        return "12-hour";
      case TimeFormat.twentyFourHour:
        return "24-hour";
    }
  }

  void _showDateFormatDialog(
    BuildContext context,
    DateFormatOption currentDateFormatOption,
    SettingsNotifier notifier,
  ) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.background(brightness),
            title: Text(
              "Date Format",
              style: AppTextStyles.sectionTitle(brightness),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  DateFormatOption.values
                      .map(
                        (opt) => RadioListTile<DateFormatOption>(
                          title: Text(
                            _getDateFormatName(opt),
                            style: AppTextStyles.prayerName(brightness),
                          ),
                          value: opt,
                          groupValue: currentDateFormatOption,
                          activeColor: AppColors.primary(brightness),
                          onChanged: (v) {
                            if (v != null) notifier.updateDateFormatOption(v);
                            Navigator.pop(ctx);
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _showTimeFormatDialog(
    BuildContext context,
    TimeFormat currentTimeFormat,
    SettingsNotifier notifier,
  ) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppColors.background(brightness),
            title: Text(
              "Time Format",
              style: AppTextStyles.sectionTitle(brightness),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  TimeFormat.values
                      .map(
                        (fmt) => RadioListTile<TimeFormat>(
                          title: Text(
                            _getTimeFormatName(fmt),
                            style: AppTextStyles.prayerName(brightness),
                          ),
                          value: fmt,
                          groupValue: currentTimeFormat,
                          activeColor: AppColors.primary(brightness),
                          onChanged: (v) {
                            if (v != null) notifier.updateTimeFormat(v);
                            Navigator.pop(ctx);
                          },
                        ),
                      )
                      .toList(),
            ),
          ),
    );
  }

  void _showCalculationMethodPicker(
    BuildContext context,
    String currentCalculationMethod, // Add currentCalculationMethod parameter
    SettingsNotifier notifier,
  ) {
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color dialogBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final Color textColor = AppColors.textPrimary(brightness);
    final Color accentColor = AppColors.accentGreen(brightness);

    // Placeholder for actual calculation methods
    // You need to define how you get these. Example:
    final List<String> calculationMethods = [
      'MuslimWorldLeague', 
      'Egyptian', 
      'Karachi', 
      'UmmAlQura', 
      'Dubai', 
      'MoonsightingCommittee', 
      'NorthAmerica', 
      'Kuwait', 
      'Qatar', 
      'Singapore', 
      'Tehran', 
      'Turkey'
      ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Select Calculation Method",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: calculationMethods.length,
              itemBuilder: (context, index) {
                final method = calculationMethods[index];
                return RadioListTile<String>(
                  title: Text(
                    _getCalculationMethodName(method), // Use helper to get display name
                    style: TextStyle(color: textColor),
                  ),
                  value: method,
                  groupValue: currentCalculationMethod, // Use passed currentCalculationMethod
                  onChanged: (String? value) {
                    if (value != null) {
                      notifier.updateCalculationMethod(value); // Corrected method name
                      _recalculatePrayerTimes(newMethod: value);
                      Navigator.of(context).pop();
                    }
                  },
                  activeColor: accentColor,
                  controlAffinity: ListTileControlAffinity.trailing,
                  tileColor: dialogBgColor,
                  selectedTileColor: accentColor.withAlpha((255 * 0.1).round()),
                );
              },
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        );
      },
    );
  }

  void _showMadhabPicker(BuildContext context, String currentMadhab, SettingsNotifier notifier) { // Add currentMadhab parameter
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;
    final Color dialogBgColor =
        isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final Color textColor = AppColors.textPrimary(brightness);
    final Color accentColor = AppColors.accentGreen(brightness);
    
    // Placeholder for actual madhab options
    // You need to define how you get these. Example:
    final List<String> madhabs = ['shafi', 'hanafi']; 

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBgColor,
          title: Text(
            "Select Madhab",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: madhabs.map((madhab) { // Use the string list
              return RadioListTile<String>(
                title: Text(
                  _getMadhabName(madhab), // Use helper to get display name
                  style: TextStyle(color: textColor),
                ),
                value: madhab,
                groupValue: currentMadhab, // Use passed currentMadhab
                onChanged: (String? value) { // Changed Madhab to String
                  if (value != null) {
                    notifier.updateMadhab(value); // Corrected method name
                    _recalculatePrayerTimes(newMadhab: value);
                    Navigator.of(context).pop();
                  }
                },
                activeColor: accentColor,
                controlAffinity: ListTileControlAffinity.trailing,
                tileColor: dialogBgColor,
                selectedTileColor: accentColor.withAlpha((255 * 0.1).round()),
              );
            }).toList(),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        );
      },
    );
  }

  Future<void> _recalculatePrayerTimes({
    String? newMethod, // Changed PrayerCalculationMethod to String
    String? newMadhab, // Changed Madhab to String
  }) async {
    // Your logic to recalculate prayer times based on newMethod and newMadhab
  }
}
