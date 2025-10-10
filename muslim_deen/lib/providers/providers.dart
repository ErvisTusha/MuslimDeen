// Core providers for the application
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/settings_notifier.dart';

// Settings provider with notifier
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
