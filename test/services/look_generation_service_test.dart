import 'dart:typed_data';

import 'package:banigoba/data/models/look_request.dart';
import 'package:banigoba/data/services/look_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGenerator implements LookImageGenerator {
  _FakeGenerator({this.isConfigured = true, this.error});

  @override
  final bool isConfigured;
  final Exception? error;
  final List<String> prompts = [];
  final List<String> photoUrls = [];
  final List<List<String>> references = [];

  @override
  Future<Uint8List> generate({
    required String photoUrl,
    required String prompt,
    List<String> referenceImageUrls = const [],
  }) async {
    prompts.add(prompt);
    photoUrls.add(photoUrl);
    references.add(referenceImageUrls);
    if (error case final failure?) throw failure;
    return Uint8List.fromList([1, 2, 3]);
  }
}

const _ready = LookRequest(
  photoUrl: 'https://example.com/me.jpg',
  scope: LookScope.hair,
  source: DescribeSource('low haircut'),
);

void main() {
  test('generates exactly one image and returns its uploaded URL', () async {
    final generator = _FakeGenerator();
    final uploads = <String>[];
    final service = LookGenerationService(
      generator: generator,
      upload: (bytes, userId) async {
        uploads.add(userId);
        return 'https://example.com/look.jpg';
      },
      currentUserId: () => 'user-1',
    );

    final look = await service.generate(_ready, part: LookPart.hair);

    expect(look.imageUrl, 'https://example.com/look.jpg');
    expect(generator.prompts, hasLength(1));
    expect(generator.prompts.single, contains('"low haircut"'));
    expect(uploads, ['user-1']);
  });

  test('a step builds on the image the user kept last', () async {
    final generator = _FakeGenerator();
    final service = LookGenerationService(
      generator: generator,
      upload: (_, _) async => 'https://example.com/shoes.jpg',
      currentUserId: () => 'user-1',
    );

    await service.generate(
      _ready,
      part: LookPart.shoes,
      baseImageUrl: 'https://example.com/after-hair.jpg',
      tweak: 'white sneakers',
    );

    expect(generator.photoUrls.single, 'https://example.com/after-hair.jpg');
    expect(generator.prompts.single, contains('Change only the shoes'));
    expect(generator.prompts.single, contains('"white sneakers"'));
  });

  test('a style twin sends the look to copy after the photo', () async {
    final generator = _FakeGenerator();
    final service = LookGenerationService(
      generator: generator,
      upload: (_, _) async => 'https://example.com/look.jpg',
      currentUserId: () => 'user-1',
    );

    await service.generate(
      const LookRequest(
        photoUrl: 'https://example.com/me.jpg',
        scope: LookScope.outfit,
        source: TwinSource(imageUrl: 'https://example.com/twin.jpg'),
      ),
      part: LookPart.outfit,
    );

    expect(generator.photoUrls.single, 'https://example.com/me.jpg');
    expect(generator.references.single, ['https://example.com/twin.jpg']);
  });

  test('asks the user to sign in when nobody is signed in', () async {
    final service = LookGenerationService(
      generator: _FakeGenerator(),
      upload: (_, _) async => '',
      currentUserId: () => '',
    );

    expect(
      () => service.generate(_ready, part: LookPart.hair),
      throwsA(
        isA<LookGenerationException>().having(
          (error) => error.message,
          'message',
          contains('Sign in'),
        ),
      ),
    );
  });

  test('refuses an incomplete request without calling the provider', () async {
    final generator = _FakeGenerator();
    final service = LookGenerationService(
      generator: generator,
      upload: (_, _) async => '',
      currentUserId: () => 'user-1',
    );

    await expectLater(
      service.generate(
        const LookRequest(
          photoUrl: '',
          scope: LookScope.hair,
          source: DescribeSource('x'),
        ),
        part: LookPart.hair,
      ),
      throwsA(isA<LookGenerationException>()),
    );
    expect(generator.prompts, isEmpty);
  });

  test('explains a missing API key instead of calling the provider', () async {
    final generator = _FakeGenerator(isConfigured: false);
    final service = LookGenerationService(
      generator: generator,
      upload: (_, _) async => '',
      currentUserId: () => 'user-1',
    );

    await expectLater(
      service.generate(_ready, part: LookPart.hair),
      throwsA(
        isA<LookGenerationException>().having(
          (error) => error.message,
          'message',
          contains('dart-define'),
        ),
      ),
    );
    expect(generator.prompts, isEmpty);
  });

  test('turns provider failures into a friendly message', () async {
    final service = LookGenerationService(
      generator: _FakeGenerator(error: Exception('HTTP 500 from provider')),
      upload: (_, _) async => '',
      currentUserId: () => 'user-1',
    );

    await expectLater(
      service.generate(_ready, part: LookPart.hair),
      throwsA(
        isA<LookGenerationException>().having(
          (error) => error.message,
          'message',
          allOf(contains('try again'), isNot(contains('500'))),
        ),
      ),
    );
  });
}
