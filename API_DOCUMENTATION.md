# Flutter System Notifications API Documentation

A high-quality, cross-platform Flutter plugin for managing system-level local notifications with advanced features like scheduling, action buttons, and deep linking.

## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Data Models](#data-models)
- [Examples](#examples)
- [Platform Support](#platform-support)

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_system_notifications: ^1.0.3
```

## Quick Start

```dart
import 'package:flutter_system_notifications/flutter_system_notifications.dart';

void main() async {
  final notificationManager = NotificationManager();
  
  // Initialize the plugin
  await notificationManager.initialize();
  
  // Request permissions
  final hasPermission = await notificationManager.requestPermissions();
  
  if (hasPermission) {
    // Show a simple notification
    await notificationManager.showNotification(
      NotificationRequest(
        id: 'my_notification',
        title: 'Hello!',
        body: 'This is a test notification',
      ),
    );
  }
}
```

## API Reference

### NotificationManager Class

The main class for managing system notifications.

#### Methods

##### `initialize()`
Initializes the notification manager.
```dart
Future<bool> initialize()
```

##### `requestPermissions()`
Requests notification permissions from the user.
```dart
Future<bool> requestPermissions()
```

##### `areNotificationsEnabled()`
Checks if notifications are enabled for the app.
```dart
Future<bool> areNotificationsEnabled()
```

##### `showNotification(NotificationRequest request)`
Shows an immediate notification.
```dart
Future<bool> showNotification(NotificationRequest request)
```

##### `scheduleNotification()`
Schedules a notification for a specific time.
```dart
Future<bool> scheduleNotification({
  required NotificationRequest request,
  required DateTime scheduledDate,
  bool isRepeating = false,
  Duration? repeatInterval,
})
```

##### `cancelNotification(String notificationId)`
Cancels a specific notification.
```dart
Future<bool> cancelNotification(String notificationId)
```

##### `cancelAllNotifications()`
Cancels all active notifications.
```dart
Future<bool> cancelAllNotifications()
```

##### `cancelAllScheduledNotifications()`
Cancels all scheduled notifications.
```dart
Future<bool> cancelAllScheduledNotifications()
```

##### `getScheduledNotifications()`
Retrieves all scheduled notifications.
```dart
Future<List<ScheduledNotification>> getScheduledNotifications()
```

##### `setBadgeCount(int count)`
Sets the app badge count.
```dart
Future<bool> setBadgeCount(int count)
```

##### `clearBadgeCount()`
Clears the app badge count.
```dart
Future<bool> clearBadgeCount()
```

##### `getBadgeCount()`
Gets the current badge count.
```dart
Future<int> getBadgeCount()
```

## Data Models

### NotificationRequest

Represents a notification to be shown.

```dart
class NotificationRequest {
  final String id;                    // Unique identifier
  final String title;                 // Notification title
  final String body;                  // Notification body
  final List<NotificationAction>? actions;  // Action buttons
  final NotificationPayload? payload; // Deep link payload
  final String? category;             // Notification category
  final int? badgeNumber;             // Badge number
  final Duration? timeout;            // Auto-dismiss timeout
  final String? duplicateKey;         // Duplicate prevention key
  final Duration? duplicateWindow;    // Duplicate prevention window
}
```

### NotificationAction

Represents an action button for notifications.

```dart
class NotificationAction {
  final String id;                    // Action identifier
  final String title;                 // Action title
  final bool isDestructive;           // Destructive action styling
  final bool requiresAuthentication;   // Requires authentication
}
```

### NotificationPayload

Represents payload data for deep linking.

```dart
class NotificationPayload {
  final String? route;                // Navigation route
  final Map<String, dynamic>? data;   // Additional data
}
```

### ScheduledNotification

Represents a scheduled notification.

```dart
class ScheduledNotification {
  final String id;                    // Unique identifier
  final NotificationRequest request;   // Notification request
  final DateTime scheduledDate;       // Scheduled time
  final bool isRepeating;             // Is repeating notification
  final Duration? repeatInterval;     // Repeat interval
}
```

## Examples

### Basic Notification

```dart
final notificationManager = NotificationManager();
await notificationManager.initialize();

await notificationManager.showNotification(
  NotificationRequest(
    id: 'basic_notification',
    title: 'Welcome!',
    body: 'Thanks for using our app!',
  ),
);
```

### Notification with Actions

```dart
await notificationManager.showNotification(
  NotificationRequest(
    id: 'action_notification',
    title: 'New Message',
    body: 'You have a new message from John',
    actions: [
      NotificationAction(
        id: 'reply',
        title: 'Reply',
      ),
      NotificationAction(
        id: 'dismiss',
        title: 'Dismiss',
        isDestructive: true,
      ),
    ],
  ),
);
```

### Scheduled Notification

```dart
await notificationManager.scheduleNotification(
  request: NotificationRequest(
    id: 'reminder',
    title: 'Meeting Reminder',
    body: 'Your meeting starts in 15 minutes',
  ),
  scheduledDate: DateTime.now().add(Duration(minutes: 15)),
);
```

### Repeating Notification

```dart
await notificationManager.scheduleNotification(
  request: NotificationRequest(
    id: 'daily_reminder',
    title: 'Daily Check-in',
    body: 'Time for your daily check-in!',
  ),
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
  isRepeating: true,
  repeatInterval: Duration(days: 1),
);
```

### Badge Management

```dart
// Set badge count
await notificationManager.setBadgeCount(5);

// Get current badge count
final count = await notificationManager.getBadgeCount();

// Clear badge count
await notificationManager.clearBadgeCount();
```

### Deep Linking

```dart
await notificationManager.showNotification(
  NotificationRequest(
    id: 'deep_link_notification',
    title: 'New Feature',
    body: 'Check out our new feature!',
    payload: NotificationPayload(
      route: '/features/new-feature',
      data: {'featureId': '123'},
    ),
  ),
);
```

### Duplicate Prevention

```dart
await notificationManager.showNotification(
  NotificationRequest(
    id: 'unique_notification',
    title: 'Important Update',
    body: 'System update available',
    duplicateKey: 'system_update_2024',
    duplicateWindow: Duration(hours: 1),
  ),
);
```

## Platform Support

- ✅ **iOS**: Full support with native notifications
- ✅ **Android**: Full support with WorkManager for scheduling
- ✅ **macOS**: Full support with native notifications
- ✅ **Linux**: Basic support
- ✅ **Windows**: Basic support

## Features

- 🔔 **Immediate Notifications**: Show notifications instantly
- ⏰ **Scheduled Notifications**: Schedule notifications for future delivery
- 🔄 **Repeating Notifications**: Set up recurring notifications
- 🎯 **Action Buttons**: Add interactive buttons to notifications
- 🔗 **Deep Linking**: Navigate to specific app screens
- 🔢 **Badge Management**: Control app badge counts
- 🚫 **Duplicate Prevention**: Prevent duplicate notifications
- 📱 **Cross-Platform**: Works on iOS, Android, macOS, Linux, and Windows
- 🔒 **Permission Handling**: Automatic permission requests
- 🎨 **Customizable**: Rich customization options

## Best Practices

1. **Always initialize** the plugin before use
2. **Request permissions** early in your app lifecycle
3. **Use unique IDs** for notifications to avoid conflicts
4. **Handle errors** gracefully when notifications fail
5. **Test on multiple platforms** to ensure compatibility
6. **Use appropriate categories** for better organization
7. **Implement deep linking** for better user experience
8. **Clean up notifications** when they're no longer needed

## Error Handling

```dart
try {
  final success = await notificationManager.showNotification(request);
  if (success) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification');
  }
} catch (e) {
  print('Error sending notification: $e');
}
```

## Migration from Other Plugins

If you're migrating from other notification plugins, the API is designed to be intuitive and easy to adopt. The main differences are:

- Uses `NotificationRequest` instead of separate parameters
- Unified API across all platforms
- Better error handling and type safety
- More comprehensive feature set

For more information and examples, visit the [GitHub repository](https://github.com/abubakarsani-raven/flutter_system_notifications). 