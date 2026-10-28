import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:banigoba/data/services/result_mirror.dart';

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('returns our own copy of a hosted result', () async {
    final mirror = ResultMirror(
      fetch: (url) async => bytes,
      upload: (data, userId) async => 'https://storage/$userId/${data.length}',
    );

    final url = await mirror.keep('https://media.fashn.ai/a.png', 'u1');

    expect(url, 'https://storage/u1/3');
  });

  test('keeps the original url when the download fails', () async {
    final mirror = ResultMirror(
      fetch: (url) async => throw Exception('blocked by CORS'),
      upload: (data, userId) async => fail('should not upload'),
    );

    final url = await mirror.keep('https://media.fashn.ai/a.png', 'u1');

    expect(url, 'https://media.fashn.ai/a.png');
  });

  test('keeps the original url when the upload fails', () async {
    final mirror = ResultMirror(
      fetch: (url) async => bytes,
      upload: (data, userId) async => throw Exception('offline'),
    );

    final url = await mirror.keep('https://media.fashn.ai/a.png', 'u1');

    expect(url, 'https://media.fashn.ai/a.png');
  });

  test('leaves our own storage urls alone', () async {
    final mirror = ResultMirror(
      fetch: (url) async => fail('should not download'),
      upload: (data, userId) async => fail('should not upload'),
    );

    const own = 'https://firebasestorage.googleapis.com/v0/b/x/o/a.jpg';
    expect(await mirror.keep(own, 'u1'), own);
  });
}
