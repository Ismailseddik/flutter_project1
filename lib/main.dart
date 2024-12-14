import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:trial/screens/login_page.dart';
import 'package:trial/screens/sign_up_page.dart';
import 'Firebase_Database/firebase_helper.dart';
import 'Local_Database/database_helper.dart';
import 'debug.dart';
import 'notification_service/notification_service.dart';
import 'screens/FriendEventListPage.dart';
import 'screens/home_page.dart';
import 'screens/event_list_page.dart';
import 'screens/gift_list_page.dart';
import 'screens/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //NotificationService notificationService = NotificationService();
  // Sync local database with Firebase
 // final dbHelper = DatabaseHelper.instance;
  //final firebaseHelper = FirebaseHelper.instance;
/*  try {
    await firebaseHelper.syncWithLocalDatabase(dbHelper);
    print('Initial sync with Firebase completed successfully.');
  } catch (e) {
    print('Error during initial sync: $e');
  }*/
 // final NotificationService notificationService = NotificationService();
 // await notificationService.init();
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
      initialRoute: '/login', // Starting route
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (context) => LoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (context) => SignUpPage());
          case '/home':
            if (settings.arguments is int) {
              final userId = settings.arguments as int;
              return MaterialPageRoute(builder: (context) => HomePage(userId: userId));
            }
            return _errorRoute();
          case '/events':
            if (settings.arguments is int) {
              final userId = settings.arguments as int;
              return MaterialPageRoute(builder: (context) => EventListPage(userId: userId));
            }
            return _errorRoute();
          case '/gifts':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final id = args['id'] as int; // Can be eventId or friendId
              final isFriendView = args['isFriendView'] as bool;
              final eventId = args['eventId'] as int;

              // Debugging: Ensure the correct parameters are passed
              print('Navigating to GiftListPage: id=$id, isFriendView=$isFriendView, eventId=$eventId');

              return MaterialPageRoute(
                builder: (context) => GiftListPage(
                  id: id,
                  isFriendView: isFriendView,
                  eventId: eventId,
                ),
              );
            }
            return _errorRoute();
          case '/friendEvents':
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final friendId = args['friendId'] as int;

              // Debugging: Ensure the correct friendId is passed
              print('Navigating to FriendEventListPage: friendId=$friendId');

              return MaterialPageRoute(
                builder: (context) => FriendEventListPage(friendId: friendId),
              );
            }
            return _errorRoute();
          case '/debug':
            return MaterialPageRoute(
              builder: (context) => DebugPage(),
            );
          case '/profile':
            if (settings.arguments is int) {
              final userId = settings.arguments as int;

              // Debugging: Ensure the correct userId is passed
              print('Navigating to ProfilePage: userId=$userId');

              return MaterialPageRoute(builder: (context) => ProfilePage(userId: userId));
            }
            return _errorRoute();
          default:
            return _errorRoute();
        }
      },
    );
  }

  // Generic error route for undefined paths
  Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('Page not found')),
      ),
    );
  }
}
