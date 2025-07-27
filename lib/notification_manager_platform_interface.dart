import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'notification_manager_method_channel.dart';

abstract class NotificationManagerPlatform extends PlatformInterface {
  /// Constructs a NotificationManagerPlatform.
  NotificationManagerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NotificationManagerPlatform _instance = MethodChannelNotificationManager();

  /// The default instance of [NotificationManagerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNotificationManager].
  static NotificationManagerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NotificationManagerPlatform] when
  /// they register themselves.
  static set instance(NotificationManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initialize the notification manager
  Future<bool> initialize() {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() {
    throw UnimplementedError('areNotificationsEnabled() has not been implemented.');
  }

  /// Show a notification
  Future<bool> showNotification(dynamic request) {
    throw UnimplementedError('showNotification() has not been implemented.');
  }

  /// Schedule a notification
  Future<bool> scheduleNotification(dynamic scheduledNotification) {
    throw UnimplementedError('scheduleNotification() has not been implemented.');
  }

  /// Get all scheduled notifications
  Future<List<dynamic>> getScheduledNotifications() {
    throw UnimplementedError('getScheduledNotifications() has not been implemented.');
  }

  /// Update a scheduled notification
  Future<bool> updateScheduledNotification(dynamic notification) {
    throw UnimplementedError('updateScheduledNotification() has not been implemented.');
  }

  /// Cancel a specific notification
  Future<bool> cancelNotification(String id) {
    throw UnimplementedError('cancelNotification() has not been implemented.');
  }

  /// Cancel a scheduled notification
  Future<bool> cancelScheduledNotification(String id) {
    throw UnimplementedError('cancelScheduledNotification() has not been implemented.');
  }

  /// Cancel all notifications
  Future<bool> cancelAllNotifications() {
    throw UnimplementedError('cancelAllNotifications() has not been implemented.');
  }

  /// Cancel all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() {
    throw UnimplementedError('cancelAllScheduledNotifications() has not been implemented.');
  }

  /// Get the current badge count
  Future<int> getBadgeCount() {
    throw UnimplementedError('getBadgeCount() has not been implemented.');
  }

  /// Set the badge count
  Future<bool> setBadgeCount(int count) {
    throw UnimplementedError('setBadgeCount() has not been implemented.');
  }

  /// Clear the badge count
  Future<bool> clearBadgeCount() {
    throw UnimplementedError('clearBadgeCount() has not been implemented.');
  }

  /// Check if a notification with the same duplicate key exists
  Future<bool> isDuplicateNotification(String duplicateKey, Duration? timeWindow) {
    throw UnimplementedError('isDuplicateNotification() has not been implemented.');
  }

  /// Clear notification history/stack
  Future<bool> clearNotificationHistory() {
    throw UnimplementedError('clearNotificationHistory() has not been implemented.');
  }
}
