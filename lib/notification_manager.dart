
import 'dart:async';

import 'notification_manager_platform_interface.dart';

/// Represents a notification action button
class NotificationAction {
  final String id;
  final String title;
  final bool isDestructive;
  final bool requiresAuthentication;

  const NotificationAction({
    required this.id,
    required this.title,
    this.isDestructive = false,
    this.requiresAuthentication = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDestructive': isDestructive,
        'requiresAuthentication': requiresAuthentication,
      };
}

/// Represents a notification payload for deep linking
class NotificationPayload {
  final String? route;
  final Map<String, dynamic>? data;

  const NotificationPayload({
    this.route,
    this.data,
  });

  Map<String, dynamic> toJson() => {
        'route': route,
        'data': data,
      };
}

/// Represents a notification to be shown
class NotificationRequest {
  final String id;
  final String title;
  final String body;
  final List<NotificationAction>? actions;
  final NotificationPayload? payload;
  final String? category;
  final int? badgeNumber;
  final Duration? timeout;
  final String? duplicateKey; // For duplicate prevention
  final Duration? duplicateWindow; // Time window for duplicate prevention

  const NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    this.actions,
    this.payload,
    this.category,
    this.badgeNumber,
    this.timeout,
    this.duplicateKey,
    this.duplicateWindow,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'actions': actions?.map((a) => a.toJson()).toList(),
        'payload': payload?.toJson(),
        'category': category,
        'badgeNumber': badgeNumber,
        'timeout': timeout?.inSeconds,
        'duplicateKey': duplicateKey,
        'duplicateWindow': duplicateWindow?.inSeconds,
      };
}

/// Represents a scheduled notification
class ScheduledNotification {
  final String id;
  final NotificationRequest request;
  final DateTime scheduledDate;
  final bool isRepeating;
  final Duration? repeatInterval;

  const ScheduledNotification({
    required this.id,
    required this.request,
    required this.scheduledDate,
    this.isRepeating = false,
    this.repeatInterval,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'scheduledDate': scheduledDate.millisecondsSinceEpoch,
        'isRepeating': isRepeating,
        'repeatInterval': repeatInterval?.inSeconds,
      };
}

/// Main notification manager class
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  /// Stream controller for notification action events
  final StreamController<NotificationActionEvent> _actionController =
      StreamController<NotificationActionEvent>.broadcast();

  /// Stream controller for notification tap events
  final StreamController<NotificationTapEvent> _tapController =
      StreamController<NotificationTapEvent>.broadcast();

  /// Stream for notification action events
  Stream<NotificationActionEvent> get onNotificationAction => _actionController.stream;

  /// Stream for notification tap events
  Stream<NotificationTapEvent> get onNotificationTap => _tapController.stream;

  /// Initialize the notification manager
  Future<bool> initialize() async {
    return await NotificationManagerPlatform.instance.initialize();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await NotificationManagerPlatform.instance.requestPermissions();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await NotificationManagerPlatform.instance.areNotificationsEnabled();
  }

  /// Show a notification immediately
  Future<bool> showNotification(NotificationRequest request) async {
    try {
      // Validate request
      if (request.id.isEmpty || request.title.isEmpty || request.body.isEmpty) {
        return false;
      }
      
      return await NotificationManagerPlatform.instance.showNotification(request);
    } catch (e) {
      return false;
    }
  }

  /// Schedule a notification for later
  Future<bool> scheduleNotification({
    required NotificationRequest request,
    required DateTime scheduledDate,
    bool isRepeating = false,
    Duration? repeatInterval,
  }) async {
    try {
      // Validate request
      if (request.id.isEmpty || request.title.isEmpty || request.body.isEmpty) {
        return false;
      }
      
      // Validate scheduled date
      if (scheduledDate.isBefore(DateTime.now())) {
        return false;
      }
      
      // Validate repeat interval for repeating notifications
      if (isRepeating && (repeatInterval == null || repeatInterval.inSeconds <= 0)) {
        return false;
      }
      
      final scheduledNotification = ScheduledNotification(
        id: request.id,
        request: request,
        scheduledDate: scheduledDate,
        isRepeating: isRepeating,
        repeatInterval: repeatInterval,
      );
      return await NotificationManagerPlatform.instance.scheduleNotification(scheduledNotification);
    } catch (e) {
      return false;
    }
  }

