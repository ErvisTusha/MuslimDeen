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
      level: Level.warning, // Set to Level.nothing in production
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
      if (data != null) 'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Navigation events
  void logNavigation(String from, String to, {Map<String, dynamic>? data}) {
    _logger.i({
      'type': 'navigation',
      'from': from,
      'to': to,
      if (data != null) 'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // General debug logs
  void debug(
    dynamic message, {
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _logger.d({
      'message': message,
      if (data != null) 'data': data,
    }, stackTrace: stackTrace);
  }

  // Info logs
  void info(dynamic message, {Map<String, dynamic>? data}) {
    _logger.i({'message': message, if (data != null) 'data': data});
  }

  // Warning logs
  void warning(
    dynamic message, {
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _logger.w({
      'message': message,
      if (data != null) 'data': data,
    }, stackTrace: stackTrace);
  }

  // Error logs
  void error(
    dynamic message, {
    dynamic error,
    Map<String, dynamic>? data,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      {'message': message, if (data != null) 'data': data},
      error: error,
      stackTrace: stackTrace,
    );
  }
}
