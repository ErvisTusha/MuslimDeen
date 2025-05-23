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
}
