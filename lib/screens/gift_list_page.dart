import 'package:flutter/material.dart';
import '../notification_service/notification_handler.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../Firebase_Database/firebase_helper.dart';
import '../models/models.dart';
import '../widgets/AppBarWithSyncStatus.dart';
import 'gift_details_page.dart';
import '../notification_service/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class GiftListPage extends StatefulWidget {
  final int id; // Can be eventId or friendId
  final bool isFriendView; // Identify if the view is for a friend
  final int? eventId; // Nullable to handle cases where it's a friend view only

  GiftListPage({
    required this.id,
    this.isFriendView = false,
    this.eventId,
  });

  @override
  _GiftListPageState createState() => _GiftListPageState();
}

class _GiftListPageState extends State<GiftListPage> {
  List<Gift> gifts = []; // Store gifts dynamically
  List<Gift> filteredGifts = []; // For filtering
  String pageTitle = '';
  String? selectedCategory;
  String? selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadGifts(); // Load the gifts based on the parameters
    _setPageTitle(); // Set the title based on view type
  }

  // Set the page title based on the view type
  void _setPageTitle() {
    setState(() {
      pageTitle = 'Event #${widget.eventId} Gifts';
    });
  }

  Future<void> _loadGifts() async {
    final db = DatabaseHelper.instance;
    final firebase = FirebaseHelper.instance;

    try {
      if (widget.eventId != null) {
        // Step 1: Sync gifts for the event
        await firebase.syncFriendGifts(db, widget.eventId!);
        final userId = await db.getCurrentUserId();
        if (userId != null) {
          await firebase.syncWithLocalDatabase(db, userId);

          gifts = await firebase.getGifts(widget.eventId!);

          // Save them locally in case they were updated in Firebase
          for (final gift in gifts) {
            await db.updateGift(gift.id!, {'category': gift.category});// Update category locally
            await db.updateGift(gift.id!, {'price': gift.price});// Update price locally
            await db.updateGift(gift.id!, {'status': gift.status}); // Update status locally
          }
        }

        gifts = await db.getGifts(widget.eventId!);
        filteredGifts = List.from(gifts); // Initialize filtered list
      } else {
        print('Error: eventId is null. Unable to fetch gifts.');
      }

      setState(() {}); // Refresh the UI with updated gifts
    } catch (e) {
      print('Error loading gifts: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredGifts = gifts.where((gift) {
        final categoryMatch = selectedCategory == null || gift.category == selectedCategory;
        final statusMatch = selectedStatus == null || gift.status == selectedStatus;
        return categoryMatch && statusMatch;
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
              title: Text('Filter Gifts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedCategory,
                    hint: Text('Select Category'),
                    items: gifts
                        .map((gift) => gift.category)
                        .toSet()
                        .map((category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value;
                      });
                    },
                  ),
                  DropdownButton<String>(
                    value: selectedStatus,
                    hint: Text('Select Status'),
                    items: ['Available', 'Pledged']
                        .map((status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(status),
                    ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = null;
                      selectedStatus = null;
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

  Future<void> _showAddGiftDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController categoryController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Gift'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Gift Name')),
              TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Category')),
              TextField(
                controller: priceController,
                decoration: InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  categoryController.text.isEmpty ||
                  priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All fields are required')),
                );
                return;
              }

              final newGift = Gift(
                name: nameController.text,
                category: categoryController.text,
                price: double.parse(priceController.text),
                status: 'Available',
                eventId: widget.eventId!,
                description: descriptionController.text,
              );

              try {
                final giftId = await DatabaseHelper.instance.insertGift(newGift);
                print('Gift added successfully with ID: $giftId');
              } catch (e) {
                print('Error adding gift: $e');
              }

              await _loadGifts(); // Reload the list after insertion
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGift(int giftId) async {
    if (widget.isFriendView) {
      return;
    }

    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Gift'),
        content: Text('Are you sure you want to delete this gift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseHelper.instance.deleteGift(giftId);
        await DatabaseHelper.instance.deleteGift(giftId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gift deleted successfully!')),
        );
        String currentUserName = 'Unknown User';
        final currentUserId = await DatabaseHelper.instance.getCurrentUserId();
        if (currentUserId != null) {
          currentUserName = await FirebaseHelper.instance.getUserNameById(currentUserId.toString()) ?? 'Unknown User';
        }
        await NotificationHandler().sendGiftUpdateNotification(
          giftId: widget.id,
          giftName: widget.id.toString(),
          eventId: widget.eventId!,
          newStatus: 'deleted',
          friendIds: await DatabaseHelper.instance.getFriendIds(currentUserId!),
          pledgerName: currentUserName,
        );
        _loadGifts();
      } catch (e) {
        print('Error deleting gift: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete gift.')),
        );
      }
    }
  }

  Future<void> _editGift(Gift gift) async {
    if (widget.isFriendView || gift.status == 'Pledged') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot edit this gift.')),
      );
      return;
    }

    final nameController = TextEditingController(text: gift.name);
    final descriptionController = TextEditingController(text: gift.description);
    final categoryController = TextEditingController(text: gift.category);
    final priceController = TextEditingController(text: gift.price.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Gift'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
                TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
                TextField(controller: categoryController, decoration: InputDecoration(labelText: 'Category')),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedGift = Gift(
                  id: gift.id,
                  name: nameController.text,
                  description: descriptionController.text,
                  category: categoryController.text,
                  price: double.tryParse(priceController.text) ?? gift.price,
                  status: gift.status,
                  eventId: gift.eventId,
                  friendId: gift.friendId,
                );

                try {
                  await DatabaseHelper.instance.updateGift(updatedGift.id!, updatedGift.toMap());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gift updated successfully!')),
                  );
                  String currentUserName = 'Unknown User';
                  final currentUserId = await DatabaseHelper.instance.getCurrentUserId();
                  if (currentUserId != null) {
                    currentUserName = await FirebaseHelper.instance.getUserNameById(currentUserId.toString()) ?? 'Unknown User';
                  }
                  await NotificationHandler().sendGiftUpdateNotification(
                    giftId: updatedGift.id!,
                    giftName: updatedGift.name,
                    eventId: updatedGift.eventId!,
                    newStatus: 'updated',
                    friendIds: await DatabaseHelper.instance.getFriendIds(currentUserId!), // Ensure this returns a valid list
                    pledgerName: currentUserName, // Correctly fetched user's name
                  );
                  _loadGifts();
                  Navigator.pop(context);
                } catch (e) {
                  print('Error updating gift: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update gift.')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithSyncStatus(
        title: pageTitle,
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _showFilterDialog,
              child: Text('Filter Gifts'),
            ),
          ),
          Expanded(
            child: filteredGifts.isEmpty
                ? Center(
              child: Text(
                'No gifts to display',
                style: AppStyles.subtitleTextStyle.copyWith(fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredGifts.length,
              itemBuilder: (context, index) {
                final gift = filteredGifts[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(
                      Icons.card_giftcard,
                      color: Colors.teal,
                      size: 40,
                    ),
                    title: Text(
                      gift.name,
                      style: AppStyles.headerTextStyle.copyWith(fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text('Category: ${gift.category}', style: AppStyles.subtitleTextStyle),
                        SizedBox(height: 4),
                        Text('Price: \$${gift.price.toStringAsFixed(2)}', style: AppStyles.subtitleTextStyle),
                        SizedBox(height: 4),
                        Text(
                          'Status: ${gift.status}',
                          style: AppStyles.subtitleTextStyle.copyWith(
                              color: gift.status == 'Pledged' ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                    trailing: widget.isFriendView
                        ? null
                        : PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          _editGift(gift);
                        } else if (action == 'delete') {
                          _deleteGift(gift.id!);
                        }
                      },
                      itemBuilder: (context) => [
                        if (gift.status != 'Pledged')
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (gift.status != 'Pledged')
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GiftDetailsPage(
                            giftName: gift.name,
                            giftImage: AssetImage('assets/gift_image.png'),
                            giftId: gift.id!,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadGifts();
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isFriendView
          ? null
          : FloatingActionButton(
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
        onPressed: _showAddGiftDialog,
      ),
    );
  }
}
