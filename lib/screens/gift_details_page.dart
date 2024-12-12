import 'package:flutter/material.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../Firebase_Database/firebase_helper.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../widgets/AppBarWithSyncStatus.dart';
class GiftDetailsPage extends StatelessWidget {
  final String giftName;
  final ImageProvider giftImage;
  final int giftId; // Added giftId for interaction

  GiftDetailsPage({
    required this.giftName,
    required this.giftImage,
    required this.giftId,
  });

  Future<void> _pledgeGift(BuildContext context) async {
    final db = DatabaseHelper.instance;
    final firebase = FirebaseHelper.instance;

    // Ask for confirmation before pledging
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
        // Try updating status in Firebase first
        await firebase.updateGiftStatus(giftId, 'Pledged');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift pledged successfully!')),
        );
      } catch (e) {
        print('Error pledging gift on Firebase: $e');

        // If Firebase fails, fallback to local database
        try {
          await db.updateGift(giftId, {'status': 'Pledged'});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gift pledged locally!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to pledge gift. Please try again.')),
          );
        }
      }

      Navigator.pop(context); // Close the details page after action
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "Gift Details",
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
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: giftImage,
                    backgroundColor: Colors.grey[200],
                  ),
                  SizedBox(height: 20),
                  Text(
                    giftName,
                    style: AppStyles.headerTextStyle.copyWith(
                      fontSize: 28,
                      color: Colors.teal.shade900,
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final pledged = await showDialog(
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
                          await FirebaseHelper.instance.updateGiftStatus(
                            giftId, // Pass the gift ID
                            'Pledged',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gift status updated in Firebase!')),
                          );
                        } catch (e) {
                          print('Error updating gift status in Firebase: $e');

                          // Fall back to updating the local database
                          await DatabaseHelper.instance.updateGiftStatus(
                            giftId,
                            'Pledged',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gift status updated locally!')),
                          );
                        }

                        Navigator.pop(context, true); // Notify GiftListPage to refresh
                      }
                    },
                    child: Text('Pledge to Gift'),
                  ),



                  SizedBox(height: 20),
                  Text(
                    'This gift is perfect for your loved ones and will be a memorable addition to their collection.',
                    style: AppStyles.subtitleTextStyle.copyWith(
                      color: Colors.teal.shade800,
                    ),
                    textAlign: TextAlign.center,
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
