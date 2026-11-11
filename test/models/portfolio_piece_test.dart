import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:banigoba/modules/provider/models/portfolio_piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('map round-trip', () {
    test('keeps the picture, size and extra details together', () {
      const piece = PortfolioPiece(
        imageUrl: 'https://example.com/gown.jpg',
        size: 'M',
        details: PieceDetails(
          shoulderMeasurement: '40',
          heightMeasurement: '150',
          linenType: 'Silk',
          madeWhere: 'Harare',
          otherDetails: ['Hand-beaded bodice'],
        ),
      );

      final restored = PortfolioPiece.fromMap(piece.toMap());

      expect(restored.imageUrl, piece.imageUrl);
      expect(restored.size, 'M');
      expect(restored.details.shoulderMeasurement, '40');
      expect(restored.details.otherDetails, ['Hand-beaded bodice']);
    });
  });

  group('listFromProfile', () {
    test('reads structured pieces when present', () {
      final pieces = PortfolioPiece.listFromProfile({
        'portfolioPieces': [
          {'imageUrl': 'https://example.com/a.jpg', 'size': 'S'},
          {'imageUrl': 'https://example.com/b.jpg', 'size': 'L'},
        ],
        // Ignored once structured pieces exist.
        'portfolioImages': ['https://example.com/old.jpg'],
      });

      expect(pieces, hasLength(2));
      expect(pieces.first.imageUrl, 'https://example.com/a.jpg');
      expect(pieces.last.size, 'L');
    });

    test('falls back to plain image URLs for an older designer profile', () {
      final pieces = PortfolioPiece.listFromProfile({
        'portfolioImages': [
          'https://example.com/old-a.jpg',
          '  ',
          'https://example.com/old-b.jpg',
        ],
      });

      expect(pieces.map((piece) => piece.imageUrl), [
        'https://example.com/old-a.jpg',
        'https://example.com/old-b.jpg',
      ]);
      expect(pieces.every((piece) => piece.size.isEmpty), isTrue);
    });

    test('is empty with no portfolio data at all', () {
      expect(PortfolioPiece.listFromProfile(const {}), isEmpty);
    });

    test('drops empty structured entries', () {
      final pieces = PortfolioPiece.listFromProfile({
        'portfolioPieces': [
          {'imageUrl': '', 'size': ''},
          {'imageUrl': 'https://example.com/a.jpg'},
        ],
      });

      expect(pieces, hasLength(1));
    });
  });
}
