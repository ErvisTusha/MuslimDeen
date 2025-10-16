/// Custom exception classes for the MuslimDeen application
/// 
/// This file defines application-specific exception types that provide
/// meaningful error context and handling for different failure scenarios.
/// Custom exceptions improve error debugging, user experience, and
/// allow for granular error handling strategies.
/// 
/// Design principles:
/// - Each exception type represents a specific error category
/// - Exceptions include contextual information for debugging
/// - Implement proper toString() methods for logging
/// - Include original exceptions when wrapping lower-level errors
/// 
/// Usage patterns:
/// - Throw specific exceptions for known error conditions
/// - Catch exceptions at appropriate abstraction levels
/// - Provide user-friendly messages based on exception type
/// - Log detailed error information for debugging

/// Exception thrown when prayer data is invalid or unavailable
/// 
/// This exception is used when there are issues with prayer time calculations,
/// data parsing, or when required prayer information cannot be retrieved.
/// It helps distinguish prayer-specific errors from other application errors.
/// 
/// Common scenarios:
/// - Invalid prayer time calculation parameters
/// - Missing or corrupted prayer data
/// - Network failures when fetching prayer times
/// - Invalid date ranges for prayer calculations
/// 
/// Error handling strategy:
/// - Display user-friendly error message about prayer time issues
/// - Offer retry options for transient failures
/// - Fall back to default prayer times when appropriate
/// - Log detailed error information for debugging
class PrayerDataException implements Exception {
  /// Human-readable error message describing the prayer data issue
  /// Should provide enough context for debugging and user communication
  final String message;

  /// Creates a new PrayerDataException with the specified message
  /// 
  /// Parameters:
  /// - [message]: Description of the prayer data error
  /// 
  /// Example:
  /// ```dart
  /// throw PrayerDataException('Unable to calculate prayer times for invalid coordinates');
  /// ```
  PrayerDataException(this.message);

  /// Returns a string representation of the exception
  /// 
  /// Includes the exception type and error message for logging purposes.
  /// This format is useful for debugging and error reporting.
  /// 
  /// Returns: Formatted string with exception type and message
  @override
  String toString() => 'PrayerDataException: $message';
}

/// Exception thrown when location services encounter errors
/// 
/// This exception handles failures related to GPS, location permissions,
/// coordinate validation, and other location-dependent operations.
/// It provides detailed context about the original error and stack trace.
/// 
/// Common scenarios:
/// - GPS is disabled or unavailable
/// - Location permissions are denied
/// - Invalid or out-of-range coordinates
/// - Location service timeout or network issues
/// - Hardware failures in location sensors
/// 
/// Error handling strategy:
/// - Guide users to enable location services
/// - Request permissions when denied
/// - Provide manual location entry as fallback
/// - Offer cached location data when available
/// - Log detailed technical information for debugging
class LocationServiceException implements Exception {
  /// Human-readable error message describing the location service issue
  /// Should provide clear context about what went wrong
  final String message;
  
  /// The original exception that caused this location service error
  /// Useful for debugging underlying technical issues
  /// Can be null if this is a top-level exception
  final dynamic originalException;
  
  /// Stack trace from the original exception
  /// Provides detailed execution context for debugging
  /// Helps identify the exact location where the error occurred
  final StackTrace? stackTrace;

  /// Creates a new LocationServiceException with detailed error information
  /// 
  /// Parameters:
  /// - [message]: Description of the location service error
  /// - [originalException]: The underlying exception that caused this error (optional)
  /// - [stackTrace]: Stack trace from the original exception (optional)
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await getLocation();
  /// } catch (e, stackTrace) {
  ///   throw LocationServiceException(
  ///     'Failed to get user location',
  ///     originalException: e,
  ///     stackTrace: stackTrace,
  ///   );
  /// }
  /// ```
  const LocationServiceException(
    this.message, {
    this.originalException,
    this.stackTrace,
  });

  /// Returns a comprehensive string representation of the exception
  /// 
  /// Includes the primary message, original exception details, and stack trace
  /// when available. This format is ideal for detailed logging and debugging.
  /// 
  /// Returns: Multi-line string with complete error information
  @override
  String toString() {
    String result = 'LocationServiceException: $message';
    if (originalException != null) {
      result += '\nOriginal Exception: $originalException';
    }
    if (stackTrace != null) {
      result += '\nStackTrace: $stackTrace';
    }
    return result;
  }
}

/// Additional exception types that could be added as the application grows:
/// 
/// ```dart
/// /// Exception for network-related errors
/// class NetworkException implements Exception {
///   final String message;
///   final int? statusCode;
///   NetworkException(this.message, {this.statusCode});
///   @override
///   String toString() => 'NetworkException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
/// }
/// 
/// /// Exception for database operations
/// class DatabaseException implements Exception {
///   final String message;
///   final String? query;
///   DatabaseException(this.message, {this.query});
///   @override
///   String toString() => 'DatabaseException: $message${query != null ? ' (Query: $query)' : ''}';
/// }
/// 
/// /// Exception for validation errors
/// class ValidationException implements Exception {
///   final String message;
///   final Map<String, String>? fieldErrors;
///   ValidationException(this.message, {this.fieldErrors});
///   @override
///   String toString() => 'ValidationException: $message${fieldErrors != null ? ' (Fields: $fieldErrors)' : ''}';
/// }
/// ```

/// Exception handling best practices for this application:
/// 
/// 1. **Specific Exception Types**: Use the most specific exception type available
///    - PrayerDataException for prayer-related issues
///    - LocationServiceException for location problems
///    - Standard Dart exceptions for general errors
/// 
/// 2. **Context Preservation**: Always include relevant context in exception messages
///    - What operation was being performed
///    - What inputs were provided
///    - What the expected vs actual outcome was
/// 
/// 3. **User Communication**: Convert technical exceptions to user-friendly messages
///    - Hide technical details from end users
///    - Provide actionable guidance when possible
///    - Offer retry mechanisms for transient failures
/// 
/// 4. **Logging Strategy**: Log detailed exception information for debugging
///    - Include full exception details and stack traces
///    - Use appropriate log levels (error, warning, info)
///    - Correlate errors with user sessions and app state
/// 
/// 5. **Graceful Degradation**: Design fallback mechanisms for common failures
///    - Cached data for network failures
///    - Default values for calculation errors
///    - Alternative input methods for sensor failures
/// 
/// 6. **Recovery Patterns**: Implement appropriate recovery strategies
///    - Retry with exponential backoff for transient failures
///    - User intervention prompts for permission issues
///    - Automatic fallbacks for non-critical features