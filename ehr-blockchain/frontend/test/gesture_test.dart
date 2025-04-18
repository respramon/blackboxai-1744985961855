import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';

import 'package:ehr_blockchain/widgets/swipe_action.dart';
import 'package:ehr_blockchain/widgets/zoom_image.dart';
import 'package:ehr_blockchain/widgets/drag_drop.dart';
import 'test_helpers.dart';

void main() {
  group('Swipe Gesture Tests', () {
    testWidgets('Swipe to delete', (WidgetTester tester) async {
      bool itemDeleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SwipeActionWidget(
            onDismissed: () => itemDeleted = true,
            child: const ListTile(
              title: Text('Swipe me'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Swipe me'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(itemDeleted, isTrue);
    });

    testWidgets('Swipe action confirmation', (WidgetTester tester) async {
      bool actionConfirmed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SwipeActionWidget(
            confirmDismiss: () async => true,
            onDismissed: () => actionConfirmed = true,
            child: const ListTile(
              title: Text('Swipe with confirmation'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Swipe with confirmation'), const Offset(-500.0, 0.0));
      await tester.pumpAndSettle();

      expect(actionConfirmed, isTrue);
    });
  });

  group('Zoom Gesture Tests', () {
    testWidgets('Pinch to zoom', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ZoomableImage(
            imageUrl: 'test_image.jpg',
            maxScale: 3.0,
          ),
        ),
      );

      final ScaleGestureRecognizer gesture = ScaleGestureRecognizer();
      final TestPointer pointer1 = TestPointer(1);
      final TestPointer pointer2 = TestPointer(2);

      gesture.addPointer(pointer1);
      gesture.addPointer(pointer2);

      // Simulate pinch gesture
      final center = tester.getCenter(find.byType(ZoomableImage));
      pointer1.down(center);
      pointer2.down(center + const Offset(100.0, 0.0));
      await tester.pump();

      pointer1.move(center - const Offset(50.0, 0.0));
      pointer2.move(center + const Offset(150.0, 0.0));
      await tester.pump();

      final Transform transform = tester.widget(find.byType(Transform));
      expect(transform.transform.getMaxScaleOnAxis(), greaterThan(1.0));
    });

    testWidgets('Double tap to zoom', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ZoomableImage(
            imageUrl: 'test_image.jpg',
            maxScale: 3.0,
          ),
        ),
      );

      await tester.tap(find.byType(ZoomableImage));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(ZoomableImage));
      await tester.pumpAndSettle();

      final Transform transform = tester.widget(find.byType(Transform));
      expect(transform.transform.getMaxScaleOnAxis(), equals(2.0));
    });
  });

  group('Drag and Drop Tests', () {
    testWidgets('Drag and drop item', (WidgetTester tester) async {
      final items = ['Item 1', 'Item 2', 'Item 3'];
      int? sourceIndex;
      int? destinationIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: DragDropList(
            items: items,
            onReorder: (oldIndex, newIndex) {
              sourceIndex = oldIndex;
              destinationIndex = newIndex;
            },
          ),
        ),
      );

      final firstItem = find.text('Item 1');
      final lastItem = find.text('Item 3');

      await tester.drag(firstItem, tester.getCenter(lastItem) - tester.getCenter(firstItem));
      await tester.pumpAndSettle();

      expect(sourceIndex, equals(0));
      expect(destinationIndex, equals(2));
    });

    testWidgets('Drag and drop with feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DraggableWidget(
            data: 'test_data',
            feedback: const Material(
              child: Text('Dragging'),
            ),
            child: const Text('Drag me'),
          ),
        ),
      );

      final dragTarget = find.text('Drag me');
      await tester.drag(dragTarget, const Offset(0.0, 100.0));
      await tester.pump();

      expect(find.text('Dragging'), findsOneWidget);
    });
  });

  group('Custom Gesture Tests', () {
    testWidgets('Long press with ripple', (WidgetTester tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CustomGestureDetector(
            onLongPress: () => longPressed = true,
            child: const Text('Long press me'),
          ),
        ),
      );

      await tester.longPress(find.text('Long press me'));
      await tester.pumpAndSettle();

      expect(longPressed, isTrue);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('Pan gesture recognition', (WidgetTester tester) async {
      double? dx;
      double? dy;

      await tester.pumpWidget(
        MaterialApp(
          home: PanHandler(
            onPanUpdate: (details) {
              dx = details.delta.dx;
              dy = details.delta.dy;
            },
            child: const SizedBox(
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      await tester.drag(
        find.byType(SizedBox),
        const Offset(20.0, 30.0),
      );

      expect(dx, isNotNull);
      expect(dy, isNotNull);
    });
  });

  group('Gesture Conflict Resolution Tests', () {
    testWidgets('Nested gesture detectors', (WidgetTester tester) async {
      bool outerTapped = false;
      bool innerTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: GestureDetector(
            onTap: () => outerTapped = true,
            child: GestureDetector(
              onTap: () => innerTapped = true,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 50,
                height: 50,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SizedBox));
      await tester.pump();

      expect(innerTapped, isTrue);
      expect(outerTapped, isFalse);
    });

    testWidgets('Scroll vs drag gesture', (WidgetTester tester) async {
      bool dragStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            children: [
              Draggable<String>(
                data: 'test',
                onDragStarted: () => dragStarted = true,
                feedback: const Material(
                  child: Text('Dragging'),
                ),
                child: const SizedBox(
                  height: 100,
                  child: Text('Drag or scroll'),
                ),
              ),
            ],
          ),
        ),
      );

      // Test vertical drag (should scroll)
      await tester.drag(find.text('Drag or scroll'), const Offset(0.0, -100.0));
      expect(dragStarted, isFalse);

      // Test horizontal drag (should initiate drag)
      await tester.drag(find.text('Drag or scroll'), const Offset(100.0, 0.0));
      expect(dragStarted, isTrue);
    });
  });
}

class SwipeActionWidget extends StatelessWidget {
  final VoidCallback onDismissed;
  final Future<bool> Function()? confirmDismiss;
  final Widget child;

  const SwipeActionWidget({
    super.key,
    required this.onDismissed,
    this.confirmDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (_) => onDismissed(),
      confirmDismiss: (_) async => confirmDismiss?.call() ?? true,
      child: child,
    );
  }
}

class ZoomableImage extends StatelessWidget {
  final String imageUrl;
  final double maxScale;

  const ZoomableImage({
    super.key,
    required this.imageUrl,
    this.maxScale = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: maxScale,
      child: Image.network(imageUrl),
    );
  }
}

class DragDropList extends StatelessWidget {
  final List<String> items;
  final Function(int, int) onReorder;

  const DragDropList({
    super.key,
    required this.items,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: onReorder,
      children: items
          .map((item) => ListTile(
                key: ValueKey(item),
                title: Text(item),
              ))
          .toList(),
    );
  }
}

class DraggableWidget extends StatelessWidget {
  final String data;
  final Widget feedback;
  final Widget child;

  const DraggableWidget({
    super.key,
    required this.data,
    required this.feedback,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: data,
      feedback: feedback,
      child: child,
    );
  }
}

class CustomGestureDetector extends StatelessWidget {
  final VoidCallback onLongPress;
  final Widget child;

  const CustomGestureDetector({
    super.key,
    required this.onLongPress,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: onLongPress,
      child: child,
    );
  }
}

class PanHandler extends StatelessWidget {
  final Function(DragUpdateDetails) onPanUpdate;
  final Widget child;

  const PanHandler({
    super.key,
    required this.onPanUpdate,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: onPanUpdate,
      child: child,
    );
  }
}
