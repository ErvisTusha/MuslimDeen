import 'package:logger/logger.dart';

/// A service for logging events throughout the application
/// with different log levels and prettier output.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() {
    return _instance;
  }

  LoggerService._internal() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTime,
      ),
      level: Level.debug, // Set to Level.nothing in production
    );
  }

  late final Logger _logger;

  // User interaction logs
  void logInteraction(
    String feature,
    String action, {
    Map<String, dynamic>? data,
  }) {
    _logger.i({
      'type': 'user_interaction',
      'feature': feature,
      'action': action,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Navigation events
  void logNavigation(String from, String to, {Map<String, dynamic>? data}) {
    _logger.i({
      'type': 'navigation',
      'from': from,
      'to': to,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // General debug logs
  void debug(
    dynamic message, {
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    if (data != null) {
      _logger.d({'message': message, 'data': data}, stackTrace: stackTrace);
    } else {
      _logger.d(message, stackTrace: stackTrace);
    }
  }

  // Info logs
  void info(dynamic message, {Map<String, dynamic>? data}) {
    if (data != null) {
      _logger.i({'message': message, 'data': data});
    } else {
      _logger.i(message);
    }
  }

  // Warning logs
  void warning(
    dynamic message, {
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    if (data != null) {
      _logger.w({'message': message, 'data': data}, stackTrace: stackTrace);
    } else {
      _logger.w(message, stackTrace: stackTrace);
    }
  }

  // Error logs
  void error(
    dynamic message, {
    dynamic error,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    if (data != null) {
      _logger.e(
        {'message': message, 'error': error, 'data': data},
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }
}
