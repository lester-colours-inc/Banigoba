import 'package:banigoba/modules/social/services/like_service.dart';
import 'package:banigoba/modules/social/widgets/like_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => LikeService.instance.likedPostIds.value = const {});

  Widget host(String postId, {int likeCount = 0}) => MaterialApp(
    home: Scaffold(
      body: LikesBuilder(
        builder: (context) {
          final action = likeCardAction(context, postId, likeCount: likeCount);
          return Row(
            children: [
              Icon(
                action.isActive ? action.activeIcon : action.icon,
                semanticLabel: action.label,
              ),
              if (action.countLabel case final count?) Text(count),
            ],
          );
        },
      ),
    ),
  );

  testWidgets('shows an outlined heart for a look not yet liked', (
    tester,
  ) async {
    await tester.pumpWidget(host('look-1'));

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.bySemanticsLabel('Like · 0 likes'), findsOneWidget);
  });

  testWidgets('fills the heart as soon as the look is liked', (tester) async {
    await tester.pumpWidget(host('look-1', likeCount: 4));

    LikeService.instance.likedPostIds.value = {'look-1'};
    await tester.pump();

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.bySemanticsLabel('Unlike · 4 likes'), findsOneWidget);
  });

  testWidgets('shows the like count beside the heart', (tester) async {
    await tester.pumpWidget(host('look-1', likeCount: 12));

    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('shows no number on a look nobody has liked', (tester) async {
    await tester.pumpWidget(host('look-1'));

    expect(find.text('0'), findsNothing);
  });

  group('displayCount', () {
    test('is the loaded count when nothing was tapped', () {
      expect(LikeService.instance.displayCount('untapped', 7), 7);
    });
  });

  group('compactCount', () {
    test('keeps small numbers as they are', () {
      expect(compactCount(0), '0');
      expect(compactCount(999), '999');
    });

    test('shortens thousands and millions', () {
      expect(compactCount(1000), '1K');
      expect(compactCount(1250), '1.2K');
      expect(compactCount(15300), '15K');
      expect(compactCount(2400000), '2.4M');
    });
  });

  test('likeCountLabel reads naturally', () {
    expect(likeCountLabel(1), '1 like');
    expect(likeCountLabel(3), '3 likes');
  });
}
