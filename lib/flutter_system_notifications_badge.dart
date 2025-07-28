import 'package:flutter/material.dart';
import 'flutter_system_notifications.dart';

/// A widget that displays a notification badge with unread count
class NotificationBadge extends StatefulWidget {
  /// The child widget to display the badge on
  final Widget child;
  
  /// The badge count to display
  final int count;
  
  /// Whether to show the badge when count is 0
  final bool showZero;
  
  /// The badge color
  final Color? badgeColor;
  
  /// The text color of the badge
  final Color? textColor;
  
  /// The badge size
  final double size;
  
  /// The badge position
  final Alignment alignment;
  
  /// The badge padding
  final EdgeInsets padding;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.size = 20.0,
    this.alignment = Alignment.topRight,
    this.padding = const EdgeInsets.all(4.0),
  });

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.count;
    _updateBadgeCount();
  }

  @override
  void didUpdateWidget(NotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _count = widget.count;
      _updateBadgeCount();
    }
  }

  void _updateBadgeCount() async {
    final notificationManager = NotificationManager();
    final currentCount = await notificationManager.getBadgeCount();
    if (mounted && currentCount != _count) {
      setState(() {
        _count = currentCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShow = _count > 0 || widget.showZero;
    
    return Stack(
      children: [
        widget.child,
        if (shouldShow)
          Positioned(
            top: widget.alignment == Alignment.topRight || widget.alignment == Alignment.topLeft ? 0 : null,
            bottom: widget.alignment == Alignment.bottomRight || widget.alignment == Alignment.bottomLeft ? 0 : null,
            left: widget.alignment == Alignment.topLeft || widget.alignment == Alignment.bottomLeft ? 0 : null,
            right: widget.alignment == Alignment.topRight || widget.alignment == Alignment.bottomRight ? 0 : null,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.badgeColor ?? Colors.red,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _count > 99 ? '99+' : _count.toString(),
                  style: TextStyle(
                    color: widget.textColor ?? Colors.white,
                    fontSize: widget.size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 