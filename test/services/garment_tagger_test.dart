// Verifies how the tagger asks the server and reads the answer.
import 'dart:convert';
import 'dart:typed_data';

import 'package:banigoba/modules/wardrobe/models/garment_tags.dart';
import 'package:banigoba/modules/wardrobe/services/garment_tagger.dart';
import 'package:flutter_test/flutter_test.dart';

final Uint8List _photo = Uint8List.fromList(List.filled(64, 7));

void main() {
  test('sends the photo and the fixed question, and reads the tags', () async {
    late Map<String, Object?> seen;
    final tagger = ServerGarmentTagger(
      call: (body) async {
        seen = body;
        return {
          'tags': {
            'name': 'Red dress',
            'category': 'dresses',
            'colours': ['red'],
            'styleTag': 'glamour',
          },
        };
      },
    );

    final tags = await tagger.tag(_photo, mimeType: 'image/png');

    expect(tags?.category, 'dresses');
    expect(tags?.colours, ['red']);
    expect(tags?.styleTag, 'glamour');
    expect(seen['prompt'], contains('never a person'));
    expect(seen['image'], base64Encode(_photo));
    expect(seen['mimeType'], 'image/png');
    expect(seen['schema'], isA<Map<String, Object?>>());
  });

  test('the question lists every allowed word', () {
    for (final word in [
      ...kGarmentCategories.keys,
      ...kGarmentColours,
      ...kGarmentStyles,
      ...kGarmentWeather,
    ]) {
      expect(ServerGarmentTagger.prompt, contains(word));
    }
  });

  test('an error or a broken answer gives no suggestion', () async {
    final failing = ServerGarmentTagger(
      call: (_) async => throw Exception('502'),
    );
    final garbled = ServerGarmentTagger(call: (_) async => 'not json');
    final empty = ServerGarmentTagger(call: (_) async => {'tags': null});

    expect(await failing.tag(_photo), isNull);
    expect(await garbled.tag(_photo), isNull);
    expect(await empty.tag(_photo), isNull);
  });

  test('an answer with nothing the app knows gives no suggestion', () async {
    final tagger = ServerGarmentTagger(
      call: (_) async => {
        'tags': {'category': 'spaceship', 'colours': <String>[]},
      },
    );

    expect(await tagger.tag(_photo), isNull);
  });

  test('an empty or oversized photo is never sent', () async {
    var called = false;
    final tagger = ServerGarmentTagger(
      call: (_) async {
        called = true;
        return null;
      },
    );

    expect(await tagger.tag(Uint8List(0)), isNull);
    expect(await tagger.tag(Uint8List(6 * 1024 * 1024 + 1)), isNull);
    expect(called, isFalse);
  });
}
