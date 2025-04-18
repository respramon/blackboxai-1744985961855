import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ehr_blockchain/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('Complete user journey test', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Verify splash screen
      expect(find.byType(app.SplashScreen), findsOneWidget);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login flow
      expect(find.byType(app.LoginScreen), findsOneWidget);
      
      // Enter credentials
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      
      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify navigation to appropriate dashboard
      expect(
        find.byType(app.PatientDashboard),
        findsOneWidget,
      );

      // Test record viewing
      if (find.text('View Records').evaluate().isNotEmpty) {
        await tester.tap(find.text('View Records'));
        await tester.pumpAndSettle();

        // Verify record list
        expect(
          find.byType(ListView),
          findsOneWidget,
        );
      }

      // Test adding new record (if provider)
      if (find.byIcon(Icons.add).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Fill record details
        await tester.enterText(
          find.byType(TextFormField).first,
          'Test Record',
        );
        
        // Submit record
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        // Verify success message
        expect(
          find.text('Record added successfully'),
          findsOneWidget,
        );
      }

      // Test profile access
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify profile screen
      expect(
        find.text('Profile'),
        findsOneWidget,
      );

      // Test logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify return to login screen
      expect(
        find.byType(app.LoginScreen),
        findsOneWidget,
      );
    });

    testWidgets('Provider authorization flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as patient
      // ... Login steps ...

      // Navigate to provider access
      await tester.tap(find.text('Provider Access'));
      await tester.pumpAndSettle();

      // Add provider
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Enter provider details
      await tester.enterText(
        find.byType(TextFormField).first,
        '0x123...',
      );

      // Grant access
      await tester.tap(find.text('Grant Access'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(
        find.text('Access granted successfully'),
        findsOneWidget,
      );

      // Verify provider listed
      expect(
        find.text('0x123...'),
        findsOneWidget,
      );

      // Revoke access
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm revocation
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(
        find.text('Access revoked successfully'),
        findsOneWidget,
      );
    });

    testWidgets('Record management flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as provider
      // ... Login steps ...

      // Add new record
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill record details
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Record',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Test Description',
      );

      // Select record type
      await tester.tap(find.text('Select Type'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prescription'));
      await tester.pumpAndSettle();

      // Add file
      await tester.tap(find.text('Add File'));
      await tester.pumpAndSettle();
      // ... File selection steps ...

      // Submit record
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify success
      expect(
        find.text('Record added successfully'),
        findsOneWidget,
      );

      // View record details
      await tester.tap(find.text('Test Record'));
      await tester.pumpAndSettle();

      // Verify record details
      expect(find.text('Test Record'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('Prescription'), findsOneWidget);
    });

    testWidgets('Error handling and offline mode', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test network error handling
      // ... Simulate network error ...

      // Verify error message
      expect(
        find.text('Network error. Please check your connection.'),
        findsOneWidget,
      );

      // Test offline mode
      // ... Simulate offline mode ...

      // Verify offline indicator
      expect(
        find.text('Offline Mode'),
        findsOneWidget,
      );

      // Verify cached data available
      expect(
        find.byType(ListView),
        findsOneWidget,
      );
    });

    testWidgets('Biometric authentication', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Enable biometric auth
      // ... Navigate to settings ...
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enable Biometric Authentication'));
      await tester.pumpAndSettle();

      // Verify biometric prompt
      expect(
        find.text('Authenticate to enable biometric login'),
        findsOneWidget,
      );

      // Simulate successful authentication
      // ... Authentication steps ...

      // Verify success message
      expect(
        find.text('Biometric authentication enabled'),
        findsOneWidget,
      );
    });
  });
}
