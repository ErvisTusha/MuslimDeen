// A simple script to test prayer notifications
// Run with: flutter run test_notification.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));
  
  // Create a minimal app to run our test
  runApp(const NotificationTestApp());
}

class NotificationTestApp extends StatelessWidget {
  const NotificationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const NotificationTestScreen(),
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
    );
  }
}

class NotificationTestScreen extends StatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  State<NotificationTestScreen> createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  String _status = 'Starting up...';
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAndTest();
  }

  // Initialize notification service and schedule test notifications
  Future<void> _initializeAndTest() async {
    try {
      setState(() => _status = 'Initializing notification service...');
      
      // Initialize notifications plugin with platform-specific settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          debugPrint('Notification tapped: ${details.payload}');
        },
      );
      
      // Request permission on Android
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      
      // Schedule test notifications
      setState(() => _status = 'Scheduling test notifications...');
      
      // Create notification details
      const androidDetails = AndroidNotificationDetails(
        'prayer_test_channel',
        'Prayer Test Channel',
        channelDescription: 'Channel for testing prayer notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableLights: true,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true, 
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show immediate notification
      await _notificationsPlugin.show(
        1000,
        'Immediate Notification Test',
        'This notification should appear immediately',
        notificationDetails,
        payload: 'immediate_test',
      );
      
      // Schedule notification in 10 seconds
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
      await _notificationsPlugin.zonedSchedule(
        1001,
        'Scheduled Notification Test (10s)',
        'This notification should appear after 10 seconds',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'scheduled_test',
      );
      
      setState(() {
        _status = 'Test notifications scheduled successfully!\n\n'
            '1. One notification should appear immediately\n'
            '2. Another notification will appear in 10 seconds\n\n'
            'If you see both notifications, your prayer notification system is working correctly.';
        _isInitializing = false;
      });
      
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isInitializing = false;
      });
      debugPrint('Error testing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Notification Test'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isInitializing) const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}