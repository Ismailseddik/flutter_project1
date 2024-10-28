import 'package:flutter/material.dart';
import '../styles.dart';
import '../widgets/common_header.dart';
import 'gift_details_page.dart';

class GiftListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonHeader(
        title: 'Gift List',
        onSignOutTapped: () {
          Navigator.pushNamed(context, '/login');
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: AppStyles.sortButtonStyle,
              onPressed: () {
                // Sorting functionality here
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
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                final categoryIcon = _getCategoryIcon(index);

                return ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.lightBlueAccent,
                    child: Icon(categoryIcon, color: Colors.white, size: 28),
                  ),
                  title: Text(
                    'Gift Name $index',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text('Category: ${_getCategoryName(index)}'),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GiftDetailsPage(
                          giftName: 'Gift Name $index',
                          giftImage: AssetImage('assets/gift_image_$index.png'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(int index) {
    switch (index % 3) {
      case 0:
        return Icons.phone_iphone;
      case 1:
        return Icons.book;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getCategoryName(int index) {
    switch (index % 3) {
      case 0:
        return 'Electronics';
      case 1:
        return 'Books';
      default:
        return 'General';
    }
  }
}
