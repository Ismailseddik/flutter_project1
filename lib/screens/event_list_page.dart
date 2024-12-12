import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import '../widgets/common_header.dart';
import '../Local_Database/database_helper.dart';
import '../models/models.dart';
import 'gift_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
class EventListPage extends StatefulWidget {
  final int userId; // User ID is required

  EventListPage({required this.userId});

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  List<Event> events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final db = DatabaseHelper.instance;
    final fetchedEvents = await db.getEvents(widget.userId);

    for (var event in fetchedEvents) {
      final gifts = await db.getGifts(event.id!);
      event.gifts = gifts;
    }

    setState(() {
      events = fetchedEvents;
    });
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    bool isSaving = false; // Add this flag to prevent multiple submissions

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add Event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: InputDecoration(labelText: 'Event Name')),
                  TextField(controller: dateController, decoration: InputDecoration(labelText: 'Event Date')),
                  TextField(controller: locationController, decoration: InputDecoration(labelText: 'Location')),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (nameController.text.isEmpty ||
                        dateController.text.isEmpty ||
                        locationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('All fields are required')),
                      );
                      return;
                    }

                    setState(() {
                      isSaving = true; // Disable button after the first press
                    });

                    final db = DatabaseHelper.instance;
                    final event = Event(
                      name: nameController.text,
                      date: dateController.text,
                      location: locationController.text,
                      description: '',
                      userId: widget.userId,
                    );

                    await db.insertEvent(event);
                    Navigator.pop(context);
                    _loadEvents();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: "Events",
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
            colors: [Colors.teal.shade200, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                style: AppStyles.sortButtonStyle,
                onPressed: () {
                  // Sorting functionality
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Sort By', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Text(
                          event.name,
                          style: AppStyles.headerTextStyle,
                        ),
                        subtitle: Text(
                          event.date,
                          style: AppStyles.subtitleTextStyle,
                        ),
                        children: event.gifts.map((gift) {
                          return ListTile(
                            leading: Icon(Icons.card_giftcard),
                            title: Text(gift.name),
                            subtitle: Text('Category: ${gift.category}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GiftDetailsPage(
                                    giftName: gift.name,
                                    giftImage: AssetImage('assets/default_gift.png'),
                                    giftId: gift.id!, // Pass the correct giftId here
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),

                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
        onPressed: () => _showAddEventDialog(context),
      ),
    );
  }
}
