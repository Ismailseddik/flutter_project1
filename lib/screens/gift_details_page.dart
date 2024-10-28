import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/common_header.dart';

class GiftDetailsPage extends StatelessWidget {
  final String giftName;
  final ImageProvider giftImage;

  GiftDetailsPage({required this.giftName, required this.giftImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'Gift Details',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundImage: giftImage,
                backgroundColor: Colors.grey[200],
              ),
              SizedBox(height: 16),
              Text(
                giftName,
                style: AppStyles.headerTextStyle.copyWith(fontSize: 28),
              ),
              SizedBox(height: 10),
              Text(
                'Category: Electronics',
                style: AppStyles.subtitleTextStyle,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: AppStyles.elevatedButtonStyle,
                onPressed: () {
                  // Pledge functionality here
                },
                child: Text(
                  'Pledge to Gift',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'gift details',
                  style: AppStyles.subtitleTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
