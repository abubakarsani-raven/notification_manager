import 'package:flutter/material.dart';
import 'dart:async';

import 'package:notification_manager/notification_manager.dart';
import 'package:notification_manager/notification_badge.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationManager _notificationManager = NotificationManager();
  int _badgeCount = 0;
  String _statusMessage = 'Initializing...';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeNotificationManager();
      }
    });
  }

  Future<void> _initializeNotificationManager() async {
    try {
      setState(() {
        _statusMessage = 'Initializing notification manager...';
      });

      // Initialize the notification manager
      await _notificationManager.initialize();
      
      // Check current permission status
      final hasPermission = await _notificationManager.requestPermissions();
      
      // Set up event listeners
      _notificationManager.onNotificationAction.listen((event) {
        if (mounted) {
          setState(() {
            _statusMessage = '🎯 Action triggered: ${event.actionId}';
          });
        }
        print('Action triggered: ${event.actionId}');
      });
      
      _notificationManager.onNotificationTap.listen((event) {
        if (mounted) {
          setState(() {
            _statusMessage = '👆 Notification tapped: ${event.notificationId}';
          });
        }
        print('Notification tapped: ${event.notificationId}');
      });
      
      // Set final status
      if (mounted) {
        setState(() {
          _statusMessage = hasPermission 
              ? '✅ Ready! Notifications enabled'
              : '⚠️ Permission not granted. Notifications may not work.';
          _isInitialized = true;
        });
      }
      
      print('Notification manager initialized. Permission: $hasPermission');
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '❌ Error: $e';
          _isInitialized = true;
        });
      }
      print('Error initializing notification manager: $e');
    }
  }



  Future<void> _showSimpleNotification() async {
    if (!_isInitialized) return;
    
    setState(() {
      _statusMessage = '📤 Sending simple notification...';
    });

    try {
      final request = NotificationRequest(
        id: 'simple_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Simple Notification',
        body: 'This is a simple notification without actions.',
      );
      
      final success = await _notificationManager.showNotification(request);
      if (success) {
        setState(() {
          _statusMessage = '✅ Simple notification sent!';
        });
        print('Simple notification sent successfully');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to send notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error sending notification: $e');
    }
  }

  Future<void> _showNotificationWithActions() async {
    if (!_isInitialized) return;
    
    setState(() {
      _statusMessage = '📤 Sending notification with actions...';
    });

    try {
      final request = NotificationRequest(
        id: 'actions_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Notification with Actions',
        body: 'Tap an action button below.',
        actions: [
          NotificationAction(
            id: 'action_1',
            title: 'Action 1',
          ),
          NotificationAction(
            id: 'action_2',
            title: 'Action 2',
          ),
        ],
      );
      
      final success = await _notificationManager.showNotification(request);
      if (success) {
        setState(() {
          _statusMessage = '✅ Action notification sent!';
        });
        print('Action notification sent successfully');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to send notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error sending notification: $e');
    }
  }

  Future<void> _showNotificationWithBadge() async {
    if (!_isInitialized) return;
    
    setState(() {
      _statusMessage = '📤 Sending notification with badge...';
    });

    try {
      _badgeCount++;
      await _notificationManager.setBadgeCount(_badgeCount);
      
      final request = NotificationRequest(
        id: 'badge_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Badge Notification',
        body: 'This notification updates the badge count.',
        badgeNumber: _badgeCount,
      );
      
      final success = await _notificationManager.showNotification(request);
      if (success) {
        setState(() {
          _statusMessage = '✅ Badge notification sent! (Badge: $_badgeCount)';
        });
        print('Badge notification sent successfully');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to send notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error sending notification: $e');
    }
  }

  Future<void> _clearBadge() async {
    if (!_isInitialized) return;
    
    try {
      await _notificationManager.clearBadgeCount();
      setState(() {
        _badgeCount = 0;
        _statusMessage = '🧹 Badge cleared!';
      });
      print('Badge cleared successfully');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error clearing badge: $e';
      });
      print('Error clearing badge: $e');
    }
  }

  Future<void> _checkNotificationStatus() async {
    if (!_isInitialized) return;
    
    try {
      final enabled = await _notificationManager.areNotificationsEnabled();
      setState(() {
        _statusMessage = enabled 
            ? '✅ Notifications are enabled' 
            : '❌ Notifications are disabled';
      });
      print('Notification status: $enabled');
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error checking status: $e';
      });
      print('Error checking notification status: $e');
    }
  }

  Future<void> _requestPermission() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '🔐 Requesting permission...';
      });
      
      // Request permission using permission_handler
      final status = await Permission.notification.request();
      
      if (status.isGranted) {
        setState(() {
          _statusMessage = '✅ Permission granted! Notifications enabled.';
        });
        print('Notification permission granted');
      } else {
        setState(() {
          _statusMessage = '❌ Permission denied. Please enable in settings.';
        });
        print('Notification permission denied');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error requesting permission: $e';
      });
      print('Error requesting permission: $e');
    }
  }

  // Scheduling Methods
  Future<void> _scheduleNotification5s() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '⏰ Scheduling notification in 5 seconds...';
      });
      
      final request = NotificationRequest(
        id: 'scheduled_5s_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification',
        body: 'This notification was scheduled for 5 seconds from now.',
        actions: [
          NotificationAction(id: 'snooze', title: 'Snooze'),
          NotificationAction(id: 'dismiss', title: 'Dismiss'),
        ],
      );
      
      final scheduledDate = DateTime.now().add(const Duration(seconds: 5));
      
      final success = await _notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
      );
      
      if (success) {
        setState(() {
          _statusMessage = '✅ Scheduled for ${scheduledDate.toString().substring(11, 19)}';
        });
        print('Notification scheduled for 5 seconds');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to schedule notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _scheduleNotification30s() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '⏰ Scheduling notification in 30 seconds...';
      });
      
      final request = NotificationRequest(
        id: 'scheduled_30s_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification',
        body: 'This notification was scheduled for 30 seconds from now.',
      );
      
      final scheduledDate = DateTime.now().add(const Duration(seconds: 30));
      
      final success = await _notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
      );
      
      if (success) {
        setState(() {
          _statusMessage = '✅ Scheduled for ${scheduledDate.toString().substring(11, 19)}';
        });
        print('Notification scheduled for 30 seconds');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to schedule notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _scheduleNotification1min() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '⏰ Scheduling notification in 1 minute...';
      });
      
      final request = NotificationRequest(
        id: 'scheduled_1min_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification',
        body: 'This notification was scheduled for 1 minute from now.',
      );
      
      final scheduledDate = DateTime.now().add(const Duration(minutes: 1));
      
      final success = await _notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
      );
      
      if (success) {
        setState(() {
          _statusMessage = '✅ Scheduled for ${scheduledDate.toString().substring(11, 19)}';
        });
        print('Notification scheduled for 1 minute');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to schedule notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _scheduleNotification5min() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '⏰ Scheduling notification in 5 minutes...';
      });
      
      final request = NotificationRequest(
        id: 'scheduled_5min_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Scheduled Notification',
        body: 'This notification was scheduled for 5 minutes from now.',
      );
      
      final scheduledDate = DateTime.now().add(const Duration(minutes: 5));
      
      final success = await _notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
      );
      
      if (success) {
        setState(() {
          _statusMessage = '✅ Scheduled for ${scheduledDate.toString().substring(11, 19)}';
        });
        print('Notification scheduled for 5 minutes');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to schedule notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error scheduling notification: $e');
    }
  }

  Future<void> _scheduleRepeatingNotification() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '🔄 Scheduling repeating notification...';
      });
      
      final request = NotificationRequest(
        id: 'repeating_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Repeating Notification',
        body: 'This notification repeats every minute.',
      );
      
      final scheduledDate = DateTime.now().add(const Duration(seconds: 10));
      
      final success = await _notificationManager.scheduleNotification(
        request: request,
        scheduledDate: scheduledDate,
        isRepeating: true,
        repeatInterval: const Duration(minutes: 1),
      );
      
      if (success) {
        setState(() {
          _statusMessage = '✅ Repeating notification scheduled!';
        });
        print('Repeating notification scheduled');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to schedule repeating notification';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error scheduling repeating notification: $e');
    }
  }

  Future<void> _cancelAllScheduled() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '❌ Cancelling all scheduled notifications...';
      });
      
      final success = await _notificationManager.cancelAllScheduledNotifications();
      
      if (success) {
        setState(() {
          _statusMessage = '✅ All scheduled notifications cancelled!';
        });
        print('All scheduled notifications cancelled');
      } else {
        setState(() {
          _statusMessage = '❌ Failed to cancel scheduled notifications';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error cancelling scheduled notifications: $e');
    }
  }

  Future<void> _getScheduledNotifications() async {
    if (!_isInitialized) return;
    
    try {
      setState(() {
        _statusMessage = '📋 Getting scheduled notifications...';
      });
      
      final notifications = await _notificationManager.getScheduledNotifications();
      
      setState(() {
        _statusMessage = '📋 Found ${notifications.length} scheduled notifications';
      });
      print('Found ${notifications.length} scheduled notifications');
      
      // Log details of each notification
      for (final notification in notifications) {
        print('Scheduled: ${notification.request.title} at ${notification.scheduledDate}');
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
      print('Error getting scheduled notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Manager Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Notification Manager'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: _statusMessage.contains('❌') 
                              ? Colors.red 
                              : _statusMessage.contains('✅') 
                                  ? Colors.green 
                                  : Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Badge Display
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Badge Count',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      NotificationBadge(
                        count: _badgeCount,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_badgeCount',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Notification Buttons
              const Text(
                'Send Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isInitialized ? _showSimpleNotification : null,
                child: const Text('📱 Simple Notification'),
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isInitialized ? _showNotificationWithActions : null,
                child: const Text('🎯 Notification with Actions'),
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isInitialized ? _showNotificationWithBadge : null,
                child: const Text('🔢 Notification with Badge'),
              ),
              
              const SizedBox(height: 20),
              
              // Scheduled Notifications Section
              const Text(
                'Scheduled Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _scheduleNotification5s : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('⏰ 5s'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _scheduleNotification30s : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('⏰ 30s'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _scheduleNotification1min : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('⏰ 1min'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _scheduleNotification5min : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('⏰ 5min'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isInitialized ? _scheduleRepeatingNotification : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                ),
                child: const Text('🔄 Repeating (every 1min)'),
              ),
              
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _cancelAllScheduled : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('❌ Cancel All'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _getScheduledNotifications : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('📋 List All'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Utility Buttons
              const Text(
                'Utilities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _clearBadge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('🧹 Clear Badge'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _checkNotificationStatus : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                      ),
                      child: const Text('🔍 Check Status'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isInitialized ? _requestPermission : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('🔐 Request Permission'),
              ),
              
              const SizedBox(height: 20),
              
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Tap buttons to send notifications\n'
                        '• Check your notification tray\n'
                        '• Try tapping notification actions\n'
                        '• Watch the status updates above',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
