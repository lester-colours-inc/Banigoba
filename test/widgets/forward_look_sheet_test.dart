import 'package:banigoba/data/models/post.dart';
import 'package:banigoba/ui/widgets/forward_look_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  'Hair Salon',
  'Shop',
  'Designer',
  'Community',
  'Friends',
  'WhatsApp',
  'More apps',
];

Future<void> _openSheet(
  WidgetTester tester, {
  String imageUrl = 'https://example.com/look.jpg',
  PostVisibility visibility = PostVisibility.private,
  Future<void> Function(PostVisibility)? onShareToAudience,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.6;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showForwardLookSheet(
              context,
              imageUrl: imageUrl,
              caption: 'Sunday best',
              visibility: visibility,
              onShareToAudience: onShareToAudience,
            ),
            child: const Text('Forward'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Forward'));
  await tester.pumpAndSettle();
}

bool _isEnabled(WidgetTester tester, ForwardDestination destination) => tester
    .widget<ListTile>(find.byKey(ValueKey('forward_${destination.name}')))
    .enabled;

void main() {
  testWidgets('lists every forward destination', (tester) async {
    await _openSheet(tester, onShareToAudience: (_) async {});

    for (final label in _destinations) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('owner of a private look can forward to community and friends', (
    tester,
  ) async {
    PostVisibility? chosen;
    await _openSheet(
      tester,
      onShareToAudience: (audience) async {
        chosen = audience;
      },
    );

    expect(_isEnabled(tester, ForwardDestination.community), isTrue);
    expect(_isEnabled(tester, ForwardDestination.friends), isTrue);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(chosen, PostVisibility.friends);
  });

  testWidgets('someone else\'s look cannot be shared to community or friends', (
    tester,
  ) async {
    await _openSheet(tester);

    expect(_isEnabled(tester, ForwardDestination.community), isFalse);
    expect(_isEnabled(tester, ForwardDestination.friends), isFalse);
    expect(_isEnabled(tester, ForwardDestination.salon), isTrue);
    expect(_isEnabled(tester, ForwardDestination.whatsapp), isTrue);
    expect(_isEnabled(tester, ForwardDestination.otherApps), isTrue);
  });

  testWidgets('an already public look only disables community', (tester) async {
    await _openSheet(
      tester,
      visibility: PostVisibility.public,
      onShareToAudience: (_) async {},
    );

    expect(_isEnabled(tester, ForwardDestination.community), isFalse);
    expect(find.text('Already shared with the community.'), findsOneWidget);
  });

  testWidgets('a look without a picture is not forwarded', (tester) async {
    await _openSheet(tester, imageUrl: '');

    expect(find.text('Hair Salon'), findsNothing);
    expect(find.text('This look has no picture to forward.'), findsOneWidget);
  });
}
