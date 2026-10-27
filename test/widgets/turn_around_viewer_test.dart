// Verifies dragging turns the try-on through its angles.
import 'package:banigoba/data/services/turn_around_service.dart';
import 'package:banigoba/ui/widgets/turn_around_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _all = {
  TurnView.front: 'front.png',
  TurnView.right: 'right.png',
  TurnView.back: 'back.png',
  TurnView.left: 'left.png',
};

Future<void> _pump(
  WidgetTester tester, {
  Map<TurnView, String> views = _all,
  bool makingMore = false,
}) {
  // A phone-sized screen, so the picture and the arrows are both on it.
  tester.view
    ..physicalSize = const Size(1170, 2532)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TurnAroundViewer(
            views: views,
            isMakingMore: makingMore,
            imageBuilder: (url) =>
                Text('image:$url', key: const ValueKey('img')),
          ),
        ),
      ),
    ),
  );
}

String _shown(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('img'))).data!;

Future<void> _drag(WidgetTester tester, double dx) async {
  await tester.drag(find.byKey(const ValueKey('turn_surface')), Offset(dx, 0));
  await tester.pump();
}

void main() {
  test('turnedIndex wraps around both ways', () {
    expect(turnedIndex(0, 4, 1), 1);
    expect(turnedIndex(3, 4, 1), 0);
    expect(turnedIndex(0, 4, -1), 3);
    expect(turnedIndex(2, 4, -7), 3);
    expect(turnedIndex(0, 0, 1), 0);
  });

  testWidgets('starts on the front, with no estimated tag', (tester) async {
    await _pump(tester);

    expect(_shown(tester), 'image:front.png');
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Estimated view'), findsNothing);
  });

  testWidgets('dragging left turns forward through the angles', (tester) async {
    await _pump(tester);

    await _drag(tester, -(kTurnStepPixels + 30));
    expect(_shown(tester), 'image:right.png');
    expect(find.text('Estimated view'), findsOneWidget);

    await _drag(tester, -(kTurnStepPixels + 30));
    expect(_shown(tester), 'image:back.png');
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('dragging right turns the other way and wraps to the left', (
    tester,
  ) async {
    await _pump(tester);

    await _drag(tester, kTurnStepPixels + 30);
    expect(_shown(tester), 'image:left.png');
  });

  testWidgets('a short drag does not turn it', (tester) async {
    await _pump(tester);

    await _drag(tester, -(kTurnStepPixels - 40));
    expect(_shown(tester), 'image:front.png');
  });

  testWidgets('the arrow buttons turn it too', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const ValueKey('turn_forward')));
    await tester.pump();
    expect(_shown(tester), 'image:right.png');

    await tester.tap(find.byKey(const ValueKey('turn_back')));
    await tester.pump();
    expect(_shown(tester), 'image:front.png');
  });

  testWidgets('only angles that are ready are in the turn', (tester) async {
    await _pump(
      tester,
      views: {TurnView.front: 'front.png', TurnView.right: 'right.png'},
      makingMore: true,
    );

    expect(find.textContaining('making more angles'), findsOneWidget);
    await _drag(tester, -(kTurnStepPixels + 30));
    expect(_shown(tester), 'image:right.png');
    await _drag(tester, -(kTurnStepPixels + 30));
    expect(_shown(tester), 'image:front.png');
  });

  testWidgets('with only the front there is nothing to turn', (tester) async {
    await _pump(tester, views: {TurnView.front: 'front.png'});

    final forward = tester.widget<IconButton>(
      find.byKey(const ValueKey('turn_forward')),
    );
    expect(forward.onPressed, isNull);
  });
}
