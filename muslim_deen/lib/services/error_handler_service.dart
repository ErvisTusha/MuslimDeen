import 'dart:async';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// The Result class implements the Either pattern for error handling
/// 
/// This class provides a type-safe way to handle operations that can
/// either succeed with a value or fail with an error. It's an implementation
/// of the Either pattern commonly used in functional programming.
/// 
/// Benefits:
/// - Type-safe error handling without exceptions
/// - Explicit error handling in the type system
/// - Better composability of error-prone operations
/// - Cleaner code with fewer try-catch blocks
/// 
/// Usage:
/// ```dart
/// final result = await someOperation();
/// if (result.isSuccess) {
///   print(result.value);
/// } else {
///   print(result.error.message);
/// }
/// ```
/// 
/// Design Patterns:
/// - Either Pattern: Represents one of two possible values
/// - Factory Pattern: Static constructors for creating instances
/// - Null Object Pattern: Provides safe default behavior
/// 
/// Performance:
/// - Minimal overhead over direct value returns
/// - No exception handling overhead for success cases
class Result<T> {
  final T? _value;
  final AppError? _error;

  /// Creates a successful Result with a value
  /// 
  /// Factory constructor for creating a Result that represents
  /// a successful operation with the provided value.
  /// 
  /// Parameters:
  /// - [value]: The successful result value
  const Result.success(T value) : _value = value, _error = null;

  /// Creates a failed Result with an error
  /// 
  /// Factory constructor for creating a Result that represents
  /// a failed operation with the provided error.
  /// 
  /// Parameters:
  /// - [error]: The error that caused the failure
  const Result.failure(AppError error) : _error = error, _value = null;

  /// Check if the Result represents a successful operation
  /// 
  /// Returns true if the Result contains a value (success),
  /// false if it contains an error (failure).
  bool get isSuccess => _error == null;

  /// Check if the Result represents a failed operation
  /// 
  /// Returns true if the Result contains an error (failure),
  /// false if it contains a value (success).
  bool get isFailure => _error != null;

  /// Get the successful value
  /// 
  /// Returns the value if the Result is successful.
  /// Throws an exception if accessed on a failure Result.
  /// 
  /// Performance:
  /// - Direct field access with null check
  /// 
  /// Throws:
  /// - StateError if accessed on a failure Result
  T get value => _value!;

  /// Get the error
  /// 
  /// Returns the error if the Result is a failure.
  /// Throws an exception if accessed on a success Result.
  /// 
  /// Performance:
  /// - Direct field access with null check
  /// 
  /// Throws:
  /// - StateError if accessed on a success Result
  AppError get error => _error!;
}

/// Standardized error class for application errors
/// 
/// This class provides a standardized way to represent and handle
/// application errors. It includes contextual information
/// that helps with debugging and error reporting.
/// 
/// Features:
/// - Structured error information with message, code, and details
/// - Stack trace preservation for debugging
/// - Original exception wrapping
/// - String representation for logging
/// 
/// Usage:
/// ```dart
/// final error = AppError(
///   message: 'Failed to load data',
///   code: 'DATA_LOAD_ERROR',
///   details: 'Network timeout after 30 seconds',
///   originalException: e,
///   stackTrace: stackTrace,
/// );
/// ```
/// 
/// Design Patterns:
/// - Value Object: Immutable error representation
/// - Wrapper Pattern: Wraps original exceptions
/// - Template Method: Standardized toString implementation
/// 
/// Performance:
/// - Minimal overhead over direct exception handling
/// - Efficient string representation for logging
class AppError {
  /// Human-readable error message
  final String message;
  
  /// Optional error code for programmatic handling
  final String? code;
  
  /// Additional error details for debugging
  final String? details;
  
  /// Stack trace from original exception
  final StackTrace? stackTrace;
  
  /// Original exception that caused this error
  final Object? originalException;

  /// Creates an AppError with comprehensive error information
  /// 
  /// Parameters:
  /// - [message]: Human-readable error message (required)
  /// - [code]: Optional error code for categorization
  /// - [details]: Additional context or debugging information
  /// - [stackTrace]: Stack trace from original exception
  /// - [originalException]: The original exception object
  const AppError({
    required this.message,
    this.code,
    this.details,
    this.stackTrace,
    this.originalException,
  });

