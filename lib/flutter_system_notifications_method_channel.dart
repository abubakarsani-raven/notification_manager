import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_system_notifications_platform_interface.dart';

/// An implementation of [FlutterSystemNotificationsPlatform] that uses method channels.
class MethodChannelFlutterSystemNotifications extends FlutterSystemNotificationsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_system_notifications');

  /// The event channel for notification events
  @visibleForTesting
  final eventChannel = const EventChannel('flutter_system_notifications_events');

  MethodChannelFlutterSystemNotifications() {
    _setupEventChannel();
  }

  void _setupEventChannel() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) {
      _handlePlatformEvent(event);
    });
  }

  void _handlePlatformEvent(dynamic event) {
    try {
      if (event is Map) {
        final String type = event['type'] ?? '';
        
        switch (type) {
          case 'action':
            // This would be handled by the main NotificationManager class
            break;
          case 'tap':
            // This would be handled by the main NotificationManager class
            break;
        }
      }
    } catch (e) {
      debugPrint('Error handling platform event: $e');
    }
  }

  @override
  Future<bool> initialize() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('initialize');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error initializing notification manager: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error requesting permissions: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('areNotificationsEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking notification status: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> showNotification(dynamic request) async {
    try {
      final Map<String, dynamic> requestData = request.toJson();
      final result = await methodChannel.invokeMethod<bool>('showNotification', requestData);
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error showing notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> scheduleNotification(dynamic scheduledNotification) async {
    try {
      final Map<String, dynamic> notificationData = scheduledNotification.toJson();
      final result = await methodChannel.invokeMethod<bool>('scheduleNotification', notificationData);
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error scheduling notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<List<dynamic>> getScheduledNotifications() async {
    try {
      final result = await methodChannel.invokeMethod<List<dynamic>>('getScheduledNotifications');
      return result ?? [];
    } on PlatformException catch (e) {
      debugPrint('Error getting scheduled notifications: ${e.message}');
      return [];
    }
  }

  @override
  Future<bool> updateScheduledNotification(dynamic notification) async {
    try {
      final Map<String, dynamic> notificationData = notification.toJson();
      final result = await methodChannel.invokeMethod<bool>('updateScheduledNotification', notificationData);
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error updating scheduled notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> cancelNotification(String id) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('cancelNotification', {'id': id});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error canceling notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> cancelScheduledNotification(String id) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('cancelScheduledNotification', {'id': id});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error canceling scheduled notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> cancelAllNotifications() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('cancelAllNotifications');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error canceling all notifications: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> cancelAllScheduledNotifications() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('cancelAllScheduledNotifications');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error canceling all scheduled notifications: ${e.message}');
      return false;
    }
  }

  @override
  Future<int> getBadgeCount() async {
    try {
      final result = await methodChannel.invokeMethod<int>('getBadgeCount');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint('Error getting badge count: ${e.message}');
      return 0;
    }
  }

  @override
  Future<bool> setBadgeCount(int count) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('setBadgeCount', {'count': count});
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error setting badge count: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> clearBadgeCount() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('clearBadgeCount');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error clearing badge count: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> isDuplicateNotification(String duplicateKey, Duration? timeWindow) async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isDuplicateNotification', {
        'duplicateKey': duplicateKey,
        'timeWindow': timeWindow?.inSeconds,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking duplicate notification: ${e.message}');
      return false;
    }
  }

  @override
  Future<bool> clearNotificationHistory() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('clearNotificationHistory');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error clearing notification history: ${e.message}');
      return false;
    }
  }
}
