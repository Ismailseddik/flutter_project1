import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/common_header.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';

class ProfilePage extends StatefulWidget {
  final int userId; // Pass the logged-in user's ID

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Event> events = []; // List to hold events
  User? user; // To hold the logged-in user's details
  bool isEditing = false; // To toggle edit mode
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserEvents(); // Fetch events on initialization
    _loadUserProfile(); // Fetch user profile on initialization
  }

  Future<void> _loadUserEvents() async {
    final db = DatabaseHelper.instance;
    final userEvents = await db.getEvents(widget.userId); // Fetch events for the user

    setState(() {
      events = userEvents;
    });
  }

  Future<void> _loadUserProfile() async {
    final db = DatabaseHelper.instance;
    try {
      // Fetch user details by ID
      final fetchedUser = await db.getUser(widget.userId);
      setState(() {
        user = fetchedUser;
        nameController.text = user!.name; // Pre-fill name
        emailController.text = user!.email; // Pre-fill email
      });
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _updateUserProfile() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name and email cannot be empty')),
      );
      return;
    }

    final db = DatabaseHelper.instance;
    final updatedUser = User(
      id: user!.id,
      name: nameController.text,
      email: emailController.text,
      password: user!.password, // Keep the same password
      preferences: user!.preferences, // Keep preferences unchanged
    );

    try {
      await db.insertUser(updatedUser); // Update user in the database
      setState(() {
        user = updatedUser;
        isEditing = false; // Exit edit mode
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'Profile',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info
            user == null
                ? Center(child: CircularProgressIndicator())
                : ListTile(
              leading: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.tealAccent,
                backgroundImage: AssetImage('assets/profile_picture.png'),
              ),
              title: isEditing
                  ? TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name'),
              )
                  : Text(user!.name, style: AppStyles.headerTextStyle),
              subtitle: isEditing
                  ? TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              )
                  : Text(user!.email, style: AppStyles.subtitleTextStyle),
              trailing: IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit),
                onPressed: () {
                  if (isEditing) {
                    _updateUserProfile(); // Save the updated profile
                  } else {
                    setState(() {
                      isEditing = true; // Enable edit mode
                    });
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Text('My Events', style: AppStyles.headerTextStyle),
            SizedBox(height: 10),
            // Events List
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.event, color: Colors.teal),
                      title: Text(event.name),
                      subtitle: Text('Date: ${event.date}'),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to GiftListPage for the event
                        Navigator.pushNamed(
                          context,
                          '/gifts',
                          arguments: {
                            'id': event.id, // Pass the event ID as 'id'
                            'isFriendView': false, // Indicate this is NOT a friend's view
                            'eventId': event.id, // Pass the event ID again
                          }, // Pass event ID to GiftListPage
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
    );
  }
}
