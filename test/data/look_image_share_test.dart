// Verifies a look's picture is fetched as a file, so sharing it (WhatsApp and
// More apps) sends the image rather than a link.

import 'package:banigoba/data/services/look_image_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _bytes = Uint8List.fromList([1, 2, 3, 4]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('downloadLookImage', () {
    test('returns the picture bytes with its image type', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          _bytes,
          200,
          headers: {'content-type': 'image/png'},
        ),
      );

      final image = await downloadLookImage(
        'https://x.test/look',
        client: client,
      );

      expect(image?.bytes, _bytes);
      expect(image?.mimeType, 'image/png');
      expect(image?.fileName, 'banigoba_look.png');
    });

    test('treats a non-image content type as a jpeg', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          _bytes,
          200,
          headers: {'content-type': 'application/octet-stream'},
        ),
      );

      final image = await downloadLookImage(
        'https://x.test/look',
        client: client,
      );

      expect(image?.mimeType, 'image/jpeg');
      expect(image?.fileName, 'banigoba_look.jpg');
    });

    test('drops content type parameters', () async {
      final client = MockClient(
        (_) async => http.Response.bytes(
          _bytes,
          200,
          headers: {'content-type': 'image/webp; charset=binary'},
        ),
      );

      final image = await downloadLookImage(
        'https://x.test/look',
        client: client,
      );

      expect(image?.mimeType, 'image/webp');
    });

    test('returns null when the picture is missing', () async {
      final client = MockClient((_) async => http.Response('nope', 404));

      expect(
        await downloadLookImage('https://x.test/look', client: client),
        isNull,
      );
    });

    test('returns null when the body is empty', () async {
      final client = MockClient((_) async => http.Response('', 200));

      expect(
        await downloadLookImage('https://x.test/look', client: client),
        isNull,
      );
    });

    test('returns null when the network fails', () async {
      final client = MockClient(
        (_) async => throw http.ClientException('down'),
      );

      expect(
        await downloadLookImage('https://x.test/look', client: client),
        isNull,
      );
    });
  });
}
