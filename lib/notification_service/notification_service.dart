import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  final user = FirebaseAuth.instance.currentUser;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Tracks whether notifications have been initialized
  bool _isInitialized = false;

  // List to store notifications
  final List<Map<String, String>> _notifications = [];

  // Getter to retrieve notifications
  List<Map<String, String>> get notifications => _notifications;

  /// Initialization: Request permissions and handle foreground/background notifications.
  Future<void> init(BuildContext context) async {
    // Prevent re-initialization
    if (_isInitialized) {
      print('NotificationService is already initialized.');
      return;
    }

    // Request permissions for notifications
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

    // Get and store the FCM token in Firestore
    await _saveTokenToFirestore();

    // Handle notifications when app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a notification in the foreground: ${message.notification?.title}');

      // Add the notification to the local list
      addNotification(
        title: message.notification?.title ?? "No Title",
        body: message.notification?.body ?? "No Body",
      );

      // Optionally show a dialog
      _showNotificationDialog(context, message.notification?.title, message.notification?.body);
    });

    // Handle notifications when the app is opened from a background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened: ${message.notification?.title}');
      _handleNotificationClick(context, message);
    });

    // Handle notifications when app is completely terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    print('NotificationService initialized successfully.');
  }

  /// Save the FCM token to Firestore
  Future<void> _saveTokenToFirestore() async {
    try {
      // Fetch the FCM token
      final String? fcmToken = await _firebaseMessaging.getToken();

      // Fetch the current logged-in user's ID
      final User? user = FirebaseAuth.instance.currentUser;

      if (fcmToken != null && user != null) {
        // Save the token to Firestore under the user's UID
        await FirebaseFirestore.instance
            .collection('notification_tokens')
            .doc(user.uid) // Document ID is the user's ID
            .set({
          'userId': user.uid,                // User ID field
          'fcmToken': fcmToken,              // FCM token field
          'createdAt': FieldValue.serverTimestamp(), // Timestamp field
        }, SetOptions(merge: true)); // Merge to avoid overwriting existing fields

        print('Debug: FCM Token saved successfully for user: ${user.uid}');
        print('Debug: Token value: $fcmToken');
      } else {
        print('Error: User is not logged in or FCM token is null.');
      }
    } catch (e) {
      print('Error saving FCM token to Firestore: $e');
    }
  }
  /// Send a notification to a specific user (new addition)
  Future<void> sendNotificationToUser({
    required String recipientToken,
    required String title,
    required String body,
  }) async {
    try {
      const String serverKey = "YOUR_FIREBASE_SERVER_KEY"; // Replace with your actual server key
      const String fcmUrl = "https://fcm.googleapis.com/fcm/send";

      final Map<String, dynamic> payload = {
        'to': recipientToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully to token: $recipientToken');
      } else {
        print('Error sending notification: ${response.body}');
      }
    } catch (e) {
      print('Error in sendNotificationToUser: $e');
    }
  }

  /// Background message handler (must be a top-level function)
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background notification: ${message.notification?.title}');
  }

  /// Add a notification to the local list
  void addNotification({required String title, required String body}) {
    _notifications.add({'title': title, 'body': body});
  }

  /// Show a dialog for the notification
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

  /// Handle notification clicks (navigate to a route)
  void _handleNotificationClick(BuildContext context, RemoteMessage message) {
    final Map<String, dynamic>? data = message.data;
    if (data != null) {
      String? route = data['route']; // Extract route from payload
      if (route != null) {
        Navigator.pushNamed(context, route);
      }
    }
  }
}
