import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:muslim_deen/models/prayer_times_model.dart';

/// A cached prayer times entry with metadata for efficient caching
/// 
/// This model encapsulates prayer times data along with caching metadata
/// to support efficient storage and retrieval of prayer calculations.
/// It implements a complete caching strategy with validation, expiration,
/// and parameter matching to optimize performance while ensuring data accuracy.
/// 
/// Design principles:
/// - Immutable data structure for thread safety
/// - Comprehensive metadata for cache management
/// - Efficient parameter matching logic
/// - Support for cache invalidation strategies
/// 
/// Key responsibilities:
/// - Store prayer times with calculation parameters
/// - Validate cache entries against current requirements
/// - Manage cache expiration based on configurable durations
/// - Support serialization for persistent storage
/// 
/// Performance considerations:
/// - Lazy evaluation of cache validity
/// - Efficient coordinate comparison with tolerance
/// - Minimal object creation for cache operations
/// - Optimized serialization for storage efficiency
class CachedPrayerTimes {
  /// Core prayer times data for the cached entry
  /// Contains all prayer times, dates, and Hijri information
  /// This is the primary data payload of the cache entry
  final PrayerTimesModel prayerTimes;
  
  /// Geographic coordinates used for prayer time calculation
  /// Essential for cache validation - ensures cached times match
  /// the requested location within tolerance bounds
  final adhan.Coordinates coordinates;
  
  /// Prayer calculation method name
  /// Examples: 'MuslimWorldLeague', 'UmmAlQura', 'NorthAmerica'
  /// Must match exactly for cache hit validation
  final String calculationMethod;
  
  /// Islamic legal school (madhab) used for calculation
  /// Examples: 'hanafi', 'shafi', 'maliki', 'hanbali'
  /// Must match exactly for cache hit validation
  final String madhab;
  
  /// Timestamp when this cache entry was created
  /// Used for cache age calculation and expiration checks
  /// Set at creation time and never modified
  final DateTime cachedAt;
  
  /// Timestamp when this cache entry expires
  /// Calculated as cachedAt + cacheDuration
  /// After this time, the entry is considered invalid
  final DateTime expiresAt;

  /// Creates a new CachedPrayerTimes entry with complete metadata
  /// 
  /// Parameters:
  /// - [prayerTimes]: The prayer times data to cache
  /// - [coordinates]: Location coordinates used for calculation
  /// - [calculationMethod]: Prayer calculation method name
  /// - [madhab]: Islamic legal school used
  /// - [cachedAt]: Timestamp when entry was created
  /// - [expiresAt]: Timestamp when entry expires
  /// 
  /// Notes:
  /// - All parameters are required for complete cache metadata
  /// - cachedAt should typically be DateTime.now()
  /// - expiresAt should be calculated based on cache policy
  const CachedPrayerTimes({
    required this.prayerTimes,
    required this.coordinates,
    required this.calculationMethod,
    required this.madhab,
    required this.cachedAt,
    required this.expiresAt,
  });

  // ==================== CACHE VALIDATION METHODS ====================

  /// Checks if this cache entry is still valid based on expiration time
  /// 
  /// This getter provides a convenient way to check cache validity
  /// without exposing the internal expiration logic.
  /// 
  /// Returns: true if current time is before expiresAt, false otherwise
  /// 
  /// Performance considerations:
  /// - Simple DateTime comparison (O(1) operation)
  /// - No additional calculations or object creation
  /// - Safe to call frequently in cache lookup operations
  bool get isValid => DateTime.now().isBefore(expiresAt);

  /// Checks if this cache entry matches the given calculation parameters
  /// 
  /// This method implements the core cache matching logic, comparing
  /// the stored parameters with requested parameters within tolerance
  /// bounds. It's used to determine if a cached entry can satisfy
  /// a specific prayer times request.
  /// 
  /// Parameters:
  /// - [coordinates]: Requested location coordinates
  /// - [calculationMethod]: Requested calculation method
  /// - [madhab]: Requested madhab (legal school)
  /// 
  /// Returns: true if all parameters match within tolerance, false otherwise
  /// 
  /// Matching logic:
  /// - Coordinates: Within positionTolerance (approximately 100m)
  /// - Calculation method: Exact string match
  /// - Madhab: Exact string match
  /// 
  /// Performance considerations:
  /// - Simple arithmetic comparisons for coordinates
  /// - String equality checks for method and madhab
  /// - O(1) complexity - suitable for frequent cache lookups
  bool matchesParameters(
    adhan.Coordinates coordinates,
    String calculationMethod,
    String madhab,
  ) {
    const positionTolerance = 0.001; // About 100m

    return (coordinates.latitude - this.coordinates.latitude).abs() <
            positionTolerance &&
        (coordinates.longitude - this.coordinates.longitude).abs() <
            positionTolerance &&
        this.calculationMethod == calculationMethod &&
        this.madhab == madhab;
  }

  // ==================== FACTORY METHODS ====================

