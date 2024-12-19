import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial/Local_Database/database_helper.dart';
import '../SyncStatusManager.dart';
import '../models/models.dart'; // Import your models for consistency
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  Future<User?> getUserById(String userId) async {
    try {
      print('Debug: Fetching user from Firebase for User ID: $userId'); // Log the userId being queried
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        print('Debug: User document found: ${userDoc.data()}');
        return User.fromMap(userDoc.data()!);
      } else {
        print('Error: User document does not exist for User ID: $userId');
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
    }
    return null; // Return null if user is not found
  }
  Future<String?> getUserNameById(String userId) async {
    try {
      print('Debug: Fetching user name from Firebase for User ID: $userId');
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userName = userDoc.data()?['name'];
        print('Debug: User name found: $userName');
        return userName;
      } else {
        print('Error: User document does not exist for User ID: $userId');
      }
    } catch (e) {
      print('Error fetching user name by ID: $e');
    }
    return null; // Return null if name is not found
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
  /// Update an event in Firebase
  Future<void> updateEvent(int eventId, Map<String, dynamic> updates) async {
    try {
      final docRef = _firestore.collection('events').doc(eventId.toString());
      await docRef.update(updates);
      print('Event updated successfully in Firebase: $updates');
    } catch (e) {
      print('Error updating event in Firebase: $e');
      rethrow;
    }
  }
  /// Delete an event and its associated gifts in Firebase
  Future<void> deleteEventWithCascading(int eventId) async {
    try {
      // Delete associated gifts
      final giftsSnapshot = await _firestore
          .collection('gifts')
          .where('eventId', isEqualTo: eventId)
          .get();

      for (var doc in giftsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the event itself
      await _firestore.collection('events').doc(eventId.toString()).delete();
      print('Event and associated gifts deleted successfully in Firebase.');
    } catch (e) {
      print('Error deleting event with cascading in Firebase: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getEventById(String eventId) async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .get();
      return eventDoc.data() ?? {};
    } catch (e) {
      print('Error fetching event by ID: $e');
      return {};
    }
  }


  // === GIFTS COLLECTION ===
  Future<void> createGift(Gift gift) async {
    try {
      if (gift.id == null) {
        throw Exception('Gift ID is null. Cannot create gift in Firebase.');
      }
      await _firestore.collection('gifts').doc(gift.id.toString()).set(gift.toMap());
      print('Gift created successfully in Firebase with ID: ${gift.id}');
    } catch (e) {
      print('Error creating gift in Firebase: $e');
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
  Future<List<Gift>> getGiftsWithCriteria(Map<String, dynamic> criteria) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('friendId', isEqualTo: criteria['friendId'])
          .where('status', isEqualTo: criteria['status'])
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Gift(
          id: int.parse(doc.id),
          name: data['name'],
          category: data['category'],
          price: data['price'],
          status: data['status'],
          friendId: data['friendId'],
          eventId: data['eventId'], description: '',
        );
      }).toList();
    } catch (e) {
      print('Error fetching gifts with criteria: $e');
      return [];
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
  Future<void> syncFriendEvents(DatabaseHelper dbHelper, int friendId) async {
    try {
      print('[SYNC] Starting sync for friend events with friendId: $friendId');
      syncStatusManager.updateStatus("Syncing...");
      // Validate if the friendId exists in the `users` collection
      final userDoc = await _firestore.collection('users').doc(friendId.toString()).get();
      if (!userDoc.exists) {
        print('[SYNC] Invalid friendId: $friendId. No user found.');
        return; // Exit if the friendId is invalid
      }

      // Fetch all events for the friendId from Firebase
      final friendEventsSnapshot = await _firestore
          .collection('events')
          .where('userId', isEqualTo: friendId)
          .get();

      // Extract event IDs from Firebase
      final firebaseEventIds = friendEventsSnapshot.docs.map((doc) => doc.id).toSet();

      // Fetch all local events for this friendId
      final localFriendEvents = await dbHelper.getEvents(friendId);

      // Step 1: Add missing events from Firebase to the local database
      for (var eventDoc in friendEventsSnapshot.docs) {
        final event = Event.fromMap(eventDoc.data());
        if (!localFriendEvents.any((e) => e.id == event.id)) {
          await dbHelper.insertEvent(event);
          print('[SYNC] Added event with ID: ${event.id} to local database');
        }
      }

      // Step 2: Remove events that are no longer in Firebase
      for (var localEvent in localFriendEvents) {
        if (!firebaseEventIds.contains(localEvent.id.toString())) {
          await dbHelper.deleteEventWithCascading(localEvent.id!);
          print('[SYNC] Removed deleted event with ID: ${localEvent.id} from local database');
        }
      }

      print('[SYNC] Friend events sync completed successfully for friendId: $friendId');
      syncStatusManager.updateStatus("Synced");
    } catch (e) {
      print('[SYNC ERROR] Failed to sync friend events: $e');
      syncStatusManager.updateStatus("Offline");
    }
  }
  Future<void> syncFriendGifts(DatabaseHelper dbHelper, int eventId) async {
    try {
      print('[SYNC] Starting sync for gifts with eventId: $eventId');
      syncStatusManager.updateStatus("Syncing...");
      // Validate if the eventId exists in the `events` collection
      final eventDoc = await _firestore.collection('events').doc(eventId.toString()).get();
      if (!eventDoc.exists) {
        print('[SYNC] Invalid eventId: $eventId. No event found.');
        return; // Exit if the eventId is invalid
      }

      // Fetch all gifts for the eventId from Firebase
      final giftsSnapshot = await _firestore
          .collection('gifts')
          .where('eventId', isEqualTo: eventId)
          .get();

      // Extract gift IDs from Firebase
      final firebaseGiftIds = giftsSnapshot.docs.map((doc) => doc.id).toSet();

      // Fetch all local gifts for this eventId
      final localGifts = await dbHelper.getGifts(eventId);

      // Step 1: Add missing gifts from Firebase to the local database
      for (var giftDoc in giftsSnapshot.docs) {
        final gift = Gift.fromMap(giftDoc.data());
        if (!localGifts.any((g) => g.id == gift.id)) {
          await dbHelper.insertGift(gift);
          print('[SYNC] Added gift with ID: ${gift.id} to local database');
        }
      }

      // Step 2: Remove gifts that are no longer in Firebase
      for (var localGift in localGifts) {
        if (!firebaseGiftIds.contains(localGift.id.toString())) {
          await dbHelper.deleteGift(localGift.id!);
          print('[SYNC] Removed deleted gift with ID: ${localGift.id} from local database');
          syncStatusManager.updateStatus("Offline");
        }
      }

      print('[SYNC] Friend gifts sync completed successfully for eventId: $eventId');
      syncStatusManager.updateStatus("Synced");
    } catch (e) {
      print('[SYNC ERROR] Failed to sync gifts: $e');
    }
  }


  Future<void> syncWithLocalDatabase(DatabaseHelper dbHelper, int userId) async {
    try {
      syncStatusManager.updateStatus("Syncing...");
      // === Sync User Data ===
      final firebase_auth.User? firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user logged in via Firebase Authentication.');
      }

      // Fetch user from Firebase
      final firebaseUserDoc = await _firestore.collection('users').doc(userId.toString()).get();
      if (firebaseUserDoc.exists) {
        final user = User.fromMap(firebaseUserDoc.data()!);

        // Check if the user exists locally
        User? localUser = await dbHelper.getUser(user.id!);
        if (localUser == null) {
          localUser = await dbHelper.getUserByEmail(firebaseUser.email!);
        }

        // Insert user locally if missing
        if (localUser == null) {
          await dbHelper.insertUser(user);
        }
      }

      // === Sync Events for the User ===
      final firebaseEvents = await _firestore
          .collection('events')
          .where('userId', isEqualTo: userId)
          .get();
      final localEvents = await dbHelper.getEvents(userId);

      // Push local events to Firebase
      for (var localEvent in localEvents) {
        if (!firebaseEvents.docs.any((doc) => doc.id == localEvent.id.toString())) {
          await _firestore.collection('events').doc(localEvent.id.toString()).set(localEvent.toMap());
          print('Local event pushed to Firebase: ${localEvent.id}');
        }
      }

      // Pull events from Firebase to local database
      for (var doc in firebaseEvents.docs) {
        final event = Event.fromMap(doc.data());
        if (!localEvents.any((e) => e.id == event.id)) {
          await dbHelper.insertEvent(event);
        }
      }

      // === Sync Events for Friends ===
      final firebaseFriends = await _firestore
          .collection('friends')
          .where('userId', isEqualTo: userId)
          .get();
      for (var friendDoc in firebaseFriends.docs) {
        final friend = Friend.fromMap(friendDoc.data());

        // Insert missing friends into the local database
        final localFriends = await dbHelper.getFriends(userId);
        if (!localFriends.any((f) => f.friendId == friend.friendId)) {
          await dbHelper.addFriend(friend);
        }

        // Fetch friend's events from Firebase
        final friendEvents = await _firestore
            .collection('events')
            .where('userId', isEqualTo: friend.friendId)
            .get();
        final localFriendEvents = await dbHelper.getEvents(friend.friendId);

        // Sync friend's events
        for (var eventDoc in friendEvents.docs) {
          final friendEvent = Event.fromMap(eventDoc.data());
          if (!localFriendEvents.any((e) => e.id == friendEvent.id)) {
            await dbHelper.insertEvent(friendEvent);
          }
        }
      }

      // === Sync Gifts for All Events ===
      final localAllEvents = await dbHelper.getAllEvents(); // Get all events (user + friends)
      for (var localEvent in localAllEvents) {
        final firebaseGifts = await _firestore
            .collection('gifts')
            .where('eventId', isEqualTo: localEvent.id)
            .get();
        final localGifts = await dbHelper.getGifts(localEvent.id!);

        // Push local gifts to Firebase
        for (var localGift in localGifts) {
          if (!firebaseGifts.docs.any((doc) => doc.id == localGift.id.toString())) {
            await _firestore.collection('gifts').doc(localGift.id.toString()).set(localGift.toMap());
            print('Local gift pushed to Firebase: ${localGift.id}');
          }
        }

        // Pull gifts from Firebase to local database
        for (var doc in firebaseGifts.docs) {
          final gift = Gift.fromMap(doc.data());
          if (!localGifts.any((g) => g.id == gift.id)) {
            await dbHelper.insertGift(gift);
          }
        }
      }

      print('Complete sync with Firebase completed successfully.');
      syncStatusManager.updateStatus("Synced");
    } catch (e) {
      print('Error during sync: $e');
      syncStatusManager.updateStatus("Offline");
      rethrow;
    }
  }



}
