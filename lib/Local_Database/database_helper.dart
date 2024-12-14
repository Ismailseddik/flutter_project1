import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../SyncStatusManager.dart';
import '../models/models.dart'; // Import the models for Users, Events, Gifts, Friends
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    try {
      _database = await _initDB('hedieaty.db');
    } catch (e) {
      print('Error initializing database: $e');
    }

    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      email TEXT UNIQUE,
      password TEXT, -- Add the password field
      preferences TEXT
    );
  ''');

    await db.execute('''
      CREATE TABLE events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        date TEXT,
        location TEXT,
        description TEXT,
        userId INTEGER,
        friendId INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (friendId) REFERENCES friends (friendId)
      );
    ''');

    await db.execute('''
      CREATE TABLE gifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        category TEXT,
        price REAL,
        status TEXT,
        eventId INTEGER,
        friendId INTEGER,
        FOREIGN KEY (eventId) REFERENCES events (id)
      );
    ''');

    await db.execute('''
      CREATE TABLE friends (
        userId INTEGER,
        friendId INTEGER,
        PRIMARY KEY (userId, friendId),
        FOREIGN KEY (userId) REFERENCES users (id),
        FOREIGN KEY (friendId) REFERENCES users (id)
      );
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // ======== USER OPERATIONS ========

  // Insert a new user during sign-up
  Future<int> insertUser(User user) async {
    final db = await instance.database;

    // Check if the user already exists
    final existingUser = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [user.id],
    );

    if (existingUser.isNotEmpty) {
      // Update the existing user record
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } else {
      // Insert new user record
      await db.insert('users', user.toMap());
    }

    // Trigger user-specific sync
    try {
      await FirebaseHelper.instance.syncWithLocalDatabase(this, user.id!);
      print('Sync completed successfully for user: ${user.id}');
    } catch (e) {
      print('Error syncing after user insertion: $e');
    }

    return user.id!;
  }


  // Get user by ID
  Future<User> getUser(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      throw Exception('User not found');
    }
  }

  // Authenticate user during login
  Future<User?> authenticateUser(String email, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?', // Ensure password is validated
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null; // User not found
  }
  // Method to fetch the current logged-in user's ID
  Future<int?> getCurrentUserId() async {
    final db = await database;

    try {
      // Check if the logged_in column exists
      final result = await db.query('sqlite_master', where: 'name = ? AND sql LIKE ?', whereArgs: ['users', '%logged_in%']);
      if (result.isNotEmpty) {
        // logged_in column exists
        final userResult = await db.query(
          'users',
          where: 'logged_in = ?',
          whereArgs: [1],
          limit: 1,
        );

        if (userResult.isNotEmpty) {
          return userResult.first['id'] as int;
        }
      } else {
        // Fallback to Firebase Authentication
        final firebase_auth.User? firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final localUser = await getUserByEmail(firebaseUser.email!);
          return localUser?.id;
        }
      }
    } catch (e) {
      print('Error fetching current user ID: $e');
    }

    return null; // Return null if no logged-in user is found
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    try {
      final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
      if (result.isNotEmpty) {
        return User.fromMap(result.first);
      }
    } catch (e) {
      print('Error fetching user by email: $e');
    }
    return null;
  }


  // ======== EVENT OPERATIONS ========

  // Insert a new event
  Future<void> insertEvent(Event event, {int? friendId}) async {
    final db = await instance.database;

    // Create a new Event object with the friendId if provided
    final eventToInsert = Event(
      id: event.id,
      name: event.name,
      date: event.date,
      location: event.location,
      description: event.description,
      userId: event.userId,
      friendId: friendId ?? event.friendId, // Use the provided friendId or retain the original
    );

    await db.insert('events', eventToInsert.toMap());

    // Trigger sync after inserting the event
    try {
      await FirebaseHelper.instance.syncWithLocalDatabase(this,event.userId);
      print('Sync after creating event successful!');
    } catch (e) {
      print('Error syncing after creating event: $e');
    }
  }
  /// Update an event in the local SQLite database
  Future<void> updateEvent(int eventId, Map<String, dynamic> updates) async {
    final db = await instance.database;
    // Trigger sync
    syncStatusManager.updateStatus("Syncing...");

    try {
      await db.update(
        'events',
        updates,
        where: 'id = ?',
        whereArgs: [eventId],
      );

      // Sync the updated event with Firebase
      final existingEvent = await getEventById(eventId);
      if (existingEvent != null) {
        await FirebaseHelper.instance.updateEvent(eventId, updates);
      }

      print('Event updated successfully in the local database.');
      syncStatusManager.updateStatus("Synced");
    } catch (e) {
      syncStatusManager.updateStatus("Offline");
      print('Error updating event in the local database: $e');
      rethrow;
    }
  }
  /// Delete an event and its associated gifts in the local SQLite database
  Future<void> deleteEventWithCascading(int eventId) async {
    final db = await instance.database;
    // Trigger sync
    syncStatusManager.updateStatus("Syncing...");
    try {
      // Delete associated gifts
      await db.delete(
        'gifts',
        where: 'eventId = ?',
        whereArgs: [eventId],
      );

      // Delete the event itself
      await db.delete(
        'events',
        where: 'id = ?',
        whereArgs: [eventId],
      );

      // Sync the deletion with Firebase
      await FirebaseHelper.instance.deleteEventWithCascading(eventId);

      print('Event and associated gifts deleted successfully in the local database.');
      syncStatusManager.updateStatus("Synced");
    } catch (e) {
      syncStatusManager.updateStatus("Offline");
      print('Error deleting event with cascading in the local database: $e');
      rethrow;
    }
  }

  /// Fetch a single event by its ID
  Future<Event?> getEventById(int eventId) async {
    final db = await instance.database;
    final result = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    if (result.isNotEmpty) {
      return Event.fromMap(result.first);
    }

    return null;
  }


  // Get events by user ID
  Future<List<Event>> getEvents(int userId) async {
    final db = await instance.database;
    final maps = await db.query(
      'events',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  // ======== GIFT OPERATIONS ========

  // Insert a new gift
  Future<int> insertGift(Gift gift) async {
    final db = await instance.database;

    try {
      // Insert the gift into the local database
      final giftId = await db.insert('gifts', gift.toMap());
      print('Gift inserted successfully with ID: $giftId for eventId: ${gift.eventId}');

      // Sync the gift to Firebase
      final currentUserId = await getCurrentUserId();
      if (currentUserId != null) {
        // Create a new gift object with the assigned ID
        final Gift updatedGift = Gift(
          id: giftId,
          name: gift.name,
          description: gift.description,
          category: gift.category,
          price: gift.price,
          status: gift.status,
          eventId: gift.eventId,
          friendId: gift.friendId,
        );
        await FirebaseHelper.instance.createGift(updatedGift); // Sync with Firebase
        print('Gift synced with Firebase successfully!');
      } else {
        print('Error: User ID not found. Unable to sync gift.');
      }

      return giftId; // Return the inserted gift's ID
    } catch (e) {
      print('Error inserting gift: $e');
      rethrow;
    }
  }



  // Get gifts by event ID
  Future<List<Gift>> getGifts(int eventId) async {
    final db = await instance.database;
    final maps = await db.query('gifts', where: 'eventId = ?', whereArgs: [eventId]);

    return maps.map((map) => Gift.fromMap(map)).toList();
  }

  // Get gifts pledged by a friend
  Future<List<Gift>> getGiftsByFriendId(int friendId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'gifts',
      where: 'friendId = ?',
      whereArgs: [friendId],
    );

    return maps.map((map) => Gift.fromMap(map)).toList();
  }

  // Fetch all gifts associated with a friend's events
  Future<List<Gift>> getFriendEventGifts(int friendId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> eventMaps = await db.query(
      'events',
      where: 'userId = ?', // Assuming userId in the events table is the friend's ID
      whereArgs: [friendId],
    );

    if (eventMaps.isEmpty) {
      return [];
    }

    final List<int> eventIds = eventMaps.map((event) => event['id'] as int).toList();

    final List<Map<String, dynamic>> giftMaps = await db.query(
      'gifts',
      where: 'eventId IN (${eventIds.join(', ')})',
    );

    return giftMaps.map((map) => Gift.fromMap(map)).toList();
  }
  // ======== GIFT OPERATIONS ========
  Future<void> updateGift(int giftId, Map<String, dynamic> updates) async {
    final db = await instance.database;

    try {
      // Check if the gift exists
      final gift = await db.query('gifts', where: 'id = ?', whereArgs: [giftId]);
      if (gift.isEmpty) {
        throw Exception('Gift not found');
      }

      // Update the gift in the local database
      await db.update('gifts', updates, where: 'id = ?', whereArgs: [giftId]);

      // Update the gift in Firebase
      await FirebaseHelper.instance.updateGift(giftId, updates);
      print('Gift updated successfully');
    } catch (e) {
      print('Error updating gift: $e');
      rethrow;
    }
  }


  Future<Gift?> getGiftById(int giftId) async {
    final db = await database;
    final result = await db.query(
      'gifts',
      where: 'id = ?',
      whereArgs: [giftId],
    );

    if (result.isNotEmpty) {
      return Gift.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<void> deleteGift(int giftId) async {
    final db = await instance.database;
    print('Deleting gift with ID: $giftId');
    try {
      final gift = await db.query('gifts', where: 'id = ?', whereArgs: [giftId]);
      if (gift.isEmpty) {
        throw Exception('Gift not found');
      }

      if (gift.first['status'] == 'Pledged') {
        throw Exception('Cannot delete a pledged gift');
      }

      await db.delete('gifts', where: 'id = ?', whereArgs: [giftId]);
    } catch (e) {
      print('Error deleting gift: $e');
      rethrow;
    }
  }
// Method to update the status of a gift
  Future<void> updateGiftStatus(int giftId, String status) async {
    final db = await database;

    try {
      await db.update(
        'gifts',
        {'status': status},
        where: 'id = ?',
        whereArgs: [giftId],
      );
      print('Gift status updated successfully');
    } catch (e) {
      print('Error updating gift status: $e');
    }
  }

  // ======== FRIEND OPERATIONS ========

  // Add a friend
  Future<void> addFriend(Friend friend) async {
    final db = await instance.database;
    await db.insert('friends', friend.toMap());

    // Trigger sync after adding a friend
    try {
      await FirebaseHelper.instance.syncWithLocalDatabase(this,friend.userId);
      print('Sync after adding friend successful!');
    } catch (e) {
      print('Error syncing after adding friend: $e');
    }
  }
// Check if Friend Relationship Exists
  Future<bool> isFriendAlreadyAdded(int userId, int friendId) async {
    final db = await database;
    final result = await db.query(
      'friends',
      where: 'userId = ? AND friendId = ?',
      whereArgs: [userId, friendId],
    );

    return result.isNotEmpty; // Return true if the relationship exists
  }

  // Get friends by user ID
  Future<List<Friend>> getFriends(int userId) async {
    final db = await instance.database;
    final maps = await db.query('friends', where: 'userId = ?', whereArgs: [userId]);

    return maps.map((map) => Friend.fromMap(map)).toList();
  }
// Get events by friend ID
// Get events by friend ID
  Future<List<Event>> getFriendEvents(int friendId) async {
    final db = await instance.database;

    // Fetch events where userId matches the friend's userId
    final maps = await db.query(
      'events',
      where: 'userId = ?', // userId corresponds to the friend's ID in the users table
      whereArgs: [friendId],
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }


  /*// ======== DUMMY DATA FOR TESTING ========

  Future<void> addDummyData(int userId) async {
    final db = await instance.database;

    // Add dummy users (to represent friends)
    final dummyUsers = [
      User(id: 101, name: 'Alice', email: 'alice@example.com', password: 'password', preferences: ''),
      User(id: 102, name: 'Bob', email: 'bob@example.com', password: 'password', preferences: ''),
      User(id: 103, name: 'Charlie', email: 'charlie@example.com', password: 'password', preferences: ''),
    ];

    for (var user in dummyUsers) {
      await db.insert('users', user.toMap());
    }

    // Add dummy friends
    final dummyFriends = [
      Friend(userId: userId, friendId: 101),
      Friend(userId: userId, friendId: 102),
      Friend(userId: userId, friendId: 103),
    ];

    for (var friend in dummyFriends) {
      await addFriend(friend);
    }

    // Add dummy events for friends
    final dummyEvents = [
      Event(name: 'Birthday Party', date: 'Dec 25', location: 'Home', description: '', userId: 101),
      Event(name: 'Wedding Anniversary', date: 'Jan 1', location: 'Resort', description: '', userId: 102),
      Event(name: 'Baby Shower', date: 'Feb 14', location: 'Hall', description: '', userId: 103),
    ];

    for (var event in dummyEvents) {
      await insertEvent(event);
    }

    // Add dummy gifts for events
    final dummyGifts = [
      Gift(name: 'Smart Watch', description: 'Tech gift', category: 'Electronics', price: 200, status: 'Pledged', eventId: 1, friendId: 101),
      Gift(name: 'Perfume', description: 'Fashion gift', category: 'Fashion', price: 50, status: 'Available', eventId: 2, friendId: 102),
      Gift(name: 'Teddy Bear', description: 'Toy gift', category: 'Toys', price: 20, status: 'Available', eventId: 3, friendId: 103),
    ];

    for (var gift in dummyGifts) {
      await insertGift(gift);
    }
  }*/
  // ======== SYNCING METHODS ========

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  Future<List<Event>> getAllEvents() async {
    final db = await database;
    final maps = await db.query('events');
    return maps.map((map) => Event.fromMap(map)).toList();
  }

  Future<List<Gift>> getAllGifts() async {
    final db = await database;
    final maps = await db.query('gifts');
    return maps.map((map) => Gift.fromMap(map)).toList();
  }

  Future<List<Friend>> getAllFriends() async {
    final db = await database;
    final maps = await db.query('friends');
    return maps.map((map) => Friend.fromMap(map)).toList();
  }


}