  /// String representation of the error
  /// 
  /// Creates a formatted string representation suitable for
  /// logging and debugging. Includes all available error
  /// information in a structured format.
  /// 
  /// Performance:
  /// - Efficient string building with StringBuffer
  /// - Conditional inclusion of optional fields
  /// 
  /// Returns:
  /// - Formatted string representation of the error
  @override
  String toString() {
    final buffer = StringBuffer('AppError: $message');
    if (code != null) buffer.write(' ($code)');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

/// Error handler service to centralize error handling
/// 
/// This service provides centralized error handling functionality
/// for the entire application. It standardizes error reporting,
/// logging, and handling patterns throughout the codebase.
/// 
/// Features:
/// - Centralized error logging with context
/// - Safe execution of error-prone operations
/// - Result pattern implementation for error handling
/// - Integration with LoggerService for consistent logging
/// 
/// Usage:
/// ```dart
/// final errorHandler = ErrorHandlerService();
/// 
/// // Report an error
/// errorHandler.reportError(
///   AppError(message: 'Operation failed'),
///   context: 'DataLoading',
/// );
/// 
/// // Safely execute an operation
/// final result = await errorHandler.guard(
///   () => riskyOperation(),
///   context: 'APIRequest',
/// );
/// ```
/// 
/// Design Patterns:
/// - Service: Provides error handling functionality
/// - Guard Pattern: Safe execution with error handling
/// - Facade: Simplifies complex error handling logic
/// - Singleton: Ensures consistent error handling across app
/// 
/// Performance:
/// - Minimal overhead for success cases
/// - Efficient error logging and reporting
/// - No exception handling overhead for successful operations
/// 
/// Dependencies:
/// - LoggerService: For centralized error logging
class ErrorHandlerService {
  final LoggerService _logger = locator<LoggerService>();

  /// Report an error with context information
  /// 
  /// Logs an error with additional context information to help
  /// with debugging and error tracking. This is the primary
  /// method for reporting errors throughout the application.
  /// 
  /// Parameters:
  /// - [error]: The AppError to report
  /// - [context]: Optional context information (e.g., operation name)
  /// 
  /// Algorithm:
  /// 1. Construct contextual error message
  /// 2. Log error with full details including stack trace
  /// 3. Include context information if provided
  /// 
  /// Performance:
  /// - Efficient error logging with structured data
  /// - Minimal overhead beyond LoggerService operations
  /// 
  /// Usage:
  /// Call this method whenever an error occurs to ensure
  /// consistent error reporting and logging.
  void reportError(AppError error, {String? context}) {
    _logger.error(
      'App error${context != null ? ' in $context' : ''}: ${error.message}',
      error: error.originalException,
      stackTrace: error.stackTrace,
      data: {'code': error.code, 'details': error.details},
    );
  }

  /// Safely execute a function with error handling
  /// 
  /// Executes a potentially error-prone function and returns a
  /// Result object. This method eliminates the need for
  /// try-catch blocks throughout the codebase.
  /// 
  /// Parameters:
  /// - [fn]: The function to execute
  /// - [context]: Optional context information for error reporting
  /// 
  /// Algorithm:
  /// 1. Execute the provided function
  /// 2. Return success Result with function's return value
  /// 3. Catch any exceptions and create AppError
  /// 4. Report error with context
  /// 5. Return failure Result with error
  /// 
  /// Type Parameters:
  /// - [T]: The return type of the function
  /// 
  /// Performance:
  /// - No exception handling overhead for successful operations
  /// - Efficient error creation and reporting
  /// - Type-safe error handling
  /// 
  /// Returns:
  /// - Result object containing either the function's return value
  ///   or an AppError if an exception occurred
  /// 
  /// Usage:
  /// Use this method to wrap any operation that might throw
  /// exceptions, ensuring consistent error handling.
  Future<Result<T>> guard<T>(Future<T> Function() fn, {String? context}) async {
    try {
      final result = await fn();
      return Result.success(result);
    } catch (e, stack) {
      final appError = AppError(
        message: e.toString(),
        stackTrace: stack,
        originalException: e,
      );
      reportError(appError, context: context);
      return Result.failure(appError);
    }
  }
}