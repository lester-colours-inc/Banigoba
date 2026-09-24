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
  Widget? footer,
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
    footer: footer,
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
              icon: Icons.shortcut_outlined,
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

    await tester.ensureVisible(find.text('Try On'));
    await tester.tap(find.text('Try On'));
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
