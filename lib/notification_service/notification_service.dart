import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
 // final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late String _oauthAccessToken;
  DateTime? _tokenExpiryTime; // Store token expiration time
  final List<Map<String, String>> _notifications = []; // Local notifications cache
  List<Map<String, String>> get notifications => _notifications;
  final String _serviceAccountPath = 'assets/trial-15cd5-f15032025cd4.json';
  /// Scopes required for Firebase Cloud Messaging
  final List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];
  Completer<void>? _tokenLock; // To prevent multiple token generations
  /// Initialize the service and generate OAuth Access Token
  Future<void> init(BuildContext context) async {
    print('[INIT] Initializing NotificationService...');
    try {
      _oauthAccessToken = await _generateOAuthToken();
      await _firebaseMessaging.requestPermission();
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('[FCM] New message received: ${message.notification?.title}');
        _showInAppPopup(context, message.notification?.title ?? '', message.notification?.body ?? '');
      });
      await _firebaseMessaging.getToken().then((token) {
        print('[INIT] Firebase Messaging Token: $token');
      });
      print('[SUCCESS] NotificationService initialized successfully.');
    } catch (e) {
      print('[ERROR] Initialization failed: $e');
    }
  }

  Future<String?> getFirebaseMessagingToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print('[NotificationService] Retrieved FCM Token: $token');
      return token;
    } catch (e) {
      print('[NotificationService] Error retrieving FCM Token: $e');
      return null;
    }
  }

  /// Generate OAuth 2.0 Access Token
  Future<String> _generateOAuthToken() async {
    print('[OAUTH] Generating OAuth Access Token...');
    _tokenLock ??= Completer<void>();
    try {
      final serviceAccountJson =
      await rootBundle.loadString(_serviceAccountPath); // Load Service Account JSON
      print('[OAUTH] Service Account JSON loaded successfully.');

      final accountCredentials =
      ServiceAccountCredentials.fromJson(serviceAccountJson);
      print('[OAUTH] Service Account Credentials created.');

      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      print('[SUCCESS] OAuth Client created successfully.');
      _oauthAccessToken = client.credentials.accessToken.data;
      _tokenExpiryTime = client.credentials.accessToken.expiry;
      _tokenLock?.complete();
      return client.credentials.accessToken.data;
    } catch (e) {
      print('[ERROR] Failed to generate OAuth Access Token: $e');
      _tokenLock?.completeError(e);
      rethrow; // Propagate the error
    }finally {
      if (!_tokenLock!.isCompleted) {
        _tokenLock?.completeError('Token generation was incomplete');
      }
      _tokenLock = null;
    }
  }

  /// Send notification using FCM HTTP v1 API
  Future<void> sendNotificationToUser({
    required String recipientToken,
    required String title,
    required String body,
  }) async {
    print('[FCM] Sending notification to user...');
    await _ensureValidOAuthToken(); // Ensure valid token before sending
    print(' - Recipient Token: $recipientToken');
    print(' - Title: $title');
    print(' - Body: $body');

    const String fcmUrl =
        'https://fcm.googleapis.com/v1/projects/trial-15cd5/messages:send';

    final Map<String, dynamic> payload = {
      "message": {
        "token": recipientToken,
        "notification": {
          "title": title,
          "body": body
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "custom_key": "custom_value"
        }
      }
    };

    print('[FCM] Payload: ${jsonEncode(payload)}');

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_oauthAccessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        print('[SUCCESS] Notification sent successfully!');
      } else {
        print('[ERROR] Retrying after regenerating OAuth token...');
        await _generateOAuthToken(); // Regenerate the token and retry once
        final retryResponse = await http.post(
          Uri.parse(fcmUrl),
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_oauthAccessToken'},
          body: jsonEncode(payload),
        );

        if (retryResponse.statusCode == 200) {
          print('[SUCCESS] Notification sent successfully after retry!');
        } else {
          print('[ERROR] Failed to send notification: ${retryResponse.statusCode}');
        }
      }
    } catch (e) {
      print('[ERROR] Error sending FCM notification: $e');
    }
  }
  Stream<List<Map<String, dynamic>>> getNotificationStream(String userId) {
    print('[NotificationService] Fetching notifications for user: $userId');
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId) // Filter notifications by user ID
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
  /// Ensure a valid OAuth token is available
  Future<void> _ensureValidOAuthToken() async {
    if (_oauthAccessToken == null || _tokenExpiryTime == null || DateTime.now().isAfter(_tokenExpiryTime!)) {
      print('[OAUTH] Token expired or not set. Generating a new OAuth token...');
      if (_tokenLock != null) {
        await _tokenLock?.future; // Wait for ongoing generation to complete
      } else {
        if (_tokenExpiryTime == null || DateTime.now().isAfter(_tokenExpiryTime!.subtract(Duration(minutes: 1)))) {
          print('[OAUTH] Token about to expire. Regenerating...');
          await _generateOAuthToken();
          print('[DEBUG] OAuth token regenerated. Expires at: $_tokenExpiryTime');
        }
      }
    } else {
      print('[OAUTH] Using cached OAuth token.');
    }
  }
  /// Show a popup in-app notification
  void _showInAppPopup(BuildContext context, String title, String body) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }
  // Listen for new notifications
  Stream<QuerySnapshot> listenForNewNotifications(String userId) {
    print("[DEBUG] Setting up notification listener for userId: $userId");

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print("[DEBUG] Received new snapshot with ${snapshot.docs.length} notifications");
      return snapshot;
    });
  }
// Mark a notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('[SUCCESS] Notification marked as read: $notificationId');
    } catch (e) {
      print('[ERROR] Failed to mark notification as read: $e');
    }
  }

  /// Upload the FCM token to Firestore for a user
  Future<void> saveTokenToFirestore({
    required String userId,
    required String fcmToken,
  }) async {
    print('[FIRESTORE] Saving FCM token for user: $userId');
    try {
      await _firestore.collection('user_tokens').doc(userId).set(
        {
          'userId': userId,
          'fcmToken': fcmToken,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print('[SUCCESS] FCM token saved to Firestore successfully!');
    } catch (e) {
      print('[ERROR] Error saving FCM token to Firestore: $e');
    }
  }
}
