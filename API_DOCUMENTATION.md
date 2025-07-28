# Flutter System Notifications API Documentation

A high-quality, cross-platform Flutter plugin for managing system-level local notifications with advanced features like scheduling, action buttons, and deep linking.

**Version**: 1.1.0  
**Platforms**: iOS, Android, macOS, Linux, Windows  
**License**: MIT

## Table of Contents
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
- [Data Models](#data-models)
- [Examples](#examples)
- [Platform Support](#platform-support)
- [Advanced Features](#advanced-features)
- [Error Handling](#error-handling)
- [Migration Guide](#migration-guide)

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_system_notifications: ^1.1.0
```

Then run:
```bash
flutter pub get
```

### Platform-Specific Setup

#### iOS
Add the following to your `ios/Runner/Info.plist`:
```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app uses notifications to keep you updated.</string>
```

#### Android
Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

## Quick Start

```dart
import 'package:flutter_system_notifications/flutter_system_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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

The main class for managing system notifications across all platforms.

#### Core Methods

##### `initialize()`
Initializes the notification manager. Must be called before using any other methods.
```dart
Future<bool> initialize()
```
**Returns**: `true` if initialization was successful, `false` otherwise.

##### `requestPermissions()`
Requests notification permissions from the user. Required on iOS and recommended on Android.
```dart
Future<bool> requestPermissions()
```
**Returns**: `true` if permissions were granted, `false` otherwise.

##### `areNotificationsEnabled()`
Checks if notifications are enabled for the app.
```dart
Future<bool> areNotificationsEnabled()
```
**Returns**: `true` if notifications are enabled, `false` otherwise.

#### Notification Methods

##### `showNotification(NotificationRequest request)`
Shows an immediate notification.
```dart
Future<bool> showNotification(NotificationRequest request)
```
**Parameters**:
- `request`: The notification request containing all notification details
**Returns**: `true` if notification was shown successfully, `false` otherwise.

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
**Parameters**:
- `request`: The notification request
- `scheduledDate`: When to show the notification
- `isRepeating`: Whether the notification should repeat
- `repeatInterval`: How often to repeat (if `isRepeating` is true)
**Returns**: `true` if notification was scheduled successfully, `false` otherwise.

#### Management Methods

##### `cancelNotification(String notificationId)`
Cancels a specific notification.
```dart
Future<bool> cancelNotification(String notificationId)
```
**Parameters**:
- `notificationId`: The ID of the notification to cancel
**Returns**: `true` if notification was cancelled successfully, `false` otherwise.

##### `cancelAllNotifications()`
Cancels all active notifications.
```dart
Future<bool> cancelAllNotifications()
```
**Returns**: `true` if all notifications were cancelled successfully, `false` otherwise.

##### `cancelAllScheduledNotifications()`
Cancels all scheduled notifications.
```dart
Future<bool> cancelAllScheduledNotifications()
```
**Returns**: `true` if all scheduled notifications were cancelled successfully, `false` otherwise.

##### `getScheduledNotifications()`
Retrieves all scheduled notifications.
```dart
Future<List<ScheduledNotification>> getScheduledNotifications()
```
**Returns**: List of all scheduled notifications.

#### Badge Management

##### `setBadgeCount(int count)`
Sets the app badge count.
```dart
Future<bool> setBadgeCount(int count)
```
**Parameters**:
- `count`: The badge count to set
**Returns**: `true` if badge count was set successfully, `false` otherwise.

##### `clearBadgeCount()`
Clears the app badge count.
```dart
Future<bool> clearBadgeCount()
```
**Returns**: `true` if badge count was cleared successfully, `false` otherwise.

##### `getBadgeCount()`
Gets the current badge count.
```dart
Future<int> getBadgeCount()
```
**Returns**: The current badge count.

## Data Models

### NotificationRequest

Represents a notification to be shown or scheduled.

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

**Properties**:
- `id`: Unique identifier for the notification
- `title`: The notification title
- `body`: The notification body text
- `actions`: Optional list of action buttons
- `payload`: Optional payload for deep linking
- `category`: Optional notification category (iOS)
- `badgeNumber`: Optional badge number to display
- `timeout`: Optional auto-dismiss timeout
- `duplicateKey`: Optional key for duplicate prevention
- `duplicateWindow`: Optional time window for duplicate prevention

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

**Properties**:
- `id`: Unique identifier for the action
- `title`: Display text for the action button
- `isDestructive`: Whether this is a destructive action (red styling)
- `requiresAuthentication`: Whether authentication is required

### NotificationPayload

Represents payload data for deep linking.

```dart
class NotificationPayload {
  final String? route;                // Navigation route
  final Map<String, dynamic>? data;   // Additional data
}
```

**Properties**:
- `route`: Optional navigation route
- `data`: Optional additional data for the route

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

**Properties**:
- `id`: Unique identifier for the scheduled notification
- `request`: The notification request
- `scheduledDate`: When the notification is scheduled to appear
- `isRepeating`: Whether this notification repeats
- `repeatInterval`: How often it repeats (if repeating)

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
        isDestructive: false,
        requiresAuthentication: false,
      ),
      NotificationAction(
        id: 'dismiss',
        title: 'Dismiss',
        isDestructive: true,
        requiresAuthentication: false,
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
print('Current badge count: $count');

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
      data: {
        'featureId': '123',
        'category': 'premium',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
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

### Notification with Category and Badge

```dart
await notificationManager.showNotification(
  NotificationRequest(
    id: 'categorized_notification',
    title: 'New Message',
    body: 'You have 3 new messages',
    category: 'message',
    badgeNumber: 3,
    timeout: Duration(seconds: 10),
  ),
);
```

### Complex Scheduled Notification

```dart
await notificationManager.scheduleNotification(
  request: NotificationRequest(
    id: 'complex_scheduled',
    title: 'Weekly Report',
    body: 'Your weekly report is ready',
    actions: [
      NotificationAction(
        id: 'view_report',
        title: 'View Report',
      ),
      NotificationAction(
        id: 'share_report',
        title: 'Share',
      ),
    ],
    payload: NotificationPayload(
      route: '/reports/weekly',
      data: {'reportId': 'weekly_2024_01'},
    ),
    category: 'report',
    badgeNumber: 1,
  ),
  scheduledDate: DateTime.now().add(Duration(days: 7)),
  isRepeating: true,
  repeatInterval: Duration(days: 7),
);
```

## Platform Support

| Platform | Status | Features |
|----------|--------|----------|
| **iOS** | ✅ Full Support | Native notifications, actions, scheduling, badges |
| **Android** | ✅ Full Support | WorkManager scheduling, actions, badges, boot restoration |
| **macOS** | ✅ Full Support | Native notifications, actions, scheduling |
| **Linux** | ⚠️ Basic Support | Basic notifications |
| **Windows** | ⚠️ Basic Support | Basic notifications |

### Platform-Specific Features

#### iOS
- Native notification center integration
- Action buttons (up to 4 per notification)
- Notification categories
- Badge management
- Background processing limitations

#### Android
- WorkManager for reliable scheduling
- Notification channels (Android 8+)
- Boot receiver for notification restoration
- Background processing restrictions
- Rich notification support

#### macOS
- Native notification center
- Action buttons
- Notification categories
- Badge management

## Advanced Features

### 🔔 Immediate Notifications
Show notifications instantly with rich content and actions.

### ⏰ Scheduled Notifications
Schedule notifications for future delivery with precise timing.

### 🔄 Repeating Notifications
Set up recurring notifications with custom intervals.

### 🎯 Action Buttons
Add interactive buttons to notifications for user engagement.

### 🔗 Deep Linking
Navigate to specific app screens when notifications are tapped.

### 🔢 Badge Management
Control app badge counts for better user experience.

### 🚫 Duplicate Prevention
Prevent duplicate notifications within specified time windows.

### 📱 Cross-Platform Compatibility
Unified API that works seamlessly across all supported platforms.

### 🔒 Permission Handling
Automatic permission requests with proper error handling.

### 🎨 Rich Customization
Extensive customization options for notifications.

## What's New in Version 1.1.0

### 🚀 Major Improvements
- **Enhanced Type Safety**: Improved `fromJson` methods for better data handling
- **iOS Build Fixes**: Resolved podspec configuration issues
- **Plugin Rename**: Updated from `notification_manager` to `flutter_system_notifications`
- **Better Error Handling**: More robust error handling across all platforms
- **Comprehensive Documentation**: Complete API documentation with examples

### 🔧 Technical Enhancements
- **Robust Data Models**: Enhanced type casting for better reliability
- **Platform Consistency**: Unified implementation across iOS, Android, macOS, Linux, and Windows
- **Improved Testing**: Better test coverage and type safety
- **Documentation Updates**: Enhanced Medium article with code formatting and emojis

### 🐛 Bug Fixes
- Fixed iOS build issues and podspec configuration
- Resolved type casting issues in data models
- Improved cross-platform compatibility
- Enhanced error handling for edge cases

## Error Handling

### Basic Error Handling

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

### Comprehensive Error Handling

```dart
Future<void> safeShowNotification(NotificationRequest request) async {
  try {
    final notificationManager = NotificationManager();
    await notificationManager.initialize();
    
    // Check permissions
    final hasPermission = await notificationManager.areNotificationsEnabled();
    if (!hasPermission) {
      final granted = await notificationManager.requestPermissions();
      if (!granted) {
        throw Exception('Notification permission denied');
      }
    }
    
    // Show notification
    final success = await notificationManager.showNotification(request);
    if (!success) {
      throw Exception('Failed to show notification');
    }
    
    print('Notification sent successfully');
  } catch (e) {
    print('Error showing notification: $e');
    // Handle error appropriately (show user message, retry, etc.)
  }
}
```

### Platform-Specific Error Handling

```dart
import 'dart:io';

Future<void> platformSpecificNotification() async {
  final notificationManager = NotificationManager();
  
  try {
    if (Platform.isIOS) {
      // iOS-specific error handling
      final hasPermission = await notificationManager.requestPermissions();
      if (!hasPermission) {
        print('iOS notification permission denied');
        return;
      }
    } else if (Platform.isAndroid) {
      // Android-specific error handling
      final enabled = await notificationManager.areNotificationsEnabled();
      if (!enabled) {
        print('Android notifications are disabled');
        return;
      }
    }
    
    await notificationManager.showNotification(request);
  } catch (e) {
    print('Platform-specific error: $e');
  }
}
```

## Migration Guide

### From Other Notification Plugins

If you're migrating from other notification plugins, here are the key differences:

#### Old Plugin Pattern
```dart
// Old way (example)
await FlutterLocalNotificationsPlugin().show(
  0,
  'Title',
  'Body',
  null,
);
```

#### New Plugin Pattern
```dart
// New way
final notificationManager = NotificationManager();
await notificationManager.initialize();

await notificationManager.showNotification(
  NotificationRequest(
    id: 'unique_id',
    title: 'Title',
    body: 'Body',
  ),
);
```

### Key Migration Points

1. **Initialization**: Always call `initialize()` first
2. **Request Object**: Use `NotificationRequest` instead of separate parameters
3. **Error Handling**: Implement proper error handling for all operations
4. **Permissions**: Request permissions explicitly on iOS
5. **Type Safety**: All methods are strongly typed for better reliability

### Migration Checklist

- [ ] Replace plugin import
- [ ] Add initialization call
- [ ] Convert notification calls to use `NotificationRequest`
- [ ] Update error handling
- [ ] Test on all target platforms
- [ ] Update any custom notification handling

## Best Practices

### 1. Always Initialize
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final notificationManager = NotificationManager();
  await notificationManager.initialize();
  
  runApp(MyApp());
}
```

### 2. Request Permissions Early
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }
  
  Future<void> _requestPermissions() async {
    final manager = NotificationManager();
    await manager.initialize();
    await manager.requestPermissions();
  }
}
```

### 3. Use Unique IDs
```dart
// Good: Unique IDs
await notificationManager.showNotification(
  NotificationRequest(
    id: 'message_${DateTime.now().millisecondsSinceEpoch}',
    title: 'New Message',
    body: 'You have a new message',
  ),
);

// Bad: Non-unique IDs
await notificationManager.showNotification(
  NotificationRequest(
    id: 'message', // This could conflict
    title: 'New Message',
    body: 'You have a new message',
  ),
);
```

### 4. Handle Platform Differences
```dart
import 'dart:io';

Future<void> showPlatformSpecificNotification() async {
  final manager = NotificationManager();
  
  if (Platform.isIOS) {
    // iOS-specific notification
    await manager.showNotification(
      NotificationRequest(
        id: 'ios_notification',
        title: 'iOS Notification',
        body: 'This is optimized for iOS',
        category: 'ios_category',
      ),
    );
  } else if (Platform.isAndroid) {
    // Android-specific notification
    await manager.showNotification(
      NotificationRequest(
        id: 'android_notification',
        title: 'Android Notification',
        body: 'This is optimized for Android',
        category: 'android_category',
      ),
    );
  }
}
```

### 5. Implement Proper Error Handling
```dart
Future<void> safeShowNotification(NotificationRequest request) async {
  try {
    final manager = NotificationManager();
    await manager.initialize();
    
    final hasPermission = await manager.areNotificationsEnabled();
    if (!hasPermission) {
      final granted = await manager.requestPermissions();
      if (!granted) {
        throw Exception('Notification permission denied');
      }
    }
    
    final success = await manager.showNotification(request);
    if (!success) {
      throw Exception('Failed to show notification');
    }
  } catch (e) {
    print('Error showing notification: $e');
    // Handle error appropriately
  }
}
```

## Troubleshooting

### Common Issues

1. **iOS Build Errors**
   - Ensure podspec file is properly configured
   - Check that all iOS files are in the correct locations
   - Verify permission settings in Info.plist

2. **Android Build Errors**
   - Check that all Android files are in the correct package structure
   - Verify WorkManager dependencies are included
   - Ensure notification channels are created

3. **Permission Issues**
   - Always request permissions before showing notifications
   - Handle permission denial gracefully
   - Provide user guidance for enabling notifications

4. **Scheduling Issues**
   - Test on real devices (simulators may not work properly)
   - Verify scheduled notifications work after device reboot
   - Check platform-specific scheduling limitations

### Debug Tips

1. **Enable Debug Logging**
   ```dart
   // Add debug prints to track issues
   print('Initializing notification manager...');
   final result = await notificationManager.initialize();
   print('Initialization result: $result');
   ```

2. **Test on Real Devices**
   - Simulators may not show all notification features
   - Test background notifications on physical devices
   - Verify scheduling works after device restart

3. **Platform-Specific Testing**
   - Test on each target platform
   - Verify permissions work correctly
   - Check notification appearance and behavior

## Support

- **GitHub Repository**: https://github.com/abubakarsani-raven/flutter_system_notifications
- **Pub.dev Package**: https://pub.dev/packages/flutter_system_notifications
- **Issues**: Report bugs and feature requests on GitHub
- **Documentation**: This API documentation and README

## License

This plugin is licensed under the MIT License. See the LICENSE file for details.

---

*This documentation covers version 1.1.0 of the Flutter System Notifications plugin. For the latest updates and examples, visit the GitHub repository.* 