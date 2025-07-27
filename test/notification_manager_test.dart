import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_system_notifications/notification_manager.dart';



void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationManager', () {
    const MethodChannel channel = MethodChannel('notification_manager');
    final log = <MethodCall>[];
    late NotificationManager notificationManager;

    setUp(() {
      notificationManager = NotificationManager();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'initialize':
            return true;
          case 'requestPermissions':
            return true;
          case 'areNotificationsEnabled':
            return true;
          case 'showNotification':
            return true;
          case 'scheduleNotification':
            return true;
          case 'getScheduledNotifications':
            return <Map<String, dynamic>>[];
          case 'updateScheduledNotification':
            return true;
          case 'cancelNotification':
            return true;
          case 'cancelScheduledNotification':
            return true;
          case 'cancelAllNotifications':
            return true;
          case 'cancelAllScheduledNotifications':
            return true;
          case 'getBadgeCount':
            return 0;
          case 'setBadgeCount':
            return true;
          case 'clearBadgeCount':
            return true;
          case 'isDuplicateNotification':
            return false;
          case 'clearNotificationHistory':
            return true;
          default:
            return null;
        }
      });
    });

    tearDown(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    test('initialize', () async {
      final result = await notificationManager.initialize();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('initialize', arguments: null),
        ],
      );
    });

    test('requestPermissions', () async {
      final result = await notificationManager.requestPermissions();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('requestPermissions', arguments: null),
        ],
      );
    });

    test('areNotificationsEnabled', () async {
      final result = await notificationManager.areNotificationsEnabled();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('areNotificationsEnabled', arguments: null),
        ],
      );
    });

    test('showNotification', () async {
      final request = NotificationRequest(
        id: 'test_id',
        title: 'Test Title',
        body: 'Test Body',
      );
      
      final result = await notificationManager.showNotification(request);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('showNotification', arguments: request.toJson()),
        ],
      );
    });

    test('scheduleNotification', () async {
      final request = NotificationRequest(
        id: 'test_id',
        title: 'Test Title',
        body: 'Test Body',
      );
      
      final scheduledDate = DateTime.now().add(Duration(minutes: 5));
      
      final result = await notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
      );
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('scheduleNotification', arguments: {
            'id': 'test_id',
            'request': request.toJson(),
            'scheduledDate': scheduledDate.millisecondsSinceEpoch,
            'isRepeating': false,
            'repeatInterval': null,
          }),
        ],
      );
    });

    test('getScheduledNotifications', () async {
      final result = await notificationManager.getScheduledNotifications();
      expect(result, isA<List<ScheduledNotification>>());
      expect(
        log,
        <Matcher>[
          isMethodCall('getScheduledNotifications', arguments: null),
        ],
      );
    });

    test('cancelNotification', () async {
      final result = await notificationManager.cancelNotification('test_id');
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelNotification', arguments: {'id': 'test_id'}),
        ],
      );
    });

    test('cancelScheduledNotification', () async {
      final result = await notificationManager.cancelScheduledNotification('test_id');
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelScheduledNotification', arguments: {'id': 'test_id'}),
        ],
      );
    });

    test('cancelAllNotifications', () async {
      final result = await notificationManager.cancelAllNotifications();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelAllNotifications', arguments: null),
        ],
      );
    });

    test('cancelAllScheduledNotifications', () async {
      final result = await notificationManager.cancelAllScheduledNotifications();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelAllScheduledNotifications', arguments: null),
        ],
      );
    });

    test('getBadgeCount', () async {
      final result = await notificationManager.getBadgeCount();
      expect(result, 0);
      expect(
        log,
        <Matcher>[
          isMethodCall('getBadgeCount', arguments: null),
        ],
      );
    });

    test('setBadgeCount', () async {
      final result = await notificationManager.setBadgeCount(5);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('setBadgeCount', arguments: {'count': 5}),
        ],
      );
    });

    test('clearBadgeCount', () async {
      final result = await notificationManager.clearBadgeCount();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('clearBadgeCount', arguments: null),
        ],
      );
    });

    test('isDuplicateNotification', () async {
      final result = await notificationManager.isDuplicateNotification('test_key', timeWindow: null);
      expect(result, false);
      expect(
        log,
        <Matcher>[
          isMethodCall('isDuplicateNotification', arguments: {
            'duplicateKey': 'test_key',
            'timeWindow': null,
          }),
        ],
      );
    });

    test('clearNotificationHistory', () async {
      final result = await notificationManager.clearNotificationHistory();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('clearNotificationHistory', arguments: null),
        ],
      );
    });
  });
}
