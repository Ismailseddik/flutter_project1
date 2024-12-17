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
      final tokensRef = _firestore.collection('user_tokens');
      await tokensRef.doc(userId).set({
        'userId': userId,
        'fcmToken': fcmToken,
      }, SetOptions(merge: true)); // Merge if document exists

      print('FCM token uploaded for user: $userId');
    } catch (e) {
      print('Error uploading FCM token: $e');
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
      // Fetch the event owner's FCM token
      final eventOwnerToken = await _fetchEventOwnerToken(eventId);
      if (eventOwnerToken == null) {
        print('Error: Event owner token not found.');
        return;
      }

      final title = "Gift Update: $giftName";
      final body = "The gift '$giftName' has been $newStatus by $pledgerName.";

      // Send the notification
      await _notificationService.sendNotificationToUser(
        recipientToken: eventOwnerToken,
        title: title,
        body: body,
      );

      // Save the notification in the 'notifications' collection
      await _createNotificationRecord(
        recipientId: eventId.toString(),
        title: title,
        body: body,
      );

      print('Notification sent and recorded for gift update.');
    } catch (e) {
      print('Error sending gift update notification: $e');
    }
  }

  /// Send notifications when an event is updated or created
  Future<void> sendEventUpdateNotification({
    required String eventName,
    required String updateType, // "Created", "Updated", "Deleted"
    required List<int> friendIds,
  }) async {
    try {
      final friendTokens = await _fetchFriendTokens(friendIds);
      if (friendTokens.isEmpty) {
        print('Error: No friends found to notify.');
        return;
      }

      final title = "Event $updateType: $eventName";
      final body = "The event '$eventName' has been $updateType.";

      // Send notifications to all friends
      for (final token in friendTokens) {
        await _notificationService.sendNotificationToUser(
          recipientToken: token,
          title: title,
          body: body,
        );
      }

      // Save the notification in the 'notifications' collection
      await _createNotificationRecord(
        recipientId: friendIds.map((id) => id.toString()).toList(),
        title: title,
        body: body,
      );

      print('Notifications sent and recorded for event update.');
    } catch (e) {
      print('Error sending event update notification: $e');
    }
  }

  /// Save notifications in a 'notifications' collection
  Future<void> _createNotificationRecord({
    required dynamic recipientId,
    required String title,
    required String body,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'recipientId': recipientId, // Could be single user ID or a list of IDs
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Notification saved to Firestore.');
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Fetch the FCM token of the event owner
  Future<String?> _fetchEventOwnerToken(int eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId.toString()).get();
      final userId = eventDoc.data()?['userId'];

      if (userId != null) {
        final tokenDoc = await _firestore.collection('user_tokens').doc(userId.toString()).get();
        return tokenDoc.data()?['fcmToken'];
      }
    } catch (e) {
      print('Error fetching event owner token: $e');
    }
    return null;
  }

  /// Fetch FCM tokens for a list of friend IDs
  Future<List<String>> _fetchFriendTokens(List<int> friendIds) async {
    List<String> tokens = [];
    try {
      final snapshot = await _firestore
          .collection('user_tokens')
          .where('userId', whereIn: friendIds.map((e) => e.toString()).toList())
          .get();

      for (var doc in snapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token != null) tokens.add(token);
      }
    } catch (e) {
      print('Error fetching friend tokens: $e');
    }
    return tokens;
  }
}
