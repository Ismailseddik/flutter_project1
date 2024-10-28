import 'package:flutter/material.dart';

import '../styles.dart';
import '../widgets/common_header.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'profile',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.tealAccent,
                backgroundImage: AssetImage('assets/profile_picture.png'),
                child: Icon(Icons.person, size: 28, color: Colors.white),
              ),
              title: Text('User Name'),
              subtitle: Text('user@example.com'),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  // Edit profile
                },
              ),
            ),
            SizedBox(height: 20),
            Text('my Events', style: AppStyles.headerTextStyle),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Example number of events
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.lightBlueAccent,
                      child: Icon(Icons.access_time, color: Colors.white, size: 28),
                    ),
                    title: Text(
                      'event',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      // Navigate to event's gift list
                      Navigator.pushNamed(context, '/gifts');
                    },
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
