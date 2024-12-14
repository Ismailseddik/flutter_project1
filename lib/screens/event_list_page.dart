import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/AppBarWithSyncStatus.dart';
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
  List<Event> filteredEvents = [];
  String? selectedDate;
  String? selectedLocation;

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
      filteredEvents = List.from(events); // Initialize filtered list
    });
  }

  void _applyFilters() {
    setState(() {
      filteredEvents = events.where((event) {
        final dateMatch = selectedDate == null || event.date == selectedDate;
        final locationMatch = selectedLocation == null || event.location == selectedLocation;
        return dateMatch && locationMatch;
      }).toList();
    });
  }

  Future<void> _showFilterDialog() async {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Filter Events'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedDate,
                    hint: Text('Select Date'),
                    items: events
                        .map((event) => event.date)
                        .toSet()
                        .map((date) => DropdownMenuItem<String>(
                      value: date,
                      child: Text(date),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDate = value;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedLocation,
                    hint: Text('Select Location'),
                    items: events
                        .map((event) => event.location)
                        .toSet()
                        .map((location) => DropdownMenuItem<String>(
                      value: location,
                      child: Text(location),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLocation = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedDate = null;
                      selectedLocation = null;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters();
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    bool isSaving = false;

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
                      isSaving = true;
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    style: AppStyles.sortButtonStyle, // Reused styling from the unused dropdown
                    onPressed: _showFilterDialog,
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Filter Events', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Expanded(
                child: filteredEvents.isEmpty
                    ? Center(
                  child: Text(
                    'No events to display',
                    style: AppStyles.subtitleTextStyle.copyWith(fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
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
                                    giftId: gift.id!,
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
