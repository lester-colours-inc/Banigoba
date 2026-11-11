import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/shop/views/shops_page.dart';
import 'package:banigoba/modules/makeover/widgets/find_pieces_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pieceLinksFor', () {
    test('links each changed item, then offers to have it made', () {
      final links = pieceLinksFor(const [LookPart.hair, LookPart.shoes]);

      expect(links.map((link) => link.title), [
        'Hair',
        'Shoes',
        'Have it made',
      ]);
      expect(links[0].destination, PieceDestination.hairdressers);
      expect(links[1].destination, PieceDestination.boutiques);
      expect(links[1].query, 'shoe');
      expect(links.last.destination, PieceDestination.designers);
    });

    test('assumes a whole look when it is not known what changed', () {
      final titles = pieceLinksFor(const []).map((link) => link.title);
      expect(titles, [
        'Hair',
        'Clothes',
        'Shoes',
        'Accessories',
        'Have it made',
      ]);
    });
  });

  group('productMatchesQuery', () {
    const trousers = {'name': 'Linen Wide Leg', 'category': 'Trousers'};

    test('matches the garment group, not just the name', () {
      expect(productMatchesQuery(trousers, 'bottoms'), isTrue);
      expect(productMatchesQuery(trousers, 'tops'), isFalse);
    });

    test('an empty query matches everything', () {
      expect(productMatchesQuery(trousers, ''), isTrue);
    });
  });

  testWidgets('the sheet returns the chosen link', (tester) async {
    PieceLink? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              chosen = await showModalBottomSheet<PieceLink>(
                context: context,
                builder: (_) => FindPiecesSheet(
                  links: pieceLinksFor(const [LookPart.outfit]),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('find_piece_Clothes')));
    await tester.pumpAndSettle();

    expect(chosen?.title, 'Clothes');
  });
}
