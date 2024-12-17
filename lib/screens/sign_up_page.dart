import 'package:flutter/material.dart';
import '../styles.dart';
import '../Local_Database/database_helper.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart' as app_models;

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController preferencesController = TextEditingController();

  Future<void> _signUp() async {
    try {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      // Use Firebase Authentication to create a user
      final userCredential = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // Generate a unique ID for the user
      final userId = DateTime.now().millisecondsSinceEpoch;

      // Create user data
      final app_models.User user = app_models.User(
        id: userId,
        name: nameController.text,
        email: emailController.text,
        password: passwordController.text,
        preferences: preferencesController.text,
      );

      // Add user to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId.toString()).set({
        'id': userId,
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'preferences': user.preferences,
      });

      // Save user locally
      final db = DatabaseHelper.instance;
      await db.insertUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User signed up successfully!')),
      );

      // Navigate to the HomePage
      Navigator.pushReplacementNamed(context, '/home', arguments: user.id);
    } catch (e) {
      print('Error during sign-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
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
        child: Center( // Center content on the screen
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center align content vertically
                children: [
                  Text(
                    'Create Your Account',
                    style: AppStyles.headerTextStyle,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
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
                  SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: preferencesController,
                    decoration: InputDecoration(
                      labelText: 'Preferences',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: AppStyles.elevatedButtonStyle,
                    onPressed: _signUp,
                    child: Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
