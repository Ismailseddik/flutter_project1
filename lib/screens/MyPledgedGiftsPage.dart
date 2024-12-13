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
  List<Gift> pledgedGifts = []; // List to hold pledged gifts

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
            'Debug: Gift ID: ${gift.id}, Name: ${gift.name}, Friend ID: ${gift.friendId}, Status: ${gift.status}');
      });

      setState(() {
        pledgedGifts = fetchedGifts;
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
        child: pledgedGifts.isEmpty
            ? Center(
          child: Text(
            'No pledged gifts found.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: pledgedGifts.length,
          itemBuilder: (context, index) {
            final gift = pledgedGifts[index];
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
