import 'dart:async';

import 'package:muslim_deen/models/app_settings.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/cache_service.dart';

/// Service for caching notification schedules and preferences
/// Delegated to CacheService for core storage and expiration logic
class NotificationCacheService {
  final CacheService _cacheService;
  final LoggerService _logger = locator<LoggerService>();

  NotificationCacheService({CacheService? cacheService})
    : _cacheService = cacheService ?? locator<CacheService>();

  // Cache keys
  static const String _notificationSchedulePrefix = 'notif_schedule_';
  static const String _notificationPreferencesKey = 'notif_preferences';
  static const String _notificationHistoryPrefix = 'notif_history_';
  static const String _notificationStatsKey = 'notif_stats';

  // Cache settings
  static const Duration _defaultCacheDuration = Duration(days: 30);

  /// Cache notification schedule
  Future<bool> cacheNotificationSchedule(
    String scheduleId,
    Map<String, dynamic> schedule,
  ) async {
    final key = '$_notificationSchedulePrefix$scheduleId';
    return _cacheService.setCache(
      key,
      schedule,
      expirationMinutes: _defaultCacheDuration.inMinutes,
    );
  }

  /// Get cached notification schedule
  Map<String, dynamic>? getCachedNotificationSchedule(String scheduleId) {
    final key = '$_notificationSchedulePrefix$scheduleId';
    return _cacheService.getCache<Map<String, dynamic>>(key);
  }

  /// Cache notification preferences
  Future<bool> cacheNotificationPreferences(AppSettings settings) async {
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

    return _cacheService.setCache(
      _notificationPreferencesKey,
      preferences,
      expirationMinutes: _defaultCacheDuration.inMinutes,
    );
  }

  /// Get cached notification preferences
  Map<String, dynamic>? getCachedNotificationPreferences() {
    return _cacheService.getCache<Map<String, dynamic>>(
      _notificationPreferencesKey,
    );
  }

  /// Cache notification history
  Future<bool> cacheNotificationHistory(
    String notificationId,
    Map<String, dynamic> historyEntry,
  ) async {
    final key = '$_notificationHistoryPrefix$notificationId';
    final success = await _cacheService.setCache(
      key,
      historyEntry,
      expirationMinutes: _defaultCacheDuration.inMinutes,
    );
    if (success) {
      await _maintainHistorySizeLimit();
    }
    return success;
  }

  /// Get cached notification history
  List<Map<String, dynamic>> getCachedNotificationHistory() {
    try {
      final historyKeys = _cacheService.getKeysByPrefix(
        _notificationHistoryPrefix,
      );
      final history = <Map<String, dynamic>>[];

      for (final key in historyKeys) {
        final entry = _cacheService.getCache<Map<String, dynamic>>(key);
        if (entry != null) {
          history.add(entry);
        }
      }

      // Sort by timestamp if available (assuming historyEntry has 'timestamp')
      history.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return history;
    } catch (e, s) {
      _logger.error(
        'Error getting notification history',
        error: e,
        stackTrace: s,
      );
      return [];
    }
  }

  /// Maintain history size limit
  Future<void> _maintainHistorySizeLimit() async {
    try {
      final historyKeys = _cacheService.getKeysByPrefix(
        _notificationHistoryPrefix,
      );
      if (historyKeys.length <= 50)
        return; // Use hardcoded 50 as reasonable limit

      // Sort keys to remove oldest (this assumes keys are not timestamped,
      // but entry has timestamp. If we want efficiency we should use entry timestamp)

      final history = <MapEntry<String, int>>[];
      for (final key in historyKeys) {
        final entry = _cacheService.getCache<Map<String, dynamic>>(key);
        history.add(MapEntry(key, entry?['timestamp'] as int? ?? 0));
      }

      history.sort((a, b) => a.value.compareTo(b.value));

      final keysToRemove = history.take(history.length - 50).map((e) => e.key);
      for (final key in keysToRemove) {
        await _cacheService.removeData(key);
      }

      _logger.debug(
        'Notification history clean up',
        data: {'removed': keysToRemove.length},
      );
    } catch (e, s) {
      _logger.error('Error maintaining history size', error: e, stackTrace: s);
    }
  }

  /// Cache notification statistics
  Future<bool> cacheNotificationStatistics(Map<String, dynamic> stats) async {
    return _cacheService.setCache(
      _notificationStatsKey,
      stats,
      expirationMinutes: _defaultCacheDuration.inMinutes,
    );
  }

  /// Get cached notification statistics
  Map<String, dynamic>? getCachedNotificationStatistics() {
    return _cacheService.getCache<Map<String, dynamic>>(_notificationStatsKey);
  }

  /// Invalidate specific cache entry
  Future<void> invalidateCacheEntry(String key) async {
    await _cacheService.removeData(key);
  }

  /// Clear all notification cache
  Future<void> clearAllNotificationCache() async {
    await _cacheService.clearByPrefix(_notificationSchedulePrefix);
    await _cacheService.clearByPrefix(_notificationHistoryPrefix);
    await _cacheService.removeData(_notificationPreferencesKey);
    await _cacheService.removeData(_notificationStatsKey);
    _logger.info('All notification cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return _cacheService.getCacheStats();
  }

  /// Dispose of resources
  void dispose() {
    _logger.info('NotificationCacheService disposed');
  }
}
