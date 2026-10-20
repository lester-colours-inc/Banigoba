// Verifies the Home feed card layouts and the preset quick-reply strip.
import 'package:banigoba/ui/widgets/dress_up_post_card.dart';
import 'package:banigoba/ui/widgets/quick_reply_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

DressUpPostCard _card({
  bool isMineLayout = false,
  List<DressUpCardAction> actions = const [],
  List<DressUpMenuItem> menuItems = const [],
  DressUpCardAction? trailingAction,
  VoidCallback? onImageTap,
  Widget? footer,
  String repostLabel = '',
  String quote = '',
}) {
  return DressUpPostCard(
    isMineLayout: isMineLayout,
    title: 'Tariro Muzaya',
    subtitle: isMineLayout ? 'Warm & Cozy' : '',
    detail: isMineLayout ? 'Vibrant & Bold' : '',
    captionLead: "Tariro's",
    caption: 'My Heritage Fusion Look! #Ankara',
    avatarUrl: '',
    timeLabel: 'Today',
    imageBackground: const Color(0xFFE3A6E6),
    visual: const SizedBox.expand(),
    actions: actions,
    menuItems: menuItems,
    trailingAction: trailingAction,
    onImageTap: onImageTap,
    footer: footer,
    repostLabel: repostLabel,
    quote: quote,
  );
}

void main() {
  testWidgets('Mine layout shows name, then caption and style below', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_card(isMineLayout: true)));

    expect(find.text('Tariro Muzaya'), findsOneWidget);
    expect(find.text('Warm & Cozy'), findsOneWidget);
    expect(find.text('Vibrant & Bold'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.textContaining('Heritage Fusion'), findsNothing);
  });

  testWidgets('action row reads a, edit, save, menu, forward, evenly spaced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        _card(
          isMineLayout: true,
          actions: [
            DressUpCardAction(glyph: 'a', label: 'Affirm', onTap: () {}),
            DressUpCardAction(
              icon: Icons.edit_outlined,
              label: 'Edit my look',
              onTap: () {},
            ),
            DressUpCardAction(
              icon: Icons.checkroom_outlined,
              label: 'Save to Smart Wardrobe',
              onTap: () {},
            ),
          ],
          menuItems: [
            DressUpMenuItem(
              icon: Icons.shopping_bag_outlined,
              label: 'Place Order',
              onSelected: () {},
            ),
          ],
          trailingAction: DressUpCardAction(
            icon: Icons.share_outlined,
            label: 'Forward',
            onTap: () {},
          ),
        ),
      ),
    );

    final xs = [
      'Affirm',
      'Edit my look',
      'Save to Smart Wardrobe',
      'More options',
      'Forward',
    ].map((label) => tester.getCenter(find.byTooltip(label)).dx).toList();
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }
    expect(find.text('a'), findsOneWidget);
    // Icons only: labels live in tooltips, not on the row.
    expect(find.text('Edit my look'), findsNothing);
    // Evenly spread across the card, with no gap wider than the rest.
    final gaps = [for (var i = 1; i < xs.length; i++) xs[i] - xs[i - 1]];
    for (final gap in gaps) {
      expect(gap, closeTo(gaps.first, 1));
    }
  });

  testWidgets('a quote shows who it quotes and the quoter\'s words', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(_card(repostLabel: 'Quoting Rudo', quote: 'This colour!')),
    );

    expect(find.text('Quoting Rudo'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsOneWidget);
    expect(find.text('This colour!'), findsOneWidget);
  });

  testWidgets('an original post has no repost banner', (tester) async {
    await tester.pumpWidget(_host(_card()));

    expect(find.byIcon(Icons.repeat), findsNothing);
    expect(find.byKey(const ValueKey('dress_up_post_quote')), findsNothing);
  });

  testWidgets('tapping the image opens the look', (tester) async {
    var opened = false;
    await tester.pumpWidget(_host(_card(onImageTap: () => opened = true)));

    await tester.tap(find.byKey(const ValueKey('dress_up_post_image')));
    expect(opened, isTrue);
  });

  testWidgets('tapping the name or caption also opens the look, like X', (
    tester,
  ) async {
    var opens = 0;
    await tester.pumpWidget(_host(_card(onImageTap: () => opens++)));

    await tester.tap(find.text('Tariro Muzaya'));
    await tester.tap(find.textContaining('#Ankara', findRichText: true));
    expect(opens, 2);
  });

  testWidgets('tapping an action does not open the look', (tester) async {
    var opened = false;
    var saved = false;
    await tester.pumpWidget(
      _host(
        _card(
          onImageTap: () => opened = true,
          actions: [
            DressUpCardAction(
              icon: Icons.checkroom_outlined,
              label: 'Save to Smart Wardrobe',
              onTap: () => saved = true,
            ),
          ],
        ),
      ),
    );

    await tester.ensureVisible(find.byTooltip('Save to Smart Wardrobe'));
    await tester.tap(find.byTooltip('Save to Smart Wardrobe'));
    expect(saved, isTrue);
    expect(opened, isFalse);
  });

  testWidgets('an active action shows its filled icon, like a liked heart', (
    tester,
  ) async {
    Widget card({required bool saved}) => _host(
      _card(
        actions: [
          DressUpCardAction(
            icon: Icons.checkroom_outlined,
            activeIcon: Icons.checkroom,
            isActive: saved,
            label: 'Save to Smart Wardrobe',
            onTap: () {},
          ),
        ],
      ),
    );

    await tester.pumpWidget(card(saved: false));
    expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    expect(find.byIcon(Icons.checkroom), findsNothing);

    await tester.pumpWidget(card(saved: true));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
    expect(find.byIcon(Icons.checkroom_outlined), findsNothing);
  });

  testWidgets('social layout shows author name and caption with lead', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_card()));

    expect(find.text('Tariro Muzaya'), findsOneWidget);
    expect(find.textContaining("Tariro's", findRichText: true), findsOneWidget);
    expect(find.textContaining('#Ankara', findRichText: true), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('action row and overflow menu invoke their callbacks', (
    tester,
  ) async {
    var triedOn = false;
    var deleted = false;
    await tester.pumpWidget(
      _host(
        _card(
          actions: [
            DressUpCardAction(
              icon: Icons.checkroom_outlined,
              label: 'Try On',
              onTap: () => triedOn = true,
            ),
          ],
          menuItems: [
            DressUpMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onSelected: () => deleted = true,
            ),
          ],
        ),
      ),
    );

    await tester.ensureVisible(find.byTooltip('Try On'));
    await tester.tap(find.byTooltip('Try On'));
    expect(triedOn, isTrue);

    await tester.ensureVisible(find.byTooltip('More options'));
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('quick reply bar sends the tapped preset', (tester) async {
    String? sent;
    await tester.pumpWidget(
      _host(QuickReplyBar(onSelected: (reply) => sent = reply)),
    );

    await tester.tap(find.text(kQuickReplies.first));
    expect(sent, kQuickReplies.first);

    await tester.scrollUntilVisible(
      find.text('Nice outfit!'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Nice outfit!'));
    expect(sent, 'Nice outfit!');
  });

  testWidgets('quick reply bar ignores taps while a reply is sending', (
    tester,
  ) async {
    String? sent;
    await tester.pumpWidget(
      _host(
        QuickReplyBar(isSending: true, onSelected: (reply) => sent = reply),
      ),
    );

    await tester.tap(find.text(kQuickReplies.first));
    expect(sent, isNull);
  });
}
