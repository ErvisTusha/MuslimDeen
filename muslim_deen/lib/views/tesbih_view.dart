// Standard library imports
import 'dart:async';

// Third-party package imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

// Local application imports
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart' show NotificationService;
import '../services/storage_service.dart';
import '../styles/app_styles.dart';

class TesbihView extends StatefulWidget {
  const TesbihView({super.key});

  @override
  State<TesbihView> createState() => _TesbihViewState();
}

class _TesbihViewState extends State<TesbihView> {
  int _count = 0;
  String _currentDhikr = 'Subhanallah'; // Default Dhikr
  bool _vibrationEnabled = true;
  bool _soundEnabled = false;
  int _target = 33; // Default target

  TimeOfDay? _reminderTime;
  bool _reminderEnabled = false;
  Timer? _permissionCheckTimer;
  late final NotificationService _notificationService =
      GetIt.I<NotificationService>();
  late final StorageService _storageService = GetIt.I<StorageService>();
  late final SettingsProvider _settingsProvider =
      context.read<SettingsProvider>();
  final LoggerService _logger = locator<LoggerService>();

  void _startPermissionCheck() {
    _permissionCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _settingsProvider.checkNotificationPermissionStatus();
      }
    });
  }

  // Arabic representations for Dhikr
  final Map<String, String> _dhikrArabic = {
    'Subhanallah': 'سُبْحَانَ اللهِ',
    'Alhamdulillah': 'الْحَمْدُ لِلَّهِ',
    'Astaghfirullah': 'أَسْتَغْفِرُ اللهَ',
    'Allahu Akbar': 'اللهُ أَكْبَر',
  };

  // Default targets for each Dhikr
  final Map<String, int> _defaultDhikrTargets = {
    'Subhanallah': 33,
    'Alhamdulillah': 33,
    'Astaghfirullah': 33,
    'Allahu Akbar': 34, // Often 34 after prayer
  };

  // Order for automatic advancement
  final List<String> _dhikrOrder = [
    'Subhanallah',
    'Alhamdulillah',
    'Astaghfirullah',
    'Allahu Akbar',
  ];

  @override
  void initState() {
    super.initState();
    _logger.info('TesbihView initialized');
    _loadPreferences();
    // Wait to initialize any localization-dependent operations until didChangeDependencies
    _settingsProvider
        .checkNotificationPermissionStatus(); // Check initial permission status
    _startPermissionCheck(); // Start periodic permission check
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.debug('TesbihView dependencies changed');
    // Safely access localizations here after dependencies are established
    _loadReminderSettings();
  }

  @override
  void dispose() {
    _logger.debug('TesbihView disposed');
    // Clean up resources
    _permissionCheckTimer?.cancel();
    if (_reminderEnabled) {
      _notificationService.cancelNotification(9999);
    }

    // Save final state
    _savePreferences();
    _saveReminderSettings();

    super.dispose();
  }

  // Load reminder settings from storage
  Future<void> _loadReminderSettings() async {
    _logger.debug('Loading Tesbih reminder settings');
    final reminderHour =
        _storageService.getData('tesbih_reminder_hour') as int?;
    final reminderMinute =
        _storageService.getData('tesbih_reminder_minute') as int?;
    final enabled = _storageService.getData('tesbih_reminder_enabled') as bool?;

    if (reminderHour != null && reminderMinute != null) {
      setState(() {
        _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
        _reminderEnabled = enabled ?? false;
      });
      if (_reminderEnabled && mounted) {
        _scheduleReminder();
      }
    }
  }

  // Schedule the daily reminder notification using the existing service method
  Future<void> _scheduleReminder() async {
    if (!_reminderEnabled) {
      // Cancel existing reminder if disabled
      await _notificationService.cancelNotification(9999);
      _logger.info('Tesbih reminder cancelled');
      return;
    }

    if (_reminderTime == null) {
      _logger.warning('Cannot schedule Tesbih reminder: Time not set');
      return; // Don't schedule if time isn't set
    }

    final now = DateTime.now();
    // Calculate the next occurrence of the reminder time
    var scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      _reminderTime!.hour,
      _reminderTime!.minute,
    );

    // If the calculated time is in the past, schedule it for the next day
    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
    }

    // Ensure context is still valid before accessing localizations
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    _logger.info(
      'Scheduling Tesbih reminder for ${scheduledDateTime.toIso8601String()}, enabled: $_reminderEnabled',
    );

    // Use the existing schedulePrayerNotification method
    await _notificationService.schedulePrayerNotification(
      id: 9999, // Unique ID for Tesbih reminder
      localizedTitle: localizations.tasbihLabel,
      // TEMP WORKAROUND: Use a known working key until tesbihReminderBody generation is fixed
      localizedBody:
          localizations.tasbihLabel, // localizations.tesbihReminderBody,
      prayerTime: scheduledDateTime, // Pass the calculated DateTime
      isEnabled: _reminderEnabled, // Pass the enabled state
    );
  }

  // Show dialog to set reminder time
  Future<void> _showReminderSettingsDialog() async {
    _logger.logInteraction('TesbihView', 'Open reminder settings dialog');

    // Ensure context is still valid before showing dialog
    if (!mounted) return;
    // final localizations = AppLocalizations.of(context)!; // Unused variable
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        // Apply theme consistent with the app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              // Or dark based on app theme
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
            // Use DialogTheme for background color
            dialogTheme: DialogTheme(backgroundColor: AppColors.background),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && mounted) {
      _logger.logInteraction(
        'TesbihView',
        'Set reminder time',
        data: {'hour': pickedTime.hour, 'minute': pickedTime.minute},
      );

      setState(() {
        _reminderTime = pickedTime;
        _reminderEnabled = true; // Enable reminder when time is set
      });
      await _saveReminderSettings();
      _scheduleReminder();
    } else {
      _logger.logInteraction('TesbihView', 'Cancel reminder time selection');
    }
  }

  // Save reminder settings to storage
  Future<void> _saveReminderSettings() async {
    if (_reminderTime != null) {
      await _storageService.saveData(
        'tesbih_reminder_hour',
        _reminderTime!.hour,
      );
      await _storageService.saveData(
        'tesbih_reminder_minute',
        _reminderTime!.minute,
      );
    }
    await _storageService.saveData('tesbih_reminder_enabled', _reminderEnabled);
  }

  // Load user preferences (vibration, sound, current dhikr, target) from StorageService
  Future<void> _loadPreferences() async {
    // Use try-catch for robustness when reading from storage
    try {
      final storedDhikr =
          _storageService.getData('current_dhikr') as String? ?? _currentDhikr;
      final storedTarget = _storageService.getData('tasbih_target') as int?;
      final storedVibration =
          _storageService.getData('vibration_enabled') as bool?;
      final storedSound = _storageService.getData('sound_enabled') as bool?;

      // Check if the stored Dhikr is valid before using it
      final validDhikr =
          _dhikrOrder.contains(storedDhikr) ? storedDhikr : _currentDhikr;

      // Check if mounted before calling setState
      if (!mounted) return;
      setState(() {
        _currentDhikr = validDhikr;
        _vibrationEnabled = storedVibration ?? true;
        _soundEnabled = storedSound ?? false;
        // Ensure target is valid, fallback to default if stored is null or invalid
        _target =
            (storedTarget != null && storedTarget > 0)
                ? storedTarget
                : _defaultDhikrTargets[_currentDhikr]!;
      });
    } catch (e, s) {
      _logger.error(
        "Error loading Tesbih preferences",
        data: {'error': e.toString(), 'stackTrace': s.toString()},
      );
      // Keep default values if loading fails
      // Check if mounted before calling setState
      if (!mounted) return;
      setState(() {
        _target = _defaultDhikrTargets[_currentDhikr]!;
      });
    }
  }

  // Save user preferences
  Future<void> _savePreferences() async {
    await _storageService.saveData('vibration_enabled', _vibrationEnabled);
    await _storageService.saveData('sound_enabled', _soundEnabled);
    await _storageService.saveData('current_dhikr', _currentDhikr);
    await _storageService.saveData('tasbih_target', _target);
  }

  // Increment the counter, handle feedback and target completion
  Future<void> _incrementCount() async {
    if (_count >= _target) return; // Don't increment if target reached

    // Check if mounted before calling setState
    if (!mounted) return;
    setState(() => _count++);

    // Haptic feedback
    if (_vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    // Sound feedback (Consider using a sound package for better control)
    if (_soundEnabled) {
      // Basic system sounds, might not be ideal across platforms
      SystemSound.play(SystemSoundType.click);
    }

    // Check if target is reached
    if (_count == _target) {
      // Target reached feedback
      if (_vibrationEnabled) {
        HapticFeedback.heavyImpact(); // Use a stronger vibration for completion
      }
      if (_soundEnabled) {
        // Play a different sound for completion?
        SystemSound.play(SystemSoundType.alert);
      }
      // Automatically advance to the next Dhikr
      await _advanceDhikr();
    }
  }

  // Advance to the next Dhikr in the sequence
  Future<void> _advanceDhikr() async {
    final currentIndex = _dhikrOrder.indexOf(_currentDhikr);
    final nextIndex = (currentIndex + 1) % _dhikrOrder.length;
    final nextDhikr = _dhikrOrder[nextIndex];
    await _setDhikrInternal(
      nextDhikr,
    ); // Use internal method to reset count and save
  }

  // Reset the counter for the current Dhikr
  void _resetCount() {
    // Check if mounted before calling setState
    if (!mounted) return;
    setState(() {
      _count = 0;
    });
    if (_vibrationEnabled) {
      HapticFeedback.lightImpact(); // Light feedback for reset
    }
  }

  // Public method to set Dhikr (e.g., from button press)
  Future<void> _setDhikr(String dhikr) async {
    await _setDhikrInternal(dhikr);
  }

  // Internal method to set Dhikr, reset count, update target, and save
  Future<void> _setDhikrInternal(String dhikr) async {
    // Check if mounted before calling setState
    if (!mounted) return;
    setState(() {
      _currentDhikr = dhikr;
      _count = 0; // Reset count when Dhikr changes
      _target =
          _defaultDhikrTargets[dhikr]!; // Set default target for the new Dhikr
    });
    await _savePreferences(); // Save the new Dhikr and target
  }

  // Show dialog to set a custom target count
  Future<void> _showTargetDialog() async {
    // Ensure context is still valid before showing dialog
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _target.toString());
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.background,
            title: Text(
              localizations.tesbihSetTarget,
              style: AppTextStyles.sectionTitle,
            ),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTextStyles.prayerTime, // Consistent text style
              decoration: InputDecoration(
                labelText: localizations.tesbihTarget,
                labelStyle: AppTextStyles.label,
                hintText: localizations.tesbihEnterTarget,
                hintStyle: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary.withAlpha(153),
                ), // 0.6 * 255 = 153
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(localizations.cancel),
              ),
              TextButton(
                onPressed: () async {
                  final newVal = int.tryParse(controller.text);
                  // Store navigator before await
                  final navigator = Navigator.of(context);
                  bool shouldPop = true; // Assume we pop unless save fails

                  if (newVal != null && newVal > 0) {
                    // Check if mounted before calling setState
                    if (!mounted) return;
                    setState(() {
                      _target = newVal;
                    });
                    try {
                      await _savePreferences();
                    } catch (e, s) {
                      _logger.error(
                        "Error saving target preference",
                        data: {
                          'error': e.toString(),
                          'stackTrace': s.toString(),
                        },
                      );
                      shouldPop = false; // Don't pop if save failed
                      // Optionally show a snackbar or message to the user
                    }
                  }
                  // Check mounted again before using navigator
                  if (shouldPop && mounted) {
                    navigator.pop();
                  }
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: Text(localizations.tesbihOk),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(localizations.tasbihLabel, style: AppTextStyles.appTitle),
        backgroundColor: AppColors.primary,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch children horizontally
          children: [
            // Current Dhikr Display Area
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: AppColors.primaryLight, // Consistent background
              child: Column(
                children: [
                  Text(
                    _dhikrArabic[_currentDhikr] ?? '',
                    style: AppTextStyles.appTitle.copyWith(
                      fontSize: 40, // Slightly smaller for balance
                      height: 1.4,
                      color: AppColors.primary, // Use primary color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentDhikr,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 16, // Slightly larger label
                      color: AppColors.textPrimary.withAlpha(
                        204,
                      ), // 0.8 * 255 = 204
                    ),
                  ),
                ],
              ),
            ),

            // Counter Area
            GestureDetector(
              onTap: _incrementCount,
              child: Container(
                // Removed fixed height, let it size naturally or use AspectRatio
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                ), // Add padding
                color: AppColors.primaryLight, // Consistent background
                child: Center(
                  // Center the Stack
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 300, // Adjusted size
                        height: 300,
                        child: CircularProgressIndicator(
                          value:
                              _target > 0
                                  ? (_count / _target).clamp(0.0, 1.0)
                                  : 0,
                          strokeWidth: 8, // Thicker stroke
                          backgroundColor: AppColors.borderColor.withAlpha(
                            128,
                          ), // 0.5 * 255 = 128
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: 280, // Adjusted size
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor.withAlpha(
                                128,
                              ), // 0.5 * 255 = 128
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_count',
                                style: AppTextStyles.currentPrayer.copyWith(
                                  fontSize: 80, // Adjusted size
                                  fontWeight:
                                      FontWeight.w600, // Slightly less bold
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizations.tesbihCounter(_target),
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 15, // Adjusted size
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons (Reset, Target)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight, // Consistent background
                // Add a subtle top border if needed
                // border: Border(top: BorderSide(color: AppColors.borderColor, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.refresh_rounded,
                    localizations.tesbihReset,
                    _resetCount,
                  ),
                  _buildActionButton(
                    Icons.track_changes_rounded,
                    localizations.tesbihTarget,
                    _showTargetDialog,
                  ), // Changed icon
                ],
              ),
            ),

            // Dhikr Selection Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround, // Better spacing
                    children: [
                      Expanded(
                        child: _buildDhikrButton('Subhanallah'),
                      ), // Use Expanded
                      const SizedBox(width: 12),
                      Expanded(child: _buildDhikrButton('Alhamdulillah')),
                    ],
                  ),
                  const SizedBox(height: 12), // Spacing between rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildDhikrButton('Astaghfirullah')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDhikrButton('Allahu Akbar')),
                    ],
                  ),
                ],
              ),
            ),

            // Settings Toggles Area
            Container(
              margin: const EdgeInsets.all(
                16,
              ), // Margin around the settings box
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ), // Adjusted padding
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10), // Rounded corners
                border: Border.all(
                  color: AppColors.borderColor,
                ), // Subtle border
                // boxShadow: [ // Optional subtle shadow
                //   BoxShadow(
                //     color: AppColors.shadowColor,
                //     blurRadius: 4,
                //     offset: const Offset(0, 1),
                //   ),
                // ],
              ),
              child: Column(
                children: [
                  _buildToggleOption(
                    localizations.tesbihVibration,
                    Icons.vibration_rounded,
                    _vibrationEnabled,
                    (value) {
                      // Check if mounted before calling setState
                      if (!mounted) return;
                      setState(() => _vibrationEnabled = value);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.borderColor, height: 1), // Divider
                  _buildToggleOption(
                    localizations.tesbihSound,
                    Icons.volume_up_rounded,
                    _soundEnabled,
                    (value) {
                      // Check if mounted before calling setState
                      if (!mounted) return;
                      setState(() => _soundEnabled = value);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.borderColor, height: 1), // Divider
                  _buildToggleOption(
                    localizations.notifications,
                    Icons.notifications_active_rounded,
                    _reminderEnabled,
                    (value) async {
                      if (_settingsProvider.areNotificationsBlocked) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Notifications are blocked. Enable them in system settings.",
                              style: AppTextStyles.snackBarText,
                            ),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        return;
                      }
                      if (!mounted) return;
                      setState(() => _reminderEnabled = value);
                      await _saveReminderSettings();
                      _scheduleReminder();
                      if (value && mounted) {
                        _showReminderSettingsDialog();
                      }
                    },
                    // Add trailing text to show current time if enabled
                    trailing:
                        _reminderEnabled && _reminderTime != null
                            ? Text(
                              _reminderTime!.format(context),
                              style: AppTextStyles.label,
                            )
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  // Builder for Dhikr selection buttons
  Widget _buildDhikrButton(String dhikr) {
    final bool isSelected = _currentDhikr == dhikr;
    return ElevatedButton(
      onPressed: () => _setDhikr(dhikr),
      style: ElevatedButton.styleFrom(
        foregroundColor:
            isSelected ? AppColors.background : AppColors.primary, // Text color
        backgroundColor:
            isSelected
                ? AppColors.primary
                : AppColors.primaryLight, // Background color
        padding: const EdgeInsets.symmetric(vertical: 14), // Adjusted padding
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Less rounded
        ),
        elevation: 0, // No elevation
        textStyle: AppTextStyles.prayerName.copyWith(
          fontWeight: FontWeight.w600,
        ), // Consistent text style
      ),
      child: Text(dhikr),
    );
  }

  // Builder for action buttons (Reset, Target)
  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      // Use InkWell for ripple effect
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: AppColors.iconInactive,
              size: 26,
            ), // Adjusted size
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 13,
              ), // Adjusted size
            ),
          ],
        ),
      ),
    );
  }

  // Builder for toggle options (Vibration, Sound, Notifications)
  Widget _buildToggleOption(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    Widget? trailing, // Optional trailing widget (for reminder time)
  }) {
    bool isNotificationToggle =
        title == AppLocalizations.of(context)!.notifications;
    bool isDisabled =
        isNotificationToggle && _settingsProvider.areNotificationsBlocked;

    return InkWell(
      onTap: isDisabled ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
        ), // Consistent padding
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.iconInactive,
              size: 22,
            ), // Adjusted size
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.prayerName.copyWith(fontSize: 15),
              ),
            ), // Adjusted size
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            Switch(
              value:
                  isNotificationToggle
                      ? (value && !_settingsProvider.areNotificationsBlocked)
                      : value,
              onChanged: isDisabled ? null : onChanged,
              activeColor: AppColors.primary,
              activeTrackColor:
                  isDisabled
                      ? AppColors.switchTrackActive.withAlpha(77)
                      : AppColors.switchTrackActive,
              inactiveTrackColor:
                  isDisabled
                      ? AppColors.borderColor.withAlpha(77)
                      : AppColors.borderColor,
              inactiveThumbColor:
                  isDisabled
                      ? AppColors.textSecondary.withAlpha(77)
                      : AppColors.iconInactive.withAlpha(178),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
