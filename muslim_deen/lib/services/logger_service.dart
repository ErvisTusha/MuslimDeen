import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// A service for logging events throughout the application
/// with different log levels and prettier output.
class LoggerService {
  static LoggerService? _instance;

  factory LoggerService() {
    if (_instance == null) {
      _instance = LoggerService._internal();
    }
    return _instance!;
  }

  LoggerService._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTime,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  void debug(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    if (data != null) {
      _logger.d('$message | data: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  void info(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    if (data != null) {
      _logger.i('$message | data: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  void warning(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    if (data != null) {
      _logger.w('$message | data: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  void error(
    dynamic message, {
    dynamic error,
    StackTrace? stackTrace,
    dynamic data,
  }) {
    if (data != null) {
      _logger.e('$message | data: $data', error: error, stackTrace: stackTrace);
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  // Custom log methods
  void logNavigation(
    String event, {
    String? routeName,
    Map<String, dynamic>? params,
    String? details,
  }) {
    String logMessage = 'Navigation: $event';
    if (routeName != null) {
      logMessage += ' | Route: $routeName';
    }
    if (params != null) {
      logMessage += ' | Params: $params';
    }
    if (details != null) {
      logMessage += ' | Details: $details';
    }
    _logger.i(logMessage);
  }

  void logInteraction(
    String widgetName,
    String interactionType, {
    String? details,
    dynamic data,
  }) {
    _logger.i(
      'Interaction: $widgetName - $interactionType${details != null ? ' ($details)' : ''}',
    );
  }
}
