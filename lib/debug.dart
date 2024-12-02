import 'package:flutter/material.dart';
import '../Firebase_Database/firebase_helper.dart';

class DebugPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Page'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              print('Starting to add dummy data...');
              //await FirebaseHelper.instance.addDummyData();
              print('Dummy data added successfully!');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dummy data added to Firebase!')),
              );
            } catch (e) {
              print('Error adding dummy data: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add dummy data: $e')),
              );
            }
          },
          child: Text('Add Dummy Data'),
        ),
      ),
    );
  }
}
