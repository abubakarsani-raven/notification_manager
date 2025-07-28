import 'dart:async';

import 'flutter_system_notifications_platform_interface.dart';

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

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      id: json['id'] as String,
      title: json['title'] as String,
      isDestructive: json['isDestructive'] as bool? ?? false,
      requiresAuthentication: json['requiresAuthentication'] as bool? ?? false,
    );
  }
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

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      route: json['route'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
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

  factory NotificationRequest.fromJson(Map<String, dynamic> json) {
    return NotificationRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      actions: json['actions'] != null 
          ? (json['actions'] as List).map((a) => NotificationAction.fromJson(a as Map<String, dynamic>)).toList()
          : null,
      payload: json['payload'] != null 
          ? NotificationPayload.fromJson(json['payload'] as Map<String, dynamic>)
          : null,
      category: json['category'] as String?,
      badgeNumber: json['badgeNumber'] as int?,
      timeout: json['timeout'] != null 
          ? Duration(seconds: json['timeout'] as int)
          : null,
      duplicateKey: json['duplicateKey'] as String?,
      duplicateWindow: json['duplicateWindow'] != null 
          ? Duration(seconds: json['duplicateWindow'] as int)
          : null,
    );
  }
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

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    // Handle the request field which might be Map<Object?, Object?> from tests
    Map<String, dynamic> requestMap;
    final requestData = json['request'];
    if (requestData is Map<String, dynamic>) {
      requestMap = requestData;
    } else if (requestData is Map<Object?, Object?>) {
      requestMap = Map<String, dynamic>.from(requestData);
    } else {
      throw ArgumentError('Expected Map for request but got ${requestData.runtimeType}');
    }
    
    return ScheduledNotification(
      id: json['id'] as String,
      request: NotificationRequest.fromJson(requestMap),
      scheduledDate: DateTime.fromMillisecondsSinceEpoch(json['scheduledDate'] as int),
      isRepeating: json['isRepeating'] as bool? ?? false,
      repeatInterval: json['repeatInterval'] != null 
          ? Duration(seconds: json['repeatInterval'] as int)
          : null,
    );
  }
}

/// Represents a notification action event
class NotificationActionEvent {
  final String notificationId;
  final String actionId;
  final Map<String, dynamic>? payload;

  const NotificationActionEvent({
    required this.notificationId,
    required this.actionId,
    this.payload,
  });

  factory NotificationActionEvent.fromJson(Map<String, dynamic> json) {
    return NotificationActionEvent(
      notificationId: json['notificationId'] as String,
      actionId: json['actionId'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

/// Represents a notification tap event
class NotificationTapEvent {
  final String notificationId;
  final Map<String, dynamic>? payload;

  const NotificationTapEvent({
    required this.notificationId,
    this.payload,
  });

  factory NotificationTapEvent.fromJson(Map<String, dynamic> json) {
    return NotificationTapEvent(
      notificationId: json['notificationId'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}

/// A high-quality, cross-platform Flutter plugin for managing system-level local notifications
/// with advanced features like scheduling, action buttons, and deep linking.
class NotificationManager {
  static FlutterSystemNotificationsPlatform get _platform => FlutterSystemNotificationsPlatform.instance;

  /// Initialize the notification manager
  Future<bool> initialize() async {
    return await _platform.initialize();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await _platform.requestPermissions();
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await _platform.areNotificationsEnabled();
  }

  /// Show a notification
  Future<bool> showNotification(NotificationRequest request) async {
    return await _platform.showNotification(request);
  }

  /// Schedule a notification
  Future<bool> scheduleNotification({
    required NotificationRequest request,
    required DateTime scheduledDate,
    bool isRepeating = false,
    Duration? repeatInterval,
  }) async {
    final scheduledNotification = ScheduledNotification(
      id: request.id,
      request: request,
      scheduledDate: scheduledDate,
      isRepeating: isRepeating,
      repeatInterval: repeatInterval,
    );
    return await _platform.scheduleNotification(scheduledNotification);
  }

  /// Cancel a specific notification
  Future<bool> cancelNotification(String notificationId) async {
    return await _platform.cancelNotification(notificationId);
  }

  /// Cancel all notifications
  Future<bool> cancelAllNotifications() async {
    return await _platform.cancelAllNotifications();
  }

  /// Cancel all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() async {
    return await _platform.cancelAllScheduledNotifications();
  }

  /// Get all scheduled notifications
  Future<List<ScheduledNotification>> getScheduledNotifications() async {
    final dynamic notifications = await _platform.getScheduledNotifications();
    return notifications.map((n) {
      // Handle both Map<String, dynamic> and Map<Object?, Object?> from tests
      Map<String, dynamic> notificationMap;
      if (n is Map<String, dynamic>) {
        notificationMap = n;
      } else if (n is Map<Object?, Object?>) {
        notificationMap = Map<String, dynamic>.from(n);
      } else {
        throw ArgumentError('Expected Map but got ${n.runtimeType}');
      }
      return ScheduledNotification.fromJson(notificationMap);
    }).toList();
  }

  /// Set the badge count
  Future<bool> setBadgeCount(int count) async {
    return await _platform.setBadgeCount(count);
  }

  /// Clear the badge count
  Future<bool> clearBadgeCount() async {
    return await _platform.clearBadgeCount();
  }

  /// Get the current badge count
  Future<int> getBadgeCount() async {
    return await _platform.getBadgeCount();
  }
} 