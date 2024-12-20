import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:trial/main.dart' as app; // Update with your app's actual package name.

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('User logs in, creates event, adds gift, views friend events, and pledges a gift',
            (WidgetTester tester) async {
          // Start the app
          app.main();
          await tester.pumpAndSettle();

          // 1. Login
          await tester.enterText(find.byType(TextField).at(0), 'testuser@example.com'); // Email field
          await tester.enterText(find.byType(TextField).at(1), 'password123'); // Password field
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle();

          // Check if login was successful by verifying if HomePage is loaded
          expect(find.text('Home'), findsOneWidget);

          // 2. Create an Event
          await tester.tap(find.text('Create Your Own Event/List'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).at(0), 'Birthday Party'); // Event name
          await tester.enterText(find.byType(TextField).at(1), '25/12/2024'); // Event date
          await tester.enterText(find.byType(TextField).at(2), 'My Home'); // Event location
          await tester.tap(find.text('Save'));
          await tester.pumpAndSettle();

          // Verify event creation
          expect(find.text('Birthday Party'), findsOneWidget);

          // 3. Add a Gift
          await tester.tap(find.text('Birthday Party'));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.add)); // Add gift button
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField).at(0), 'Smart Watch'); // Gift name
          await tester.enterText(find.byType(TextField).at(1), 'Gadgets'); // Category
          await tester.enterText(find.byType(TextField).at(2), '299.99'); // Price
          await tester.tap(find.text('Add'));
          await tester.pumpAndSettle();

          // Verify gift addition
          expect(find.text('Smart Watch'), findsOneWidget);

          // 4. View Friend's Event List
          await tester.tap(find.text('Home')); // Navigate back to Home
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'friend@example.com'); // Friend's email
          await tester.tap(find.text('Add Friend')); // Add Friend
          await tester.pumpAndSettle();

          // Navigate to the friend's event list
          await tester.tap(find.text('Friend ID:'));
          await tester.pumpAndSettle();

          // Verify friend's event list is displayed
          expect(find.text('Friend Events'), findsOneWidget);

          // 5. Pledge a Gift
          await tester.tap(find.text('Event Name: Friend\'s Party')); // Select friend's event
          await tester.pumpAndSettle();
          await tester.tap(find.text('Pledge Gift').first); // Pledge the first gift
          await tester.pumpAndSettle();

          // Verify that the pledge was successful
          expect(find.text('Pledged'), findsOneWidget);
        });
  });
}
