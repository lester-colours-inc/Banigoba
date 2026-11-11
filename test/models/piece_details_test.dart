import 'package:banigoba/modules/wardrobe/models/piece_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fromControllerText', () {
    test('trims fields and drops empty other-detail rows', () {
      final details = PieceDetails.fromControllerText(
        shoulderMeasurement: ' 42 ',
        heightMeasurement: '150',
        linenType: ' Pure linen ',
        madeWhere: ' Harare, Zimbabwe ',
        otherDetails: ['Hand-stitched hem', '  ', 'Dry clean only'],
      );

      expect(details.shoulderMeasurement, '42');
      expect(details.linenType, 'Pure linen');
      expect(details.madeWhere, 'Harare, Zimbabwe');
      expect(details.otherDetails, ['Hand-stitched hem', 'Dry clean only']);
      expect(details.isEmpty, isFalse);
    });

    test('is empty when every field is blank', () {
      final details = PieceDetails.fromControllerText(
        shoulderMeasurement: '',
        heightMeasurement: '  ',
        linenType: '',
        madeWhere: '',
        otherDetails: const [],
      );

      expect(details.isEmpty, isTrue);
    });
  });

  group('map round-trip', () {
    test('toMap and fromMap agree', () {
      const details = PieceDetails(
        shoulderMeasurement: '42',
        heightMeasurement: '150',
        linenType: 'Linen blend',
        madeWhere: 'Bulawayo',
        otherDetails: ['Limited edition'],
      );

      final restored = PieceDetails.fromMap(details.toMap());

      expect(restored.shoulderMeasurement, '42');
      expect(restored.heightMeasurement, '150');
      expect(restored.linenType, 'Linen blend');
      expect(restored.madeWhere, 'Bulawayo');
      expect(restored.otherDetails, ['Limited edition']);
    });

    test('tolerates missing and malformed data', () {
      final fromNull = PieceDetails.fromMap(null);
      expect(fromNull.isEmpty, isTrue);

      final fromMalformed = PieceDetails.fromMap({
        'otherDetails': 'not a list',
      });
      expect(fromMalformed.otherDetails, isEmpty);
    });
  });
}
