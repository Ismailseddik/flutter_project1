import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:trial/main.dart' as app;
import 'package:flutter/material.dart';

extension PumpUntilFound on WidgetTester {
      Future<void> pumpUntilFound(
          Finder finder, {
                Duration timeout = const Duration(seconds: 10),
          }) async {
            final endTime = DateTime.now().add(timeout);

            while (DateTime.now().isBefore(endTime)) {
                  await pump();
                  if (finder.evaluate().isNotEmpty) {
                        return;
                  }
            }

            throw TestFailure('Widget not found: $finder');
      }
}
extension PumpForDuration on WidgetTester {
      Future<void> pumpForDuration(Duration duration) async {
            final endTime = DateTime.now().add(duration);

            while (DateTime.now().isBefore(endTime)) {
                  await pump();
            }
      }
}

void main() {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      group('Integration Tests', () {
            testWidgets('User logs in, adds event, and adds gift', (WidgetTester tester) async {
                  // Start the app
                  app.main();

                  // Wait for the app to settle and render the Login page
                  await tester.pumpAndSettle();

                  // Ensure the "Login" text appears
                  await tester.pumpUntilFound(find.text('Login'), timeout: const Duration(seconds: 5));

                  // Find email and password fields
                  final emailField = find.byType(TextField).at(0);
                  final passwordField = find.byType(TextField).at(1);

                  // Wait for TextFields to render before interacting with them
                  await tester.pumpUntilFound(emailField, timeout: const Duration(seconds: 5));
                  await tester.pumpUntilFound(passwordField, timeout: const Duration(seconds: 5));

                  // Enter the email
                  await tester.enterText(emailField, '1234@gmail.com');
                  await tester.pumpAndSettle(); // Allow the input to register

                  // Enter the password
                  await tester.enterText(passwordField, '654321');
                  await tester.pumpAndSettle(); // Allow the input to register

                  // Tap the "Login" button
                  final loginButton = find.widgetWithText(ElevatedButton, 'Login');
                  await tester.tap(loginButton);
                  await tester.pumpAndSettle();

                  // Wait for 100 seconds to ensure the HomePage widget tree is fully rendered
                  await tester.pumpForDuration(const Duration(seconds: 100));

                  // Step 1: Verify navigation to HomePage (after delay)
                  //expect(find.text('Events Created'), findsOneWidget); // Verifies an element unique to HomePage

                  // Step 2: Navigate to the Event List Page
                  // Tap the "Create Event" button
                  final createEventButton = find.widgetWithText(ElevatedButton, 'Create Your Own Event/List');
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 30));
                  await tester.tap(createEventButton);
                  await tester.pumpAndSettle();
                  final addeventButton = find.byIcon(Icons.add);
                  await tester.tap(addeventButton);
                  await tester.pumpAndSettle();
                  // Fill out the event creation form
                  final eventNameField = find.byType(TextField).at(0);
                  final eventDateField = find.byType(TextField).at(1);
                  final eventLocationField = find.byType(TextField).at(2);

                  await tester.enterText(eventNameField, 'Test Event');
                  await tester.enterText(eventDateField, '25/12/2024');
                  await tester.enterText(eventLocationField, 'Test Location');
                  await tester.pumpAndSettle();

                  // Tap the "Save Event" button
                  final saveEventButton = find.widgetWithText(ElevatedButton, 'Save');
                  await tester.tap(saveEventButton);
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  await tester.pumpAndSettle();

                  // Verify that the event is added (check for event name in the Event List Page)
                  await tester.pumpUntilFound(find.text('Test Event'), timeout: const Duration(seconds: 10));

                  // Step 3: Navigate to Gift List Page for the Created Event
                  // Tap the circular avatar in the profile section to navigate to events
                  final backButton = find.byIcon(Icons.arrow_back);
                  await tester.tap(backButton);
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  final profileAvatar = find.byType(CircleAvatar).at(0);
                  //await tester.pumpForDuration(const Duration(seconds: 15));
                  await tester.tap(profileAvatar);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  // Tap on the created event name to navigate to the Gift List Page
                  final createdEvent = find.text('Test Event');
                  await tester.tap(createdEvent);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  // Step 4: Add a Gift to the Event
                  final addGiftButton = find.byIcon(Icons.add); // "Add Gift" button
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  await tester.tap(addGiftButton);
                  await tester.pumpAndSettle();
                  // Fill out the gift creation form
                  final giftNameField = find.byType(TextField).at(0);
                  final giftCategoryField = find.byType(TextField).at(1);
                  final giftPriceField = find.byType(TextField).at(2);
                  final giftDescriptionField = find.byType(TextField).at(3);

                  await tester.enterText(giftNameField, 'Test Gift');
                  await tester.enterText(giftCategoryField, 'Category');
                  await tester.enterText(giftPriceField, '50');
                  await tester.enterText(giftDescriptionField, 'Test Description');
                  await tester.pumpAndSettle();

                  // Tap the "Save Gift" button
                  final saveGiftButton = find.widgetWithText(ElevatedButton, 'Add');
                  await tester.tap(saveGiftButton);
                  await tester.pumpForDuration(const Duration(seconds: 15));
                  await tester.pumpAndSettle();

                  // Verify that the gift is added (check for gift name in the Gift List Page)
                  await tester.pumpUntilFound(find.text('Test Gift'), timeout: const Duration(seconds: 10));
                  expect(find.text('Test Gift'),findsOneWidget);
                  //testing pledging mechanism
                  /*await tester.tap(backButton);
                  await tester.pumpForDuration(const Duration(seconds: 5));
                  await tester.tap(backButton);
                  await tester.pumpUntilFound(find.text('mohamed'), timeout: const Duration(seconds: 30));
                  final friend = find.text('mohamed');
                  await tester.tap(friend);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 10));
                  final friendEvent = find.text('Test Event');
                  await tester.tap(friendEvent);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 10));
                  final FriendGift = find.text('testing test script');
                  await tester.tap(FriendGift);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 10));
                  final PledgeButton = find.widgetWithText(ElevatedButton, 'Pledge to Gift');
                  await tester.tap(PledgeButton);
                  await tester.pumpAndSettle();
                  await tester.pumpForDuration(const Duration(seconds: 10));
                  expect(find.text('Pledged'),findsOneWidget);*/
            });
      });
}
