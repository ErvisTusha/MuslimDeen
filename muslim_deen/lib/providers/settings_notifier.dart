import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/logger_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  static const String _settingsKey = 'app_settings';
  final StorageService _storage;
  final NotificationService _notificationService;
  final LoggerService _logger;
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;

  SettingsNotifier(
    this._storage,
    this._notificationService,
    this._logger,
  ) : super(AppSettings.defaults) {
    loadSettings();
    _initializePermissionListener();
  }

  bool get areNotificationsBlocked => _notificationService.isBlocked;

  void _initializePermissionListener() {
    _permissionSubscription = _notificationService.permissionStatusStream
        .listen((status) {
          _updateNotificationPermissionStatus(status);
        });
  }

  Future<void> loadSettings() async {
    try {
      final String? storedSettings = _storage.getData(_settingsKey) as String?;
      if (storedSettings != null) {
        state = AppSettings.fromJson(jsonDecode(storedSettings));
      }
    } catch (e) {
      _logger.error('Error loading settings', error: e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.saveData(_settingsKey, jsonEncode(state.toJson()));
    } catch (e) {
      _logger.error('Error saving settings', error: e);
    }
  }

  Future<void> updateCalculationMethod(String method) async {
    state = state.copyWith(calculationMethod: method);
    await _saveSettings();
  }

  Future<void> updateMadhab(String madhab) async {
    state = state.copyWith(madhab: madhab);
    await _saveSettings();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> updateTimeFormat(TimeFormat format) async {
    state = state.copyWith(timeFormat: format);
    await _saveSettings();
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    state = state.copyWith(dateFormatOption: option);
    await _saveSettings();
  }

  Future<void> setPrayerNotification(
    PrayerNotification prayer,
    bool enabled,
  ) async {
    if (enabled && _notificationService.isBlocked) {
      // Don't update if notifications are blocked and trying to enable
      return;
    }

    final updatedNotifications = Map<PrayerNotification, bool>.from(
      state.notifications,
    );
    updatedNotifications[prayer] = enabled;
    state = state.copyWith(notifications: updatedNotifications);
    await _saveSettings();
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (state.notificationPermissionStatus != status) {
      state = state.copyWith(notificationPermissionStatus: status);
      await _saveSettings();
    }
  }

  Future<void> checkNotificationPermissionStatus() async {
    await _notificationService.checkPermissionStatus();
  }

  @override
  void dispose() {
    _permissionSubscription?.cancel();
    super.dispose();
  }
}
