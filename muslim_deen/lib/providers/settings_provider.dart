import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../service_locator.dart';
import '../services/logger_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _settingsKey = 'app_settings';
  AppSettings _settings = AppSettings.defaults;
  final StorageService _storage = locator<StorageService>();
  final NotificationService _notificationService =
      locator<NotificationService>();
  StreamSubscription<NotificationPermissionStatus>? _permissionSubscription;

  AppSettings get settings => _settings;
  bool get areNotificationsBlocked => _notificationService.isBlocked;

  SettingsProvider() {
    loadSettings();
    _initializePermissionListener();
  }

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
        _settings = AppSettings.fromJson(jsonDecode(storedSettings));
        notifyListeners();
      }
    } catch (e) {
      locator<LoggerService>().error('Error loading settings', error: e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storage.saveData(_settingsKey, jsonEncode(_settings.toJson()));
    } catch (e) {
      locator<LoggerService>().error('Error saving settings', error: e);
    }
  }

  Future<void> updateCalculationMethod(String method) async {
    _settings = _settings.copyWith(calculationMethod: method);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateMadhab(String madhab) async {
    _settings = _settings.copyWith(madhab: madhab);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLanguage(String language) async {
    _settings = _settings.copyWith(language: language);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateTimeFormat(TimeFormat format) async {
    _settings = _settings.copyWith(timeFormat: format);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateDateFormatOption(DateFormatOption option) async {
    _settings = _settings.copyWith(dateFormatOption: option);
    await _saveSettings();
    notifyListeners();
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
      _settings.notifications,
    );
    updatedNotifications[prayer] = enabled;
    _settings = _settings.copyWith(notifications: updatedNotifications);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> _updateNotificationPermissionStatus(
    NotificationPermissionStatus status,
  ) async {
    if (_settings.notificationPermissionStatus != status) {
      _settings = _settings.copyWith(notificationPermissionStatus: status);
      await _saveSettings();
      notifyListeners();
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
