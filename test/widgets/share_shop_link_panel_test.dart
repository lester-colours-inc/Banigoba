import 'package:banigoba/data/models/shop_link.dart';
import 'package:banigoba/ui/screens/shop/share_shop_link_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

ShopLink _link(ShareAudience audience) => ShopLink(
  id: 'L1',
  ownerId: 'shop1',
  shopName: 'Glow Boutique',
  title: 'Winter coats',
  scope: ShareScope.all,
  audience: audience,
);

Future<void> _pump(
  WidgetTester tester, {
  ShareAudience audience = ShareAudience.linkOnly,
  VoidCallback? onWhatsApp,
  VoidCallback? onMore,
  VoidCallback? onQr,
  VoidCallback? onCopy,
}) {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ShareShopLinkPanel(
          link: _link(audience),
          onWhatsApp: onWhatsApp ?? () {},
          onShareMore: onMore ?? () {},
          onShareQr: onQr ?? () {},
          onCopy: onCopy ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows a QR code for the link and the link itself', (
    tester,
  ) async {
    await _pump(tester);

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr, isNotNull);
    expect(find.text(shopLinkUrl('L1')), findsOneWidget);
  });

  testWidgets('every way of sending calls its action', (tester) async {
    final calls = <String>[];
    await _pump(
      tester,
      onWhatsApp: () => calls.add('wa'),
      onMore: () => calls.add('more'),
      onQr: () => calls.add('qr'),
      onCopy: () => calls.add('copy'),
    );

    for (final key in [
      'share_whatsapp',
      'share_more',
      'share_qr',
      'copy_link',
    ]) {
      await tester.tap(find.byKey(ValueKey(key)));
    }

    expect(calls, ['wa', 'more', 'qr', 'copy']);
  });

  testWidgets('explains that groups are picked in WhatsApp', (tester) async {
    await _pump(tester);

    expect(find.textContaining('choose the groups'), findsOneWidget);
  });

  testWidgets('says who in Banigoba is being told', (tester) async {
    await _pump(tester, audience: ShareAudience.linkOnly);
    expect(find.textContaining('Only people you send it to'), findsOneWidget);

    await _pump(tester, audience: ShareAudience.followers);
    expect(find.textContaining('followers are being told'), findsOneWidget);

    await _pump(tester, audience: ShareAudience.public);
    expect(find.textContaining('Community'), findsOneWidget);

    await _pump(tester, audience: ShareAudience.friends);
    expect(find.textContaining('friends are being told'), findsOneWidget);
  });
}
