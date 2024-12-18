import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationBell extends StatelessWidget {
  final String userId;
  final VoidCallback onBellPressed;

  NotificationBell({required this.userId, required this.onBellPressed});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('recipientId', isEqualTo: userId)
          .where('isRead', isEqualTo: false) // Filter for unread notifications
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _notificationBell(0); // Default to 0 if error
        }

        final int unreadNotificationCount = snapshot.data?.docs.length ?? 0;

        return _notificationBell(unreadNotificationCount);
      },
    );
  }

  Widget _notificationBell(int count) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(Icons.notifications, color: Colors.teal, size: 30),
          onPressed: onBellPressed, // Function passed to open notifications dropdown
          tooltip: 'View Notifications',
        ),
        if (count > 0) // Show badge only when there are unread notifications
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
