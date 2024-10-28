import 'package:flutter/material.dart';
import 'package:trial/styles.dart';

class CommonHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onSignOutTapped;     // Callback for sign-out action

  CommonHeader({
    required this.title,
    required this.onSignOutTapped,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.teal,
      title: Text(
        title,
        style: AppStyles.headerTextStyle,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.logout),
          onPressed: onSignOutTapped,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
