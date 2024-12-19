import 'dart:io';
import 'dart:convert'; // For base64 encoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import '../SyncStatusManager.dart';
import '../models/models.dart';
import '../notification_service/notification_handler.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../Firebase_Database/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../widgets/AppBarWithSyncStatus.dart';

class GiftDetailsPage extends StatefulWidget {
  final String giftName;
  final ImageProvider giftImage;
  final int giftId; // Added giftId for interaction

  GiftDetailsPage({
    required this.giftName,
    required this.giftImage,
    required this.giftId,
  });

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _savedImage; // Locally saved image
  bool _isUploading = false; // Upload status indicator
  Gift? giftDetails; // Store gift details fetched from the database
  bool isOwner = false; // Flag to determine if the user is the event owner
  final dbHelper = DatabaseHelper.instance;
  final fbhelper = FirebaseHelper.instance;
  @override
  void initState() {
    super.initState();
    _initializeGiftDetails();
    _loadImageIfAvailable();
  }
  /// Initialize gift details and determine ownership
  Future<void> _initializeGiftDetails() async {
    try {
      // Fetch the gift details
      final gift = await dbHelper.getGiftById(widget.giftId);

      if (gift != null) {
        // Fetch the associated event to determine ownership
        final event = await dbHelper.getEventById(gift.eventId!);
        final currentUserId = await dbHelper.getCurrentUserId();

        if (event != null && currentUserId != null && event.userId == currentUserId) {
          setState(() {
            isOwner = true; // The user owns this event
          });
        }

        // Update the UI with fetched gift details
        setState(() {
          giftDetails = gift;
        });
      }
    } catch (e) {
      print('Error initializing gift details: $e');
    }
  }
  Future<bool> _isCurrentUserOwner() async {
    try {
      final currentUserId = await DatabaseHelper.instance.getCurrentUserId();
      if (currentUserId == null) return false;

      final gift = await DatabaseHelper.instance.getGiftById(widget.giftId);
      if (gift == null) return false;

      final event = await DatabaseHelper.instance.getEventById(gift.eventId!);
      if (event == null) return false;

      return event.userId == currentUserId; // Check if the current user owns the event
    } catch (e) {
      print('Error checking ownership: $e');
      return false; // Default to non-ownership on error
    }
  }
  Future<String?> _fetchGiftDescription() async {
    try {
      final gift = await DatabaseHelper.instance.getGiftById(widget.giftId);
      return gift?.description ?? 'No description available.';
    } catch (e) {
      print('Error fetching gift description: $e');
      return null; // Return null on failure
    }
  }

  // Load the saved image if it exists locally
// Load the image: first check local storage, then Firestore
  Future<void> _loadImageIfAvailable() async {
    final imagePath = await _getSavedImagePath();

    if (imagePath != null && await File(imagePath).exists()) {
      // Load from local storage
      setState(() {
        _savedImage = File(imagePath);
      });
      print('Debug: Image loaded from local storage.');
    } else {
      // Fetch image from Firestore if not found locally
      try {

        final firestore = FirebaseFirestore.instance;
        syncStatusManager.updateStatus("Syncing...");
        // Query Firestore for the image with the giftId
        final snapshot = await firestore
            .collection('gift_images')
            .where('giftId', isEqualTo: widget.giftId)
            .orderBy('imageId', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final base64Image = snapshot.docs.first['base64Image'];

          // Decode the base64 string into an image
          final decodedBytes = base64Decode(base64Image);
          final tempDir = await getTemporaryDirectory();
          final tempImagePath = '${tempDir.path}/gift_${widget.giftId}_temp.jpg';
          final tempImageFile = await File(tempImagePath).writeAsBytes(decodedBytes);

          setState(() {
            _savedImage = tempImageFile;
          });
          print('Debug: Image loaded from Firestore and saved temporarily.');
          syncStatusManager.updateStatus("Synced");
        } else {
          print('Debug: No image found in Firestore for giftId ${widget.giftId}.');
          syncStatusManager.updateStatus("Synced");
        }
      } catch (e) {
        print('Error fetching image from Firestore: $e');
        syncStatusManager.updateStatus("Offline");
      }
    }
  }


