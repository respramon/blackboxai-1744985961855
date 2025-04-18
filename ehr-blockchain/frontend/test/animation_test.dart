import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ehr_blockchain/widgets/animated_loading.dart';
import 'package:ehr_blockchain/widgets/fade_in_widget.dart';
import 'package:ehr_blockchain/widgets/slide_transition_widget.dart';
import 'package:ehr_blockchain/utils/animations.dart';
import 'test_helpers.dart';

void main() {
  group('Animation Controller Tests', () {
    late AnimationController controller;

    setUp(() {
      controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: TestVSync(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('Animation controller initialization', () {
      expect(controller.duration, const Duration(milliseconds: 300));
      expect(controller.value, 0.0);
      expect(controller.status, AnimationStatus.dismissed);
    });

    test('Animation controller forward and reverse', () {
      controller.forward();
      expect(controller.status, AnimationStatus.forward);

      controller.reverse();
      expect(controller.status, AnimationStatus.reverse);
    });
  });

  group('Loading Animation Tests', () {
    testWidgets('Circular loading animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedLoading(),
          ),
        ),
      );

      expect(find.byType(AnimatedLoading), findsOneWidget);
      
      // Test animation frames
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
    });

    testWidgets('Loading animation color transition',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedLoading(
              color: ColorTween(
                begin: Colors.blue,
                end: Colors.red,
              ).animate(
                CurvedAnimation(
                  parent: tester.binding.clock,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Fade Animation Tests', () {
    testWidgets('Fade in animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeInWidget(
              child: Text('Fade In Text'),
            ),
          ),
        ),
      );

      // Initial state
      expect(find.byType(FadeTransition), findsOneWidget);
      
      // After animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Fade In Text'), findsOneWidget);
    });

    testWidgets('Fade out animation', (WidgetTester tester) async {
      bool visible = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => FadeInWidget(
                visible: visible,
                child: const Text('Fade Out Text'),
              ),
            ),
          ),
        ),
      );

      // Initial state
      expect(find.text('Fade Out Text'), findsOneWidget);

      // Trigger fade out
      visible = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });

  group('Slide Animation Tests', () {
    testWidgets('Slide in animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideTransitionWidget(
              direction: SlideDirection.leftToRight,
              child: Text('Slide In Text'),
            ),
          ),
        ),
      );

      // Initial position
      expect(find.byType(SlideTransition), findsOneWidget);

      // After animation
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Slide In Text'), findsOneWidget);
    });

    testWidgets('Slide direction tests', (WidgetTester tester) async {
      for (final direction in SlideDirection.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SlideTransitionWidget(
                direction: direction,
                child: const Text('Sliding Text'),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });

  group('Custom Animation Tests', () {
    testWidgets('Custom curve animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomAnimatedWidget(
              curve: Curves.bounceOut,
              duration: const Duration(milliseconds: 500),
              builder: (context, animation) => ScaleTransition(
                scale: animation,
                child: const Text('Bouncing Text'),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Chained animations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChainedAnimationWidget(
              animations: [
                AnimationConfig(
                  type: AnimationType.fade,
                  duration: const Duration(milliseconds: 200),
                ),
                AnimationConfig(
                  type: AnimationType.scale,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
              child: const Text('Chained Animation Text'),
            ),
          ),
        ),
      );

      // Test each animation in sequence
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    });
  });

  group('Page Transition Tests', () {
    testWidgets('Page transition animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) {
                return FadeTransition(
                  opacity: animation,
                  child: const Text('New Page'),
                );
              },
            );
          },
          home: const Text('Home Page'),
        ),
      );

      expect(find.text('Home Page'), findsOneWidget);

      // Navigate to new page
      Navigator.of(tester.element(find.text('Home Page')))
          .pushNamed('/new-page');
      
      // Test transition
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      
      expect(find.text('New Page'), findsOneWidget);
    });
  });
}

class TestVSync extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

enum AnimationType {
  fade,
  scale,
  slide,
  rotate,
}

class AnimationConfig {
  final AnimationType type;
  final Duration duration;
  final Curve curve;

  const AnimationConfig({
    required this.type,
    required this.duration,
    this.curve = Curves.easeInOut,
  });
}

class CustomAnimatedWidget extends StatefulWidget {
  final Widget Function(BuildContext, Animation<double>) builder;
  final Curve curve;
  final Duration duration;

  const CustomAnimatedWidget({
    super.key,
    required this.builder,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<CustomAnimatedWidget> createState() => _CustomAnimatedWidgetState();
}

class _CustomAnimatedWidgetState extends State<CustomAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animation);
  }
}

class ChainedAnimationWidget extends StatefulWidget {
  final List<AnimationConfig> animations;
  final Widget child;

  const ChainedAnimationWidget({
    super.key,
    required this.animations,
    required this.child,
  });

  @override
  State<ChainedAnimationWidget> createState() => _ChainedAnimationWidgetState();
}

class _ChainedAnimationWidgetState extends State<ChainedAnimationWidget>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = widget.animations
        .map((config) => AnimationController(
              duration: config.duration,
              vsync: this,
            ))
        .toList();

    _animations = _controllers
        .asMap()
        .map((i, controller) => MapEntry(
              i,
              CurvedAnimation(
                parent: controller,
                curve: widget.animations[i].curve,
              ),
            ))
        .values
        .toList();

    _playAnimationsInSequence();
  }

  Future<void> _playAnimationsInSequence() async {
    for (final controller in _controllers) {
      await controller.forward();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    for (var i = _animations.length - 1; i >= 0; i--) {
      final type = widget.animations[i].type;
      switch (type) {
        case AnimationType.fade:
          child = FadeTransition(opacity: _animations[i], child: child);
          break;
        case AnimationType.scale:
          child = ScaleTransition(scale: _animations[i], child: child);
          break;
        case AnimationType.slide:
          child = SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(_animations[i]),
            child: child,
          );
          break;
        case AnimationType.rotate:
          child = RotationTransition(turns: _animations[i], child: child);
          break;
      }
    }
    return child;
  }
}
