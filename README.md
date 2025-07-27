# flutter_system_notifications

A high-quality, cross-platform Flutter plugin for managing system-level local notifications with advanced features like scheduling, action buttons, and deep linking.

## 📚 Documentation & Resources

- 📖 **[Medium Article](https://medium.com/@abubakarbabaganasani/building-a-cross-platform-notification-in-flutter-7fd2b4caf532)** - Complete guide with examples
- 📦 **[pub.dev Package](https://pub.dev/packages/flutter_system_notifications)** - Download and install
- 📚 **[GitHub Repository](https://github.com/abubakarsani-raven/flutter_system_notifications)** - Source code and issues
- 📧 **Contact**: abubakarbabaganasani@gmail.com

## ✨ Features

- 🔔 **System-wide notifications** - Not just in-app badges
- ⏰ **Scheduled notifications** - Future and repeating notifications
- 🎯 **Action buttons** - Custom actions with callbacks
- 🔗 **Deep linking** - Open specific screens with payload
- 🏷️ **Badge management** - Set, get, and clear badge counts
- 🚫 **Duplicate prevention** - Prevent duplicate notifications
- 📱 **Cross-platform** - Android, iOS, macOS, Windows, Linux
- 🔄 **Background processing** - Notifications persist after app restart
- 🎨 **Modern UI** - Clean, professional interface

## 🚀 Installation

Add `flutter_system_notifications` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_system_notifications: ^1.0.2
```

Run:
```bash
flutter pub get
```

## ⚡ Quick Start

### 1. Initialize the Plugin

```dart
import 'package:flutter_system_notifications/flutter_system_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the notification manager
  await NotificationManager().initialize();
  
  runApp(MyApp());
}
```

### 2. Request Permissions

```dart
final notificationManager = NotificationManager();

// Request notification permissions
final hasPermission = await notificationManager.requestPermissions();
if (hasPermission) {
  print('Notifications enabled!');
} else {
  print('Notifications disabled');
}
```

### 3. Show a Simple Notification

```dart
final request = NotificationRequest(
  id: 'simple_notification',
  title: 'Hello!',
  body: 'This is a simple notification.',
);

final success = await notificationManager.showNotification(request);
```

### 4. Handle Notification Events

```dart
// Listen for notification taps
notificationManager.onNotificationTap.listen((event) {
  print('Notification tapped: ${event.notificationId}');
  print('Payload: ${event.payload}');
});

// Listen for action button taps
notificationManager.onNotificationAction.listen((event) {
  print('Action tapped: ${event.actionId}');
});
```

## 🔧 Platform Setup

### Android

No additional setup required! The plugin automatically handles:
- ✅ Notification channels
- ✅ Permission requests (Android 13+)
- ✅ Background processing
- ✅ Boot restoration

### iOS

Add to your `ios/Runner/Info.plist`:

```xml
<key>NSUserNotificationUsageDescription</key>
<string>This app needs notification permission to show you important updates.</string>
```

### macOS

Add to your `macos/Runner/Info.plist`:

```xml
<key>NSUserNotificationAlertStyle</key>
<string>alert</string>
<key>NSUserNotificationUsageDescription</key>
<string>This app needs notification permission to show you important updates.</string>
```

### Windows

No additional setup required! The plugin uses WinRT Toast Notifications.

### Linux

Install required dependencies:

```bash
# Ubuntu/Debian
sudo apt-get install libnotify4 libjson-glib-dev

# Fedora/RHEL
sudo dnf install libnotify json-glib-devel

# Arch Linux
sudo pacman -S libnotify json-glib
```

## 📚 API Reference

### Core Methods

#### `initialize()`
Initialize the notification manager.

```dart
await NotificationManager().initialize();
```

#### `requestPermissions()`
Request notification permissions.

```dart
final hasPermission = await notificationManager.requestPermissions();
```

#### `showNotification(NotificationRequest request)`
Show a notification immediately.

```dart
final request = NotificationRequest(
  id: 'unique_id',
  title: 'Notification Title',
  body: 'Notification body text',
  actions: [
    NotificationAction(id: 'action1', title: 'Action 1'),
    NotificationAction(id: 'action2', title: 'Action 2'),
  ],
  payload: NotificationPayload(
    route: '/profile',
    data: {'userId': '123'},
  ),
);

final success = await notificationManager.showNotification(request);
```

#### `scheduleNotification()`
Schedule a notification for the future.

```dart
final scheduledDate = DateTime.now().add(Duration(minutes: 5));

final success = await notificationManager.scheduleNotification(
  request: request,
  scheduledDate: scheduledDate,
  isRepeating: true,
  repeatInterval: Duration(minutes: 1),
);
```

### Data Models

#### `NotificationRequest`
```dart
class NotificationRequest {
  final String id;
  final String title;
  final String body;
  final List<NotificationAction>? actions;
  final NotificationPayload? payload;
  final int? badgeNumber;
  final String? category;
  final String? duplicateKey;
  final Duration? duplicateWindow;
  final Duration? timeout;
}
```

#### `NotificationAction`
```dart
class NotificationAction {
  final String id;
  final String title;
  final bool isDestructive;
  final bool requiresAuthentication;
}
```

#### `NotificationPayload`
```dart
class NotificationPayload {
  final String? route;
  final Map<String, dynamic>? data;
}
```

### Event Streams

#### `onNotificationTap`
```dart
notificationManager.onNotificationTap.listen((event) {
  print('Notification ID: ${event.notificationId}');
  print('Payload: ${event.payload}');
});
```

#### `onNotificationAction`
```dart
notificationManager.onNotificationAction.listen((event) {
  print('Notification ID: ${event.notificationId}');
  print('Action ID: ${event.actionId}');
});
```

## 💡 Usage Examples

### Simple Notification
```dart
final request = NotificationRequest(
  id: 'simple_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Simple Notification',
  body: 'This is a simple notification without actions.',
);

await notificationManager.showNotification(request);
```

### Notification with Actions
```dart
final request = NotificationRequest(
  id: 'actions_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Notification with Actions',
  body: 'Tap an action button below.',
  actions: [
    NotificationAction(id: 'accept', title: 'Accept'),
    NotificationAction(id: 'decline', title: 'Decline', isDestructive: true),
  ],
);

await notificationManager.showNotification(request);
```

### Notification with Payload
```dart
final request = NotificationRequest(
  id: 'payload_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Deep Link Notification',
  body: 'Tap to open a specific screen.',
  payload: NotificationPayload(
    route: '/profile',
    data: {'userId': '123', 'action': 'view_profile'},
  ),
);

await notificationManager.showNotification(request);
```

### Scheduled Notification
```dart
final request = NotificationRequest(
  id: 'scheduled_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Scheduled Notification',
  body: 'This notification was scheduled for later.',
);

final scheduledDate = DateTime.now().add(Duration(minutes: 5));

await notificationManager.scheduleNotification(
  request: request,
  scheduledDate: scheduledDate,
);
```

### Repeating Notification
```dart
final request = NotificationRequest(
  id: 'repeating_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Repeating Notification',
  body: 'This notification repeats every minute.',
);

final scheduledDate = DateTime.now().add(Duration(seconds: 10));

await notificationManager.scheduleNotification(
  request: request,
  scheduledDate: scheduledDate,
  isRepeating: true,
  repeatInterval: Duration(minutes: 1),
);
```

### Badge Management
```dart
// Set badge count
await notificationManager.setBadgeCount(5);

// Get current badge count
final count = await notificationManager.getBadgeCount();

// Clear badge
await notificationManager.clearBadgeCount();
```

### Duplicate Prevention
```dart
final request = NotificationRequest(
  id: 'duplicate_${DateTime.now().millisecondsSinceEpoch}',
  title: 'Duplicate Prevention',
  body: 'This notification has duplicate prevention enabled.',
  duplicateKey: 'unique_message_key',
  duplicateWindow: Duration(minutes: 5),
);

await notificationManager.showNotification(request);
```

## 🔧 Advanced Features

### Notification Badge Widget
```dart
import 'package:notification_manager/notification_badge.dart';

NotificationBadge(
  count: 5,
  child: Icon(Icons.notifications),
)
```

### Check for Duplicates
```dart
final isDuplicate = await notificationManager.isDuplicateNotification(
  'unique_key',
  timeWindow: Duration(minutes: 5),
);
```

### Get Scheduled Notifications
```dart
final scheduled = await notificationManager.getScheduledNotifications();
for (final notification in scheduled) {
  print('Scheduled: ${notification.request.title} at ${notification.scheduledDate}');
}
```

### Cancel Notifications
```dart
// Cancel specific notification
await notificationManager.cancelNotification('notification_id');

// Cancel all notifications
await notificationManager.cancelAllNotifications();

// Cancel scheduled notification
await notificationManager.cancelScheduledNotification('scheduled_id');

// Cancel all scheduled notifications
await notificationManager.cancelAllScheduledNotifications();
```

## 🛠️ Troubleshooting

### Common Issues

#### Notifications not showing on Android
1. **Check permissions**: Ensure `POST_NOTIFICATIONS` permission is granted
2. **Check notification channel**: Verify channel importance is set correctly
3. **Check app state**: Notifications work even when app is closed

#### Notifications not showing on iOS
1. **Check permissions**: Request notification permissions explicitly
2. **Check app state**: iOS may limit background notifications
3. **Check notification settings**: Verify in iOS Settings > Notifications

#### Build errors
1. **Clean and rebuild**: `flutter clean && flutter pub get`
2. **Check platform setup**: Ensure all platform-specific setup is complete
3. **Check dependencies**: Verify all required dependencies are installed

### Debug Tips

```dart
// Enable debug logging
final notificationManager = NotificationManager();
await notificationManager.initialize();

// Check notification status
final enabled = await notificationManager.areNotificationsEnabled();
print('Notifications enabled: $enabled');

// Check badge count
final badgeCount = await notificationManager.getBadgeCount();
print('Badge count: $badgeCount');
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Run tests: `flutter test`
4. Run example: `flutter run -d <device>`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent plugin architecture
- Android WorkManager for background processing
- iOS UNUserNotificationCenter for notification management
- Windows WinRT for toast notifications
- Linux libnotify for system notifications

## 📞 Support

- 📧 Email: abubakarbabaganasani@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/abubakarsani-raven/flutter_system_notifications/issues)
- 📖 Documentation: [API Docs](https://pub.dev/documentation/flutter_system_notifications)
- 📝 Blog Post: [Medium Article](https://medium.com/@abubakarbabaganasani/building-a-cross-platform-notification-in-flutter-7fd2b4caf532)

## 🌟 Show Your Support

If this plugin helps you, please consider:
- ⭐ **Star the repository** on [GitHub](https://github.com/abubakarsani-raven/flutter_system_notifications)
- 📝 **Write a review** on [pub.dev](https://pub.dev/packages/flutter_system_notifications)
- 🐛 **Report issues** or suggest features
- 💬 **Share** with other Flutter developers

---

**Made with ❤️ for the Flutter community**

**Author**: Abubakar Sani - abubakarbabaganasani@gmail.com