  /// Get all scheduled notifications
  Future<List<ScheduledNotification>> getScheduledNotifications() async {
    final dynamicList = await NotificationManagerPlatform.instance.getScheduledNotifications();
    return dynamicList.map((dynamic item) {
      if (item is Map<String, dynamic>) {
        try {
          // Convert the dynamic map to ScheduledNotification
          final requestData = item['request'] as Map<String, dynamic>;
          final request = NotificationRequest(
            id: requestData['id'] as String,
            title: requestData['title'] as String,
            body: requestData['body'] as String,
            actions: (requestData['actions'] as List<dynamic>?)?.map((action) => NotificationAction(
              id: action['id'] as String,
              title: action['title'] as String,
              isDestructive: action['isDestructive'] as bool? ?? false,
              requiresAuthentication: action['requiresAuthentication'] as bool? ?? false,
            )).toList(),
            payload: requestData['payload'] != null ? NotificationPayload(
              route: requestData['payload']['route'] as String?,
              data: requestData['payload']['data'] as Map<String, dynamic>?,
            ) : null,
            category: requestData['category'] as String?,
            badgeNumber: requestData['badgeNumber'] as int?,
            timeout: requestData['timeout'] != null ? Duration(seconds: requestData['timeout'] as int) : null,
            duplicateKey: requestData['duplicateKey'] as String?,
            duplicateWindow: requestData['duplicateWindow'] != null ? Duration(seconds: requestData['duplicateWindow'] as int) : null,
          );
          
          return ScheduledNotification(
            id: item['id'] as String,
            request: request,
            scheduledDate: DateTime.fromMillisecondsSinceEpoch(item['scheduledDate'] as int),
            isRepeating: item['isRepeating'] as bool? ?? false,
            repeatInterval: item['repeatInterval'] != null ? Duration(seconds: item['repeatInterval'] as int) : null,
          );
        } catch (e) {
          // Skip invalid notifications instead of throwing
          return null;
        }
      }
      return null;
    }).whereType<ScheduledNotification>().toList();
  }

  /// Update a scheduled notification
  Future<bool> updateScheduledNotification(ScheduledNotification notification) async {
    return await NotificationManagerPlatform.instance.updateScheduledNotification(notification);
  }

  /// Cancel a specific notification
  Future<bool> cancelNotification(String id) async {
    return await NotificationManagerPlatform.instance.cancelNotification(id);
  }

  /// Cancel a scheduled notification
  Future<bool> cancelScheduledNotification(String id) async {
    return await NotificationManagerPlatform.instance.cancelScheduledNotification(id);
  }

  /// Cancel all notifications
  Future<bool> cancelAllNotifications() async {
    return await NotificationManagerPlatform.instance.cancelAllNotifications();
  }

  /// Cancel all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() async {
    return await NotificationManagerPlatform.instance.cancelAllScheduledNotifications();
  }

  /// Get the current badge count
  Future<int> getBadgeCount() async {
    return await NotificationManagerPlatform.instance.getBadgeCount();
  }

  /// Set the badge count
  Future<bool> setBadgeCount(int count) async {
    return await NotificationManagerPlatform.instance.setBadgeCount(count);
  }

  /// Clear the badge count
  Future<bool> clearBadgeCount() async {
    return await NotificationManagerPlatform.instance.clearBadgeCount();
  }

  /// Check if a notification with the same duplicate key exists within the time window
  Future<bool> isDuplicateNotification(String duplicateKey, {Duration? timeWindow}) async {
    try {
      if (duplicateKey.isEmpty) {
        return false;
      }
      return await NotificationManagerPlatform.instance.isDuplicateNotification(duplicateKey, timeWindow);
    } catch (e) {
      return false;
    }
  }

  /// Clear notification history/stack
  Future<bool> clearNotificationHistory() async {
    return await NotificationManagerPlatform.instance.clearNotificationHistory();
  }



  /// Dispose resources
  void dispose() {
    _actionController.close();
    _tapController.close();
  }
}

/// Event fired when a notification action is triggered
class NotificationActionEvent {
  final String notificationId;
  final String actionId;

  const NotificationActionEvent({
    required this.notificationId,
    required this.actionId,
  });
}

/// Event fired when a notification is tapped
class NotificationTapEvent {
  final String notificationId;
  final NotificationPayload? payload;

  const NotificationTapEvent({
    required this.notificationId,
    this.payload,
  });
}
