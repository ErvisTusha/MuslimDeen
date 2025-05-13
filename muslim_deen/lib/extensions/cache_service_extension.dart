import 'package:muslim_deen/services/cache_service.dart';

/// Extension on CacheService to implement required methods
extension CacheServiceExtension on CacheService {
  Future<void> saveData(String key, dynamic value) async {
    await setCache(key, value);
  }

  dynamic getData(String key) {
    return getCache(key);
  }

  List<String> getAllKeys() {
    // Implementation would need access to SharedPreferences keys
    // This is a simplified version
    return [];
  }

  Future<void> removeData(String key) async {
    await removeCache(key);
  }
}
