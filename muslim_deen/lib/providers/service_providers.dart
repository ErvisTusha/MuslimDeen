// Service providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/database_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/services/prayer_service.dart';
import 'package:muslim_deen/services/storage_service.dart';
import 'package:muslim_deen/services/dhikr_reminder_service.dart';
import 'package:muslim_deen/services/audio_player_service.dart';

final loggerServiceProvider = Provider<LoggerService>(
  (ref) => locator<LoggerService>(),
);

final prayerServiceProvider = Provider<PrayerService>(
  (ref) => locator<PrayerService>(),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => locator<StorageService>(),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => locator<NotificationService>(),
);

final databaseServiceProvider = Provider<DatabaseService>(
  (ref) => locator<DatabaseService>(),
);

final dhikrReminderServiceProvider = Provider<DhikrReminderService>(
  (ref) => locator<DhikrReminderService>(),
);

final audioPlayerServiceProvider = Provider<AudioPlayerService>(
  (ref) => locator<AudioPlayerService>(),
);
