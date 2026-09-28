import 'dart:convert';
import 'dart:typed_data';

import 'package:banigoba/data/services/gemini_image_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final avatar = GeminiImage(
    bytes: Uint8List.fromList([1, 2, 3]),
    mimeType: 'image/jpeg',
  );
  final garment = GeminiImage(
    bytes: Uint8List.fromList([4, 5, 6]),
    mimeType: 'image/png',
  );

  /// Base64 for a two-byte payload, standing in for a generated image.
  const outputBase64 = 'AQI=';

  String interactionWithImage({String mimeType = 'image/jpeg'}) {
    return jsonEncode({
      'id': 'v1_test',
      'status': 'completed',
      'steps': [
        {
          'type': 'user_input',
          'content': [
            {'type': 'text', 'text': 'dress the person'},
          ],
        },
        {
          'type': 'model_output',
          'content': [
            {'type': 'image', 'data': outputBase64, 'mime_type': mimeType},
          ],
        },
      ],
    });
  }

  group('GeminiImageApi.editImage', () {
    test('returns the decoded image from the model_output step', () async {
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(interactionWithImage(), 200),
        ),
      );

      final result = await api.editImage(
        images: [avatar, garment],
        prompt: 'put the garment on the person',
      );

      expect(result.bytes, base64Decode(outputBase64));
      expect(result.mimeType, 'image/jpeg');
    });

    test('sends every image before the prompt text', () async {
      late Map<String, dynamic> sentBody;
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(interactionWithImage(), 200);
        }),
      );

      await api.editImage(images: [avatar, garment], prompt: 'the prompt');

      final input = sentBody['input'] as List;
      expect(input.length, 3);
      expect(input[0]['type'], 'image');
      expect(input[0]['mime_type'], 'image/jpeg');
      expect(input[0]['data'], base64Encode(avatar.bytes));
      expect(input[1]['data'], base64Encode(garment.bytes));
      expect(input[2], {'type': 'text', 'text': 'the prompt'});
      expect(sentBody['model'], GeminiImageApi.defaultModel);
    });

    test('pins the API revision and sends the key as a header', () async {
      late http.BaseRequest sentRequest;
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sentRequest = request;
          return http.Response(interactionWithImage(), 200);
        }),
      );

      await api.editImage(images: [avatar], prompt: 'the prompt');

      expect(sentRequest.headers['x-goog-api-key'], 'test-key');
      expect(sentRequest.headers['Api-Revision'], isNotEmpty);
    });

    test('omits aspect_ratio when it is not requested', () async {
      late Map<String, dynamic> sentBody;
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(interactionWithImage(), 200);
        }),
      );

      await api.editImage(images: [avatar], prompt: 'the prompt');

      final responseFormat = sentBody['response_format'] as Map;
      expect(responseFormat['type'], 'image');
      expect(responseFormat.containsKey('aspect_ratio'), isFalse);
    });

    test('throws when no image is provided', () async {
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => api.editImage(images: [], prompt: 'the prompt'),
        throwsA(isA<GeminiApiException>()),
      );
    });

    test('surfaces the API error message on a failed request', () async {
      final api = GeminiImageApi(
        apiKey: 'bad-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'API key not valid'},
            }),
            400,
          ),
        ),
      );

      await expectLater(
        api.editImage(images: [avatar], prompt: 'the prompt'),
        throwsA(
          isA<GeminiApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                contains('API key not valid'),
              ),
        ),
      );
    });

    test('surfaces the model refusal when it answers with text only', () async {
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'steps': [
                {
                  'type': 'model_output',
                  'content': [
                    {'type': 'text', 'text': 'I cannot edit this image.'},
                  ],
                },
              ],
            }),
            200,
          ),
        ),
      );

      await expectLater(
        api.editImage(images: [avatar], prompt: 'the prompt'),
        throwsA(
          isA<GeminiApiException>().having(
            (e) => e.message,
            'message',
            contains('I cannot edit this image.'),
          ),
        ),
      );
    });

    test('throws when the response has no steps', () async {
      final api = GeminiImageApi(
        apiKey: 'test-key',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'id': 'v1_test'}), 200),
        ),
      );

      await expectLater(
        api.editImage(images: [avatar], prompt: 'the prompt'),
        throwsA(isA<GeminiApiException>()),
      );
    });
  });

  group('GeminiImageApi.fetchImage', () {
    test('returns bytes and the mime type reported by the server', () async {
      final image = await GeminiImageApi.fetchImage(
        'https://example.com/avatar.png',
        client: MockClient(
          (_) async => http.Response.bytes(
            [7, 8, 9],
            200,
            headers: {'content-type': 'image/png'},
          ),
        ),
      );

      expect(image.bytes, [7, 8, 9]);
      expect(image.mimeType, 'image/png');
    });

    test('falls back to image/jpeg for a non-image content type', () async {
      final image = await GeminiImageApi.fetchImage(
        'https://example.com/avatar',
        client: MockClient(
          (_) async => http.Response.bytes(
            [7],
            200,
            headers: {'content-type': 'application/octet-stream'},
          ),
        ),
      );

      expect(image.mimeType, 'image/jpeg');
    });

    test('rejects a URL without a scheme', () async {
      await expectLater(
        GeminiImageApi.fetchImage('not-a-url'),
        throwsA(isA<GeminiApiException>()),
      );
    });

    test('throws when the image cannot be downloaded', () async {
      await expectLater(
        GeminiImageApi.fetchImage(
          'https://example.com/missing.png',
          client: MockClient((_) async => http.Response('not found', 404)),
        ),
        throwsA(
          isA<GeminiApiException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });
}
