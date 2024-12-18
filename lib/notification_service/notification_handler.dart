import 'package:cloud_firestore/cloud_firestore.dart';
import '../notification_service/notification_service.dart';

class NotificationHandler {
  // Singleton instance
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Upload or update FCM token to 'user_tokens' collection
  Future<void> uploadUserToken({
    required String userId,
    required String fcmToken,
  }) async {
    try {
      print('[HANDLER] Uploading FCM token for user: $userId');
      await _notificationService.saveTokenToFirestore(
          userId: userId, fcmToken: fcmToken);
      print('[SUCCESS] FCM token uploaded for user: $userId');
    } catch (e) {
      print('[ERROR] Failed to upload FCM token: $e');
    }
  }

  /// Send notifications when a gift is updated
  Future<void> sendGiftUpdateNotification({
    required int giftId,
    required String giftName,
    required int eventId,
    required String newStatus,
    required String pledgerName,
  }) async {
    try {
      print('[HANDLER] Fetching event owner token for eventId: $eventId');
      final eventOwnerToken = await _fetchEventOwnerToken(eventId);

      if (eventOwnerToken == null) {
        print('[ERROR] Event owner token not found.');
        return;
      }

      final title = "Gift Update: $giftName";
      final body = "The gift '$giftName' has been $newStatus by $pledgerName.";

      print('[HANDLER] Sending gift update notification...');
      await _notificationService.sendNotificationToUser(
        recipientToken: eventOwnerToken,
        title: title,
        body: body,
      );

      await _createNotificationRecord(
        recipientId: eventId.toString(),
        title: title,
        body: body,
      );

      print('[SUCCESS] Notification sent and recorded for gift update.');
    } catch (e) {
      print('[ERROR] Failed to send gift update notification: $e');
    }
  }

  /// Send notifications when an event is updated or created
  Future<void> sendEventUpdateNotification({
    required String eventName,
    required String updateType, // "Created", "Updated", "Deleted"
    required List<int> friendIds,
  }) async {
    try {
      print('[HANDLER] Fetching friend tokens...');
      final friendTokens = await _fetchFriendTokens(friendIds);

      if (friendTokens.isEmpty) {
        print('[ERROR] No friends found to notify.');
        return;
      }

      final title = "Event $updateType: $eventName";
      final body = "The event '$eventName' has been $updateType.";

      print('[HANDLER] Sending notifications to friends...');
      for (final token in friendTokens) {
        await _notificationService.sendNotificationToUser(
          recipientToken: token,
          title: title,
          body: body,
        );
      }

      await _createNotificationRecord(
        recipientId: friendIds.map((id) => id.toString()).toList(),
        title: title,
        body: body,
      );

      print('[SUCCESS] Notifications sent and recorded for event update.');
    } catch (e) {
      print('[ERROR] Failed to send event update notifications: $e');
    }
  }

  /// Send notification when a gift is pledged
  Future<void> sendGiftPledgeNotification({
    required int giftId,
    required String? pledgerName,
    required String giftName,
  }) async {
    try {
      print('[HANDLER] Fetching gift details for giftId: $giftId...');
      final giftDoc =
      await _firestore.collection('gifts').doc(giftId.toString()).get();

      if (!giftDoc.exists) {
        print('[ERROR] Gift not found with ID: $giftId');
        return;
      }

      final eventId = giftDoc.data()?['eventId'];
      if (eventId == null) {
        print('[ERROR] eventId not found for gift ID: $giftId');
        return;
      }

      print('[HANDLER] Fetching event owner...');
      final eventDoc =
      await _firestore.collection('events').doc(eventId.toString()).get();

      if (!eventDoc.exists) {
        print('[ERROR] Event not found with ID: $eventId');
        return;
      }

      final ownerId = eventDoc.data()?['userId'];
      if (ownerId == null) {
        print('[ERROR] Event owner userId not found for event ID: $eventId');
        return;
      }

      print('[HANDLER] Fetching recipient token for userId: $ownerId...');
      final tokenDoc = await _firestore
          .collection('user_tokens')
          .doc(ownerId.toString())
          .get();
      final recipientToken = tokenDoc.data()?['fcmToken'];

      if (recipientToken == null) {
        print('[ERROR] FCM token not found for user ID: $ownerId');
        return;
      }

      final title = "Gift Pledged: $giftName";
      final body = "$pledgerName has pledged the gift '$giftName'.";

      print('[HANDLER] Sending gift pledge notification...');
      await _notificationService.sendNotificationToUser(
        recipientToken: recipientToken,
        title: title,
        body: body,
      );

      await _createNotificationRecord(
        recipientId: ownerId.toString(),
        title: title,
        body: body,
      );

      print('[SUCCESS] Notification sent successfully for pledged gift.');
    } catch (e) {
      print('[ERROR] Failed to send gift pledge notification: $e');
    }
  }

  /// Save notifications in a 'notifications' collection
  Future<void> _createNotificationRecord({
    required dynamic recipientId,
    required String title,
    required String body,
  }) async {
    try {
      print('[HANDLER] Saving notification record...');
      await _firestore.collection('notifications').add({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      print('[SUCCESS] Notification saved to Firestore.');
    } catch (e) {
      print('[ERROR] Failed to save notification record: $e');
    }
  }

  /// Fetch the FCM token of the event owner
  Future<String?> _fetchEventOwnerToken(int eventId) async {
    try {
      print('[HANDLER] Fetching event for eventId: $eventId...');
      final eventDoc =
      await _firestore.collection('events').doc(eventId.toString()).get();
      final userId = eventDoc.data()?['userId'];

      if (userId != null) {
        final tokenDoc = await _firestore
            .collection('user_tokens')
            .doc(userId.toString())
            .get();
        return tokenDoc.data()?['fcmToken'];
      }
    } catch (e) {
      print('[ERROR] Failed to fetch event owner token: $e');
    }
    return null;
  }

  /// Fetch FCM tokens for a list of friend IDs
  Future<List<String>> _fetchFriendTokens(List<int> friendIds) async {
    List<String> tokens = [];
    try {
      print('[HANDLER] Fetching friend tokens...');
      final snapshot = await _firestore
          .collection('user_tokens')
          .where('userId', whereIn: friendIds.map((e) => e.toString()).toList())
          .get();

      for (var doc in snapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token != null) tokens.add(token);
      }
      print('[SUCCESS] Friend tokens fetched successfully.');
    } catch (e) {
      print('[ERROR] Failed to fetch friend tokens: $e');
    }
    return tokens;
  }
}
