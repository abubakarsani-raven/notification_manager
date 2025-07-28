// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_system_notifications/flutter_system_notifications.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter System Notifications Integration Tests', () {
    late NotificationManager notificationManager;

    setUp(() {
      notificationManager = NotificationManager();
    });

    testWidgets('should initialize notification manager', (tester) async {
      // Build the app
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Check if the app is running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should request permissions', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for permission request
      await Future.delayed(Duration(seconds: 3));

      // The app should be running without errors
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('should show simple notification', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the simple notification button
      final simpleButton = find.text('📱 Simple Notification');
      expect(simpleButton, findsOneWidget);

      await tester.tap(simpleButton);
      await tester.pumpAndSettle();

      // Wait for notification to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should show notification with actions', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the action notification button
      final actionButton = find.text('🎯 Notification with Actions');
      expect(actionButton, findsOneWidget);

      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      // Wait for notification to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should show notification with badge', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the badge notification button
      final badgeButton = find.text('🔢 Notification with Badge');
      expect(badgeButton, findsOneWidget);

      await tester.tap(badgeButton);
      await tester.pumpAndSettle();

      // Wait for notification to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should schedule notification', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the 5s schedule button
      final scheduleButton = find.text('⏰ 5s');
      expect(scheduleButton, findsOneWidget);

      await tester.tap(scheduleButton);
      await tester.pumpAndSettle();

      // Wait for scheduling to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should clear badge count', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the clear badge button
      final clearBadgeButton = find.text('🧹 Clear Badge');
      expect(clearBadgeButton, findsOneWidget);

      await tester.tap(clearBadgeButton);
      await tester.pumpAndSettle();

      // Wait for badge clearing to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should check notification status', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the check status button
      final statusButton = find.text('🔍 Check Status');
      expect(statusButton, findsOneWidget);

      await tester.tap(statusButton);
      await tester.pumpAndSettle();

      // Wait for status check to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should request permission', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the request permission button
      final permissionButton = find.text('🔐 Request Permission');
      expect(permissionButton, findsOneWidget);

      await tester.tap(permissionButton);
      await tester.pumpAndSettle();

      // Wait for permission request to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should cancel all scheduled notifications', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the cancel all button
      final cancelAllButton = find.text('❌ Cancel All');
      expect(cancelAllButton, findsOneWidget);

      await tester.tap(cancelAllButton);
      await tester.pumpAndSettle();

      // Wait for cancellation to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should get scheduled notifications', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the list all button
      final listAllButton = find.text('📋 List All');
      expect(listAllButton, findsOneWidget);

      await tester.tap(listAllButton);
      await tester.pumpAndSettle();

      // Wait for listing to be processed
      await Future.delayed(Duration(seconds: 1));
    });

    testWidgets('should handle repeating notifications', (tester) async {
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Wait for initialization
      await Future.delayed(Duration(seconds: 2));

      // Find and tap the repeating notification button
      final repeatingButton = find.text('🔄 Repeating (every 1min)');
      expect(repeatingButton, findsOneWidget);

      await tester.tap(repeatingButton);
      await tester.pumpAndSettle();

      // Wait for scheduling to be processed
      await Future.delayed(Duration(seconds: 1));
    });
  });
}

// Simple test app for integration testing
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationManager _notificationManager = NotificationManager();
  String _statusMessage = 'Initializing...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotificationManager();
  }

  Future<void> _initializeNotificationManager() async {
    try {
      await _notificationManager.initialize();
      final hasPermission = await _notificationManager.requestPermissions();
      
      setState(() {
        _statusMessage = hasPermission 
            ? '✅ Ready! Notifications enabled'
            : '⚠️ Permission not granted. Notifications may not work.';
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Integration Test App',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Integration Test'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_statusMessage),
              SizedBox(height: 20),
              if (_isInitialized) ...[
                ElevatedButton(
                  onPressed: () async {
                    final request = NotificationRequest(
                      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
                      title: 'Test Notification',
                      body: 'This is a test notification',
                    );
                    await _notificationManager.showNotification(request);
                  },
                  child: Text('Show Test Notification'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
