import 'package:flutter/material.dart';
import 'package:trial/screens/login_page.dart';
import 'package:trial/screens/sign_up_page.dart';
import 'screens/home_page.dart';
import 'screens/event_list_page.dart';
import 'screens/gift_list_page.dart';
import 'screens/gift_details_page.dart';
import 'screens/profile_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedieaty',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/login',
      routes: {
        '/home': (context) => HomePage(),
        '/login': (context) => LoginPage(),
        '/events': (context) => EventListPage(),
        '/signup': (context) => SignUpPage(),
        '/gifts': (context) => GiftListPage(),
        '/profile': (context) => ProfilePage(),
      },
    );
  }
}