  // Retrieve the saved image path
  Future<String?> _getSavedImagePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final filePath = '${appDir.path}/gift_${widget.giftId}.jpg';
    return filePath;
  }

  // Capture, save locally, and upload image as base64 to Firestore
  Future<void> _captureAndUploadImage() async {
    try {
      syncStatusManager.updateStatus("Syncing...");
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() => _isUploading = true);

        // Save image locally
        final savedImagePath = await _saveImageToLocalDirectory(pickedFile);
        setState(() {
          _savedImage = File(savedImagePath);
        });

        // Convert image to base64
        final base64Image = await _convertImageToBase64(File(savedImagePath));

        // Upload base64 string to Firestore
        await _addImageRecordToFirestore(base64Image);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image uploaded to Firestore successfully!')),
        );
        syncStatusManager.updateStatus("Synced");
      }
    } catch (e) {
      syncStatusManager.updateStatus("Offline");
      print('Error capturing/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image. Please try again.')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Save image locally
  Future<String> _saveImageToLocalDirectory(XFile pickedFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'gift_${widget.giftId}.jpg';
    final savedImagePath = '${appDir.path}/$fileName';
    await File(pickedFile.path).copy(savedImagePath);
    return savedImagePath;
  }

  // Convert image file to base64 string
  Future<String> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return base64Encode(bytes);
  }

  // Add base64 image to Firestore
  Future<void> _addImageRecordToFirestore(String base64Image) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('gift_images').add({
      'giftId': widget.giftId,
      'imageId': DateTime.now().millisecondsSinceEpoch, // Unique image ID
      'base64Image': base64Image,
    });
    print('Debug: Image record added to Firestore with base64 data.');
  }

  // Existing pledge functionality
  Future<int?> _getCurrentUserId() async {
    final db = DatabaseHelper.instance;
    try {
      return await db.getCurrentUserId();
    } catch (e) {
      print('Error fetching current user ID: $e');
      return null;
    }
  }

  Future<void> _pledgeGift(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final firebase = FirebaseHelper.instance;

    final currentUserId = await _getCurrentUserId();
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch user ID. Please try again.')),
      );
      return;
    }

    final pledged = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pledge Gift'),
        content: Text('Are you sure you want to pledge this gift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pledge'),
          ),
        ],
      ),
    );

    if (pledged == true) {
      try {
        // Update gift status in Firebase
        await firebase.updateGift(widget.giftId, {
          'status': 'Pledged',
          'friendId': currentUserId,
        });

        // Fetch the current user's name
        String userName = 'Unknown User';
        try {
          userName = await firebase.getUserNameById(currentUserId.toString()) ?? 'Unknown User';
          print('Debug: Username fetched successfully - $userName');
        } catch (e) {
          print('Error fetching username: $e');
        }

        // Notify other users (e.g., the event creator)
        await NotificationHandler().sendGiftPledgeNotification(
          giftId: widget.giftId,
          pledgerName: userName,
          giftName: widget.giftName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift pledged successfully! Notification sent.')),
        );
      } catch (e) {
        print('Error pledging gift on Firebase: $e');
        try {
          // Update gift status locally
          await db.updateGift(widget.giftId, {
            'status': 'Pledged',
            'friendId': currentUserId,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift pledged locally!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pledge gift. Please try again.')),
          );
        }
      }
      Navigator.pop(context, true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "Gift Details",
        onSignOutPressed: () async {
          await firebase_auth.FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SizedBox.expand(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image Capture and Upload
                  GestureDetector(
                    onTap: _captureAndUploadImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundImage: _savedImage != null
                              ? FileImage(_savedImage!)
                              : widget.giftImage,
                          backgroundColor: Colors.grey[200],
                          child: _savedImage == null
                              ? Icon(Icons.camera_alt,
                              size: 40, color: Colors.white70)
                              : null,
                        ),
                        if (_isUploading) CircularProgressIndicator(),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Gift Name
                  Text(
                    widget.giftName,
                    style: AppStyles.headerTextStyle.copyWith(
                      fontSize: 28,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  SizedBox(height: 20),

                  // Gift Description (Dynamic Loading)
                  FutureBuilder<String?>(
                    future: _fetchGiftDescription(), // Fetch the description dynamically
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Loading description...',
                          style: AppStyles.subtitleTextStyle.copyWith(
                            color: Colors.teal.shade800,
                          ),
                          textAlign: TextAlign.center,
                        );
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return Text(
                          'Failed to load description.',
                          style: AppStyles.subtitleTextStyle.copyWith(
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return Text(
                          snapshot.data!,
                          style: AppStyles.subtitleTextStyle.copyWith(
                            color: Colors.teal.shade800,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }
                    },
                  ),
                  SizedBox(height: 20),

                  // Pledge Button (Conditionally Rendered for Non-Owners)
                  FutureBuilder<bool>(
                    future: _isCurrentUserOwner(), // Check if the user is the owner
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // Show a loader while checking
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return SizedBox(); // Hide the button if an error occurs
                      } else if (!snapshot.data!) {
                        return ElevatedButton(
                          onPressed: () => _pledgeGift(context),
                          child: Text('Pledge to Gift'),
                        );
                      } else {
                        return SizedBox(); // Hide the button for owners
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}
