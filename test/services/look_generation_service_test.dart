import 'package:banigoba/modules/provider/models/look_request.dart';
import 'package:banigoba/modules/makeover/services/ai_job_service.dart';
import 'package:banigoba/modules/makeover/services/look_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGenerator implements LookImageGenerator {
  _FakeGenerator({this.isConfigured = true, this.error});

  @override
  final bool isConfigured;
  final Exception? error;
  static const String url = 'https://example.com/look.jpg';
  final List<String> prompts = [];
  final List<String> photoUrls = [];
  final List<List<String>> references = [];

  @override
  Future<String> generate({
    required String photoUrl,
    required String prompt,
    List<String> referenceImageUrls = const [],
  }) async {
    prompts.add(prompt);
    photoUrls.add(photoUrl);
    references.add(referenceImageUrls);
    if (error case final failure?) throw failure;
    return url;
  }
}

const _ready = LookRequest(
  photoUrl: 'https://example.com/me.jpg',
  scope: LookScope.hair,
  source: DescribeSource('low haircut'),
);

void main() {
  test('generates exactly one image and returns its URL', () async {
    final generator = _FakeGenerator();
    final service = LookGenerationService(
      generator: generator,
      currentUserId: () => 'user-1',
    );

    final look = await service.generate(_ready, part: LookPart.hair);

    expect(look.imageUrl, 'https://example.com/look.jpg');
    expect(generator.prompts, hasLength(1));
    expect(generator.prompts.single, contains('"low haircut"'));
  });

  test('a step builds on the image the user kept last', () async {
    final generator = _FakeGenerator();
    final service = LookGenerationService(
      generator: generator,
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

  test('says so when generation is unavailable, without calling it', () async {
    final generator = _FakeGenerator(isConfigured: false);
    final service = LookGenerationService(
      generator: generator,
      currentUserId: () => 'user-1',
    );

    await expectLater(
      service.generate(_ready, part: LookPart.hair),
      throwsA(
        isA<LookGenerationException>().having(
          (error) => error.message,
          'message',
          contains('not available'),
        ),
      ),
    );
    expect(generator.prompts, isEmpty);
  });

  test('turns provider failures into a friendly message', () async {
    final service = LookGenerationService(
      generator: _FakeGenerator(error: Exception('HTTP 500 from provider')),
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

  test('passes on that a slow look will arrive by notification', () async {
    final service = LookGenerationService(
      generator: _FakeGenerator(
        error: const AiJobException(
          'This is taking a while. We will let you know when it is ready.',
          isStillRunning: true,
        ),
      ),
      currentUserId: () => 'user-1',
    );

    await expectLater(
      service.generate(_ready, part: LookPart.hair),
      throwsA(
        isA<LookGenerationException>().having(
          (error) => error.message,
          'message',
          contains('let you know'),
        ),
      ),
    );
  });
}
