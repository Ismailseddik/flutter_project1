import 'package:flutter/material.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import 'gift_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
      // Fetch friend events using the existing `getFriendEvents` function
      final fetchedEvents = await db.getFriendEvents(widget.friendId);

      if (fetchedEvents.isEmpty) {
        // If no events found locally, sync friend-specific events with Firebase
        await FirebaseHelper.instance.syncWithLocalDatabase(db, widget.friendId);

        // Re-fetch events after syncing
        final updatedEvents = await db.getFriendEvents(widget.friendId);
        setState(() {
          events = updatedEvents;
        });
      } else {
        setState(() {
          events = fetchedEvents;
        });
      }
    } catch (e) {
      print('Error fetching events for friend: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "friend events",
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
