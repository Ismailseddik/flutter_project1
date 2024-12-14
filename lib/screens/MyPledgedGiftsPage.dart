import 'package:flutter/material.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MyPledgedGiftsPage extends StatefulWidget {
  final int userId; // Currently logged-in user's ID

  MyPledgedGiftsPage({required this.userId});

  @override
  _MyPledgedGiftsPageState createState() => _MyPledgedGiftsPageState();
}

class _MyPledgedGiftsPageState extends State<MyPledgedGiftsPage> {
  List<Map<String, dynamic>> enrichedGifts = []; // Holds gifts with event and user details

  @override
  void initState() {
    super.initState();
    _loadPledgedGifts(); // Load pledged gifts when the page initializes
  }

  Future<void> _loadPledgedGifts() async {
    final db = DatabaseHelper.instance;
    final firebase = FirebaseHelper.instance;

    try {
      // Fetch pledged gifts directly from Firebase
      final fetchedGifts = await firebase.getGiftsWithCriteria({
        'friendId': widget.userId, // Match the logged-in user ID
        'status': 'Pledged', // Only fetch pledged gifts
      });

      // Log debugging information
      fetchedGifts.forEach((gift) {
        print(
            'Debug: Gift ID: ${gift.id}, Event ID: ${gift.eventId}, Name: ${gift.name}, Friend ID: ${gift.friendId}, Status: ${gift.status}');
      });

      // Enrich gifts with event and user details
      List<Map<String, dynamic>> tempEnrichedGifts = [];
      for (var gift in fetchedGifts) {
        // Try to fetch the associated event using eventId
        Event? event;
        try {
          event = await db.getEventById(gift.eventId);
          if (event == null) {
            print('Event not found locally. Fetching from Firebase...');
            event = (await firebase.getEventById(gift.eventId as String)) as Event?;
            if (event != null) {
              await db.insertEvent(event); // Sync locally for future use
            }
          }
                } catch (e) {
          print('Error fetching event for gift ID ${gift.id}: $e');
        }

        // Try to fetch the user (creator of the event) using event's userId
        User? user;
        try {
          if (event != null) {
            user = await db.getUser(event.userId!);
          }
        } catch (e) {
          print('Error fetching user for event ID ${event?.id}: $e');
        }

        // Add enriched data for this gift with fallbacks
        tempEnrichedGifts.add({
          'gift': gift, // The original gift object
          'friendName': user?.name ?? 'Unknown User', // Fallback for missing user
          'eventDate': event?.date ?? 'No date', // Fallback for missing event
        });
      }

      // Update the state with enriched gifts
      setState(() {
        enrichedGifts = tempEnrichedGifts;
      });

    } catch (e) {
      print('Error fetching pledged gifts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "My Pledged Gifts",
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
        child: enrichedGifts.isEmpty
            ? Center(
          child: Text(
            'No pledged gifts found.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: enrichedGifts.length,
          itemBuilder: (context, index) {
            final gift = enrichedGifts[index]['gift'] as Gift;
            final friendName = enrichedGifts[index]['friendName'];
            final eventDate = enrichedGifts[index]['eventDate'];

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.card_giftcard, color: Colors.teal),
                title: Text(
                  gift.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${gift.category}'),
                    Text('Price: \$${gift.price.toStringAsFixed(2)}'),
                    Text('Friend: $friendName'), // Friend name
                    Text('Date: $eventDate'), // Event date
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
