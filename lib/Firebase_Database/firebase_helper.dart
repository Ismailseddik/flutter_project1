import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial/Local_Database/database_helper.dart';
import '../models/models.dart'; // Import your models for consistency

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseHelper._init();

  // === USERS COLLECTION ===
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id.toString()).set(user.toMap());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<User?> getUser(int userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId.toString()).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  Future<int?> getUserIdByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['id'];
      }
    } catch (e) {
      print('Error fetching user by email: $e');
    }
    return null;
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _firestore.collection('users').doc(userId.toString()).delete();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  // === EVENTS COLLECTION ===
  Future<void> createEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id.toString()).set(event.toMap());
    } catch (e) {
      print('Error creating event: $e');
      rethrow;
    }
  }

  Future<List<Event>> getEvents(int userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.map((doc) => Event.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<void> deleteEvent(int eventId) async {
    try {
      await _firestore.collection('events').doc(eventId.toString()).delete();
    } catch (e) {
      print('Error deleting event: $e');
    }
  }

  // === GIFTS COLLECTION ===
  Future<void> createGift(Gift gift) async {
    try {
      await _firestore.collection('gifts').doc(gift.id.toString()).set(gift.toMap());
    } catch (e) {
      print('Error creating gift: $e');
      rethrow;
    }
  }
  Future<void> updateGift(int giftId, Map<String, dynamic> updates) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Find the document with the matching giftId field
      final querySnapshot = await firestore
          .collection('gifts')
          .where('id', isEqualTo: giftId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Gift not found');
      }

      // Update the gift document
      final docId = querySnapshot.docs.first.id;
      await firestore.collection('gifts').doc(docId).update(updates);

      print('Gift updated successfully: $updates');
    } catch (e) {
      print('Error updating gift: $e');
      rethrow;
    }
  }


  Future<List<Gift>> getGifts(int eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('eventId', isEqualTo: eventId)
          .get();
      return querySnapshot.docs.map((doc) => Gift.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching gifts: $e');
      return [];
    }
  }

  Future<void> updateGiftStatus(int giftId, String status) async {
    try {
      await _firestore.collection('gifts').doc(giftId.toString()).update({'status': status});
    } catch (e) {
      print('Error updating gift status: $e');
    }
  }

  Future<void> deleteGift(int giftId) async {
    try {
      await _firestore.collection('gifts').doc(giftId.toString()).delete();
    } catch (e) {
      print('Error deleting gift: $e');
    }
  }

  // === FRIENDS COLLECTION ===
  Future<void> addFriend(Friend friend) async {
    try {
      await _firestore
          .collection('friends')
          .doc('${friend.userId}_${friend.friendId}')
          .set(friend.toMap());
    } catch (e) {
      print('Error adding friend: $e');
      rethrow;
    }
  }

  Future<List<Friend>> getFriends(int userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: userId)
          .get();
      return querySnapshot.docs.map((doc) => Friend.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching friends: $e');
      return [];
    }
  }
  Future<List<Gift>> getGiftsByFriendId(int friendId) async {
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .where('friendId', isEqualTo: friendId)
          .get();
      return querySnapshot.docs.map((doc) => Gift.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error fetching gifts by friendId: $e');
      return [];
    }
  }
  Future<void> deleteFriend(int userId, int friendId) async {
    try {
      await _firestore
          .collection('friends')
          .doc('${userId}_$friendId')
          .delete();
    } catch (e) {
      print('Error deleting friend: $e');
    }
  }

  // === SYNCING FUNCTIONS ===
  Future<void> syncWithLocalDatabase(DatabaseHelper dbHelper) async {
    // Sync Users
    final users = await dbHelper.getAllUsers();
    for (var user in users) {
      try {
        final firebaseUser = await getUser(user.id!);
        if (firebaseUser == null) {
          await createUser(user);
        }
      } catch (e) {
        print('Error syncing user: $e');
      }
    }

    // Sync Events
    final events = await dbHelper.getAllEvents();
    for (var event in events) {
      try {
        final firebaseEvents = await getEvents(event.userId);
        if (!firebaseEvents.any((e) => e.id == event.id)) {
          await createEvent(event);
        }
      } catch (e) {
        print('Error syncing event: $e');
      }
    }

    // Sync Gifts
    final gifts = await dbHelper.getAllGifts();
    for (var gift in gifts) {
      try {
        final firebaseGifts = await getGifts(gift.eventId);
        if (!firebaseGifts.any((g) => g.id == gift.id)) {
          await createGift(gift);
        }
      } catch (e) {
        print('Error syncing gift: $e');
      }
    }

    // Sync Friends
    final friends = await dbHelper.getAllFriends();
    for (var friend in friends) {
      try {
        final firebaseFriends = await getFriends(friend.userId);
        if (!firebaseFriends.any((f) => f.friendId == friend.friendId)) {
          await addFriend(friend);
        }
      } catch (e) {
        print('Error syncing friend: $e');
      }
    }
  }
}
