import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audioplayers/audioplayers.dart';

import '../providers/providers.dart';
import '../providers/tesbih_reminder_provider.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';
import '../services/notification_service.dart' show NotificationService;
import '../services/storage_service.dart';
import '../styles/app_styles.dart';

class TesbihView extends ConsumerStatefulWidget {
  const TesbihView({super.key});

  @override
  ConsumerState<TesbihView> createState() => _TesbihViewState();
}

class _TesbihViewState extends ConsumerState<TesbihView>
    with WidgetsBindingObserver {
  int _count = 0;
  String _currentDhikr = 'Subhanallah';
  bool _vibrationEnabled = true;
  bool _soundEnabled = false;
  int _target = 33;

  Timer? _permissionCheckTimer;
  late final NotificationService _notificationService =
      GetIt.I<NotificationService>();
  late final StorageService _storageService = GetIt.I<StorageService>();
  final LoggerService _logger = locator<LoggerService>();

  static final Map<String, String> _dhikrArabic = {
    'Subhanallah': 'سُبْحَانَ اللهِ',
    'Alhamdulillah': 'الْحَمْدُ لِلَّهِ',
    'Astaghfirullah': 'أَسْتَغْفِرُ اللهَ',
    'Allahu Akbar': 'اللهُ أَكْبَر',
  };

  static final Map<String, int> _defaultDhikrTargets = {
    'Subhanallah': 33,
    'Alhamdulillah': 33,
    'Astaghfirullah': 33,
    'Allahu Akbar': 34, // Often 34 after prayer
  };

  final List<String> _dhikrOrder = [
    'Subhanallah',
    'Alhamdulillah',
    'Astaghfirullah',
    'Allahu Akbar',
  ];

  static final Map<String, String> _dhikrAudioFiles = {
    'Subhanallah': 'audio/SubhanAllah.mp3',
    'Alhamdulillah': 'audio/Alhamdulillah.mp3',
    'Astaghfirullah': 'audio/Astaghfirullah.mp3',
    'Allahu Akbar': 'audio/AllahuAkbar.mp3',
  };

  AudioPlayer? _dhikrPlayer;
  AudioPlayer? _counterPlayer;

  bool _isAudioPlaying = false;
  bool _isResetting = false;
  bool _isInDhikrTransition = false;
  int _dhikrTransitionDelay = 1500;

  bool _preferencesChanged = false;
  bool? _notificationsBlocked;
  bool _isCustomTarget = false;
  final Map<String, int> _customDhikrTargets = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _logger.info('TesbihView initialized');
    _loadPreferences();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveDataIfNeeded();
    } else if (state == AppLifecycleState.resumed &&
        ref.read(tesbihReminderProvider).reminderEnabled) {
      ref.read(settingsProvider.notifier).checkNotificationPermissionStatus();
      _notificationsBlocked =
          ref.read(settingsProvider.notifier).areNotificationsBlocked;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logger.debug('TesbihView dependencies changed');
    _loadReminderSettings();
  }

  @override
  void dispose() {
    _logger.debug('TesbihView disposed');
    WidgetsBinding.instance.removeObserver(this);
    _permissionCheckTimer?.cancel();

    if (mounted && ref.read(tesbihReminderProvider).reminderEnabled) {
      _notificationService.cancelNotification(9876);
    }

    _dhikrPlayer?.dispose();
    _counterPlayer?.dispose();
    super.dispose();
  }

  Future<void> _saveDataIfNeeded() async {
    final futures = <Future<void>>[];

    if (_preferencesChanged) {
      futures.add(
        _savePreferences().catchError((Object e, StackTrace? s) {
          _logger.error(
            "Error saving preferences on app pause",
            error: e,
            stackTrace: s,
          );
          if (mounted) {
            _showErrorSnackBar(
              "Failed to save some preferences. Please try again.",
            );
          }
        }),
      );
      _preferencesChanged = false;
    }

    if (futures.isNotEmpty) {
      await Future.wait<void>(futures);
    }
  }

  Future<void> _checkAndUpdateNotificationStatus() async {
    if (!mounted) return;

    try {
      await ref
          .read(settingsProvider.notifier)
          .checkNotificationPermissionStatus();
      if (mounted) {
        _notificationsBlocked =
            ref.read(settingsProvider.notifier).areNotificationsBlocked;
      }
    } catch (e) {
      _logger.warning('Error checking notification status: $e');
    }
  }

  Future<void> _loadReminderSettings() async {
    try {
      final reminderHour =
          _storageService.getData('tesbih_reminder_hour') as int?;
      final reminderMinute =
          _storageService.getData('tesbih_reminder_minute') as int?;
      final enabled =
          _storageService.getData('tesbih_reminder_enabled') as bool?;

      if (reminderHour != null && reminderMinute != null) {
        if (!mounted) return;
        setState(() {
          ref
              .read(tesbihReminderProvider.notifier)
              .setReminderTime(
                TimeOfDay(hour: reminderHour, minute: reminderMinute),
              );
          ref
              .read(tesbihReminderProvider.notifier)
              .toggleReminder(enabled ?? false);
        });

        if (ref.read(tesbihReminderProvider).reminderEnabled && mounted) {
          _scheduleReminder();
        }
      }
    } catch (e, s) {
      _logger.error('Error loading reminder settings', error: e, stackTrace: s);
    }
  }

  Future<void> _scheduleReminder() async {
    try {
      if (!ref.read(tesbihReminderProvider).reminderEnabled) {
        await _notificationService.cancelNotification(9876);
        _logger.info('Tesbih reminder cancelled');
        return;
      }

      if (ref.read(tesbihReminderProvider).reminderTime == null) {
        _logger.warning('Cannot schedule Tesbih reminder: Time not set');
        return;
      }

      final now = DateTime.now();
      var scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        ref.read(tesbihReminderProvider).reminderTime!.hour,
        ref.read(tesbihReminderProvider).reminderTime!.minute,
      );

      if (scheduledDateTime.isBefore(now)) {
        scheduledDateTime = scheduledDateTime.add(const Duration(days: 1));
      }

      if (!mounted) return;

      _logger.info(
        'Scheduling Tesbih reminder for ${scheduledDateTime.toIso8601String()}, enabled: ${ref.read(tesbihReminderProvider).reminderEnabled}',
      );

      // Remove notification title - only use body text
      final notificationBody =
          "🤲 Time for your dhikr. Remember Allah with a peaceful heart.";

      await _notificationService.schedulePrayerNotification(
        id: 9876,
        localizedTitle: "", // Empty string for no title
        localizedBody: notificationBody,
        prayerTime: scheduledDateTime,
        isEnabled: ref.read(tesbihReminderProvider).reminderEnabled,
      );

      _logger.info('Reminder scheduled successfully');
    } catch (e, s) {
      _logger.error('Failed to schedule reminder', error: e, stackTrace: s);
      if (mounted) {
        ref.read(tesbihReminderProvider.notifier).toggleReminder(false);
        await _saveReminderSettings();

        _showErrorSnackBar(
          'Failed to schedule reminder. Notifications have been disabled.',
        );
      }
    }
  }

  Future<void> _showReminderSettingsDialog() async {
    _logger.logInteraction('TesbihView', 'Open reminder settings dialog');

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime:
          ref.read(tesbihReminderProvider).reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                Theme.of(context).brightness == Brightness.dark
                    ? ColorScheme.dark(
                      primary: AppColors.accentGreen(
                        Theme.of(context).brightness,
                      ),
                      onPrimary: Colors.white,
                      surface: AppColors.surface(
                        Theme.of(context).brightness,
                      ), // Dark surface for dialog
                      onSurface: AppColors.textPrimary(
                        Theme.of(context).brightness,
                      ),
                    )
                    : ColorScheme.light(
                      primary: AppColors.primary(Theme.of(context).brightness),
                      onPrimary: AppColors.background(
                        Theme.of(context).brightness,
                      ),
                      surface: AppColors.background(
                        Theme.of(context).brightness,
                      ),
                      onSurface: AppColors.textPrimary(
                        Theme.of(context).brightness,
                      ),
                    ),
            dialogTheme: DialogTheme(
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.surface(
                        Theme.of(context).brightness,
                      ) // Dark surface for dialog
                      : AppColors.background(Theme.of(context).brightness),
            ),
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

      ref.read(tesbihReminderProvider.notifier).setReminderTime(pickedTime);
    }
  }

  Future<void> _saveReminderSettings() async {
    final Map<String, dynamic> dataToSave = {};

    if (ref.read(tesbihReminderProvider).reminderTime != null) {
      dataToSave['tesbih_reminder_hour'] =
          ref.read(tesbihReminderProvider).reminderTime!.hour;
      dataToSave['tesbih_reminder_minute'] =
          ref.read(tesbihReminderProvider).reminderTime!.minute;
    }
    dataToSave['tesbih_reminder_enabled'] =
        ref.read(tesbihReminderProvider).reminderEnabled;

    try {
      await Future.wait(
        dataToSave.entries.map(
          (entry) => _storageService.saveData(entry.key, entry.value),
        ),
      );
    } catch (e, s) {
      _logger.error('Error saving reminder settings', error: e, stackTrace: s);
    }
  }

  Future<void> _loadPreferences() async {
    try {
      String? storedDhikr = _storageService.getData('current_dhikr') as String?;
      int? storedTarget = _storageService.getData('tasbih_target') as int?;
      final bool? storedVibration =
          _storageService.getData('vibration_enabled') as bool?;
      final bool? storedSound =
          _storageService.getData('sound_enabled') as bool?;
      final int? storedCount =
          _storageService.getData('${storedDhikr ?? _currentDhikr}_count')
              as int?;

      final bool? isCustom =
          _storageService.getData('is_custom_target') as bool?;
      final String? customTargetsJson =
          _storageService.getData('custom_dhikr_targets') as String?;

      if (customTargetsJson != null) {
        try {
          final Map<String, dynamic> decoded =
              json.decode(customTargetsJson) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            if (value is int && value > 0) {
              _customDhikrTargets[key] = value;
            }
          });
        } catch (e) {
          _logger.warning('Failed to parse custom targets: $e');
        }
      }

      if (storedDhikr == null || !_dhikrOrder.contains(storedDhikr)) {
        storedDhikr = _currentDhikr;
        _logger.warning(
          'Invalid stored dhikr: $storedDhikr, using default: $_currentDhikr',
        );
      }

      if (storedTarget == null || storedTarget <= 0) {
        storedTarget = _defaultDhikrTargets[storedDhikr]!;
        _logger.warning(
          'Invalid stored target: $storedTarget, using default: $storedTarget',
        );
      }

      final transitionDelay =
          _storageService.getData('dhikr_transition_delay') as int?;

      if (!mounted) return;

      setState(() {
        _currentDhikr = storedDhikr!;
        _vibrationEnabled = storedVibration ?? true;
        _soundEnabled = storedSound ?? false;
        _isCustomTarget = isCustom ?? false;

        if (_isCustomTarget && _customDhikrTargets.containsKey(_currentDhikr)) {
          _target = _customDhikrTargets[_currentDhikr]!;
        } else {
          _target =
              (storedTarget != null && storedTarget > 0)
                  ? storedTarget
                  : _defaultDhikrTargets[_currentDhikr]!;
        }

        _count =
            (storedCount != null && storedCount >= 0 && storedCount <= _target)
                ? storedCount
                : 0;

        _dhikrTransitionDelay = transitionDelay ?? 1500;
      });

      if (_soundEnabled) {
        _initializeAudioPlayers();
      }

      _logger.info('Preferences loaded successfully');
    } catch (e, s) {
      _logger.error(
        "Error loading Tesbih preferences",
        error: e,
        stackTrace: s,
      );

      if (!mounted) return;
      setState(() {
        _target = _defaultDhikrTargets[_currentDhikr]!;
      });
    }
  }

  void _initializeAudioPlayers() {
    if (_soundEnabled) {
      _dhikrPlayer ??= AudioPlayer();
      _counterPlayer ??= AudioPlayer();
    }
  }

  Future<void> _savePreferences() async {
    try {
      final String customTargetsJson = json.encode(_customDhikrTargets);

      final Map<String, dynamic> dataToSave = {
        'vibration_enabled': _vibrationEnabled,
        'sound_enabled': _soundEnabled,
        'current_dhikr': _currentDhikr,
        'tasbih_target': _target,
        '${_currentDhikr}_count': _count,
        'is_custom_target': _isCustomTarget,
        'custom_dhikr_targets': customTargetsJson,
        'dhikr_transition_delay': _dhikrTransitionDelay,
      };

      await Future.wait(
        dataToSave.entries.map(
          (entry) => _storageService.saveData(entry.key, entry.value),
        ),
      );
      _logger.info('Preferences saved successfully');
      _preferencesChanged = false;
    } catch (e, s) {
      _logger.error('Error saving preferences', error: e, stackTrace: s);
      return Future.error(e, s);
    }
  }

  Future<void> _incrementCount() async {
    if (_count >= _target) return;

    if (!mounted) return;
    setState(() => _count++);

    if (_vibrationEnabled) {
      _triggerHapticFeedback();
    }

    if (_soundEnabled) {
      await _playCounterSound();
    }

    if (_count == _target) {
      await _handleTargetReached();
    }
  }

  Future<void> _handleTargetReached() async {
    if (!mounted) return;

    if (_vibrationEnabled) {
      try {
        for (int i = 0; i < 3; i++) {
          HapticFeedback.heavyImpact();
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        _logger.warning('Failed to trigger haptic feedback');
      }
    }

    if (mounted) {
      await _advanceDhikr();
    }
  }

  Future<void> _advanceDhikr() async {
    if (_isInDhikrTransition) return;
    _isInDhikrTransition = true;

    final currentIndex = _dhikrOrder.indexOf(_currentDhikr);
    final nextIndex = (currentIndex + 1) % _dhikrOrder.length;
    final nextDhikr = _dhikrOrder[nextIndex];

    if (_soundEnabled) {
      await _playDhikrSound(nextDhikr);

      if (!mounted) {
        _isInDhikrTransition = false;
        return;
      }

      setState(() {});

      await Future<void>.delayed(Duration(milliseconds: _dhikrTransitionDelay));
    }

    if (!mounted) {
      _isInDhikrTransition = false;
      return;
    }

    await _setDhikrInternal(nextDhikr);
    _isInDhikrTransition = false;
  }

  Future<void> _resetCount() async {
    if (_isResetting) return;
    _isResetting = true;

    if (!mounted) {
      _isResetting = false;
      return;
    }

    final previousCount = _count;

    setState(() {
      _count = 0;
    });

    if (_vibrationEnabled) {
      _triggerHapticFeedback();
    }

    try {
      await _savePreferences();
      _logger.info('Reset count saved successfully');
      _isResetting = false;
    } catch (e, s) {
      _logger.error('Error saving reset count', error: e, stackTrace: s);
      if (mounted && previousCount > 0) {
        setState(() {
          _count = previousCount;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to save reset. Your count has been restored.",
              style: AppTextStyles.snackBarText(Theme.of(context).brightness),
            ),
            backgroundColor: AppColors.error(Theme.of(context).brightness),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Reset Again',
              textColor: AppColors.background(Theme.of(context).brightness),
              onPressed: () {
                Future.delayed(const Duration(milliseconds: 500), () {
                  _isResetting = false;
                  _resetCount();
                });
              },
            ),
          ),
        );
      }
      _isResetting = false;
    }
  }

  void _triggerHapticFeedback() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      _logger.warning('Failed to trigger haptic feedback');
    }
  }

  Future<void> _playCounterSound() async {
    if (!_soundEnabled || _isAudioPlaying) return;

    _initializeAudioPlayers();

    try {
      _isAudioPlaying = true;
      await _counterPlayer?.stop();
      await _counterPlayer?.play(AssetSource('audio/tesbih.mp3'));

      final completeTimer = Timer(const Duration(seconds: 3), () {
        if (_isAudioPlaying) {
          _isAudioPlaying = false;
        }
      });

      _counterPlayer?.onPlayerComplete.first.then((_) {
        completeTimer.cancel();
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
          });
        } else {
          _isAudioPlaying = false;
        }
      });
    } catch (e, s) {
      _isAudioPlaying = false;
      _logger.error('Error playing tesbih sound', error: e, stackTrace: s);
    }
  }

  Future<void> _setDhikr(String dhikr) async {
    if (dhikr == _currentDhikr || _isInDhikrTransition) return;

    if (_soundEnabled && _isAudioPlaying) {
      await _stopAllAudio();
    }

    await _playDhikrSound(dhikr);
    await _setDhikrInternal(dhikr);
  }

  Future<void> _setDhikrInternal(String dhikr) async {
    if (!mounted) return;

    final bool dhikrChanged = dhikr != _currentDhikr;

    int newTarget;
    if (_isCustomTarget && _customDhikrTargets.containsKey(dhikr)) {
      newTarget = _customDhikrTargets[dhikr]!;
    } else {
      newTarget = _defaultDhikrTargets[dhikr]!;
    }

    setState(() {
      _currentDhikr = dhikr;
      _count = 0;
      _target = newTarget;
    });

    if (dhikrChanged) {
      try {
        await _savePreferences();
      } catch (e, s) {
        _logger.error('Error saving dhikr change', error: e, stackTrace: s);
        if (mounted) {
          _showErrorSnackBar('Failed to save dhikr change');
        }
      }
    }
  }

  Future<void> _stopAllAudio() async {
    try {
      await _dhikrPlayer?.stop();
      await _counterPlayer?.stop();
      _isAudioPlaying = false;
    } catch (e, s) {
      _logger.error('Error stopping audio', error: e, stackTrace: s);
    }
  }

  Future<void> _playDhikrSound(String dhikr) async {
    if (!_soundEnabled) return;

    if (_isAudioPlaying) {
      await _stopAllAudio();
    }

    _initializeAudioPlayers();

    try {
      final audioFile = _dhikrAudioFiles[dhikr];
      if (audioFile != null) {
        _isAudioPlaying = true;
        _logger.info('Playing dhikr sound: $audioFile');

        await _dhikrPlayer?.play(AssetSource(audioFile));

        final completeTimer = Timer(const Duration(seconds: 3), () {
          if (_isAudioPlaying) {
            _isAudioPlaying = false;
          }
        });

        _dhikrPlayer?.onPlayerComplete.first.then((_) {
          completeTimer.cancel();
          if (mounted) {
            setState(() {
              _isAudioPlaying = false;
            });
          } else {
            _isAudioPlaying = false;
          }
        });
      } else {
        _logger.warning('No audio file found for dhikr: $dhikr');
      }
    } catch (e, s) {
      _isAudioPlaying = false;
      _logger.error('Error playing dhikr sound', error: e, stackTrace: s);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppTextStyles.snackBarText(Theme.of(context).brightness),
        ),
        backgroundColor: AppColors.error(Theme.of(context).brightness),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showTargetDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) => _TargetDialog(
            initialTarget: _target,
            onTargetSet: _updateTargetValue,
            brightness: Theme.of(context).brightness,
          ),
    );
  }

  void _updateTargetValue(int newVal) {
    if (!mounted || newVal == _target) return;

    setState(() {
      _target = newVal;
      _isCustomTarget = true;
      _customDhikrTargets[_currentDhikr] = newVal;

      _count = _count > _target ? _target : _count;
    });

    _preferencesChanged = true;
    _savePreferences().catchError((Object e, StackTrace? s) {
      _logger.error("Error saving target preference", error: e, stackTrace: s);

      if (mounted) {
        _showErrorSnackBar("Failed to save target. Please try again.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    // Define colors for TesbihView in dark mode to make it lighter
    final Color tesbihScaffoldBg =
        isDarkMode
            ? AppColors.surface(brightness)
            : AppColors.background(brightness);
    // AppBar uses AppColors.primary(brightness) which is 0xFF1A1A1A in dark mode, this is fine.

    final Color tesbihContentSurface =
        isDarkMode
            ? const Color(0xFF2C2C2C)
            : AppColors.primaryVariant(brightness);
    final Color tesbihCounterCircleBg =
        isDarkMode ? const Color(0xFF3C3C3C) : AppColors.background(brightness);

    final Color tesbihDhikrArabicText =
        isDarkMode
            ? AppColors.textPrimary(brightness)
            : AppColors.primary(brightness);
    final Color tesbihCounterProgress =
        isDarkMode
            ? AppColors.accentGreen(brightness)
            : AppColors.primary(brightness);
    final Color tesbihCounterCountText =
        isDarkMode
            ? AppColors.accentGreen(brightness)
            : AppColors.primary(brightness);

    final Color tesbihToggleCardBg =
        isDarkMode ? tesbihContentSurface : AppColors.background(brightness);

    return Scaffold(
      backgroundColor: tesbihScaffoldBg,
      appBar: AppBar(
        title: Text("Tasbih", style: AppTextStyles.appTitle(brightness)),
        backgroundColor: AppColors.primary(
          brightness,
        ), // Stays 0xFF1A1A1A in dark mode
        elevation: 2,
        shadowColor: AppColors.shadowColor(brightness),
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Make status bar transparent
          statusBarIconBrightness:
              Brightness.light, // Keep icons light since AppBar is always dark
          statusBarBrightness: Brightness.dark, // This affects iOS status bar
          systemNavigationBarColor:
              tesbihScaffoldBg, // Match scaffold background
          systemNavigationBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: tesbihContentSurface, // Applied tesbihContentSurface
              child: Column(
                children: [
                  Text(
                    _dhikrArabic[_currentDhikr] ?? '',
                    style: AppTextStyles.appTitle(brightness).copyWith(
                      fontSize: 40,
                      height: 1.4,
                      color:
                          tesbihDhikrArabicText, // Applied tesbihDhikrArabicText
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentDhikr,
                    style: AppTextStyles.label(brightness).copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary(brightness).withAlpha(
                        isDarkMode ? 230 : 204,
                      ), // Slightly more opaque for better readability on new bg
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _incrementCount,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                color: tesbihContentSurface, // Applied tesbihContentSurface
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: CircularProgressIndicator(
                          value:
                              _target > 0
                                  ? (_count / _target).clamp(0.0, 1.0)
                                  : 0,
                          strokeWidth: 8,
                          backgroundColor: AppColors.borderColor(
                            brightness,
                          ).withAlpha(isDarkMode ? 80 : 128),
                          color:
                              tesbihCounterProgress, // Applied tesbihCounterProgress
                        ),
                      ),
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              tesbihCounterCircleBg, // Applied tesbihCounterCircleBg
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor(
                                brightness,
                              ).withAlpha(isDarkMode ? 60 : 128),
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
                                style: AppTextStyles.currentPrayer(
                                  brightness,
                                ).copyWith(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      tesbihCounterCountText, // Applied tesbihCounterCountText
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Target: $_target",
                                style: AppTextStyles.label(brightness).copyWith(
                                  fontSize: 15,
                                  color:
                                      isDarkMode
                                          ? AppColors.textSecondary(
                                            brightness,
                                          ).withAlpha(200)
                                          : AppColors.textSecondary(brightness),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: tesbihContentSurface,
              ), // Applied tesbihContentSurface
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    Icons.refresh_rounded,
                    "Reset",
                    _resetCount,
                    brightness,
                  ),
                  _buildActionButton(
                    Icons.track_changes_rounded,
                    "Set Target",
                    _showTargetDialog,
                    brightness,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildDhikrButton('Subhanallah', brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDhikrButton('Alhamdulillah', brightness),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildDhikrButton('Astaghfirullah', brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDhikrButton('Allahu Akbar', brightness),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: tesbihToggleCardBg, // Applied tesbihToggleCardBg
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderColor(brightness)),
              ),
              child: Column(
                children: [
                  _buildToggleOption(
                    "Vibration",
                    Icons.vibration_rounded,
                    _vibrationEnabled,
                    (value) {
                      if (!mounted) return;
                      setState(() => _vibrationEnabled = value);
                      _savePreferences().catchError((Object e, StackTrace? s) {
                        _logger.error(
                          "Error saving vibration preference",
                          error: e,
                          stackTrace: s,
                        );
                        if (mounted) {
                          _showErrorSnackBar(
                            "Failed to save vibration preference. Please try again.",
                          );
                        }
                      });
                    },
                    brightness,
                  ),
                  Divider(color: AppColors.borderColor(brightness), height: 1),
                  _buildToggleOption(
                    "Sound",
                    Icons.volume_up_rounded,
                    _soundEnabled,
                    (value) {
                      if (!mounted) return;

                      if (value && !_soundEnabled) {
                        _initializeAudioPlayers();
                      }

                      setState(() => _soundEnabled = value);
                      _savePreferences().catchError((Object e, StackTrace? s) {
                        _logger.error(
                          "Error saving sound preference",
                          error: e,
                          stackTrace: s,
                        );
                        if (mounted) {
                          _showErrorSnackBar(
                            "Failed to save sound preference. Please try again.",
                          );
                        }
                      });
                    },
                    brightness,
                  ),
                  Divider(color: AppColors.borderColor(brightness), height: 1),
                  _buildToggleOption(
                    "Notifications",
                    Icons.notifications_active_rounded,
                    ref.watch(tesbihReminderProvider).reminderEnabled,
                    (value) async {
                      // This onChanged handler is simplified since most logic is in the Switch
                      if (!value) {
                        // Only handle disabling notifications here
                        ref
                            .read(tesbihReminderProvider.notifier)
                            .toggleReminder(false);
                      } else {
                        // Enabling is handled by the Switch directly
                        // The time picker will be shown in the Switch's onChanged
                        ref
                            .read(tesbihReminderProvider.notifier)
                            .toggleReminder(true);
                      }
                    },
                    brightness,
                    trailing:
                        ref.watch(tesbihReminderProvider).reminderEnabled &&
                                ref
                                        .watch(tesbihReminderProvider)
                                        .reminderTime !=
                                    null
                            ? Text(
                              ref
                                  .watch(tesbihReminderProvider)
                                  .reminderTime!
                                  .format(context),
                              style: AppTextStyles.label(brightness),
                            )
                            : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDhikrButton(String dhikr, Brightness brightness) {
    final bool isSelected = _currentDhikr == dhikr;
    final bool isDarkMode = brightness == Brightness.dark;

    final Color selectedBgColor =
        isDarkMode
            ? AppColors.accentGreen(brightness)
            : AppColors.primary(brightness);
    final Color selectedFgColor =
        isDarkMode ? Colors.white : AppColors.background(brightness);

    final Color unselectedBgColor =
        isDarkMode
            ? const Color(0xFF2C2C2C)
            : AppColors.primaryVariant(brightness);
    final Color unselectedFgColor =
        isDarkMode
            ? AppColors.textPrimary(brightness)
            : AppColors.primary(brightness);

    return ElevatedButton(
      onPressed: () => _setDhikr(dhikr),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? selectedFgColor : unselectedFgColor,
        backgroundColor: isSelected ? selectedBgColor : unselectedBgColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: AppTextStyles.prayerName(
          brightness,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(dhikr),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
    Brightness brightness,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconInactive(brightness), size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.label(brightness).copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    IconData icon,
    bool value,
    void Function(bool) onChanged,
    Brightness brightness, {
    Widget? trailing,
  }) {
    final bool isNotificationToggle = title == "Notifications";

    final bool isDisabled =
        isNotificationToggle &&
        (_notificationsBlocked ??
            ref.read(settingsProvider.notifier).areNotificationsBlocked);

    return InkWell(
      onTap:
          isDisabled
              ? null
              : () {
                if (isNotificationToggle) {
                  // Special handling for notification toggle is within the Switch's onChanged
                  // Directly calling onChanged here might bypass permission checks/dialogs
                  // So, we let the Switch handle its own tap for notifications.
                  // For other toggles, we can proceed.
                  if (value) {
                    // If current value is true, new value will be false
                    onChanged(!value);
                  } else {
                    // If current value is false, new value will be true
                    // For non-notification toggles, just call onChanged
                    onChanged(!value);
                  }
                } else {
                  onChanged(!value);
                }
              },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconInactive(brightness), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.prayerName(
                  brightness,
                ).copyWith(fontSize: 15),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            Switch(
              value: isNotificationToggle ? (value && !isDisabled) : value,
              onChanged:
                  isDisabled
                      ? null
                      : (newValue) async {
                        if (isNotificationToggle) {
                          // Notifications toggle needs special handling
                          if (newValue) {
                            // Check permissions first when enabling notifications
                            await _checkAndUpdateNotificationStatus();
                            if (_notificationsBlocked == true) {
                              _showErrorSnackBar(
                                "Notifications are blocked. Enable them in system settings.",
                              );
                              // Do not call onChanged(newValue) here as we don't want to change the state
                              // if notifications are blocked. The switch should reflect the actual state.
                              // We might need to refresh the provider state if it was optimistically updated.
                              // For now, we assume the UI will reflect the actual provider state.
                              return;
                            }
                            // Always show time picker when enabling notifications
                            // The onChanged callback will be triggered by the dialog if time is set.
                            // For now, we call onChanged(true) to update the provider,
                            // and then show the dialog.
                            onChanged(newValue); // Update provider state
                            _showReminderSettingsDialog(); // Then show dialog
                          } else {
                            // Disabling notifications
                            onChanged(newValue);
                          }
                        } else {
                          // For other toggles (vibration, sound)
                          onChanged(
                            newValue,
                          ); // This will call setState and _savePreferences
                          // from the TesbihView's _buildToggleOption call.
                          // Error handling for _savePreferences is added there.
                        }
                      },
              activeColor: AppColors.primary(brightness),
              activeTrackColor:
                  isDisabled
                      ? AppColors.switchTrackActive(brightness).withAlpha(77)
                      : AppColors.switchTrackActive(brightness),
              inactiveTrackColor:
                  isDisabled
                      ? AppColors.borderColor(brightness).withAlpha(77)
                      : AppColors.borderColor(brightness),
              inactiveThumbColor:
                  isDisabled
                      ? AppColors.textSecondary(brightness).withAlpha(77)
                      : AppColors.iconInactive(brightness).withAlpha(178),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetDialog extends StatefulWidget {
  final int initialTarget;
  final void Function(int) onTargetSet;
  final Brightness brightness;

  const _TargetDialog({
    required this.initialTarget,
    required this.onTargetSet,
    required this.brightness,
  });

  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTarget.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateTargetInput(String input) {
    if (input.isEmpty) {
      return 'Target cannot be empty';
    }

    final value = int.tryParse(input);
    if (value == null) {
      return 'Please enter a valid number';
    }

    if (value <= 0) {
      return 'Target must be greater than 0';
    }

    if (value > 99999) {
      return 'Target is too large';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.brightness here as it's passed to _TargetDialog
    final brightness = widget.brightness;
    final bool isDarkMode = brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDarkMode
              ? AppColors.surface(brightness)
              : AppColors.background(brightness),
      title: Text("Set Target", style: AppTextStyles.sectionTitle(brightness)),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.prayerTime(brightness),
        decoration: InputDecoration(
          labelText: "Target",
          labelStyle: AppTextStyles.label(brightness),
          hintText: "Enter target",
          hintStyle: AppTextStyles.label(
            brightness,
          ).copyWith(color: AppColors.textSecondary(brightness).withAlpha(153)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderColor(brightness)),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary(brightness)),
            borderRadius: BorderRadius.circular(8),
          ),
          errorText: _errorText,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(5),
        ],
        autofocus: true,
        onChanged: (value) {
          setState(() {
            _errorText = _validateTargetInput(value);
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary(brightness),
          ),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            final newVal = int.tryParse(_controller.text);

            final errorMessage = _validateTargetInput(_controller.text);
            if (errorMessage != null) {
              setState(() {
                _errorText = errorMessage;
              });
              return;
            }

            Navigator.of(context).pop();

            widget.onTargetSet(newVal!);
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary(brightness),
          ),
          child: Text("OK"),
        ),
      ],
    );
  }
}
