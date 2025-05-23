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
