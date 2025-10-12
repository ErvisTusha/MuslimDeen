import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:muslim_deen/models/prayer_times_model.dart';

/// A cached prayer times entry with metadata for efficient caching
class CachedPrayerTimes {
  final PrayerTimesModel prayerTimes;
  final adhan.Coordinates coordinates;
  final String calculationMethod;
  final String madhab;
  final DateTime cachedAt;
  final DateTime expiresAt;

  const CachedPrayerTimes({
    required this.prayerTimes,
    required this.coordinates,
    required this.calculationMethod,
    required this.madhab,
    required this.cachedAt,
    required this.expiresAt,
  });

  /// Check if this cache entry is still valid
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Check if this cache entry matches the given parameters
  bool matchesParameters(
    adhan.Coordinates coordinates,
    String calculationMethod,
    String madhab,
  ) {
    const positionTolerance = 0.001; // About 100m
    
    return (coordinates.latitude - this.coordinates.latitude).abs() < positionTolerance &&
           (coordinates.longitude - this.coordinates.longitude).abs() < positionTolerance &&
           this.calculationMethod == calculationMethod &&
           this.madhab == madhab;
  }

  /// Create a CachedPrayerTimes from an Adhan PrayerTimes object
  factory CachedPrayerTimes.fromAdhanPrayerTimes(
    adhan.PrayerTimes adhanPrayerTimes,
    adhan.Coordinates coordinates,
    String calculationMethod,
    String madhab,
    DateTime cachedAt,
    Duration cacheDuration,
  ) {
    return CachedPrayerTimes(
      prayerTimes: PrayerTimesModel.fromAdhanPrayerTimes(
        adhanPrayerTimes,
        DateTime.now(),
      ),
      coordinates: coordinates,
      calculationMethod: calculationMethod,
      madhab: madhab,
      cachedAt: cachedAt,
      expiresAt: cachedAt.add(cacheDuration),
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'prayerTimes': prayerTimes.toJson(),
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'calculationMethod': calculationMethod,
      'madhab': madhab,
      'cachedAt': cachedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  /// Create from JSON
  factory CachedPrayerTimes.fromJson(Map<String, dynamic> json) {
    return CachedPrayerTimes(
      prayerTimes: PrayerTimesModel.fromJson(json['prayerTimes'] as Map<String, dynamic>),
      coordinates: adhan.Coordinates(
        (json['coordinates']['latitude'] as num).toDouble(),
        (json['coordinates']['longitude'] as num).toDouble(),
      ),
      calculationMethod: json['calculationMethod'] as String,
      madhab: json['madhab'] as String,
      cachedAt: DateTime.fromMillisecondsSinceEpoch(json['cachedAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
    );
  }
}