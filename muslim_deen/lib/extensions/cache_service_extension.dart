import 'package:muslim_deen/services/cache_service.dart';

/// Extension on CacheService to implement required methods
extension CacheServiceExtension on CacheService {
  Future<void> saveData(String key, dynamic value) async {
    await setCache(key, value);
  }

  dynamic getData(String key) {
    return getCache<dynamic>(key);
  }

  List<String> getAllKeys() {
    // Uses the new method in CacheService to get all base keys
    return getAllBaseKeys().toList();
  }

  Future<void> removeData(String key) async {
    await removeCache(key);
  }
}
