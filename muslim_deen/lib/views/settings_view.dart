import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/providers.dart';
import 'package:muslim_deen/providers/settings_notifier.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/location_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/styles/app_styles.dart';
import 'package:muslim_deen/styles/ui_theme_helper.dart';
import 'package:muslim_deen/views/about_view.dart';
import 'package:muslim_deen/views/city_search_screen.dart';
import 'package:muslim_deen/widgets/custom_app_bar.dart';
import 'package:muslim_deen/widgets/settings_ui_elements.dart';

class SettingsView extends ConsumerStatefulWidget {
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _dateKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    _logger.info('SettingsView initialized');
    _loadCurrentLocation();

    /// Schedule scroll to appropriate section after build if requested
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Future.delayed(Duration.zero, () {
        if (!mounted) return;

        if (widget.scrollToNotifications) {
          _logger.debug('Delayed auto-scroll to notifications section');
          _scrollToNotificationsSection();
        } else if (widget.scrollToLocation) {
          _logger.debug('Delayed auto-scroll to location section');
          _scrollToLocationSection();
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
        }
      }

      final position = await _locationService.getLocation();
      if (!mounted) return;

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
          alignment: 0.0,
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
    if (widget.scrollToDate && mounted) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          final settingsNotifierInstance = ref.read(settingsProvider.notifier);
          final currentSettings = ref.read(settingsProvider);
          _showDateFormatDialog(
            context,
            currentSettings.dateFormatOption,
            settingsNotifierInstance,
          );
        }
      });
    }
  }

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

  void _scrollToLocationSection() {
    if (!mounted) {
      _logger.warning(
        '_scrollToLocationSection: Widget not mounted when trying to scroll.',
      );
      return;
    }
    if (_locationKey.currentContext != null && _scrollController.hasClients) {
      Scrollable.ensureVisible(
        _locationKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.0,
      );
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

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
      backgroundColor: AppColors.getScaffoldBackground(brightness),
      appBar: CustomAppBar(title: "Settings", brightness: brightness),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const SettingsSectionHeader(title: "Appearance"),

          SettingsListItem(
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

          SettingsListItem(
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

          const SettingsSectionHeader(title: "Tesbih & Sound"),

          SettingsListItem(
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

          SettingsSectionHeader(
            title: "Notifications",
            trailing:
                ref.watch(settingsProvider.notifier).areNotificationsBlocked
                    ? const Icon(
                      Icons.notifications_off,
                      size: 16,
                      color: Colors.orange,
                    )
                    : null,
            sectionKey: _notificationsKey,
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
                settingsNotifier.updatePrayerNotification(prayer, value);
              },
            ),
          ),

          const SettingsSectionHeader(title: "Prayer Calculation"),

          SettingsListItem(
            icon: Icons.calculate_outlined,
            title: "Calculation Method",
            subtitle: _getCalculationMethodName(settings.calculationMethod),
            onTap: () {
              _logger.logInteraction(
                'SettingsView',
                'Change calculation method',
                data: {'current': settings.calculationMethod},
              );
              _showCalculationMethodPicker(
                context,
                settings.calculationMethod,
                settingsNotifier,
              );
            },
          ),

          SettingsListItem(
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
                const SettingsSectionHeader(title: "Location"),
                _buildLocationTile(context),
              ],
            ),
          ),

          // Date & Time and Units section grouped for scrolling
          Column(
            key: _dateKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionHeader(title: "Date & Time"),
              SettingsListItem(
                icon: Icons.calendar_today,
                title: "Date Format",
                subtitle: _getDateFormatName(settings.dateFormatOption),
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
              SettingsListItem(
                icon: Icons.access_time,
                title: "Time Format",
                subtitle: _getTimeFormatName(settings.timeFormat),
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

          const SettingsSectionHeader(title: "Other"),

          SettingsListItem(
            icon: Icons.info_outline,
            title: "About",
            subtitle: "About this app",
            onTap: () {
              _logger.logInteraction('SettingsView', 'Open about screen');
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
        ],
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
    final colors = UIThemeHelper.getThemeColors(brightness);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color:
            isBlocked
                ? colors.contentSurface.withAlpha(178)
                : colors.contentSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(
              _getPrayerName(prayer),
              style: AppTextStyles.prayerName(
                brightness,
              ).copyWith(color: isBlocked ? colors.iconInactive : null),
            ),
            subtitle: Text(
              "Receive notification for ${_getPrayerName(prayer)} prayer",
              style: AppTextStyles.label(
                brightness,
              ).copyWith(color: isBlocked ? colors.iconInactive : null),
            ),
            value: value,
            onChanged: isBlocked ? null : onChanged,
            activeColor: colors.accentColor,
            inactiveThumbColor: colors.iconInactive,
            inactiveTrackColor: colors.borderColor,
            secondary: Icon(
              isBlocked
                  ? Icons.notifications_off
                  : Icons.notifications_outlined,
              color: colors.iconInactive,
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
                      style: AppTextStyles.label(
                        brightness,
                      ).copyWith(color: Colors.orange, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(BuildContext context) {
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
                    future: _locationService.getStoredLocationName(),
                    builder: (context, nameSnapshot) {
                      return Text(
                        nameSnapshot.data ?? "Unknown Location",
                        style: AppTextStyles.label(brightness),
                      );
                    },
                  );
                } else {
                  return _isLoadingLocation
                      ? Text("Loading", style: AppTextStyles.label(brightness))
                      : _currentPosition != null
                      ? Text(
                        "${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                        style: AppTextStyles.label(brightness),
                      )
                      : Text("Not Set", style: AppTextStyles.label(brightness));
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

    showDialog<void>(
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
                leading: Icon(
                  Icons.my_location,
                  color: AppColors.primary(brightness),
                ),
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
                leading: Icon(
                  Icons.search,
                  color: AppColors.primary(brightness),
                ),
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
                    MaterialPageRoute<bool>(
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
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary(brightness),
              ),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGenericSelectionDialog<T>({
    required BuildContext context,
    required String dialogTitle,
    required T currentValue,
    required List<T> options,
    required String Function(T option) optionTitleBuilder,
    required void Function(T? value) onSettingChanged,
  }) async {
    final brightness = Theme.of(context).brightness;
    final dialogBackgroundColor = AppColors.surface(brightness);
    final textColor = AppTextStyles.label(brightness).color;
    final activeColor = AppColors.primary(brightness);

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          title: Text(
            dialogTitle,
            style: AppTextStyles.sectionTitle(
              brightness,
            ).copyWith(color: textColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  options.map((option) {
                    return RadioListTile<T>(
                      title: Text(
                        optionTitleBuilder(option),
                        style: AppTextStyles.label(
                          brightness,
                        ).copyWith(color: textColor),
                      ),
                      value: option,
                      groupValue: currentValue,
                      activeColor: activeColor,
                      onChanged: (T? value) {
                        if (value != null) {
                          onSettingChanged(value);
                          Navigator.of(dialogContext).pop();
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _showThemePicker(
    BuildContext context,
    ThemeMode currentThemeMode,
    SettingsNotifier notifier,
  ) {
    _showGenericSelectionDialog<ThemeMode>(
      context: context,
      dialogTitle: "Select Theme",
      currentValue: currentThemeMode,
      options: ThemeMode.values,
      optionTitleBuilder: _getThemeName,
      onSettingChanged: (ThemeMode? value) {
        if (value != null) {
          notifier.updateThemeMode(value);
        }
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

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
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
                      groupValue: tempSelectedAzan,
                      activeColor: AppColors.primary(brightness),
                      onChanged: (value) async {
                        if (value != null) {
                          setStateDialog(() {
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
                      settingsNotifier.updateAzanSound(tempSelectedAzan!);
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
      await _audioPlayer.stop();
    });
  }

  String _getAzanSoundDisplayName(String fileName) {
    if (fileName.isEmpty) return "Not Set";
    String name = fileName.replaceAll('_adhan.mp3', '').replaceAll('_', ' ');
    name = name.replaceAll('azaan ', '');
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
    return name;
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

  String _getCalculationMethodName(String method) {
    return method;
  }

  String _getMadhabName(String madhab) {
    if (madhab.toLowerCase() == 'shafi') return "Shafi";
    if (madhab.toLowerCase() == 'hanafi') return "Hanafi";
    return madhab;
  }

  String _getPrayerName(PrayerNotification prayer) {
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
    _showGenericSelectionDialog<DateFormatOption>(
      context: context,
      dialogTitle: "Date Format",
      currentValue: currentDateFormatOption,
      options: DateFormatOption.values,
      optionTitleBuilder: _getDateFormatName,
      onSettingChanged: (DateFormatOption? value) {
        if (value != null) {
          notifier.updateDateFormatOption(value);
        }
      },
    );
  }

  void _showTimeFormatDialog(
    BuildContext context,
    TimeFormat currentTimeFormat,
    SettingsNotifier notifier,
  ) {
    _showGenericSelectionDialog<TimeFormat>(
      context: context,
      dialogTitle: "Time Format",
      currentValue: currentTimeFormat,
      options: TimeFormat.values,
      optionTitleBuilder: _getTimeFormatName,
      onSettingChanged: (TimeFormat? value) {
        if (value != null) {
          notifier.updateTimeFormat(value);
        }
      },
    );
  }

  void _showCalculationMethodPicker(
    BuildContext context,
    String currentCalculationMethod,
    SettingsNotifier notifier,
  ) {
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
      'Turkey',
    ];

    _showGenericSelectionDialog<String>(
      context: context,
      dialogTitle: "Select Calculation Method",
      currentValue: currentCalculationMethod,
      options: calculationMethods,
      optionTitleBuilder: _getCalculationMethodName,
      onSettingChanged: (String? value) {
        if (value != null) {
          notifier.updateCalculationMethod(value);
          _recalculatePrayerTimes(newMethod: value);
        }
      },
    );
  }

  void _showMadhabPicker(
    BuildContext context,
    String currentMadhab,
    SettingsNotifier notifier,
  ) {
    final List<String> madhabs = ['shafi', 'hanafi'];

    _showGenericSelectionDialog<String>(
      context: context,
      dialogTitle: "Select Madhab",
      currentValue: currentMadhab,
      options: madhabs,
      optionTitleBuilder: _getMadhabName,
      onSettingChanged: (String? value) {
        if (value != null) {
          notifier.updateMadhab(value);
          _recalculatePrayerTimes(newMadhab: value);
        }
      },
    );
  }

  Future<void> _recalculatePrayerTimes({
    String? newMethod,
    String? newMadhab,
  }) async {
    _logger.info(
      'RecalculatePrayerTimes called (placeholder)',
      data: {'newMethod': newMethod, 'newMadhab': newMadhab},
    );
  }
}
