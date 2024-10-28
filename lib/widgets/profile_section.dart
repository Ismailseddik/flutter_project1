import 'package:flutter/material.dart';
import 'package:trial/styles.dart';

class ProfileSection extends StatelessWidget {
  final String userName;
  final VoidCallback onProfileIconTapped;

  ProfileSection({
    required this.userName,
    required this.onProfileIconTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onProfileIconTapped,
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.tealAccent,
              backgroundImage: AssetImage('assets/user_profile.png'),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Hello, $userName!',
            style: AppStyles.headerTextStyle,
          ),
          Text(
            'Welcome back!',
            style: AppStyles.subtitleTextStyle,
          ),
        ],
      ),
    );
  }
}
