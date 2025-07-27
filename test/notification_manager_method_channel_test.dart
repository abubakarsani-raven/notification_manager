import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_notification_manager/notification_manager_method_channel.dart';
import 'package:flutter_notification_manager/notification_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelNotificationManager', () {
    const MethodChannel channel = MethodChannel('notification_manager');
    final log = <MethodCall>[];
    late MethodChannelNotificationManager methodChannelNotificationManager;

    setUp(() {
      methodChannelNotificationManager = MethodChannelNotificationManager();
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
      final result = await methodChannelNotificationManager.initialize();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('initialize', arguments: null),
        ],
      );
    });

    test('requestPermissions', () async {
      final result = await methodChannelNotificationManager.requestPermissions();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('requestPermissions', arguments: null),
        ],
      );
    });

    test('areNotificationsEnabled', () async {
      final result = await methodChannelNotificationManager.areNotificationsEnabled();
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
      
      final result = await methodChannelNotificationManager.showNotification(request);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('showNotification', arguments: request.toJson()),
        ],
      );
    });

    test('scheduleNotification', () async {
      final scheduledNotification = ScheduledNotification(
        id: 'test_id',
        request: NotificationRequest(
          id: 'test_id',
          title: 'Test Title',
          body: 'Test Body',
        ),
        scheduledDate: DateTime.now().add(Duration(minutes: 5)),
      );
      
      final result = await methodChannelNotificationManager.scheduleNotification(scheduledNotification);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('scheduleNotification', arguments: scheduledNotification.toJson()),
        ],
      );
    });

    test('getScheduledNotifications', () async {
      final result = await methodChannelNotificationManager.getScheduledNotifications();
      expect(result, isA<List<dynamic>>());
      expect(
        log,
        <Matcher>[
          isMethodCall('getScheduledNotifications', arguments: null),
        ],
      );
    });

    test('updateScheduledNotification', () async {
      final scheduledNotification = ScheduledNotification(
        id: 'test_id',
        request: NotificationRequest(
          id: 'test_id',
          title: 'Updated Title',
          body: 'Updated Body',
        ),
        scheduledDate: DateTime.now().add(Duration(minutes: 10)),
      );
      
      final result = await methodChannelNotificationManager.updateScheduledNotification(scheduledNotification);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('updateScheduledNotification', arguments: scheduledNotification.toJson()),
        ],
      );
    });

    test('cancelNotification', () async {
      final result = await methodChannelNotificationManager.cancelNotification('test_id');
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelNotification', arguments: {'id': 'test_id'}),
        ],
      );
    });

    test('cancelScheduledNotification', () async {
      final result = await methodChannelNotificationManager.cancelScheduledNotification('test_id');
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelScheduledNotification', arguments: {'id': 'test_id'}),
        ],
      );
    });

    test('cancelAllNotifications', () async {
      final result = await methodChannelNotificationManager.cancelAllNotifications();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelAllNotifications', arguments: null),
        ],
      );
    });

    test('cancelAllScheduledNotifications', () async {
      final result = await methodChannelNotificationManager.cancelAllScheduledNotifications();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('cancelAllScheduledNotifications', arguments: null),
        ],
      );
    });

    test('getBadgeCount', () async {
      final result = await methodChannelNotificationManager.getBadgeCount();
      expect(result, 0);
      expect(
        log,
        <Matcher>[
          isMethodCall('getBadgeCount', arguments: null),
        ],
      );
    });

    test('setBadgeCount', () async {
      final result = await methodChannelNotificationManager.setBadgeCount(5);
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('setBadgeCount', arguments: {'count': 5}),
        ],
      );
    });

    test('clearBadgeCount', () async {
      final result = await methodChannelNotificationManager.clearBadgeCount();
      expect(result, true);
      expect(
        log,
        <Matcher>[
          isMethodCall('clearBadgeCount', arguments: null),
        ],
      );
    });

    test('isDuplicateNotification', () async {
      final result = await methodChannelNotificationManager.isDuplicateNotification('test_key', null);
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
      final result = await methodChannelNotificationManager.clearNotificationHistory();
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
