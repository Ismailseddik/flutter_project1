import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../main.dart';
import '../styles.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import '../widgets/notification_bell.dart';
import '../widgets/profile_section.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import 'FriendEventListPage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:convert'; // For base64 encoding/decoding
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'MyPledgedGiftsPage.dart';
import 'event_list_page.dart';
import '../notification_service/notification_service.dart'; // Import NotificationService
import '../notification_service/notification_handler.dart';
class HomePage extends StatefulWidget {
  final int userId; // Pass the logged-in user's ID

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool isRefreshing = false; // Tracks whether profile needs refreshing
  String userName = ''; // To hold the user's name dynamically
  List<Friend> friends = []; // List to hold friends
  final TextEditingController emailController = TextEditingController();
  String profileImagePath = '';
  int eventsCount = 0; // Number of events created
  int giftsPledgedCount = 0; // Number of gifts pledged
  int friendsCount = 0; // Number of friends added
  final NotificationHandler _notificationHandler = NotificationHandler();
  Stream<QuerySnapshot>? notificationsStream;
  // Map for friend names
  late Map<int, String> friendNames = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeNotifications(); // Initialize NotificationService
    _loadUserInfo(); // Fetch user's name
    _loadFriends(); // Fetch friends
    _loadAnalytics(); // Load analytics data
    // Start listening to notifications
    _listenForRealTimeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      print('[HomePage] Initializing Notifications...');
      await NotificationService().init(context);
      await _uploadUserToken(); // Ensure token is uploaded
      print('[HomePage] Notifications initialized successfully.');
    } catch (e) {
      print('[HomePage] Error initializing Notifications: $e');
    }
  }
  Future<void> _uploadUserToken() async {
    try {
      final String? fcmToken = await NotificationService().getFirebaseMessagingToken();
      if (fcmToken != null) {
        await _notificationHandler.uploadUserToken(
          userId: widget.userId.toString(),
          fcmToken: fcmToken,
        );
        print('[HomePage] User FCM token uploaded successfully.');
      } else {
        print('[HomePage] FCM token is null.');
      }
    } catch (e) {
      print('[HomePage] Error uploading FCM token: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop observing lifecycle
    super.dispose();
  }
  // Force a full refresh of the HomePage
  void _refreshPage() {
    setState(() {
      isRefreshing = true;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        isRefreshing = false;
      });
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("Debug: App resumed, refreshing analytics.");
      rebuildAnalytics();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //NotificationService().initializeLocalNotifications();
    NotificationService().listenForNewNotifications(widget.userId.toString());
    _initializeNotifications();
    _loadUserInfo();
    _loadFriends();
    rebuildAnalytics();
  }

  // Fetch user's name from the database
  Future<void> _loadUserInfo() async {
    final db = DatabaseHelper.instance;

    try {
      final user = await db.getUser(widget.userId); // Fetch user by ID
      setState(() {
        userName = user.name; // Assign user's name dynamically
      });
      await _refreshProfileSection();
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  // Fetch friends for the logged-in user
  Future<void> _loadFriends() async {
    final dbHelper = DatabaseHelper.instance;
    final firebaseHelper = FirebaseHelper.instance;

    try {
      // Fetch friends list
      final fetchedFriends = await dbHelper.getFriends(widget.userId);

      print('Debug: Fetched friends from local database: $fetchedFriends');

      // Clear the friendNames map before populating
      friendNames.clear();

      for (final friend in fetchedFriends) {
        String friendName = "Unknown Friend";

        try {
          // Fetch the friend's name using FirebaseHelper's getUserNameById
          print('Debug: Fetching name for friendId: ${friend.friendId}');
          final fetchedName = await firebaseHelper.getUserNameById(friend.friendId.toString());

          if (fetchedName != null) {
            friendName = fetchedName;
            print('Debug: Name found for friendId ${friend.friendId}: $friendName');
          } else {
            print('Debug: No name found for friendId ${friend.friendId}');
          }
        } catch (e) {
          print('Error fetching friend name for ID ${friend.friendId}: $e');
        }

        // Populate the friendNames map
        friendNames[friend.friendId] = friendName;
      }

      // Update the state
      setState(() {
        friends = fetchedFriends; // Preserve the original friends list
      });

      print('Debug: Final friendNames map: $friendNames');
    } catch (e) {
      print('Error fetching friends: $e');
    }
  }



  void rebuildAnalytics() {
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final db = DatabaseHelper.instance;
    final firebase = FirebaseHelper.instance;
    _refreshProfileSection();
    try {
      print('Debug: Starting analytics refresh...');

      final userId = widget.userId;
      final events = await db.getEvents(userId);
      final friendsList = await db.getFriends(userId);

      // Fetching pledged gifts from Firebase
      final firebaseGifts = await firebase.getGiftsWithCriteria({
        'friendId': userId,
        'status': 'Pledged',
      });

      setState(() {
        eventsCount = events.length;
        giftsPledgedCount = firebaseGifts.length;
        friendsCount = friendsList.length;
      });

      print('Debug: Analytics refreshed successfully.');
      print('Debug: Events Count: $eventsCount');
      print('Debug: Pledged Gifts Count: $giftsPledgedCount');
      print('Debug: Friends Count: $friendsCount');
    } catch (e) {
      print('Error loading analytics data: $e');
    }
  }
  // Return local image path
  Future<String> _getLocalImagePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/profile_${widget.userId}.jpg';
  }
  // Refresh profile image (local + Firebase fallback)
  Future<void> _refreshProfileSection() async {
    final localImagePath = await _getLocalImagePath();

    if (await File(localImagePath).exists()) {
      setState(() {
        profileImagePath = localImagePath;
      });
      print('Debug: Profile image loaded from local storage.');
    } else {
      print('Debug: No local profile image, fetching from Firebase...');
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profile_pictures')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('imageId', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final base64Image = snapshot.docs.first['base64Image'];
          final decodedBytes = base64Decode(base64Image);
          final tempDir = await getTemporaryDirectory();
          final tempImagePath = '${tempDir.path}/profile_${widget.userId}_temp.jpg';
          await File(tempImagePath).writeAsBytes(decodedBytes);

          setState(() {
            profileImagePath = tempImagePath;
          });
          print('Debug: Profile image refreshed from Firebase.');
        }
      } catch (e) {
        print('Error refreshing profile image: $e');
      }
    }
  }

  Future<void> _addFriend() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email.');
      return;
    }
    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }
    try {
      final firebaseHelper = FirebaseHelper.instance;
      final dbHelper = DatabaseHelper.instance;

      // Fetch friendId by email
      final friendId = await firebaseHelper.getUserIdByEmail(email);

      if (friendId == null) {
        _showSnackBar('No user found with this email.');
        return;
      }

      // Check if already added
      final isAlreadyAdded =
      await dbHelper.isFriendAlreadyAdded(widget.userId, friendId);

      if (isAlreadyAdded) {
        _showSnackBar('This user is already your friend.');
        return;
      }

      // Add friend locally
      final newFriend = Friend(userId: widget.userId, friendId: friendId);
      await dbHelper.addFriend(newFriend);

      // Add friend in Firebase
      await firebaseHelper.addFriend(newFriend);

      _showSnackBar('Friend added successfully!');
      emailController.clear();
      _loadFriends(); // Refresh the list
      _loadAnalytics(); // Refresh analytics
    } catch (e) {
      _showSnackBar('Error adding friend: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

// === NEW DROPDOWN METHOD FOR NOTIFICATIONS ===
  void _showNotificationsDropdown() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: NotificationService().listenForNewNotifications(widget.userId.toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator()); // Loading spinner
            }

            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}")); // Error handling
            }

            final notifications = snapshot.data?.docs ?? [];
            final unreadNotifications = notifications
                .where((doc) => !(doc['isRead'] ?? false))
                .toList();
            return Container(
              height: 300,
              padding: EdgeInsets.all(16),
              child: notifications.isEmpty
                  ? Center(child: Text("No Notifications"))
                  : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final notificationId = notification.id;

                  return ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: notification['isRead'] ?? false
                          ? Colors.grey
                          : Colors.teal,
                    ),
                    title: Text(notification['title'] ?? 'No Title'),
                    subtitle: Text(notification['body'] ?? 'No Body'),
                    onTap: () async {
                      // Mark the notification as read when clicked
                      await NotificationService()
                          .markNotificationAsRead(notificationId);

                      setState(() {}); // Update the UI
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
  /// Listen for new notifications and display a popup
  void _listenForRealTimeNotifications() {
    final stream = NotificationService().listenForNewNotifications(widget.userId.toString());

    stream.listen((snapshot) {
      print("[DEBUG] Listening to notifications...");

      if (snapshot.docs.isNotEmpty) {
        final newNotification = snapshot.docs.last;
        final title = newNotification['title'] ?? 'No Title';
        final body = newNotification['body'] ?? 'No Body';

        print("[DEBUG] New Notification Received - Title: $title, Body: $body");

        // Show a popup SnackBar
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('$title: $body'),
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                _showNotificationsDropdown(); // Open dropdown when clicked
              },
            ),
          ),
        );
      } else {
        print("[DEBUG] No new notifications received.");
      }
    }, onError: (e) {
      print("[ERROR] Error in listening to notifications: $e");
    });
  }



