// Core providers for the application
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/providers/settings_notifier.dart';
import 'package:muslim_deen/service_locator.dart';
import '../services/fasting_service.dart';

// Settings provider with notifier
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// Fasting provider
final fastingServiceProvider = FutureProvider<FastingService>((ref) async {
  return await locator.getAsync<FastingService>();
});

final isRamadanProvider = FutureProvider<bool>((ref) async {
  final fastingService = await ref.watch(fastingServiceProvider.future);
  final ramadanInfo = fastingService.getRamadanCountdown();
  return ramadanInfo['isRamadan'] == true;
});
