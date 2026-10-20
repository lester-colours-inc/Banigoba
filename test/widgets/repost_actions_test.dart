// Verifies Repost/Quote on a private look ask to share it first (P-8).
import 'package:banigoba/data/models/post.dart';
import 'package:banigoba/ui/widgets/repost_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(PostVisibility visibility) => Post(
  id: 'p1',
  authorId: 'me',
  caption: '',
  commentCount: 0,
  createdAt: DateTime(2026, 10, 20),
  imageURL: 'https://example.com/p1.png',
  visibility: visibility,
);

Future<bool?> _run(
  WidgetTester tester,
  Post post, {
  required List<PostVisibility> shared,
  Future<void> Function()? interact,
}) async {
  bool? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await ensureLookShared(
            context,
            post,
            share: (audience) async => shared.add(audience),
          ),
          child: const Text('go'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  await interact?.call();
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('a shared look goes straight on', (tester) async {
    final shared = <PostVisibility>[];
    expect(
      await _run(tester, _post(PostVisibility.friends), shared: shared),
      isTrue,
    );
    expect(find.byKey(const ValueKey('share_first_dialog')), findsNothing);
    expect(shared, isEmpty);
  });

  testWidgets('a private look is shared first, then goes on', (tester) async {
    final shared = <PostVisibility>[];
    final result = await _run(
      tester,
      _post(PostVisibility.private),
      shared: shared,
      interact: () async {
        expect(find.text('Share this look first?'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('share_first_confirm')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Public'));
      },
    );
    expect(result, isTrue);
    expect(shared, [PostVisibility.public]);
  });

  testWidgets('"Not now" leaves a private look private', (tester) async {
    final shared = <PostVisibility>[];
    final result = await _run(
      tester,
      _post(PostVisibility.private),
      shared: shared,
      interact: () => tester.tap(find.text('Not now')),
    );
    expect(result, isFalse);
    expect(shared, isEmpty);
  });
}
