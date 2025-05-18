import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audioplayers/audioplayers.dart';

import '../l10n/app_localizations.dart';
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

    if (ref.read(tesbihReminderProvider).reminderEnabled) {
      _notificationService.cancelNotification(9876);
    }

    _dhikrPlayer?.dispose();
    _counterPlayer?.dispose();
    _saveDataIfNeeded();
    super.dispose();
  }

  Future<void> _saveDataIfNeeded() async {
    final futures = <Future>[];

    if (_preferencesChanged) {
      futures.add(_savePreferences());
      _preferencesChanged = false;
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
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
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.background,
              surface: AppColors.background,
              onSurface: AppColors.textPrimary,
            ),
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
      bool? storedVibration =
          _storageService.getData('vibration_enabled') as bool?;
      bool? storedSound = _storageService.getData('sound_enabled') as bool?;
      int? storedCount =
          _storageService.getData('${storedDhikr ?? _currentDhikr}_count')
              as int?;

      final isCustom = _storageService.getData('is_custom_target') as bool?;
      final customTargetsJson =
          _storageService.getData('custom_dhikr_targets') as String?;

      if (customTargetsJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(customTargetsJson);
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
          await Future.delayed(const Duration(milliseconds: 100));
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

      await Future.delayed(Duration(milliseconds: _dhikrTransitionDelay));
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
              style: AppTextStyles.snackBarText,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Reset Again',
              textColor: AppColors.background,
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
        content: Text(message, style: AppTextStyles.snackBarText),
        backgroundColor: AppColors.error,
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
    _savePreferences().catchError((e, s) {
      _logger.error("Error saving target preference", error: e, stackTrace: s);

      if (mounted) {
        _showErrorSnackBar("Failed to save target. Please try again.");
      }
    });
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              color: AppColors.primaryLight,
              child: Column(
                children: [
                  Text(
                    _dhikrArabic[_currentDhikr] ?? '',
                    style: AppTextStyles.appTitle.copyWith(
                      fontSize: 40,
                      height: 1.4,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentDhikr,
                    style: AppTextStyles.label.copyWith(
                      fontSize: 16,
                      color: AppColors.textPrimary.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _incrementCount,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                color: AppColors.primaryLight,
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
                          backgroundColor: AppColors.borderColor.withAlpha(128),
                          color: AppColors.primary,
                        ),
                      ),
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowColor.withAlpha(128),
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
                                  fontSize: 80,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                localizations.tesbihCounter(_target),
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 15,
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
              decoration: BoxDecoration(color: AppColors.primaryLight),
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
                      Expanded(child: _buildDhikrButton('Subhanallah')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDhikrButton('Alhamdulillah')),
                    ],
                  ),
                  const SizedBox(height: 12),
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
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  _buildToggleOption(
                    localizations.tesbihVibration,
                    Icons.vibration_rounded,
                    _vibrationEnabled,
                    (value) {
                      if (!mounted) return;
                      setState(() => _vibrationEnabled = value);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.borderColor, height: 1),
                  _buildToggleOption(
                    localizations.tesbihSound,
                    Icons.volume_up_rounded,
                    _soundEnabled,
                    (value) {
                      if (!mounted) return;

                      if (value && !_soundEnabled) {
                        _initializeAudioPlayers();
                      }

                      setState(() => _soundEnabled = value);
                      _savePreferences();
                    },
                  ),
                  Divider(color: AppColors.borderColor, height: 1),
                  _buildToggleOption(
                    localizations.notifications,
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
                              style: AppTextStyles.label,
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

  Widget _buildDhikrButton(String dhikr) {
    final bool isSelected = _currentDhikr == dhikr;
    return ElevatedButton(
      onPressed: () => _setDhikr(dhikr),
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? AppColors.background : AppColors.primary,
        backgroundColor:
            isSelected ? AppColors.primary : AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        textStyle: AppTextStyles.prayerName.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(dhikr),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.iconInactive, size: 26),
            const SizedBox(height: 6),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged, {
    Widget? trailing,
  }) {
    bool isNotificationToggle =
        title == AppLocalizations.of(context)!.notifications;

    bool isDisabled =
        isNotificationToggle &&
        (_notificationsBlocked ??
            ref.read(settingsProvider.notifier).areNotificationsBlocked);

    return InkWell(
      onTap: isDisabled ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconInactive, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.prayerName.copyWith(fontSize: 15),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            Switch(
              value: isNotificationToggle ? (value && !isDisabled) : value,
              onChanged:
                  isDisabled
                      ? null
                      : (newValue) async {
                        // Notifications toggle needs special handling
                        if (isNotificationToggle && newValue) {
                          // Check permissions first when enabling notifications
                          await _checkAndUpdateNotificationStatus();
                          if (_notificationsBlocked == true) {
                            _showErrorSnackBar(
                              "Notifications are blocked. Enable them in system settings.",
                            );
                            return;
                          }

                          // Always show time picker when enabling notifications
                          _showReminderSettingsDialog();
                        }

                        // Call the regular onChange for other toggles
                        onChanged(newValue);
                      },
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

class _TargetDialog extends StatefulWidget {
  final int initialTarget;
  final Function(int) onTargetSet;

  const _TargetDialog({required this.initialTarget, required this.onTargetSet});

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
    final localizations = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text(
        localizations.tesbihSetTarget,
        style: AppTextStyles.sectionTitle,
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: AppTextStyles.prayerTime,
        decoration: InputDecoration(
          labelText: localizations.tesbihTarget,
          labelStyle: AppTextStyles.label,
          hintText: localizations.tesbihEnterTarget,
          hintStyle: AppTextStyles.label.copyWith(
            color: AppColors.textSecondary.withAlpha(153),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
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
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: Text(localizations.cancel),
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
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: Text(localizations.tesbihOk),
        ),
      ],
    );
  }
}
