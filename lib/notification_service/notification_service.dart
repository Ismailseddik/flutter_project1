import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Tracks whether notifications have been initialized
  bool _isInitialized = false;

  // List to store notifications
  final List<Map<String, String>> _notifications = [];

  // Getter to retrieve notifications
  List<Map<String, String>> get notifications => _notifications;

  Future<void> init(BuildContext context) async {
    // Prevent re-initialization
    if (_isInitialized) {
      print('NotificationService is already initialized.');
      return;
    }

    // Request permissions for notifications (iOS-specific)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions');
    } else {
      print('User declined or has not granted notification permissions');
    }

    // Get and log the FCM token
    final String? fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      print('FCM Token: $fcmToken');
      // Optionally save the token to your backend or Firestore
    }

    // Handle notifications when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a notification in the foreground: ${message.notification?.title}');

      // Add the notification to the local list
      addNotification(
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
      );

      // Optionally show a dialog or snackbar
      _showNotificationDialog(context, message.notification?.title, message.notification?.body);
    });

    // Handle notifications when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      _handleNotificationClick(context, message);
    });

    // Handle notifications when app is completely terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Mark as initialized
    _isInitialized = true;
    print('NotificationService initialized successfully.');
  }

  // Background message handler (must be a top-level function)
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background notification: ${message.notification?.title}');
  }

  // Helper method to add a notification to the list
  void addNotification({required String title, required String body}) {
    _notifications.add({'title': title, 'body': body});
  }

  // Helper method to show notification dialog
  void _showNotificationDialog(BuildContext context, String? title, String? body) {
    if (title == null && body == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title ?? 'Notification'),
          content: Text(body ?? 'You have a new notification.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Handle notification clicks (navigate to specific screens, etc.)
  void _handleNotificationClick(BuildContext context, RemoteMessage message) {
    final Map<String, dynamic>? data = message.data;
    if (data != null) {
      String? route = data['route']; // Extract a route from the notification payload
      if (route != null) {
        Navigator.pushNamed(context, route); // Navigate to the route
      }
    }
  }
}
