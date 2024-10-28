import 'package:flutter/material.dart';
import '../styles.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/present-box-with-red-ribbon_23-2148015273.webp', // Path to logo asset
              width: 200,
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome Back!',
              style: AppStyles.headerTextStyle,
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: AppStyles.elevatedButtonStyle,
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
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
    );
  }
}
