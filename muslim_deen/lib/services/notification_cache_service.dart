import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/cache_metrics_service.dart';

/// Service for caching notification schedules and preferences
class NotificationCacheService {
  final SharedPreferences _prefs;
  final LoggerService _logger = locator<LoggerService>();
  CacheMetricsService? _metricsService;

  // Cache keys
  static const String _notificationSchedulePrefix = 'notif_schedule_';
  static const String _notificationPreferencesKey = 'notif_preferences';
  static const String _notificationHistoryPrefix = 'notif_history_';
  static const String _notificationStatsKey = 'notif_stats';

  // Cache settings
  static const Duration _defaultCacheDuration = Duration(days: 30);
  static const int _maxHistoryEntries = 100;
  static const Duration _cleanupInterval = Duration(hours: 6);

  Timer? _cleanupTimer;
  final Map<String, DateTime> _cacheTimestamps = {};

  NotificationCacheService(this._prefs) {
    _startPeriodicCleanup();
  }

  /// Set metrics service for performance tracking
  void setMetricsService(CacheMetricsService metricsService) {
    _metricsService = metricsService;
    _logger.debug('Cache metrics service attached to NotificationCacheService');
  }

  /// Start periodic cleanup timer
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Perform cleanup of expired cache entries
  Future<void> _performCleanup() async {
    try {
      final now = DateTime.now();
      final keysToRemove = <String>[];

      for (final entry in _cacheTimestamps.entries) {
        if (now.difference(entry.value) > _defaultCacheDuration) {
          keysToRemove.add(entry.key);
        }
      }

      for (final key in keysToRemove) {
        await _prefs.remove(key);
        _cacheTimestamps.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        _logger.debug(
          'Cleaned up expired notification cache entries',
          data: {'count': keysToRemove.length},
        );
      }
    } catch (e, s) {
      _logger.error(
        'Error during notification cache cleanup',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Cache notification schedule
  Future<bool> cacheNotificationSchedule(
    String scheduleId,
    Map<String, dynamic> schedule,
  ) async {
    try {
      final key = '$_notificationSchedulePrefix$scheduleId';
      final scheduleJson = jsonEncode(schedule);

      await _prefs.setString(key, scheduleJson);
      _cacheTimestamps[key] = DateTime.now();

      _metricsService?.recordHit(key, 'notification_schedule');
      _logger.info(
        'Notification schedule cached',
        data: {'scheduleId': scheduleId},
      );
      return true;
    } catch (e, s) {
      _logger.error(
        'Error caching notification schedule',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Get cached notification schedule
  Map<String, dynamic>? getCachedNotificationSchedule(String scheduleId) {
    try {
      final key = '$_notificationSchedulePrefix$scheduleId';

      // Check if cache is still valid
      final timestamp = _cacheTimestamps[key];
      if (timestamp == null ||
          DateTime.now().difference(timestamp) > _defaultCacheDuration) {
        _prefs.remove(key);
        _cacheTimestamps.remove(key);
        _metricsService?.recordMiss(key, 'notification_schedule');
        return null;
      }

      final scheduleJson = _prefs.getString(key);
      if (scheduleJson == null) {
        _metricsService?.recordMiss(key, 'notification_schedule');
        return null;
      }

      final schedule = jsonDecode(scheduleJson) as Map<String, dynamic>;
      _cacheTimestamps[key] = DateTime.now(); // Update access time

      _metricsService?.recordHit(key, 'notification_schedule');
      _logger.debug(
        'Notification schedule retrieved from cache',
        data: {'scheduleId': scheduleId},
      );
      return schedule;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached notification schedule',
        error: e,
        stackTrace: s,
      );
      _metricsService?.recordMiss(
        '$_notificationSchedulePrefix$scheduleId',
        'notification_schedule',
      );
      return null;
    }
  }

  /// Cache notification preferences
  Future<bool> cacheNotificationPreferences(AppSettings settings) async {
    try {
      final preferences = {
        'notifications': settings.notifications.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'dhikrRemindersEnabled': settings.dhikrRemindersEnabled,
        'dhikrReminderInterval': settings.dhikrReminderInterval,
        'fajrOffset': settings.fajrOffset,
        'sunriseOffset': settings.sunriseOffset,
        'dhuhrOffset': settings.dhuhrOffset,
        'asrOffset': settings.asrOffset,
        'maghribOffset': settings.maghribOffset,
        'ishaOffset': settings.ishaOffset,
        'azanSoundForStandardPrayers': settings.azanSoundForStandardPrayers,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      final preferencesJson = jsonEncode(preferences);
      await _prefs.setString(_notificationPreferencesKey, preferencesJson);

      _metricsService?.recordHit(
        _notificationPreferencesKey,
        'notification_preferences',
      );
      _logger.info('Notification preferences cached');
      return true;
    } catch (e, s) {
      _logger.error(
        'Error caching notification preferences',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Get cached notification preferences
  Map<String, dynamic>? getCachedNotificationPreferences() {
    try {
      final preferencesJson = _prefs.getString(_notificationPreferencesKey);
      if (preferencesJson == null) {
        _metricsService?.recordMiss(
          _notificationPreferencesKey,
          'notification_preferences',
        );
        return null;
      }

      final preferences = jsonDecode(preferencesJson) as Map<String, dynamic>;

      _metricsService?.recordHit(
        _notificationPreferencesKey,
        'notification_preferences',
      );
      _logger.debug('Notification preferences retrieved from cache');
      return preferences;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached notification preferences',
        error: e,
        stackTrace: s,
      );
      _metricsService?.recordMiss(
        _notificationPreferencesKey,
        'notification_preferences',
      );
      return null;
    }
  }

  /// Cache notification history
  Future<bool> cacheNotificationHistory(
    String notificationId,
    Map<String, dynamic> historyEntry,
  ) async {
    try {
      final key = '$_notificationHistoryPrefix$notificationId';
      final historyJson = jsonEncode(historyEntry);

      await _prefs.setString(key, historyJson);
      _cacheTimestamps[key] = DateTime.now();

      // Maintain history size limit
      await _maintainHistorySizeLimit();

      _metricsService?.recordHit(key, 'notification_history');
      _logger.debug(
        'Notification history cached',
        data: {'notificationId': notificationId},
      );
      return true;
    } catch (e, s) {
      _logger.error(
        'Error caching notification history',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Get cached notification history
  List<Map<String, dynamic>> getCachedNotificationHistory() {
    try {
      final historyKeys =
          _prefs
              .getKeys()
              .where((key) => key.startsWith(_notificationHistoryPrefix))
              .toList();

      final history = <Map<String, dynamic>>[];
      final now = DateTime.now();

      for (final key in historyKeys) {
        // Check if entry is still valid
        final timestamp = _cacheTimestamps[key];
        if (timestamp == null ||
            now.difference(timestamp) > _defaultCacheDuration) {
          _prefs.remove(key);
          _cacheTimestamps.remove(key);
          continue;
        }

        final historyJson = _prefs.getString(key);
        if (historyJson != null) {
          final entry = jsonDecode(historyJson) as Map<String, dynamic>;
          history.add(entry);
        }
      }

      // Sort by timestamp (newest first)
      history.sort((a, b) {
        final timeA = DateTime.parse(a['timestamp'] as String);
        final timeB = DateTime.parse(b['timestamp'] as String);
        return timeB.compareTo(timeA);
      });

      _metricsService?.recordHit(
        _notificationHistoryPrefix,
        'notification_history',
      );
      _logger.debug(
        'Notification history retrieved from cache',
        data: {'entries': history.length},
      );
      return history;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached notification history',
        error: e,
        stackTrace: s,
      );
      _metricsService?.recordMiss(
        _notificationHistoryPrefix,
        'notification_history',
      );
      return [];
    }
  }

  /// Maintain history size limit
  Future<void> _maintainHistorySizeLimit() async {
    try {
      final historyKeys =
          _prefs
              .getKeys()
              .where((key) => key.startsWith(_notificationHistoryPrefix))
              .toList();

      if (historyKeys.length <= _maxHistoryEntries) return;

      // Sort keys by timestamp (oldest first)
      final sortedKeys = <String>[];
      for (final key in historyKeys) {
        final historyJson = _prefs.getString(key);
        if (historyJson != null) {
          sortedKeys.add(key);
        }
      }

      sortedKeys.sort((a, b) {
        final timestampA =
            _cacheTimestamps[a] ?? DateTime.fromMillisecondsSinceEpoch(0);
        final timestampB =
            _cacheTimestamps[b] ?? DateTime.fromMillisecondsSinceEpoch(0);
        return timestampA.compareTo(timestampB);
      });

      // Remove oldest entries
      final removeCount = sortedKeys.length - _maxHistoryEntries;
      for (int i = 0; i < removeCount; i++) {
        final key = sortedKeys[i];
        await _prefs.remove(key);
        _cacheTimestamps.remove(key);
      }

      if (removeCount > 0) {
        _logger.debug(
          'Removed old notification history entries',
          data: {'count': removeCount},
        );
      }
    } catch (e, s) {
      _logger.error(
        'Error maintaining history size limit',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Cache notification statistics
  Future<bool> cacheNotificationStatistics(Map<String, dynamic> stats) async {
    try {
      final statsJson = jsonEncode(stats);
      await _prefs.setString(_notificationStatsKey, statsJson);

      _metricsService?.recordHit(_notificationStatsKey, 'notification_stats');
      _logger.info('Notification statistics cached');
      return true;
    } catch (e, s) {
      _logger.error(
        'Error caching notification statistics',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Get cached notification statistics
  Map<String, dynamic>? getCachedNotificationStatistics() {
    try {
      final statsJson = _prefs.getString(_notificationStatsKey);
      if (statsJson == null) {
        _metricsService?.recordMiss(
          _notificationStatsKey,
          'notification_stats',
        );
        return null;
      }

      final stats = jsonDecode(statsJson) as Map<String, dynamic>;

      _metricsService?.recordHit(_notificationStatsKey, 'notification_stats');
      _logger.debug('Notification statistics retrieved from cache');
      return stats;
    } catch (e, s) {
      _logger.error(
        'Error retrieving cached notification statistics',
        error: e,
        stackTrace: s,
      );
      _metricsService?.recordMiss(_notificationStatsKey, 'notification_stats');
      return null;
    }
  }

  /// Invalidate specific cache entry
  Future<void> invalidateCacheEntry(String key) async {
    try {
      await _prefs.remove(key);
      _cacheTimestamps.remove(key);
      _logger.debug('Cache entry invalidated', data: {'key': key});
    } catch (e, s) {
      _logger.error('Error invalidating cache entry', error: e, stackTrace: s);
    }
  }

  /// Clear all notification cache
  Future<void> clearAllNotificationCache() async {
    try {
      final keys =
          _prefs
              .getKeys()
              .where(
                (key) =>
                    key.startsWith(_notificationSchedulePrefix) ||
                    key.startsWith(_notificationHistoryPrefix) ||
                    key == _notificationPreferencesKey ||
                    key == _notificationStatsKey,
              )
              .toList();

      for (final key in keys) {
        await _prefs.remove(key);
        _cacheTimestamps.remove(key);
      }

      _metricsService?.recordCacheSize(0);
      _logger.info(
        'All notification cache cleared',
        data: {'entries': keys.length},
      );
    } catch (e, s) {
      _logger.error(
        'Error clearing notification cache',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final scheduleKeys =
        _prefs
            .getKeys()
            .where((key) => key.startsWith(_notificationSchedulePrefix))
            .length;
    final historyKeys =
        _prefs
            .getKeys()
            .where((key) => key.startsWith(_notificationHistoryPrefix))
            .length;
    final hasPreferences = _prefs.containsKey(_notificationPreferencesKey);
    final hasStats = _prefs.containsKey(_notificationStatsKey);

    return {
      'scheduleEntries': scheduleKeys,
      'historyEntries': historyKeys,
      'hasPreferences': hasPreferences,
      'hasStats': hasStats,
      'totalEntries': _cacheTimestamps.length,
      'cacheSize': _cacheTimestamps.length,
    };
  }

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    _logger.info('NotificationCacheService disposed');
  }
}