  /// Creates a CachedPrayerTimes from an Adhan PrayerTimes object
  /// 
  /// This factory method simplifies the creation of cache entries
  /// from raw prayer time calculations. It automatically handles
  /// the conversion from adhan package types to our internal models
  /// and sets up the cache metadata.
  /// 
  /// Parameters:
  /// - [adhanPrayerTimes]: Raw prayer times from adhan package
  /// - [coordinates]: Location coordinates used for calculation
  /// - [calculationMethod]: Prayer calculation method name
  /// - [madhab]: Islamic legal school used
  /// - [cachedAt]: Timestamp when entry was created (typically now)
  /// - [cacheDuration]: How long this entry should remain valid
  /// 
  /// Returns: New CachedPrayerTimes entry with calculated expiration
  /// 
  /// Example:
  /// ```dart
  /// final cacheEntry = CachedPrayerTimes.fromAdhanPrayerTimes(
  ///   adhanPrayerTimes,
  ///   userCoordinates,
  ///   'MuslimWorldLeague',
  ///   'hanafi',
  ///   DateTime.now(),
  ///   Duration(hours: 24),
  /// );
  /// ```
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

  // ==================== SERIALIZATION METHODS ====================

  /// Converts this cache entry to JSON for storage
  /// 
  /// Serializes the complete cache entry including prayer times,
  /// metadata, and timestamps to a format suitable for persistent
  /// storage in databases, SharedPreferences, or network transmission.
  /// 
  /// Serialization details:
  /// - Prayer times are nested as JSON object
  /// - Coordinates are stored as latitude/longitude pair
  /// - Timestamps converted to milliseconds since epoch
  /// - All string values stored directly
  /// 
  /// Returns: Map<String, dynamic> containing all cache data
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

  /// Creates a CachedPrayerTimes from JSON data
  /// 
  /// Deserializes a previously cached entry from stored JSON data.
  /// Handles all data type conversions and reconstruction of the
  /// nested PrayerTimesModel object.
  /// 
  /// Parameters:
  /// - [json]: Map containing serialized cache entry data
  /// 
  /// Returns: New CachedPrayerTimes entry with restored data
  /// 
  /// Error handling:
  /// - Assumes valid JSON structure (should be validated before use)
  /// - PrayerTimesModel.fromJson handles its own validation
  /// - Invalid timestamps may cause DateTime parsing errors
  /// 
  /// Example:
  /// ```dart
  /// final cacheEntry = CachedPrayerTimes.fromJson(storedData);
  /// if (cacheEntry.isValid) {
  ///   // Use cached prayer times
  /// }
  /// ```
  factory CachedPrayerTimes.fromJson(Map<String, dynamic> json) {
    return CachedPrayerTimes(
      prayerTimes: PrayerTimesModel.fromJson(
        json['prayerTimes'] as Map<String, dynamic>,
      ),
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

  // ==================== UTILITY METHODS ====================

  /// Calculates the remaining time until this cache entry expires
  /// 
  /// Useful for cache management decisions and debugging.
  /// Returns a negative duration if the entry has already expired.
  /// 
  /// Returns: Duration until expiration (negative if expired)
  Duration get timeUntilExpiration {
    return expiresAt.difference(DateTime.now());
  }

  /// Gets the age of this cache entry
  /// 
  /// Calculates how long ago this entry was created.
  /// Useful for cache analytics and performance monitoring.
  /// 
  /// Returns: Duration since creation
  Duration get age {
    return DateTime.now().difference(cachedAt);
  }

  /// Creates a copy with updated expiration time
  /// 
  /// Useful for cache refresh strategies where the same prayer
  /// times are extended with a new expiration time.
  /// 
  /// Parameters:
  /// - [newExpiresAt]: New expiration timestamp
  /// 
  /// Returns: New CachedPrayerTimes with updated expiration
  CachedPrayerTimes withUpdatedExpiration(DateTime newExpiresAt) {
    return CachedPrayerTimes(
      prayerTimes: this.prayerTimes,
      coordinates: this.coordinates,
      calculationMethod: this.calculationMethod,
      madhab: this.madhab,
      cachedAt: this.cachedAt,
      expiresAt: newExpiresAt,
    );
  }

  @override
  String toString() {
    return 'CachedPrayerTimes('
        'location: ${coordinates.latitude}, ${coordinates.longitude}, '
        'method: $calculationMethod, '
        'madhab: $madhab, '
        'cached: $cachedAt, '
        'expires: $expiresAt, '
        'valid: $isValid'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedPrayerTimes &&
        other.prayerTimes == prayerTimes &&
        other.coordinates.latitude == coordinates.latitude &&
        other.coordinates.longitude == coordinates.longitude &&
        other.calculationMethod == calculationMethod &&
        other.madhab == madhab &&
        other.cachedAt == cachedAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return prayerTimes.hashCode ^
        coordinates.latitude.hashCode ^
        coordinates.longitude.hashCode ^
        calculationMethod.hashCode ^
        madhab.hashCode ^
        cachedAt.hashCode ^
        expiresAt.hashCode;
  }
}