import 'package:flutter/material.dart';
import '../screens/profile_page.dart';
import '../widgets/common_header.dart';
import '../widgets/profile_section.dart';
import '../styles.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'Friends List',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
        },
      ),
      body: Column(
        children: [
          ProfileSection(
            userName: 'userName', // Replace with dynamic user name
            onProfileIconTapped: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: AppStyles.elevatedButtonStyle,
              onPressed: () {
                Navigator.pushNamed(context, '/events');
              },
              child: Text(
                'Create Your Own Event/List',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) {
                final hasUpcomingEvent = index % 2 == 0;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.tealAccent,
                    backgroundImage: AssetImage('assets/profile_picture.png'),
                    child: Icon(Icons.person, size: 28, color: Colors.white),
                  ),
                  title: Text(
                    'Friend Name $index',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    hasUpcomingEvent ? 'Upcoming Events: 1' : 'No Upcoming Events',
                    style: TextStyle(color: hasUpcomingEvent ? Colors.green : Colors.red),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                  onTap: () {
                    Navigator.pushNamed(context, '/gifts');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
