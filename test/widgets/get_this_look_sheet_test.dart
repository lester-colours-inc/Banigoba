import 'package:banigoba/data/models/look_purchase.dart';
import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/services/look_purchase_service.dart';
import 'package:banigoba/ui/widgets/find_pieces_sheet.dart';
import 'package:banigoba/ui/widgets/get_this_look_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ShopPick _pick(String id, {String size = 'M', String name = 'Blazer'}) =>
    ShopPick(
      product: {'id': id, 'name': name, 'price': 49.5},
      size: size,
      score: 2,
      reasons: const ['In your size (M)', 'Suits your Smart style'],
    );

PieceAdvice _advice(
  LookPart part, {
  int owned = 0,
  List<ShopPick> picks = const [],
}) => PieceAdvice(
  part: part,
  owned: [
    for (var i = 0; i < owned; i += 1) {'category': 'tops'},
  ],
  picks: picks,
);

Future<void> _pumpSheet(
  WidgetTester tester,
  List<PieceAdvice> advices, {
  AddPickToCart? onAdd,
  ValueChanged<LookPart>? onBrowse,
  VoidCallback? onHair,
  bool showHair = false,
}) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GetThisLookSheet(
          advices: advices,
          showHair: showHair,
          onAddToCart: onAdd ?? (_) async => null,
          onBrowse: onBrowse ?? (_) {},
          onHair: onHair ?? () {},
          onDesigner: () {},
        ),
      ),
    ),
  );
}

class _FakeSource implements LookPurchaseSource {
  _FakeSource(this.advices, {this.fail = false});

  final List<PieceAdvice> advices;
  final bool fail;
  List<LookPart>? askedFor;

  @override
  Future<List<PieceAdvice>> load(String userId, List<LookPart> parts) async {
    askedFor = parts;
    if (fail) throw Exception('offline');
    return advices;
  }
}

Future<void> _openFromButton(
  WidgetTester tester, {
  required LookPurchaseSource source,
  List<LookPart> parts = const [LookPart.top],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showFindPiecesSheet(
              context,
              parts: parts,
              source: source,
              userId: 'me',
              addToCart: (_) async => null,
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
  group('GetThisLookSheet', () {
    testWidgets('says what is already in the wardrobe', (tester) async {
      await _pumpSheet(tester, [
        _advice(LookPart.top, owned: 2),
        _advice(LookPart.bottom),
      ]);

      expect(find.text('You have 2 in your wardrobe'), findsOneWidget);
      expect(find.text('None in your wardrobe'), findsOneWidget);
    });

    testWidgets('shows each pick with price and reasons', (tester) async {
      await _pumpSheet(tester, [
        _advice(LookPart.top, picks: [_pick('p1')]),
      ]);

      expect(find.text('Blazer'), findsOneWidget);
      expect(find.text('\$49.50'), findsOneWidget);
      expect(
        find.text('In your size (M) · Suits your Smart style'),
        findsOneWidget,
      );
    });

    testWidgets('adds a pick to the bag in one tap', (tester) async {
      ShopPick? added;
      await _pumpSheet(
        tester,
        [
          _advice(LookPart.top, picks: [_pick('p1')]),
        ],
        onAdd: (pick) async {
          added = pick;
          return null;
        },
      );

      await tester.tap(find.byKey(const ValueKey('add_pick_p1')));
      await tester.pump();

      expect(added?.product['id'], 'p1');
      expect(find.text('Added'), findsOneWidget);
    });

    testWidgets('shows why a pick could not be added and allows a retry', (
      tester,
    ) async {
      await _pumpSheet(tester, [
        _advice(LookPart.top, picks: [_pick('p1')]),
      ], onAdd: (_) async => 'Size M is out of stock.');

      await tester.tap(find.byKey(const ValueKey('add_pick_p1')));
      await tester.pump();

      expect(find.text('Size M is out of stock.'), findsOneWidget);
      expect(find.text('Add to bag'), findsOneWidget);
    });

    testWidgets('says so when no shop piece fits', (tester) async {
      await _pumpSheet(tester, [_advice(LookPart.shoes)]);

      expect(find.byKey(const ValueKey('no_picks_shoes')), findsOneWidget);
    });

    testWidgets('browse opens that part in the boutiques', (tester) async {
      LookPart? browsed;
      await _pumpSheet(tester, [
        _advice(LookPart.bottom),
      ], onBrowse: (part) => browsed = part);

      await tester.tap(find.byKey(const ValueKey('browse_bottom')));

      expect(browsed, LookPart.bottom);
    });

    testWidgets('offers a hairdresser only when the look has hair', (
      tester,
    ) async {
      await _pumpSheet(tester, [_advice(LookPart.top)]);
      expect(find.byKey(const ValueKey('get_look_hair')), findsNothing);

      await _pumpSheet(tester, [_advice(LookPart.top)], showHair: true);
      expect(find.byKey(const ValueKey('get_look_hair')), findsOneWidget);
    });
  });

  group('showFindPiecesSheet', () {
    testWidgets('asks only about the changed parts and shows the advice', (
      tester,
    ) async {
      final source = _FakeSource([
        _advice(LookPart.top, owned: 1, picks: [_pick('p1')]),
      ]);

      await _openFromButton(tester, source: source);

      expect(source.askedFor, [LookPart.top]);
      expect(find.text('Get this look'), findsOneWidget);
      expect(find.text('You have 1 in your wardrobe'), findsOneWidget);
    });

    testWidgets('falls back to the plain links when loading fails', (
      tester,
    ) async {
      await _openFromButton(tester, source: _FakeSource(const [], fail: true));

      expect(find.text('Find these pieces'), findsOneWidget);
      expect(find.byKey(const ValueKey('find_piece_Top')), findsOneWidget);
    });

    testWidgets('a hair-only look goes straight to the plain links', (
      tester,
    ) async {
      final source = _FakeSource(const []);

      await _openFromButton(
        tester,
        source: source,
        parts: const [LookPart.hair],
      );

      expect(source.askedFor, isNull);
      expect(find.text('Find these pieces'), findsOneWidget);
    });
  });

  group('categoriesToScan', () {
    test('covers the kinds of piece the look needs', () {
      expect(categoriesToScan([LookPart.bottom]), {'bottoms'});
      expect(categoriesToScan([LookPart.top, LookPart.bottom]), {
        'tops',
        'outerwear',
        'bottoms',
      });
      expect(categoriesToScan([LookPart.shoes]), {
        'shoes',
        'other',
        'accessories',
      });
      expect(categoriesToScan([LookPart.hair]), isEmpty);
    });
  });
}
