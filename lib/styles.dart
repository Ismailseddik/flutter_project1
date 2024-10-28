import 'package:flutter/material.dart';

class AppStyles {
  static const TextStyle headerTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.teal,
  );

  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 18,
    color: Colors.grey,
  );

  static final ButtonStyle sortButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}
