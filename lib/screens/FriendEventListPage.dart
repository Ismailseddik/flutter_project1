import 'package:flutter/material.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import 'gift_list_page.dart';

class FriendEventListPage extends StatefulWidget {
  final int friendId; // Friend ID to fetch their events

  FriendEventListPage({required this.friendId});

  @override
  _FriendEventListPageState createState() => _FriendEventListPageState();
}

class _FriendEventListPageState extends State<FriendEventListPage> {
  List<Event> events = []; // To store friend's events

  @override
  void initState() {
    super.initState();
    _loadFriendEvents(); // Load friend's events on initialization
  }

  Future<void> _loadFriendEvents() async {
    final db = DatabaseHelper.instance;

    try {
      // Fetch events assigned to this friend
      final fetchedEvents = await db.getFriendEvents(widget.friendId);

      setState(() {
        events = fetchedEvents;
      });
    } catch (e) {
      print('Error fetching events for friend: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend\'s Events'),
        backgroundColor: Colors.teal,
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
          child: events.isEmpty
              ? Center(
            child: Text(
              'No events found for this friend.',
              style: AppStyles.subtitleTextStyle.copyWith(fontSize: 18),
            ),
          )
              : ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    event.name,
                    style: AppStyles.headerTextStyle,
                  ),
                  subtitle: Text(
                      'Date: ${event.date}\nLocation: ${event.location}'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftListPage(
                          id: widget.friendId, // Pass the friend's ID as the id
                          isFriendView: true, // Indicate that this is a friend's view
                          eventId: event.id!, // Pass the specific event ID
                        ),
                      ),

                    );
                  },

                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