// === END OF DROPDOWN METHOD ===

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "Home",
        onSignOutPressed: () async {
          try {
            await firebase_auth.FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error signing out: $e')),
            );
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    // Centered Profile Section
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20.0), // Adjust spacing
                        child: ProfileSection(
                          userName: userName.isNotEmpty ? userName : 'Loading...',
                          userId: widget.userId,
                          profileImagePath: profileImagePath,
                          onProfileIconTapped: () async {
                            await Navigator.pushNamed(context, '/profile', arguments: widget.userId);
                            rebuildAnalytics(); // Refresh analytics
                          },
                        ),
                      ),
                    ),
                    // Notification Bell Positioned at Top-Right
                    Positioned(
                      right: 20,
                      top: 10,
                      child: NotificationBell(
                        userId: widget.userId.toString(),
                        onBellPressed: _showNotificationsDropdown,
                      ),
                    ),
                  ],
                ),
                // === NEW NOTIFICATION BUTTON BELOW PROFILE SECTION ===
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Rounded button
                      ),
                    ),
                    onPressed: _showNotificationsDropdown, // Show notifications dropdown
                    icon: Icon(Icons.notifications, color: Colors.white),
                    label: Text(
                      'View Notifications',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
// === END OF NOTIFICATION BUTTON ===
                // Analytics Section with Same Height Cards
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      // Row 1: Events Created
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Events Created',
                              eventsCount,
                              Icons.event,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventListPage(userId: widget.userId),
                                  ),
                                ).then((_) {
                                  rebuildAnalytics(); // Reload analytics when back to HomePage
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Gifts Pledged',
                              giftsPledgedCount,
                              Icons.card_giftcard,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyPledgedGiftsPage(userId: widget.userId),
                                  ),
                                ).then((_) {
                                  rebuildAnalytics(); // Reload analytics when back to HomePage
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0), // Add spacing between rows
                      // Row 2: Friends
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Friends', friendsCount, Icons.group,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  style: AppStyles.elevatedButtonStyle,
                  onPressed: () {
                    Navigator.pushNamed(context, '/events', arguments: widget.userId);
                  },
                  child: Text(
                    'Create Your Own Event/List',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
                // Add Friend Section
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Enter friend\'s email',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _addFriend,
                  child: Text('Add Friend'),
                ),
                SizedBox(height: 20),
                friends.isEmpty
                    ? Center(
                  child: Text(
                    'No friends found. Add some friends!',
                    style: AppStyles.subtitleTextStyle.copyWith(fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    final friendName = friendNames[friend.friendId] ?? "Unknown Friend";

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          friendName, // Display friend's name
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Friend ID: ${friend.friendId}', // Keep the ID as well
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FriendEventListPage(friendId: friend.friendId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build analytics cards
  Widget _buildAnalyticsCard(String title, int count, IconData icon,
      {VoidCallback? onTap}) {
    return Flexible(
      child: GestureDetector(
        onTap: onTap, // Navigation functionality for card
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 4), // Shadow position
              ),
            ],
          ),
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.teal, size: 40),
              SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
