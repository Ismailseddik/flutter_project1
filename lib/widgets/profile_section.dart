import 'dart:convert'; // For base64 encoding/decoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trial/styles.dart';

class ProfileSection extends StatefulWidget {
  final String userName;
  final int userId; // Add userId to fetch images
  final String? profileImagePath; // <-- Added to allow external dynamic updates
  final VoidCallback onProfileIconTapped;

  ProfileSection({
    required this.userName,
    required this.userId,
    this.profileImagePath, // <-- Optional external image path
    required this.onProfileIconTapped,
  });

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  File? _profileImage; // Local profile image
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeProfileImage();
  }

  // Initialize profile image based on parent-provided path or load from storage/Firebase
  Future<void> _initializeProfileImage() async {
    setState(() => _isLoading = true);

    if (widget.profileImagePath != null && File(widget.profileImagePath!).existsSync()) {
      // Use external image path if provided
      setState(() {
        _profileImage = File(widget.profileImagePath!);
      });
      print('Debug: Profile image loaded from external path.');
    } else {
      // Load image from local storage or Firebase
      await _loadProfileImage();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadProfileImage() async {
    final localImagePath = await _getLocalImagePath();

    if (await File(localImagePath).exists()) {
      // Load image from local storage
      setState(() {
        _profileImage = File(localImagePath);
      });
      print('Debug: Profile image loaded from local storage.');
    } else {
      // Fetch image from Firebase
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('profile_pictures')
            .where('userId', isEqualTo: widget.userId)
            .orderBy('imageId', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final base64Image = snapshot.docs.first['base64Image'];

          // Decode and save the image temporarily
          final decodedBytes = base64Decode(base64Image);
          final tempDir = await getTemporaryDirectory();
          final tempImagePath =
              '${tempDir.path}/profile_${widget.userId}_temp.jpg';
          final tempImageFile =
          await File(tempImagePath).writeAsBytes(decodedBytes);

          setState(() {
            _profileImage = tempImageFile;
          });

          print('Debug: Profile image fetched from Firebase.');
        } else {
          print('Debug: No profile image found in Firebase.');
        }
      } catch (e) {
        print('Error fetching profile image: $e');
      }
    }
  }

  Future<String> _getLocalImagePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/profile_${widget.userId}.jpg';
  }

  @override
  void didUpdateWidget(covariant ProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the external profileImagePath changes, reload the image
    if (widget.profileImagePath != oldWidget.profileImagePath) {
      _initializeProfileImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: widget.onProfileIconTapped,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.tealAccent,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : AssetImage('assets/user_profile.png') as ImageProvider,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : (_profileImage == null
                  ? Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              )
                  : null),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Hello, ${widget.userName}!',
            style: AppStyles.headerTextStyle,
          ),
          Text(
            'Welcome back!',
            style: AppStyles.subtitleTextStyle,
          ),
        ],
      ),
    );
  }
}
