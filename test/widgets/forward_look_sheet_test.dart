// Verifies the "Send to" sheet: someone specific, never who sees the look
// in the feeds (that is "Post", P-4).
import 'package:banigoba/ui/widgets/forward_look_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _destinations = [
  'Hair Salon',
  'Shop',
  'Designer',
  'WhatsApp',
  'More apps',
];

Future<void> _openSheet(
  WidgetTester tester, {
  String imageUrl = 'https://example.com/look.jpg',
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
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('is titled Send to and lists every destination', (tester) async {
    await _openSheet(tester);

    expect(find.text('Send to'), findsOneWidget);
    for (final label in _destinations) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('does not offer feed audiences, which belong to Post', (
    tester,
  ) async {
    await _openSheet(tester);

    expect(find.text('Community'), findsNothing);
    expect(find.text('Friends'), findsNothing);
  });

  testWidgets('a look without a picture is not sent', (tester) async {
    await _openSheet(tester, imageUrl: '');

    expect(find.text('Hair Salon'), findsNothing);
    expect(find.text('This look has no picture to send.'), findsOneWidget);
  });

  testWidgets('WhatsApp opens the share sheet like More apps, not a link', (
    tester,
  ) async {
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final shared = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (call) async {
        shared.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        shareChannel,
        null,
      ),
    );

    await _openSheet(tester);
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    expect(shared.single.method, 'share');
    expect(shared.single.arguments['text'], contains('Sunday best'));
  });

  group('shareLookText', () {
    test('leaves the image link out when the picture is attached', () {
      final text = shareLookText('Low cut look');
      expect(text, contains('Low cut look'));
      expect(text, contains('Styled on Banigoba'));
      expect(text, isNot(contains('http')));
    });

    test('adds the link only when the picture could not be attached', () {
      final text = shareLookText(
        'Low cut look',
        fallbackUrl: 'https://example.com/look.jpg',
      );
      expect(text, contains('https://example.com/look.jpg'));
    });

    test('uses a default lead when there is no caption', () {
      expect(shareLookText('  '), startsWith('Check out this look'));
    });
  });
}
