import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:ehr_blockchain/services/navigation_service.dart';
import 'package:ehr_blockchain/services/auth_service.dart';
import 'package:ehr_blockchain/screens/login_screen.dart';
import 'package:ehr_blockchain/screens/home_screen.dart';
import 'package:ehr_blockchain/screens/patient/patient_dashboard.dart';
import 'package:ehr_blockchain/screens/provider/provider_dashboard.dart';
import 'test_helpers.dart';

void main() {
  group('Route Generation Tests', () {
    late NavigatorObserver mockObserver;

    setUp(() {
      mockObserver = MockNavigatorObserver();
    });

    testWidgets('Generate named routes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [mockObserver],
          onGenerateRoute: NavigationService.generateRoute,
          initialRoute: '/',
        ),
      );

      final routes = [
        '/login',
        '/home',
        '/patient/dashboard',
        '/provider/dashboard',
      ];

      for (final route in routes) {
        final settings = RouteSettings(name: route);
        final generatedRoute = NavigationService.generateRoute(settings);
        expect(generatedRoute, isA<MaterialPageRoute>());
      }
    });

    testWidgets('Handle unknown routes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [mockObserver],
          onGenerateRoute: NavigationService.generateRoute,
          initialRoute: '/unknown',
        ),
      );

      expect(find.text('404 - Page Not Found'), findsOneWidget);
    });
  });

  group('Navigation Guard Tests', () {
    late MockAuthService mockAuthService;
    late NavigatorObserver mockObserver;

    setUp(() {
      mockAuthService = MockAuthService();
      mockObserver = MockNavigatorObserver();
    });

    testWidgets('Protect authenticated routes', (WidgetTester tester) async {
      when(mockAuthService.isAuthenticated).thenReturn(false);

      await tester.pumpWidget(
        TestWrapper(
          authService: mockAuthService,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            onGenerateRoute: NavigationService.generateRoute,
            initialRoute: '/patient/dashboard',
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Role-based route protection', (WidgetTester tester) async {
      when(mockAuthService.isAuthenticated).thenReturn(true);
      when(mockAuthService.currentUser).thenReturn(
        TestData.createTestUser(role: 'PATIENT'),
      );

      await tester.pumpWidget(
        TestWrapper(
          authService: mockAuthService,
          child: MaterialApp(
            navigatorObservers: [mockObserver],
            onGenerateRoute: NavigationService.generateRoute,
            initialRoute: '/provider/dashboard',
          ),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Deep Link Tests', () {
    late MockNavigationService mockNavigationService;

    setUp(() {
      mockNavigationService = MockNavigationService();
    });

    test('Parse deep link URL', () {
      const url = 'ehrapp://records/123?type=prescription';
      final parsedLink = mockNavigationService.parseDeepLink(url);

      expect(parsedLink['path'], equals('/records/123'));
      expect(parsedLink['params']['type'], equals('prescription'));
    });

    test('Handle malformed deep link', () {
      const url = 'invalid://link';
      expect(
        () => mockNavigationService.parseDeepLink(url),
        throwsA(isA<FormatException>()),
      );
    });

    test('Generate deep link', () {
      final link = mockNavigationService.generateDeepLink(
        path: '/records/123',
        params: {'type': 'prescription'},
      );

      expect(link, equals('ehrapp://records/123?type=prescription'));
    });
  });

  group('Navigation History Tests', () {
    late MockNavigationService mockNavigationService;

    setUp(() {
      mockNavigationService = MockNavigationService();
    });

    test('Track navigation history', () {
      when(mockNavigationService.navigationHistory)
          .thenReturn([
            '/login',
            '/home',
            '/patient/dashboard',
          ]);

      final history = mockNavigationService.navigationHistory;
      expect(history.length, equals(3));
      expect(history.last, equals('/patient/dashboard'));
    });

    test('Clear navigation history', () {
      when(mockNavigationService.clearHistory())
          .thenAnswer((_) async {});

      mockNavigationService.clearHistory();
      verify(mockNavigationService.clearHistory()).called(1);
    });
  });

  group('Route Transition Tests', () {
    testWidgets('Custom page transitions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) {
                return FadeTransition(
                  opacity: animation,
                  child: const HomeScreen(),
                );
              },
            );
          },
          home: const HomeScreen(),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Modal dialog transitions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Test Dialog'),
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Test Dialog'), findsOneWidget);
    });
  });

  group('Route Parameter Tests', () {
    testWidgets('Pass and retrieve route parameters',
        (WidgetTester tester) async {
      final params = {'id': '123', 'type': 'prescription'};

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == '/record-details') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => RouteParamsWidget(params: settings.arguments),
              );
            }
            return null;
          },
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/record-details',
                  arguments: params,
                );
              },
              child: const Text('Navigate'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('ID: 123'), findsOneWidget);
      expect(find.text('Type: prescription'), findsOneWidget);
    });
  });
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class RouteParamsWidget extends StatelessWidget {
  final Map<String, String> params;

  const RouteParamsWidget({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('ID: ${params['id']}'),
        Text('Type: ${params['type']}'),
      ],
    );
  }
}
