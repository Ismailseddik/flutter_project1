import 'package:flutter/material.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../styles.dart';
import '../widgets/common_header.dart';
import '../widgets/profile_section.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import 'FriendEventListPage.dart';

class HomePage extends StatefulWidget {
  final int userId; // Pass the logged-in user's ID

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = ''; // To hold the user's name dynamically
  List<Friend> friends = []; // List to hold friends
  final TextEditingController emailController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserInfo(); // Fetch user's name
    _loadFriends(); // Fetch friends
  }

  // Fetch user's name from the database
  Future<void> _loadUserInfo() async {
    final db = DatabaseHelper.instance;

    try {
      final user = await db.getUser(widget.userId); // Fetch user by ID
      setState(() {
        userName = user.name; // Assign user's name dynamically
      });
    } catch (e) {
      print('Error fetching user: $e');
    }
  }

  // Fetch friends for the logged-in user
  Future<void> _loadFriends() async {
    final db = DatabaseHelper.instance;

    try {
      final fetchedFriends = await db.getFriends(widget.userId);

      if (fetchedFriends.isEmpty) {
        await db.addDummyData(widget.userId); // Add dummy data for testing
        final updatedFriends = await db.getFriends(widget.userId);

        setState(() {
          friends = updatedFriends;
        });
      } else {
        setState(() {
          friends = fetchedFriends;
        });
      }
    } catch (e) {
      print('Error fetching friends: $e');
    }
  }

  Future<void> _addFriend() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Please enter an email.');
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
    } catch (e) {
      _showSnackBar('Error adding friend: $e');
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'Friends List',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
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
          child: Column(
            children: [
              ProfileSection(
                userName: userName.isNotEmpty ? userName : 'Loading...', // Show the user's name dynamically
                onProfileIconTapped: () {
                  Navigator.pushNamed(context, '/profile', arguments: widget.userId);
                },
              ),
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
              Expanded(
                child: friends.isEmpty
                    ? Center(
                  child: Text(
                    'No friends found. Add some friends!',
                    style: AppStyles.subtitleTextStyle.copyWith(fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          'Friend ID: ${friend.friendId}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Associated User: ${friend.userId}',
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendEventListPage(friendId: friend.friendId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
