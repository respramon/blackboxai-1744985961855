import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ehr_blockchain/utils/responsive_helper.dart';
import 'package:ehr_blockchain/widgets/responsive_layout.dart';
import 'package:ehr_blockchain/screens/login_screen.dart';
import 'package:ehr_blockchain/screens/patient/patient_dashboard.dart';
import 'test_helpers.dart';

void main() {
  group('Responsive Layout Tests', () {
    testWidgets('Screen size breakpoints', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600)); // Mobile
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: const Text('Mobile'),
            tablet: const Text('Tablet'),
            desktop: const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Mobile'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 1024)); // Tablet
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: const Text('Mobile'),
            tablet: const Text('Tablet'),
            desktop: const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Tablet'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: const Text('Mobile'),
            tablet: const Text('Tablet'),
            desktop: const Text('Desktop'),
          ),
        ),
      );
      expect(find.text('Desktop'), findsOneWidget);
    });

    testWidgets('Orientation changes', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: OrientationBuilder(
            builder: (context, orientation) {
              return Text(orientation == Orientation.portrait
                  ? 'Portrait'
                  : 'Landscape');
            },
          ),
        ),
      );
      expect(find.text('Portrait'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpWidget(
        MaterialApp(
          home: OrientationBuilder(
            builder: (context, orientation) {
              return Text(orientation == Orientation.portrait
                  ? 'Portrait'
                  : 'Landscape');
            },
          ),
        ),
      );
      expect(find.text('Landscape'), findsOneWidget);
    });
  });

  group('Responsive Widget Tests', () {
    testWidgets('Grid layout responsiveness', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveGridView(
            items: List.generate(
              6,
              (index) => Container(
                color: Colors.blue,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(GridView), findsOneWidget);
      final GridView gridView = tester.widget(find.byType(GridView));
      expect(
        (gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        1,
      );

      await tester.binding.setSurfaceSize(const Size(800, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveGridView(
            items: List.generate(
              6,
              (index) => Container(
                color: Colors.blue,
                child: Text('Item $index'),
              ),
            ),
          ),
        ),
      );
      final GridView tabletGridView = tester.widget(find.byType(GridView));
      expect(
        (tabletGridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount,
        2,
      );
    });

    testWidgets('Text scaling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ResponsiveText(
              'Test Text',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );

      final Text text = tester.widget(find.text('Test Text'));
      expect(text.style?.fontSize, isNotNull);
    });
  });

  group('Layout Adaptation Tests', () {
    testWidgets('Login screen layout adaptation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('Dashboard layout adaptation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: TestWrapper(
            authService: MockBuilder.createMockAuthService(
              isAuthenticated: true,
              currentUser: TestData.createTestUser(),
            ),
            child: const PatientDashboard(),
          ),
        ),
      );
      expect(find.byType(Drawer), findsNothing);

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: TestWrapper(
            authService: MockBuilder.createMockAuthService(
              isAuthenticated: true,
              currentUser: TestData.createTestUser(),
            ),
            child: const PatientDashboard(),
          ),
        ),
      );
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('Responsive Helper Tests', () {
    testWidgets('Device type detection', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Text(
              ResponsiveHelper.getDeviceType(context).toString(),
            ),
          ),
        ),
      );
      expect(find.text('DeviceType.mobile'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 1024));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Text(
              ResponsiveHelper.getDeviceType(context).toString(),
            ),
          ),
        ),
      );
      expect(find.text('DeviceType.tablet'), findsOneWidget);
    });

    testWidgets('Responsive values', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(300, 600));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Container(
              width: ResponsiveHelper.responsiveValue(
                context,
                mobile: 100,
                tablet: 200,
                desktop: 300,
              ),
            ),
          ),
        ),
      );

      final Container container = tester.widget(find.byType(Container));
      expect(container.constraints?.maxWidth, 100);
    });
  });

  group('Layout Constraints Tests', () {
    testWidgets('Maximum content width', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveConstrainedBox(
            child: Container(
              color: Colors.blue,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final Container container = tester.widget(find.byType(Container));
      expect(container.constraints?.maxWidth, ResponsiveHelper.maxContentWidth);
    });

    testWidgets('Minimum content height', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveConstrainedBox(
            child: Container(
              color: Colors.blue,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final Container container = tester.widget(find.byType(Container));
      expect(container.constraints?.minHeight, ResponsiveHelper.minContentHeight);
    });
  });
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> items;

  const ResponsiveGridView({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const ResponsiveText(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: ResponsiveHelper.getResponsiveFontSize(context, style!.fontSize!),
      ),
    );
  }
}

class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;

  const ResponsiveConstrainedBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveHelper.maxContentWidth,
          minHeight: ResponsiveHelper.minContentHeight,
        ),
        child: child,
      ),
    );
  }
}
