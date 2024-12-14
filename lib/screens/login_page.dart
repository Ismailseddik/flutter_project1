import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import '../Firebase_Database/firebase_helper.dart'; // Import FirebaseHelper

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      // Authenticate the user with Firebase
      final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Get the user ID from Firebase Firestore
      final firebaseHelper = FirebaseHelper.instance;
      final dbHelper = DatabaseHelper.instance;

      final firebaseUserId = await firebaseHelper.getUserIdByEmail(emailController.text);

      if (firebaseUserId != null) {
        // Fetch the user data from Firestore
        final firebaseUser = await firebaseHelper.getUser(firebaseUserId);

        if (firebaseUser != null) {
          // Save the user data to the local database
          await dbHelper.insertUser(firebaseUser);

          // Sync other data (events, gifts, etc.) for this user
          await firebaseHelper.syncWithLocalDatabase(dbHelper, firebaseUserId);

          // Navigate to the HomePage
          Navigator.pushReplacementNamed(context, '/home', arguments: firebaseUserId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User data not found in Firestore')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not found in Firebase')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/present-box-with-red-ribbon_23-2148015273.webp',
                width: 150,
                height: 150,
              ),
              SizedBox(height: 20),
              Text(
                'Welcome Back!',
                style: AppStyles.headerTextStyle,
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: AppStyles.elevatedButtonStyle,
                onPressed: () => _login(context),
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: Text(
                  'Don’t have an account? Sign Up',
                  style: TextStyle(fontSize: 16, color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
