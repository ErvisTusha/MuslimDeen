import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service_locator.dart';
import '../services/logger_service.dart';

/// The Result class implements the Either pattern for error handling
class Result<T> {
  final T? _value;
  final AppError? _error;
  
  const Result.success(T value)
      : _value = value,
        _error = null;
  
  const Result.failure(AppError error)
      : _error = error,
        _value = null;
  
  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;
  
  T get value => _value!;
  AppError get error => _error!;
  
  R fold<R>(R Function(T) onSuccess, R Function(AppError) onFailure) {
    if (isSuccess) {
      return onSuccess(_value as T);
    } else {
      return onFailure(_error!);
    }
  }
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
  
  static AppError fromException(Object e, [StackTrace? stack]) {
    return AppError(
      message: e.toString(),
      stackTrace: stack,
      originalException: e,
    );
  }
}

/// Error handler service to centralize error handling
class ErrorHandlerService {
  final LoggerService _logger = locator<LoggerService>();
  final _errorController = StreamController<AppError>.broadcast();
  
  Stream<AppError> get errorStream => _errorController.stream;
  
  void reportError(AppError error) {
    _logger.error(
      'App error: ${error.message}',
      error: error.originalException,
      stackTrace: error.stackTrace,
    );
    
    _errorController.add(error);
    
    // Add reporting to external services if needed
    // e.g. Firebase Crashlytics, Sentry, etc.
  }
  
  Future<Result<T>> guard<T>(Future<T> Function() fn) async {
    try {
      final result = await fn();
      return Result.success(result);
    } catch (e, stack) {
      final error = AppError(
        message: e.toString(),
        stackTrace: stack,
        originalException: e,
      );
      reportError(error);
      return Result.failure(error);
    }
  }
  
  Result<T> guardSync<T>(T Function() fn) {
    try {
      final result = fn();
      return Result.success(result);
    } catch (e, stack) {
      final error = AppError(
        message: e.toString(),
        stackTrace: stack,
        originalException: e,
      );
      reportError(error);
      return Result.failure(error);
    }
  }
  
  void dispose() {
    _errorController.close();
  }
}

// Provider for error handler service
final errorHandlerProvider = Provider<ErrorHandlerService>((ref) {
  final errorHandler = ErrorHandlerService();
  ref.onDispose(errorHandler.dispose);
  return errorHandler;
});

// Stream provider for error notifications across the app
final appErrorsProvider = StreamProvider<AppError>((ref) {
  return ref.watch(errorHandlerProvider).errorStream;
});
