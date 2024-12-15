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
        'friendId': widget.userId,
        'status': 'Pledged',
      });

      print('Debug: Total gifts fetched: ${fetchedGifts.length}');

      // Cache to avoid redundant Firebase calls
      Map<int, User?> userCache = {};

      List<Map<String, dynamic>> tempEnrichedGifts = [];

      for (var gift in fetchedGifts) {
        print('Debug: Processing Gift ID: ${gift.id}, Event ID: ${gift.eventId}, Name: ${gift.name}');

        // Fetch the associated event
        Event? event;
        try {
          event = await db.getEventById(gift.eventId);
          if (event == null) {
            print('Debug: Event not found locally. Fetching from Firebase...');
            final eventData = await firebase.getEventById(gift.eventId.toString());
            if (eventData.isNotEmpty) {
              event = Event.fromMap(eventData);
              await db.insertEvent(event); // Sync event locally
              print('Debug: Event synced locally: ${event.name}');
            }
          }
        } catch (e) {
          print('Error fetching event for gift ID ${gift.id}: $e');
        }

        // Fetch the user
        User? user;
        try {
          int? userId = event?.userId ?? gift.friendId;
          if (userId == null) {
            print('Debug: User ID is null. Skipping gift processing.');
            continue;
          }

          if (userCache.containsKey(userId)) {
            user = userCache[userId];
            print('Debug: User fetched from cache for User ID: $userId');
          } else {
            user = await firebase.getUserById(userId.toString());
            if (user != null) {
              await db.insertUser(user); // Sync user locally
              print('Debug: User synced locally: ${user.name}');
              userCache[userId] = user;
            } else {
              print('Debug: User not found in Firebase.');
            }
          }
        } catch (e) {
          print('Error fetching user for Gift ID ${gift.id}: $e');
        }

        // Add enriched data for this gift
        tempEnrichedGifts.add({
          'gift': gift,
          'friendName': user?.name ?? 'Unknown User',
          'eventDate': event?.date ?? 'No date',
        });
      }

      setState(() {
        enrichedGifts = tempEnrichedGifts;
      });
      print('Debug: Finished loading pledged gifts. Total: ${enrichedGifts.length}');
    } catch (e) {
      print('Error loading pledged gifts: $e');
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
