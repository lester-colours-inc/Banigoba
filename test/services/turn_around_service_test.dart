// Verifies the turn-around prompts and the generate-one-angle-at-a-time flow.
import 'dart:typed_data';

import 'package:banigoba/data/services/gemini_image_api.dart';
import 'package:banigoba/data/services/turn_around_service.dart';
import 'package:flutter_test/flutter_test.dart';

GeminiImage _image(String url) => GeminiImage(
  bytes: Uint8List.fromList(url.codeUnits),
  mimeType: 'image/png',
);

void main() {
  group('turnAroundPrompt', () {
    test('describes each angle and the attached images', () {
      final back = turnAroundPrompt(TurnView.back, garmentCount: 2);
      expect(back, contains('from directly behind'));
      expect(back, contains('The remaining 2 image(s)'));
      expect(
        turnAroundPrompt(TurnView.right, garmentCount: 0),
        isNot(contains('remaining')),
      );
      expect(
        turnAroundPrompt(TurnView.left, garmentCount: 1),
        contains('left side'),
      );
    });

    test('keeps the person and outfit and admits unseen backs are guessed', () {
      final prompt = turnAroundPrompt(TurnView.back, garmentCount: 1);
      expect(prompt, contains('exactly this person'));
      expect(prompt, contains('not visible in the references'));
    });
  });

  group('TurnAroundService.run', () {
    late List<String> uploaded;
    late List<String> prompts;
    late List<List<GeminiImage>> sentImages;

    TurnAroundService service({int failOn = -1}) {
      uploaded = [];
      prompts = [];
      sentImages = [];
      return TurnAroundService(
        fetch: (url) async => _image(url),
        generate: (images, prompt) async {
          if (prompts.length == failOn) throw Exception('model refused');
          prompts.add(prompt);
          sentImages.add(images);
          return Uint8List.fromList([prompts.length]);
        },
        upload: (bytes) async {
          final url = 'https://x/view-${bytes.first}.png';
          uploaded.add(url);
          return url;
        },
      );
    }

    test('makes right, back and left in order and keeps the front', () async {
      final seen = <TurnView>[];
      final views = await service().run(
        frontUrl: 'front',
        avatarUrl: 'avatar',
        garmentUrls: ['g1', '', 'g2'],
        onView: (view, _) => seen.add(view),
      );

      expect(seen, [TurnView.right, TurnView.back, TurnView.left]);
      expect(views.keys, TurnView.values);
      expect(views[TurnView.front], 'front');
      expect(views[TurnView.back], 'https://x/view-2.png');
      expect(prompts[0], contains('right side'));
      expect(prompts[1], contains('directly behind'));
      expect(prompts[2], contains('left side'));
    });

    test('sends the front, the photo, then up to three garments', () async {
      await service().run(
        frontUrl: 'front',
        avatarUrl: 'avatar',
        garmentUrls: ['a', 'b', 'c', 'd', 'e'],
      );
      final names = sentImages.first
          .map((image) => String.fromCharCodes(image.bytes))
          .toList();
      expect(names, ['front', 'avatar', 'a', 'b', 'c']);
    });

    test('keeps the angles already made when a later one fails', () async {
      final seen = <TurnView>[];
      await expectLater(
        service(failOn: 1).run(
          frontUrl: 'front',
          avatarUrl: 'avatar',
          onView: (view, _) => seen.add(view),
        ),
        throwsException,
      );
      expect(seen, [TurnView.right]);
    });
  });
}
