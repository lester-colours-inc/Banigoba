// Verifies the guided first five minutes (O-1): four optional steps, with
// progress, and a way out at any point.
import 'package:banigoba/data/models/first_run_guide.dart';
import 'package:banigoba/ui/screens/onboarding/first_run_guide_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeActions implements GuideActions {
  final calls = <String>[];
  var finished = 0;
  bool photoSaves = true;
  Object? failPieceWith;

  @override
  Future<bool> addPhoto(BuildContext context) async {
    calls.add('photo');
    return photoSaves;
  }

  @override
  Future<bool> pickStyle(BuildContext context) async {
    calls.add('style');
    return true;
  }

  @override
  Future<bool> addPiece(BuildContext context) async {
    calls.add('piece');
    if (failPieceWith != null) throw failPieceWith!;
    return true;
  }

  @override
  Future<bool> tryMakeover(BuildContext context) async {
    calls.add('makeover');
    return true;
  }

  @override
  Future<void> finish() async => finished += 1;
}

Future<_FakeActions> _open(WidgetTester tester, {_FakeActions? actions}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = actions ?? _FakeActions();
  await tester.pumpWidget(
    MaterialApp(
      home: FirstRunGuideScreen(
        userId: 'user-1',
        name: 'Tari Moyo',
        actions: fake,
      ),
    ),
  );
  return fake;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcomes the person by first name and lists four steps', (
    tester,
  ) async {
    await _open(tester);

    expect(find.text('Welcome, Tari'), findsOneWidget);
    for (final step in GuideStep.values) {
      expect(find.byKey(ValueKey('guide_${step.name}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('guide_skip')), findsOneWidget);
    expect(find.byKey(const ValueKey('guide_finish')), findsNothing);
  });

  testWidgets('doing a step marks it done and moves the progress on', (
    tester,
  ) async {
    final actions = await _open(tester);

    await _tap(tester, 'guide_photo_go');

    expect(actions.calls, ['photo']);
    expect(find.byKey(const ValueKey('guide_photo_go')), findsNothing);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byKey(const ValueKey('guide_progress')),
    );
    expect(bar.value, 0.25);
  });

  testWidgets('a step the person backs out of stays open', (tester) async {
    final actions = _FakeActions()..photoSaves = false;
    await _open(tester, actions: actions);

    await _tap(tester, 'guide_photo_go');

    expect(find.byKey(const ValueKey('guide_photo_go')), findsOneWidget);
  });

  testWidgets('wardrobe pieces count up to three', (tester) async {
    await _open(tester);

    await _tap(tester, 'guide_wardrobe_go');
    expect(find.textContaining('1 of 3'), findsOneWidget);
    expect(find.text('Add another'), findsOneWidget);

    await _tap(tester, 'guide_wardrobe_go');
    await _tap(tester, 'guide_wardrobe_go');
    expect(find.byKey(const ValueKey('guide_wardrobe_go')), findsNothing);
  });

  testWidgets('a failed step says so and can be tried again', (tester) async {
    final actions = _FakeActions()..failPieceWith = Exception('offline');
    await _open(tester, actions: actions);

    await _tap(tester, 'guide_wardrobe_go');

    expect(find.textContaining('That did not work'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide_wardrobe_go')), findsOneWidget);
  });

  testWidgets('skipping finishes the guide at once', (tester) async {
    final actions = await _open(tester);

    await _tap(tester, 'guide_skip');

    expect(actions.finished, 1);
    expect(actions.calls, isEmpty);
  });

  testWidgets('after some steps the skip button says finish later', (
    tester,
  ) async {
    await _open(tester);

    await _tap(tester, 'guide_style_go');

    expect(find.text('Finish later'), findsOneWidget);
  });

  testWidgets('finishing every step ends with a kind word and a way in', (
    tester,
  ) async {
    final actions = await _open(tester);

    await _tap(tester, 'guide_photo_go');
    await _tap(tester, 'guide_style_go');
    for (var i = 0; i < kGuideWardrobeGoal; i++) {
      await _tap(tester, 'guide_wardrobe_go');
    }
    await _tap(tester, 'guide_makeover_go');

    expect(find.byKey(const ValueKey('guide_welcome')), findsOneWidget);
    expect(find.text('You are all set.'), findsOneWidget);
    expect(find.byKey(const ValueKey('guide_skip')), findsNothing);

    await _tap(tester, 'guide_finish');
    expect(actions.finished, 1);
  });
}
