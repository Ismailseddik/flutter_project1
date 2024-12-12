import 'package:flutter/material.dart';
import 'package:trial/styles.dart';
import '../SyncStatusManager.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
class AppBarWithSyncStatus extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSignOutPressed;

  AppBarWithSyncStatus({required this.title, this.onSignOutPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Colors.teal,
      actions: [
        // Sync Status Indicator
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: ValueListenableBuilder<String>(
            valueListenable: syncStatusManager,
            builder: (context, syncStatus, child) {
              return Row(
                children: [
                  if (syncStatus == "Syncing...")
                    CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  if (syncStatus == "Synced")
                    Icon(Icons.cloud_done, color: Colors.white),
                  if (syncStatus == "Offline")
                    Icon(Icons.cloud_off, color: Colors.red),
                  SizedBox(width: 8),
                  Text(
                    syncStatus,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              );
            },
          ),
        ),
        // Sign Out Button
        if (onSignOutPressed != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                try {
                  await firebase_auth.FirebaseAuth.instance.signOut(); // Using alias
                  Navigator.pushReplacementNamed(context, '/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
              tooltip: "Sign Out",
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}



