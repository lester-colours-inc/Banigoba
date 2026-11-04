// Verifies how the tagger asks Gemini and reads the answer.
import 'dart:convert';
import 'dart:typed_data';

import 'package:banigoba/data/models/garment_tags.dart';
import 'package:banigoba/data/services/garment_tagger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

String _reply(Map<String, Object?> tags) => jsonEncode({
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': jsonEncode(tags)},
        ],
      },
    },
  ],
});

final Uint8List _photo = Uint8List.fromList(List.filled(64, 7));

void main() {
  test('without a key it does nothing and never calls out', () async {
    var called = false;
    final tagger = GeminiGarmentTagger(
      apiKey: '',
      client: MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    expect(tagger.isConfigured, isFalse);
    expect(await tagger.tag(_photo), isNull);
    expect(called, isFalse);
  });

  test('sends the photo and the fixed question, and reads the tags', () async {
    late http.Request seen;
    final tagger = GeminiGarmentTagger(
      apiKey: 'k',
      client: MockClient((request) async {
        seen = request;
        return http.Response(
          _reply({
            'name': 'Red dress',
            'category': 'dresses',
            'colours': ['red'],
            'styleTag': 'glamour',
          }),
          200,
        );
      }),
    );

    final tags = await tagger.tag(_photo);

    expect(tags?.category, 'dresses');
    expect(tags?.colours, ['red']);
    expect(tags?.styleTag, 'glamour');
    expect(seen.headers['x-goog-api-key'], 'k');
    expect(seen.url.path, contains('gemini-2.5-flash:generateContent'));
    final body = jsonDecode(seen.body) as Map<String, dynamic>;
    final parts = (body['contents'] as List).first['parts'] as List;
    expect(parts.first['text'], contains('never a person'));
    expect(parts.last['inline_data']['data'], base64Encode(_photo));
  });

  test('the question lists every allowed word', () {
    for (final word in [
      ...kGarmentCategories.keys,
      ...kGarmentColours,
      ...kGarmentStyles,
      ...kGarmentWeather,
    ]) {
      expect(GeminiGarmentTagger.prompt, contains(word));
    }
  });

  test('an error status or a broken answer gives no suggestion', () async {
    final failing = GeminiGarmentTagger(
      apiKey: 'k',
      client: MockClient((_) async => http.Response('nope', 500)),
    );
    final garbled = GeminiGarmentTagger(
      apiKey: 'k',
      client: MockClient((_) async => http.Response('not json', 200)),
    );

    expect(await failing.tag(_photo), isNull);
    expect(await garbled.tag(_photo), isNull);
  });

  test('an answer with nothing the app knows gives no suggestion', () async {
    final tagger = GeminiGarmentTagger(
      apiKey: 'k',
      client: MockClient(
        (_) async => http.Response(
          _reply({'category': 'spaceship', 'colours': []}),
          200,
        ),
      ),
    );

    expect(await tagger.tag(_photo), isNull);
  });

  test('a network failure gives no suggestion', () async {
    final tagger = GeminiGarmentTagger(
      apiKey: 'k',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    expect(await tagger.tag(_photo), isNull);
  });
}
