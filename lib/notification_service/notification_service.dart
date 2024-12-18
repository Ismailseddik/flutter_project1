import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle;
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  late String _oauthAccessToken;
  final List<Map<String, String>> _notifications = []; // Local notifications cache
  List<Map<String, String>> get notifications => _notifications;
  /// Path to your Service Account JSON file
  final String _serviceAccountPath = 'assets/trial-15cd5-f15032025cd4.json';

  /// Scopes required for Firebase Cloud Messaging
  final List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging'
  ];

  /// Initialize the service and generate OAuth Access Token
  Future<void> init(BuildContext context) async {
    print('[INIT] Initializing NotificationService...');
    try {
      _oauthAccessToken = await _generateOAuthToken();
      await _firebaseMessaging.requestPermission();
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
    try {
      final serviceAccountJson =
      await rootBundle.loadString(_serviceAccountPath); // Load Service Account JSON
      print('[OAUTH] Service Account JSON loaded successfully.');

      final accountCredentials =
      ServiceAccountCredentials.fromJson(serviceAccountJson);
      print('[OAUTH] Service Account Credentials created.');

      final client = await clientViaServiceAccount(accountCredentials, _scopes);
      print('[SUCCESS] OAuth Client created successfully.');

      return client.credentials.accessToken.data;
    } catch (e) {
      print('[ERROR] Failed to generate OAuth Access Token: $e');
      rethrow; // Propagate the error
    }
  }

  /// Send notification using FCM HTTP v1 API
  Future<void> sendNotificationToUser({
    required String recipientToken,
    required String title,
    required String body,
  }) async {
    print('[FCM] Sending notification to user...');
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
        print('[ERROR] Failed to send notification: ${response.statusCode}');
        print('[FCM] Response Body: ${response.body}');
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
