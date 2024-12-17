import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import '../SyncStatusManager.dart';
import '../styles.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
class ProfilePage extends StatefulWidget {
  final int userId; // Pass the logged-in user's ID

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage; // Locally saved profile image
  List<Event> events = []; // List to hold events
  User? user; // To hold the logged-in user's details
  bool isEditing = false; // To toggle edit mode
  // Controllers for user data fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadUserEvents(); // Fetch events on initialization
    _loadUserProfile(); // Fetch user profile on initialization
    _loadProfileImage();
  }
// 1. Load profile image: Check local storage first, then fetch from Firebase
  Future<void> _loadProfileImage() async {
    final imagePath = await _getProfileImagePath();
    if (imagePath != null && await File(imagePath).exists()) {
      setState(() {
        _profileImage = File(imagePath);
      });
      print('Debug: Profile image loaded from local storage.');
    } else {
      // Fetch profile image from Firestore
      try {
        final firestore = FirebaseFirestore.instance;
        syncStatusManager.updateStatus("Syncing...");
        final snapshot = await firestore
            .collection('profile_pictures')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('imageId', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final base64Image = snapshot.docs.first['base64Image'];
          final decodedBytes = base64Decode(base64Image);
          final tempDir = await getTemporaryDirectory();
          final tempImagePath = '${tempDir.path}/profile_${widget.userId}.jpg';
          final tempImageFile =
          await File(tempImagePath).writeAsBytes(decodedBytes);

          setState(() {
            _profileImage = tempImageFile;
          });
          print('Debug: Profile image loaded from Firestore and saved locally.');
          syncStatusManager.updateStatus("Synced");
        } else {
          print('Debug: No profile image found for userId ${widget.userId}.');
          syncStatusManager.updateStatus("Synced");

        }
      } catch (e) {
        print('Error fetching profile image from Firestore: $e');
        syncStatusManager.updateStatus("Offline");
      }
    }
  }
  // 2. Capture and upload a new profile image
  Future<void> _captureAndUploadProfileImage() async {
    try {
      syncStatusManager.updateStatus("Syncing...");
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        // Save image locally
        final savedImagePath = await _saveImageToLocalDirectory(pickedFile);
        setState(() {
          _profileImage = File(savedImagePath);
        });

        // Convert to base64 and upload to Firestore
        final base64Image = await _convertImageToBase64(File(savedImagePath));
        await _addProfileImageRecordToFirestore(base64Image);
        syncStatusManager.updateStatus("Synced");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      print('Error capturing/uploading profile image: $e');
      syncStatusManager.updateStatus("Offline");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture.')),
      );
    }
  }
  // 3. Save profile image locally
  Future<String> _saveImageToLocalDirectory(XFile pickedFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${widget.userId}.jpg';
    final savedImagePath = '${appDir.path}/$fileName';
    await File(pickedFile.path).copy(savedImagePath);
    return savedImagePath;
  }
  // 4. Get the profile image path
  Future<String?> _getProfileImagePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/profile_${widget.userId}.jpg';
    return filePath;
  }
  // 5. Convert image file to base64 string
  Future<String> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }
  // 6. Add profile image record to Firestore
  Future<void> _addProfileImageRecordToFirestore(String base64Image) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('profile_pictures').add({
      'userId': widget.userId,
      'imageId': DateTime.now().millisecondsSinceEpoch,
      'base64Image': base64Image,
    });
    print('Debug: Profile image record added to Firestore.');
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
        passwordController.text = user!.password;
        preferencesController.text = user!.preferences ?? '';
      });
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }
  // Function to show popup dialog for editing user data
  Future<void> _showEditProfilePopup() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                TextField(
                  controller: preferencesController,
                  decoration: InputDecoration(labelText: 'Preferences'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancel action
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateUserProfile, // Update action
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  // Update user profile
  Future<void> _updateUserProfile() async {
    final db = DatabaseHelper.instance;

    // Ensure no critical fields (like ID and password) are modified unintentionally
    final updatedUser = User(
      id: user!.id, // Keep the original ID
      name: nameController.text,
      email: emailController.text,
      password: user!.password, // Keep the original password unless explicitly changed
      preferences: preferencesController.text,
    );

    try {
      // Update user in local database
      await db.insertUser(updatedUser);

      // Update specific fields in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.id.toString()) // Use the correct document ID
          .update({
        'name': updatedUser.name,
        'email': updatedUser.email,
        'preferences': updatedUser.preferences,
      });

      setState(() {
        user = updatedUser;
      });

      Navigator.pop(context); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    }
  }


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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info
            user == null
                ? Center(child: CircularProgressIndicator())
                : ListTile(
              leading: GestureDetector(
                onTap: _captureAndUploadProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.tealAccent,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : AssetImage('assets/profile_picture.png')
                  as ImageProvider,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt, color: Colors.white, size: 40)
                      : null,
                ),
              ),
              title: Text(user!.name, style: AppStyles.headerTextStyle),
              subtitle: Text(user!.email, style: AppStyles.subtitleTextStyle),
              trailing: IconButton(
                icon: Icon(Icons.edit, color: Colors.teal),
                onPressed: _showEditProfilePopup, // Trigger the popup dialog
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
                        // Original working navigation logic
                        Navigator.pushNamed(
                          context,
                          '/gifts',
                          arguments: {
                            'id': event.id, // Pass the event ID as 'id'
                            'isFriendView': false, // Indicate this is NOT a friend's view
                            'eventId': event.id, // Pass the event ID again
                          },
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