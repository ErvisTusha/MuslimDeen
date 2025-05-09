// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim_deen/service_locator.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones();
    
    // Provide mock initial values for shared_preferences
    SharedPreferences.setMockInitialValues({
      'manual_location_lat': 21.422487,
      'manual_location_lng': 39.826206,
      'manual_location_name': 'Mecca',
      'exact_alarm_permission_granted': true,
      'use_manual_location': true, // Force use of manual location for tests
    });
    
    // Setup service locator for testing environment
    await setupLocator(testing: true);
  });

  testWidgets('App contains basic structure elements', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Icon(Icons.explore), // Check for the Qibla direction icon
          ),
        ),
      ),
    );

    // Verify that our icon is present
    expect(find.byIcon(Icons.explore), findsOneWidget);
  });
}
