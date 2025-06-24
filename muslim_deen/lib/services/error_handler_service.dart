import 'dart:async';

import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/logger_service.dart';

/// The Result class implements the Either pattern for error handling
class Result<T> {
  final T? _value;
  final AppError? _error;

  const Result.success(T value) : _value = value, _error = null;

  const Result.failure(AppError error) : _error = error, _value = null;

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T get value => _value!;
  AppError get error => _error!;
}

/// Standardized error class for application errors
class AppError {
  final String message;
  final String? code;
  final String? details;
  final StackTrace? stackTrace;
  final Object? originalException;

  const AppError({
    required this.message,
    this.code,
    this.details,
    this.stackTrace,
    this.originalException,
  });

  @override
  String toString() {
    final buffer = StringBuffer('AppError: $message');
    if (code != null) buffer.write(' ($code)');
    if (details != null) buffer.write('\nDetails: $details');
    return buffer.toString();
  }
}

String processDisplayErrorMessage(Object? error) {
  if (error == null) return 'An unknown error occurred. Please try again.';

  String errorMessageString;
  if (error is String) {
    errorMessageString = error;
  } else if (error is AppError) {
    errorMessageString = error.details ?? error.message;
  } else {
    errorMessageString = error.toString();
  }

  if (errorMessageString.contains('Location permission denied. Please enable it in settings.')) {
    return 'Location permission denied. Please enable it in settings.';
  } else if (errorMessageString.contains('Location permissions are denied')) {
    return 'Location permissions are denied. Please grant permission.';
  } else if (errorMessageString.contains('permanently denied')) {
    return 'Location permission permanently denied. Please enable it in app settings.';
  } else if (errorMessageString.contains('Location services are disabled') || errorMessageString.contains('service is disabled')) {
    return 'Location services are disabled. Please enable them in your device settings.';
  } else if (errorMessageString.contains('Could not determine location')) {
    return 'Could not determine your location. Please ensure location services are enabled and permissions granted.';
  } else if (errorMessageString.contains('Compass sensor error')) {
    return "Compass sensor error. Please try again.";
  } else if (errorMessageString.contains('StorageService not initialized')) {
    return 'Initialization error. Please restart the app.';
  } else if (errorMessageString.contains('Failed to calculate prayer times')) {
    return 'Failed to calculate prayer times. Please check your connection or location settings.';
  }

  // Generic fallbacks for common error types or messages
  if (errorMessageString.toLowerCase().contains('network') || errorMessageString.toLowerCase().contains('socketexception')) {
    return 'Network error. Please check your internet connection and try again.';
  }
  if (errorMessageString.toLowerCase().contains('timeout') || errorMessageString.toLowerCase().contains('timed out')) {
    return 'The request timed out. Please try again.';
  }

  // If no specific message is matched, return a generic one or a cleaned up version of the original
  // For now, let's return a generic one for unknown technical errors.
  // More sophisticated parsing could be added if needed.
  if (errorMessageString.length > 150 || errorMessageString.contains(RegExp(r'[a-zA-Z]+\.[a-zA-Z]+:'))) { // Heuristic for technical error messages
    return 'An unexpected error occurred. Please try again.';
  }

  return errorMessageString; // Return original if not specifically handled and not overly technical
}

/// Error handler service to centralize error handling
class ErrorHandlerService {
  final LoggerService _logger = locator<LoggerService>();

  void reportError(AppError error, {String? context}) {
    _logger.error(
      'App error${context != null ? ' in $context' : ''}: ${error.message}',
      error: error.originalException,
      stackTrace: error.stackTrace,
      data: {'code': error.code, 'details': error.details},
    );
  }

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
