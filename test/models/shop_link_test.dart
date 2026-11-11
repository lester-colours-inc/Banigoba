import 'package:banigoba/modules/shop/models/shop_link.dart';
import 'package:flutter_test/flutter_test.dart';

ShopLink _link({
  ShareScope scope = ShareScope.all,
  String category = '',
  List<String> productIds = const [],
  ShareAudience audience = ShareAudience.linkOnly,
}) => ShopLink(
  id: 'abc123',
  ownerId: 'shop1',
  shopName: 'Glow Boutique',
  title: 'New in: winter coats',
  note: 'Sizes S to XL',
  scope: scope,
  category: category,
  productIds: productIds,
  audience: audience,
);

void main() {
  group('links', () {
    test('a link is the web address with the id', () {
      expect(shopLinkUrl('abc123'), '$kShareHost/s?id=abc123');
    });

    test('reads the id back from a link, an app route or a web route', () {
      expect(shopLinkIdFrom(Uri.parse('$kShareHost/s?id=abc123')), 'abc123');
      expect(shopLinkIdFrom(Uri.parse('/s?id=abc123')), 'abc123');
      expect(
        shopLinkIdFrom(Uri.parse('https://elsewhere.example/x?id=1')),
        isNull,
      );
      expect(shopLinkIdFrom(Uri.parse('/s')), isNull);
      expect(shopLinkIdFrom(Uri.parse('/s?id=')), isNull);
    });

    test('refuses ids that are not plain', () {
      expect(shopLinkIdFrom(Uri.parse('/s?id=../users')), isNull);
      expect(shopLinkIdFrom(Uri.parse('/s?id=a b')), isNull);
    });
  });

  group('the message that is shared', () {
    test('names the shop and what to do, and ends with the link', () {
      final text = shareMessage(_link());

      expect(text, contains('Glow Boutique'));
      expect(text, contains('New in: winter coats'));
      expect(text, contains('Sizes S to XL'));
      expect(text, contains('try them on'));
      expect(text.trim(), endsWith(shopLinkUrl('abc123')));
    });

    test('leaves the note out when there is none', () {
      final text = shareMessage(
        ShopLink(
          id: 'x',
          ownerId: 's',
          shopName: 'Glow',
          title: 'All stock',
          note: '',
          scope: ShareScope.all,
          audience: ShareAudience.linkOnly,
        ),
      );

      expect(text, isNot(contains('\n\n\n')));
    });

    test(
      'opens WhatsApp with the message ready, for the person to pick groups',
      () {
        final uri = whatsAppShareUri(
          'Hello & welcome https://x.example/s?id=1',
        );

        expect(uri.host, 'wa.me');
        expect(
          uri.queryParameters['text'],
          'Hello & welcome https://x.example/s?id=1',
        );
      },
    );
  });

  group('ShopLink.validate', () {
    test('needs a title', () {
      expect(
        validateShopLink(
          title: '  ',
          scope: ShareScope.all,
          productIds: const [],
        ),
        'Give your link a title.',
      );
    });

    test('a category share needs a category', () {
      expect(
        validateShopLink(
          title: 'Coats',
          scope: ShareScope.category,
          category: '',
          productIds: const [],
        ),
        'Choose a category.',
      );
    });

    test('a pick-pieces share needs at least one piece, and not too many', () {
      expect(
        validateShopLink(
          title: 'Picks',
          scope: ShareScope.items,
          productIds: const [],
        ),
        'Choose at least one piece.',
      );
      expect(
        validateShopLink(
          title: 'Picks',
          scope: ShareScope.items,
          productIds: [for (var i = 0; i <= kMaxSharedPieces; i += 1) 'p$i'],
        ),
        'Choose at most $kMaxSharedPieces pieces.',
      );
    });

    test('a long title or note is refused', () {
      expect(
        validateShopLink(
          title: 'x' * 81,
          scope: ShareScope.all,
          productIds: const [],
        ),
        isNotNull,
      );
      expect(
        validateShopLink(
          title: 'ok',
          note: 'x' * 301,
          scope: ShareScope.all,
          productIds: const [],
        ),
        isNotNull,
      );
    });

    test('a good share passes', () {
      expect(
        validateShopLink(
          title: 'All stock',
          scope: ShareScope.all,
          productIds: const [],
        ),
        isNull,
      );
    });
  });

  group('round trip', () {
    test('toMap and fromMap keep everything', () {
      final link = _link(
        scope: ShareScope.items,
        productIds: const ['p1', 'p2'],
        audience: ShareAudience.followers,
      );

      final back = ShopLink.fromMap('abc123', link.toMap());

      expect(back.ownerId, 'shop1');
      expect(back.shopName, 'Glow Boutique');
      expect(back.scope, ShareScope.items);
      expect(back.productIds, ['p1', 'p2']);
      expect(back.audience, ShareAudience.followers);
      expect(back.active, isTrue);
    });

    test('a category share keeps its category; others drop it', () {
      expect(
        _link(
          scope: ShareScope.category,
          category: 'Outerwear',
        ).toMap()['category'],
        'outerwear',
      );
      expect(
        _link(category: 'outerwear').toMap().containsKey('category'),
        isFalse,
      );
    });

    test('unknown values read as the safest choice', () {
      final back = ShopLink.fromMap('x', const {
        'scope': 'weird',
        'audience': 'everyone',
      });

      expect(back.scope, ShareScope.all);
      expect(back.audience, ShareAudience.linkOnly);
    });
  });

  group('describe', () {
    test('says in words what the link holds', () {
      expect(_link().scopeLabel, 'All my stock');
      expect(
        _link(scope: ShareScope.category, category: 'outerwear').scopeLabel,
        'Outerwear',
      );
      expect(
        _link(scope: ShareScope.items, productIds: const ['a', 'b']).scopeLabel,
        '2 pieces',
      );
      expect(
        _link(scope: ShareScope.items, productIds: const ['a']).scopeLabel,
        '1 piece',
      );
    });
  });
}
