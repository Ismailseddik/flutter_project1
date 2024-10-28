import 'package:flutter/material.dart';
import '../screens/profile_page.dart';
import '../widgets/common_header.dart';
import '../styles.dart';
class EventListPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
      title: 'Event List',
      onSignOutTapped: () {
        Navigator.pushNamed(context, '/login');
      },
    ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: AppStyles.sortButtonStyle,
              onPressed: () {
                // Sorting functionality here
              }, child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort, color: Colors.white),
                SizedBox(width: 8),
                Text('Sort By', style: TextStyle(color: Colors.white)),
               ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Example number of events
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.tealAccent,
                    backgroundImage: AssetImage('assets/profile_picture.png'),
                    child: Icon(Icons.access_time, size: 28, color: Colors.white),
                  ),
                  title: Text('Event $index'),
                  subtitle: Text(index % 2 == 0 ? 'Upcoming' : 'Past'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          // Edit event
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Delete event
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    // Navigate to gift list
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
