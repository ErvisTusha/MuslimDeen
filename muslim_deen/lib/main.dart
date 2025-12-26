import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'package:muslim_deen/app.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:muslim_deen/services/error_handler_service.dart';
import 'package:muslim_deen/services/logger_service.dart';
import 'package:muslim_deen/services/notification_service.dart';
import 'package:muslim_deen/widgets/error_boundary.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await setupLocator();
  } catch (e, s) {
    debugPrint('Failed to setup service locator: $e');
    debugPrint('Stack trace: $s');
    runApp(const ErrorApp());
    return;
  }

  final List<Future<void>> startupFutures = [
    _requestPermissions(),
    Future<void>(() async => tz.initializeTimeZones()),
    Future<void>(() async {
      final notificationService = locator<NotificationService>();
      await notificationService.init();
      await notificationService.rescheduleAllNotifications();
    }),
  ];

  try {
    await Future.wait(startupFutures);
    locator<LoggerService>().info("Parallel startup operations completed.");
  } catch (e, s) {
    locator<LoggerService>().error(
      "Error during parallel startup operations",
      error: e,
      stackTrace: s,
    );
  }

  FlutterError.onError = (details) {
    final errorHandler = locator<ErrorHandlerService>();
    errorHandler.reportError(
      AppError(
        message: 'Flutter framework error',
        details: details.exceptionAsString(),
        stackTrace: details.stack,
        originalException: details.exception,
      ),
    );
  };

  runApp(const ProviderScope(child: ErrorBoundary(child: MuslimDeenApp())));
}

Future<void> _requestPermissions() async {
  final LoggerService logger = locator<LoggerService>();

  var notificationStatus = await Permission.notification.status;
  if (!notificationStatus.isGranted) {
    notificationStatus = await Permission.notification.request();
    logger.info(
      'Notification permission status after request: $notificationStatus',
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'The app failed to start properly. Please try restarting the app.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(onPressed: main, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
